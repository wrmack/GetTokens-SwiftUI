//
//  ContentInteractor.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 30/07/21.
//

import Foundation
import Combine
import AuthenticationServices


//struct Config: Codable {
//    var issuer: String
//    var jwks_uri: String
//}



/// `ContentInteractor` is responsible for interacting with the data model and the network.
///
/// `ContentView` is the main app UI. It works with `ContentInteractor` and `ContentPresenter`.
///
/// `ContentInteractor` is responsible for interacting with the data model and the network.
///
/// `ContentPresenter` is responsible for formatting data it receives from `ContentInteractor`
/// so that it is ready for presentation by `ContentView`. It is initialised as a `@StateObject`
/// to ensure there is only one instance and it notifies new content through a publisher.
///
/// This pattern is based on the VIP (View-Interactor-Presenter) and VMVM (View-Model-ViewModel) patterns.
///
/// `ContentInteractor` uses the ASWebAuthenticationSession API for logging into a Solid OP in order to receive an access token.
class ContentInteractor: NSObject, ASWebAuthenticationPresentationContextProviding {
    
    // Function required by ASWebAuthenticationPresentationContextProviding protocol
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    private var cancellable: AnyCancellable?

    
    // MARK: - Discover provider configuration
    
    /// Discovers the provider's OIDC configuration.
    /// - Parameters:
    ///     - providerPath: The path to the OIDC Provider eg https://solidcommunity.net
    ///     - presenter: The `ContentPresenter` to send new data to for presenting to `ContentView`
    ///     - authState: The `AuthState` object which holds data we want to track
    /// - Note: From [OpenID Connect Discovery 1.0, part 4](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig):
    ///
    /// An OpenID Provider Configuration Document MUST be queried using an HTTP GET request.
    ///
    /// A successful response MUST use the 200 OK HTTP status code and return a JSON object using the application/json content type that contains a set of Claims.
    func discoverConfiguration(providerPath: String, presenter: ContentPresenter, authState: AuthState) {
        
        presenter.presentTitle(title: "Fetching configuration...")
        
        // Create base URL from input string
        guard let providerURL = URL(string: providerPath) else {
            print("Error creating URL for : \(providerPath)")
            return
        }

        // Add path to configuration end-point
        let discoveryURL = providerURL.appendingPathComponent(".well-known/openid-configuration")
        
        // Create url session publisher
        // Publisher returns a tuple comprising data, response
        // tryMap() checks the response component for status code 200 and returns the data component
        // sink() receives only the data
        cancellable = URLSession.shared
            .dataTaskPublisher(for: discoveryURL)
            .receive(on: DispatchQueue.main)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }
                return element.data
                }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        print("Successfully discovered configuration")
                    }
                },
                receiveValue: { [self] data in
                    // Update state with configuration data
                    authState.updateAuthStateWithConfig(JSONData: data)
                    // Send configuration data to presenter
                    presenter.presentData(data: data, requestUrl: discoveryURL, flowStage: "Discovery")
                    // Move to next stage
                    registerClient(presenter: presenter, authState: authState)
                }
            )
        

    }
    
    // MARK: - Register client
    
    /// Registers the client (Get tokens) with the authorization server using dynamic registration.
    /// - Parameters:
    ///     - presenter: The `ContentPresenter` to send new data to for presenting to `ContentView`
    ///     - authState: The `AuthState` object which holds data we want to track
    /// - Note: From [OpenID Connect Dynamic Client Registration 1.0](https://openid.net/specs/openid-connect-registration-1_0.html):
    ///
    /// To register a new Client at the Authorization Server, the Client sends an HTTP POST message to the Client Registration Endpoint with any
    /// Client Metadata parameters that the Client chooses to specify for itself during the registration. The Authorization Server assigns this Client a
    /// unique Client Identifier, optionally assigns a Client Secret, and associates the Metadata given in the request with the issued Client Identifier.
    /// The Authorization Server MAY provision default values for any items omitted in the Client Metadata.
    ///
    /// The Authorization Server MAY reject or replace any of the Client's requested field values and substitute them with suitable values. If this
    /// happens, the Authorization Server MUST include these fields in the response to the Client. An Authorization Server MAY ignore values
    /// provided by the client, and MUST ignore any fields sent by the Client that it does not understand.
    ///
    ///A successful **response** SHOULD use the HTTP 201 Created status code and return a JSON document [RFC4627] using the application/json
    ///content type with the following fields and the Client Metadata parameters as top-level members of the root JSON object:
    ///
    /// - `client_id` REQUIRED. Unique Client Identifier. It MUST NOT be currently valid for any other registered Client.
    /// - `client_secret` OPTIONAL. Client Secret. The same Client Secret value MUST NOT be assigned to multiple Clients.
    /// - `registration_access_token` OPTIONAL. Registration Access Token that can be used at the Client Configuration Endpoint to perform subsequent
    /// operations upon the Client registration.
    /// - `registration_client_uri` OPTIONAL. Location of the Client Configuration Endpoint where the Registration Access Token can be used to
    /// perform subsequent operations upon the resulting Client registration. Implementations MUST either return both a Client Configuration Endpoint and
    /// a Registration Access Token or neither of them.
    /// - `client_id_issued_at` OPTIONAL. Time at which the Client Identifier was issued.
    /// `- client_secret_expires_at` REQUIRED if `client_secret` is issued. Time at which the client_secret will expire or 0 if it will not expire.
    func registerClient(presenter: ContentPresenter, authState: AuthState) {
        
        presenter.presentTitle(title: "Registering client...")
        
        let configuration = authState.opConfig
        guard let redirectURI = URL(string: authState.kRedirectURI) else {
            print("Error creating URL for : \(authState.kRedirectURI)")
            return
        }
        
        var request = RegistrationRequest()
        request.configuration = configuration
        request.redirectURIs = [redirectURI]
        request.responseTypes = ["code"]
        request.grantTypes = ["authorization_code"]
        request.subjectType = nil
        request.tokenEndpointAuthenticationMethod = "client_secret_post"
        request.initialAccessToken = nil
        request.additionalParameters = nil
        request.applicationType = kApplicationTypeNative
        request.clientName = "Get tokens"
        
        let URLRequest = request.urlRequest()
        
        if URLRequest == nil {
            // A problem occurred deserializing the response/JSON.
            let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.JSONSerializationError, underlyingError: nil, description: """
                The registration request could not \
                be serialized as JSON.
                """)
            DispatchQueue.main.async(execute: {
                print("Registration error: \(returnedError?.localizedDescription ?? "DEFAULT_ERROR")")
            })
            return
        }
        
        
        cancellable = URLSession.shared
            .dataTaskPublisher(for: URLRequest!)
            .receive(on: DispatchQueue.main)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse
                    else {
                        throw URLError(.badServerResponse)
                    }
                print("Response status code: \(httpResponse.statusCode)")
                return element.data
                }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("Received error: \(error)")
                    case .finished:
                        print("Success")
                    }
                },
                receiveValue: { [self] data in
                    // Update state with registration data
                    authState.updateAuthStateWithRegistration(request: request, data: data)
                    // Send registration data to presenter
                    presenter.presentData(data: data, requestUrl: URLRequest!.url!, flowStage: "Registration")
                    // Move to next stage
                    fetchProviderAuthorizationCode(presenter: presenter, authState: authState)
                    
                }
            )
    }
    
    // MARK: - Authorization and receipt of access token
    
    /// 
    func fetchProviderAuthorizationCode(presenter: ContentPresenter, authState: AuthState) {
        
        presenter.presentTitle(title: "Authorizing client...")
        
        guard let redirectURI = URL(string: authState.kRedirectURI) else { print("Error creating URL for : \(authState.kRedirectURI)"); return }
        let configuration = authState.opConfig
        let registrationResponse = authState.registrationResponse
        let clientID = registrationResponse!.clientID
        let clientSecret = registrationResponse!.clientSecret
        
        let request = AuthorizationRequest(
            configuration: configuration,
            clientId: clientID,
            clientSecret: clientSecret,
            scopes: [kScopeOpenID, kScopeProfile, kScopeOfflineAccess],
            redirectURL: redirectURI,
            responseType: kResponseTypeCode
        )
        
        
        cancellable = Future<URL, Error> { completion in
                    
            let authSession = ASWebAuthenticationSession(
                url: request.authorizationRequestURL()!,
                callbackURLScheme: request.redirectURL?.scheme) { (url, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
            
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = true
            authSession.start()
        }
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                print("Received error: \(error)")
            case .finished:
                print("Success")
            }
        },
        receiveValue: { [self] url in
            authState.updateAuthStateWithAuthentication(request: request, url: url)
            presenter.presentDataFromURL(dataURL: url, requestUrl: request.authorizationRequestURL()!, flowStage: "Authorization")
            fetchTokensFromTokenEndpoint(presenter: presenter, authState: authState)
        })
    }
    
    
    // MARK: - Fetch tokens
    
    func fetchTokensFromTokenEndpoint(presenter: ContentPresenter, authState: AuthState)  {
        
        presenter.presentTitle(title: "Fetching tokens...")
        
        let authorizationRequest = authState.authorizationResponse?.request
        let tokenExchangeRequest = TokenRequest(configuration: authorizationRequest?.configuration,
            grantType: kGrantTypeAuthorizationCode,
            authorizationCode: authState.authorizationResponse!.authorizationCode,
            redirectURL: authorizationRequest!.redirectURL,
            clientID: authorizationRequest!.clientID,
            clientSecret: authorizationRequest!.clientSecret,
            scope: nil,
            refreshToken: nil,
            codeVerifier: authorizationRequest!.codeVerifier,
            nonce: authorizationRequest?.nonce
//            additionalParameters: authorizationRequest!.additionalParameters
        )
        let URLRequest = tokenExchangeRequest.urlRequest()
        print("URLRequest for tokens: \(URLRequest)")
        print("URLRequest for tokens showing body: \(tokenExchangeRequest.description(request: URLRequest)!)")
        
        cancellable = URLSession.shared
            .dataTaskPublisher(for: URLRequest)
            .receive(on: DispatchQueue.main)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }
                return element.data
                }
//            .decode(type: Config.self, decoder: JSONDecoder())
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("Error fetching tokens: \(error)")
                    case .finished:
                        print("Success fetching tokens")
                    }
                },
                receiveValue: { [self] data in                    
                    authState.updateAuthStateWithTokens(tokenExchangeRequest: tokenExchangeRequest, JSONData: data)
                    presenter.presentData(data: data, requestUrl: URLRequest.url!, flowStage: "Tokens")
                    fetchUserInfo(presenter: presenter, authState: authState)
                }
            )
        
    }
    
    // MARK: - Get userinfo 
    
    func fetchUserInfo(presenter: ContentPresenter, authState: AuthState) {
        let userinfoEndpoint = authState.opConfig?.userInfoEndpoint
        if userinfoEndpoint == nil {
            print("Userinfo endpoint not declared in discovery document")
            return
        }
        let currentAccessToken = authState.tokenResponse!.accessToken
        print("Performing userinfo request")
        let tokenManager = TokenManager(authState: authState)
        tokenManager.performActionWithFreshTokens() { accessToken, idToken, error in

            if error != nil {
                print("Error fetching fresh tokens: \(error!.localizedDescription)")
                return
            }

            // log whether a token refresh occurred
            if currentAccessToken != accessToken {
                print("Access token was refreshed automatically")
            } else {
                print("Access token was fresh and not updated \(accessToken!)")
            }

            // creates request to the userinfo endpoint, with access token in the Authorization header  // check 'Content-Type': 'application/json'
            var request =  URLRequest(url: userinfoEndpoint!)
            request.httpMethod = "GET"
            request.addValue("DPoP \(accessToken!)", forHTTPHeaderField: "authorization")
            request.addValue("\(self.dpopToken(authState: authState)!)", forHTTPHeaderField: "dpop")
            request.addValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            
            self.cancellable = URLSession.shared
                .dataTaskPublisher(for:request)
                .receive(on: DispatchQueue.main)
                .tryMap() { element -> Data in
                    guard let httpResponse = element.response as? HTTPURLResponse,
                        httpResponse.statusCode == 200 else {
                            throw URLError(.badServerResponse)
                        }
                    return element.data
                    }
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            print("Error fetching userinfo \(error)")
                        case .finished:
                            print("Success fetching userinfo")
                        }
                    },
                    receiveValue: {  data in
                        print("Data from userinfo: \(data)")
                        presenter.presentData(data: data, requestUrl: request.url!, flowStage: "Userinfo")
                    }
                )
        }
    }
    
    func dpopToken(authState: AuthState) -> String? {
        let keys = authState.tokenResponse!.request!.dpopKeyPair
        
        // Form JWK
        let jwkPublicKey = try! RSAPublicKey(publicKey: keys!.publicKey)
        print("Public key plain text: \(jwkPublicKey.jsonString()!)")
        
        // Header
        var header = JWSHeader(algorithm: .RS256)
        header.typ = "dpop+jwt"
        header.jwkTyped = jwkPublicKey
        
        // Payload
        var randomIdentifier: Data?
        do {
            randomIdentifier = try SecureRandom.generate(count: 12)
        }
        catch {
            print(error)
        }
        let tokenPayload = TokenPayload(
            htu: authState.opConfig!.userInfoEndpoint!.absoluteString,
            htm: "GET",
            jti: randomIdentifier!.base64EncodedString(),
            iat: Int(Date().timeIntervalSince1970)
        )
        let jsonPayload = try? JSONEncoder().encode(tokenPayload)
        let payload = Payload(jsonPayload!)
        
        // Signer
        let signer = Signer(signingAlgorithm: .RS256, key: keys!.privateKey)
        var jws: JWS?
        do {
            jws = try JWS(header: header, payload: payload, signer: signer!)
        } catch {
            print("jws error \(error)")
        }
        let dpopToken = jws!.compactSerializedString
        print("dpopToken: \(dpopToken)")
        return dpopToken
    }
}
