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

class ContentInteractor: NSObject, ASWebAuthenticationPresentationContextProviding {
    
    // Function required by ASWebAuthenticationPresentationContextProviding protocol
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    private var cancellable: AnyCancellable?

    
    // MARK: - Fetch provider configuration
    
    func fetchConfiguration(providerPath: String, presenter: ContentPresenter, authState: AuthState) {
        
        presenter.presentTitle(title: "Fetching configuration...")
        
        // Create URL from input string
        guard let providerURL = URL(string: providerPath) else {
            print("Error creating URL for : \(providerPath)")
            return
        }

        let discoveryURL = providerURL.appendingPathComponent(".well-known/openid-configuration")
        
        // Create url session publisher
        // Publisher returns a tuple comprising data, response
        // tryMap() checks the response component for correct status code and returns the data component
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
//            .decode(type: Config.self, decoder: JSONDecoder())
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        print("Success")
                    }
                },
                receiveValue: { [self] data in
                    authState.updateAuthStateWithConfig(JSONData: data)
                    presenter.presentData(data: data, requestUrl: discoveryURL, flowStage: "discovery")
                    registerClient(presenter: presenter, authState: authState)
                }
            )
        

    }
    
    // MARK: - Register client
    
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
//                self.setAuthState(nil)
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
//            .decode(type: Config.self, decoder: JSONDecoder())
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
                    authState.updateAuthStateWithRegistration(request: request, data: data)
                    presenter.presentData(data: data, requestUrl: URLRequest!.url!, flowStage: "registration")
                    fetchProviderAuthorizationCode(presenter: presenter, authState: authState)
                    
                }
            )
    }
    
    // MARK: - Authorization
    
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
            presenter.presentDataFromURL(dataURL: url, requestUrl: request.authorizationRequestURL()!, flowStage: "authorization")
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
                    presenter.presentData(data: data, requestUrl: URLRequest.url!, flowStage: "tokens")
                    fetchUserInfo(presenter: presenter, authState: authState)
                }
            )
        
    }
    
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
    //            .decode(type: Config.self, decoder: JSONDecoder())
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
                        presenter.presentData(data: data, requestUrl: request.url!, flowStage: "userinfo")
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
