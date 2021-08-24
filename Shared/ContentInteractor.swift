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

struct RequestDescription {
    var httpMethod: String
    var httpHeaders: [String : String]
    var httpBody: Data
    var url: URL
}



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
    ///
    /// From [OpenID Connect Discovery 1.0, part 4](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig):
    ///
    /// An OpenID Provider Configuration Document MUST be queried using an HTTP GET request.
    ///
    /// A successful response MUST use the 200 OK HTTP status code and return a JSON object using the application/json content type that contains a set of Claims.
    ///
    /// From [Solid-OIDC]()
    ///
    /// An Identity Provider that conforms to the Solid-OIDC specification MUST advertise this in the OpenID Connect Discovery 1.0 resource. An Identity Provider would indicate this support by using the solid_oidc_supported metadata property, referencing the Solid-OIDC specification URL.
    ///
    func discoverConfiguration(providerPath: String, presenter: ContentPresenter, authState: AuthState) {
        
        presenter.displayData = [RowData]()
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
                    presenter.presentResponse(data: data, url: discoveryURL, flowStage: "Discovery")
                    // Move to next stage
                    registerClient(presenter: presenter, authState: authState)
                }
            )
        

    }
    
    // MARK: - Register client
    
    /// Registers the client (Get tokens) with the authorization server using the dynamic registration protocol.
    /// - Parameters:
    ///     - presenter: The `ContentPresenter` to send new data to for presenting to `ContentView`
    ///     - authState: The `AuthState` object which holds data we want to track
    ///
    /// From [OpenID Connect Dynamic Client Registration 1.0](https://openid.net/specs/openid-connect-registration-1_0.html):
    ///
    /// To register a new Client at the Authorization Server, the Client sends an HTTP POST message to the Client Registration Endpoint with any Client Metadata parameters that the Client chooses to specify for itself during the registration. The Authorization Server assigns this Client a unique Client Identifier, optionally assigns a Client Secret, and associates the Metadata given in the request with the issued Client Identifier. The Authorization Server MAY provision default values for any items omitted in the Client Metadata.
    ///
    /// A successful **response** SHOULD use the HTTP 201 Created status code and return a JSON document [RFC4627] using the application/json content type with the following fields and the Client Metadata parameters as top-level members of the root JSON object:
    ///
    /// - `client_id` REQUIRED. Unique Client Identifier. It MUST NOT be currently valid for any other registered Client.
    /// - `client_secret` OPTIONAL. Client Secret. The same Client Secret value MUST NOT be assigned to multiple Clients.
    /// - `registration_access_token` OPTIONAL. Registration Access Token that can be used at the Client Configuration Endpoint to perform subsequent operations upon the Client registration.
    /// - `registration_client_uri` OPTIONAL. Location of the Client Configuration Endpoint where the Registration Access Token can be used to perform subsequent operations upon the resulting Client registration. Implementations MUST either return both a Client Configuration Endpoint and a Registration Access Token or neither of them.
    /// - `client_id_issued_at` OPTIONAL. Time at which the Client Identifier was issued.
    /// - `client_secret_expires_at` REQUIRED if `client_secret` is issued. Time at which the client_secret will expire or 0 if it will not expire.
    ///
    /// From [RFC 8252](https://datatracker.ietf.org/doc/html/rfc8252#section-8.4) OAuth 2.0 for Native Apps:
    ///
    /// Except when using a mechanism like Dynamic Client Registration [RFC7591] to provision per-instance secrets, native apps are classified as public clients, as defined by Section 2.1 of OAuth 2.0 [RFC6749]; they MUST be registered with the authorization server as such.  Authorization servers MUST record the client type in the client registration details in order to identify and process requests accordingly.
    ///
    /// Authorization servers MUST require clients to register their complete redirect URI (including the path component) and reject authorization requests that specify a redirect URI that doesn't exactly match the one that was registered; the exception is loopback redirects, where an exact match is required except for the port URI component.
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
        request.tokenEndpointAuthenticationMethod = "none"
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
                    presenter.presentResponse(data: data, urlRequest: URLRequest!, flowStage: "Registration")
                    // Move to next stage
                    fetchAuthorizationCode(presenter: presenter, authState: authState)
                    
                }
            )
    }
    
    // MARK: - Authorization and receipt of authorization code
    
    /// Sends an authentication request to the authorization endpoint. The request contains the client ID obtained from registering the client and a redirect url.
    /// The authorization server presents a log-in page using an 'external user-agent' (browser).  When the user has been authenticated and the user has given consent for the client (Get tokens) to access the user's resources, the authorization returns an authorization code to the redirect url.  The authorization code is used for requesting tokens.
    ///
    /// - Parameters:
    ///     - presenter: The `ContentPresenter` to send new data to for presenting to `ContentView`
    ///     - authState: The `AuthState` object which holds data we want to track
    ///
    /// From: [OpenID](https://openid.net/specs/openid-connect-core-1_0.html#CodeFlowAuth):
    ///
    /// The Authorization Code Flow returns an Authorization Code to the Client, which can then exchange it for an ID Token and an Access Token directly. This provides the benefit of not exposing any tokens to the User Agent and possibly other malicious applications with access to the User Agent.
    ///
    /// An Authentication Request is an OAuth 2.0 Authorization Request that requests that the End-User be authenticated by the Authorization Server. Clients MAY use the HTTP GET or POST methods to send the Authorization Request to the Authorization Server.
    ///
    /// OpenID Connect uses the following OAuth 2.0 request parameters with the Authorization Code Flow:
    ///
    /// - `scope` REQUIRED. OpenID Connect requests MUST contain the openid scope value. If the openid scope value is not present, the behavior is entirely unspecified. Other scope values MAY be present. Scope values used that are not understood by an implementation SHOULD be ignored. See Sections 5.4 and 11 for additional scope values defined by this specification.
    /// - `response_type` REQUIRED. OAuth 2.0 Response Type value that determines the authorization processing flow to be used, including what parameters are returned from the endpoints used. When using the Authorization Code Flow, this value is code.
    /// - `client_id` REQUIRED. OAuth 2.0 Client Identifier valid at the Authorization Server.
    /// - `redirect_uri`  REQUIRED. Redirection URI to which the response will be sent.
    /// - `state` RECOMMENDED. Opaque value used to maintain state between the request and the callback. Typically, Cross-Site Request Forgery (CSRF, XSRF) mitigation is done by cryptographically binding the value of this parameter with a browser cookie.
    ///
    /// **Proof Key for Code Exchange (PKCE)**
    ///
    /// From [RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636)
    ///
    /// The Authorization Code is returned to the requester via the Redirection Endpoint URI. it is possible for a malicious app to register itself as a handler for the custom scheme in addition to the legitimate OAuth 2.0  app.  Once it does so, the malicious app is now able to intercept the authorization code.  This allows the attacker to request and obtain an access token.
    ///
    /// To mitigate this attack, this extension utilizes a dynamically created cryptographically random key called "code verifier".  A unique code verifier is created for every authorization request, and its transformed value, called "code challenge", is sent to the authorization server to obtain the authorization code.  The authorization code obtained is then sent to the token endpoint with the "code verifier", and the server compares it with the previously received request code so that it can perform the proof of possession of the "code verifier" by the client.  This works as the mitigation since the attacker would not know this one-time key, since it is sent over TLS and cannot be intercepted.
    ///
    /// The `code_challenge` is `BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))`
    ///
    func fetchAuthorizationCode(presenter: ContentPresenter, authState: AuthState) {
        
        presenter.presentTitle(title: "Authorizing client...")
        
        guard let redirectURI = URL(string: authState.kRedirectURI) else { print("Error creating URL for : \(authState.kRedirectURI)"); return }
        let configuration = authState.opConfig
        let clientID = authState.registrationResponse!.clientID
//        let clientSecret = registrationResponse!.clientSecret
        
        let request = AuthorizationRequest(
            configuration: configuration,
            clientId: clientID,
//            clientSecret: clientSecret,
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
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Received error: \(error)")
                case .finished:
                    print("Success")
                }
            },
            receiveValue: { [self] url in
                // Update state with authorization data
                authState.updateAuthStateWithAuthorization(request: request, url: url)
                // Send authorization data to presenter
                presenter.presentResponse(dataURL: url, url: request.authorizationRequestURL()!, flowStage: "Authorization")
                // Move to next stage
                fetchTokensFromTokenEndpoint(presenter: presenter, authState: authState)
            }
        )
    }
    
    
    // MARK: - Fetch tokens
    
    /// Exchanges the authorization code for an access token, id token and refresh token
    ///
    /// - Parameters:
    ///     - presenter: The `ContentPresenter` to send new data to for presenting to `ContentView`
    ///     - authState: The `AuthState` object which holds data we want to track
    ///
    /// From: [OpenID](https://openid.net/specs/openid-connect-core-1_0.html#TokenRequest)
    ///
    /// A Client makes a Token Request by presenting its Authorization Grant (in the form of an Authorization Code) to the Token Endpoint using the `grant_type` value `authorization_code`, as described in Section 4.1.3 of OAuth 2.0 [RFC6749]. If the Client is a Confidential Client, then it MUST authenticate to the Token Endpoint using the authentication method registered for its client_id, as described in Section 9.
    ///
    /// The Client sends the parameters to the Token Endpoint using the HTTP POST method and the Form Serialization, per Section 13.2, as described in Section 4.1.3 of OAuth 2.0 [RFC6749].
    func fetchTokensFromTokenEndpoint(presenter: ContentPresenter, authState: AuthState)  {
        
        presenter.presentTitle(title: "Fetching tokens...")
        
        let authorizationRequest = authState.authorizationResponse?.request
        let tokenExchangeRequest = TokenRequest(configuration: authorizationRequest?.configuration,
            grantType: kGrantTypeAuthorizationCode,
            authorizationCode: authState.authorizationResponse!.authorizationCode,
            redirectURL: authorizationRequest!.redirectURL,
            clientID: authorizationRequest!.clientID,
//            clientSecret: authorizationRequest!.clientSecret,
            clientSecret: nil,
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
                    presenter.presentResponse(data: data, urlRequest: URLRequest, flowStage: "Tokens")
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
                        presenter.presentResponse(data: data, urlRequest: request, flowStage: "Userinfo")
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
