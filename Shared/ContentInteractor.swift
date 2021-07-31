//
//  ContentInteractor.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 30/07/21.
//

import Foundation
import Combine
import AuthenticationServices


struct Config: Codable {
    var issuer: String
    var jwks_uri: String
}

class ContentInteractor: NSObject, ASWebAuthenticationPresentationContextProviding {
    
    // Function required by ASWebAuthenticationPresentationContextProviding protocol
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    private var cancellable: AnyCancellable?

    
    // Fetch OIDC Provider configuration
    func fetchConfiguration(providerPath: String, presenter: ContentPresenter, authState: AuthState) {
        
        // Create URL from input string
        guard let providerURL = URL(string: providerPath) else {
            print("Error creating URL for : \(providerPath)")
            return
        }
        presenter.displayData = "Getting info ....."
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
                    print("Value: \(data)")
                    updateAuthStateWithConfig(data: data, authState: authState)
                    presenter.presentData(data: data, url: discoveryURL)
                    registerClient(presenter: presenter, authState: authState)
                }
            )
        

    }
    
    // Register client
    
    func registerClient(presenter: ContentPresenter, authState: AuthState) {
        let configuration = authState.opConfig
        guard let redirectURI = URL(string: authState.kRedirectURI) else {
            print("Error creating URL for : \(authState.kRedirectURI)")
            return
        }
        
        let request = RegistrationRequest(
                configuration: configuration,
                redirectURIs: [redirectURI],
                responseTypes: ["code"],
                grantTypes: ["authorization_code"],
                subjectType: nil,
                tokenEndpointAuthMethod: "client_secret_post",
                additionalParameters: nil
        )
        
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
                    print("Value: \(data)")
                    updateAuthStateWithRegistration(request: request, data: data, authState: authState)
                    presenter.presentData(data: data, url: URLRequest!.url!)
                    authenticateWithProvider(presenter: presenter, authState: authState)
                    
                }
            )
    }
    
    // Authentication request
    
    func authenticateWithProvider(presenter: ContentPresenter, authState: AuthState) {
        
        guard let redirectURI = URL(string: authState.kRedirectURI) else { print("Error creating URL for : \(authState.kRedirectURI)"); return }
        let configuration = authState.opConfig
        let registrationResponse = authState.registrationResponse
        let clientID = registrationResponse!.clientID
        let clientSecret = registrationResponse!.clientSecret
        
        let request = AuthorisationRequest(
            configuration: configuration,
            clientId: clientID,
            clientSecret: clientSecret,
            scopes: [kScopeOpenID, kScopeProfile, kScopeWebID],
            redirectURL: redirectURI,
            responseType: kResponseTypeCode
        )
        
        let signInPromise = Future<URL, Error> { completion in
                    
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
                
        signInPromise.sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                print("Received error: \(error)")
            case .finished:
                print("Success")
            }
        },
        receiveValue: { url in
//            self.processResponseURL(url: url)
            print("Here \(url)")
        })
//        .store(in: &subscriptions)
    }
        
    func updateAuthStateWithConfig(data: Data, authState: AuthState) {
        authState.opConfig = OPConfiguration(JSONData: data)
        print("Here")
    }
    
    func updateAuthStateWithRegistration(request: RegistrationRequest, data: Data, authState: AuthState) {
        var json:[String : Any]?
        do {
            json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
        }
        catch {
            // A problem occurred deserializing the response/JSON.
            let errorDescription = "JSON error parsing registration response: \(error.localizedDescription)"
            let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.JSONDeserializationError, underlyingError: error as NSError, description: errorDescription)
            DispatchQueue.main.async(execute: {
                print("Registration error: \(returnedError!.localizedDescription)")
//                self.setAuthState(nil)
            })
            return
        }
//        self.writeToTextView(status: nil, message: data)
        let registrationResponse = RegistrationResponse(request: request, parameters: json!)
        if registrationResponse == nil {
            // A problem occurred constructing the registration response from the JSON.
            let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.RegistrationResponseConstructionError, underlyingError: nil, description: "Registration response invalid.")
            DispatchQueue.main.async(execute: {
                print("Registration error: \(returnedError!.localizedDescription)")
//                self.setAuthState(nil)
            })
            return
        }
        authState.registrationResponse = registrationResponse
    }
        
}
        

        
//        print("Initiating authorization request with scope: \(request.scope ?? "DEFAULT_SCOPE")")
//        writeToTextView(status: "Requesting authorization...\n\n", message: nil)
        
        // Get HandleAuthenticationServices to launch the ASWebauthenticationServices view controller
        // If successful, the authorization tokens are returned in the callback.
        // The authorization flow is stored in the app delegate.
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { print("Error accessing AppDelegate"); return }
//        let authSession = AuthenticationSession()
//        appDelegate.currentAuthorizationFlow = authSession.fetchAuthState(authorizationRequest: request, presentingViewController: viewController) { authState, error in
//
//            if error != nil {
//                self.writeToTextView(status: "Error", message: error?.localizedDescription)
//            }
//            self.writeToTextView(status: "Got authorization code and state code\n\nRequesting tokens...\n\n", message: nil)
//            self.writeToTextView(status: "Got access token: \n", message: "\(authState!.lastTokenResponse!.accessToken!)\n")
//            self.writeToTextView(status: "\nGot id token: \n", message: "\(authState!.lastTokenResponse!.idToken!)\n")
//            self.writeToTextView(status: "\nGot refresh token:\n", message: "\(authState!.lastTokenResponse!.refreshToken!)")
//            if let authState = authState {
//                self.setAuthState(authState)
//                print("Got authorization tokens. \nAccess token: \(authState.lastTokenResponse!.accessToken!) \nID token: \(authState.lastTokenResponse!.idToken!)")
//            } else {
//                print("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
//                self.setAuthState(nil)
//            }
//        }
//
//    }
    
 
    
    
    
    
    
    
    
    
    
    
    
//        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
//        session.dataTask(with: URLRequest!, completionHandler: { data, response, error in
//
//            if error != nil {
//                // A network error or server error occurred.
//                var errorDescription: String? = nil
//                if let anURL = URLRequest!.url {
//                    errorDescription = "Connection error making registration request to '\(anURL)': \(error?.localizedDescription ?? "")."
//                }
//                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.NetworkError, underlyingError: error as NSError?, description: errorDescription)
//                DispatchQueue.main.async(execute: {
//                    print("Registration error: \(returnedError?.localizedDescription ?? "DEFAULT_ERROR")")
//                    self.setAuthState(nil)
//                })
//                return
//            }
//
//
//            let HTTPURLResponse = response as? HTTPURLResponse
//            if HTTPURLResponse?.statusCode != 201 && HTTPURLResponse?.statusCode != 200 {
//                // A server error occurred.
//                let serverError = ErrorUtilities.HTTPError(HTTPResponse: HTTPURLResponse!, data: data)
//                // HTTP 400 may indicate an OpenID Connect Dynamic Client Registration 1.0 Section 3.3 error
//                // response, checks for that
//                if HTTPURLResponse?.statusCode == 400 {
//                    let json = ((try? JSONSerialization.jsonObject(with: data!, options: []) as? [String : (NSObject & NSCopying)]) as [String : (NSObject & NSCopying)]??)
//                    // if the HTTP 400 response parses as JSON and has an 'error' key, it's an OAuth error
//                    // these errors are special as they indicate a problem with the authorization grant
//                    if json?![OIDOAuthErrorFieldError] != nil {
//                        let oauthError = ErrorUtilities.OAuthError(OAuthErrorDomain: OIDOAuthRegistrationErrorDomain, OAuthResponse: json!, underlyingError: serverError)
//                        DispatchQueue.main.async(execute: {
//                            print("Registration error: \(oauthError.localizedDescription)")
//                            self.setAuthState(nil)
//                        })
//                        return
//                    }
//                }
//                // not an OAuth error, just a generic server error
//                var errorDescription: String? = nil
//                if let anURL = URLRequest!.url {
//                    errorDescription = """
//                    Non-200/201 HTTP response (\(Int(HTTPURLResponse?.statusCode ?? 0))) making registration request \
//                    to '\(anURL)'.
//                    """
//                }
//                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.ServerError, underlyingError: serverError, description: errorDescription)
//                DispatchQueue.main.async(execute: {
//                    print("Registration error: \(returnedError!.localizedDescription)")
//                    self.setAuthState(nil)
//                })
//                return
//            }
//            var json:[String : Any]?
//            do {
//                json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
//            }
//            catch {
//                // A problem occurred deserializing the response/JSON.
//                let errorDescription = "JSON error parsing registration response: \(error.localizedDescription)"
//                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.JSONDeserializationError, underlyingError: error as NSError, description: errorDescription)
//                DispatchQueue.main.async(execute: {
//                    print("Registration error: \(returnedError!.localizedDescription)")
//                    self.setAuthState(nil)
//                })
//                return
//            }
//            self.writeToTextView(status: nil, message: data)
//            let registrationResponse = RegistrationResponse(request: request, parameters: json!)
//            if registrationResponse == nil {
//                // A problem occurred constructing the registration response from the JSON.
//                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.RegistrationResponseConstructionError, underlyingError: nil, description: "Registration response invalid.")
//                DispatchQueue.main.async(execute: {
//                    print("Registration error: \(returnedError!.localizedDescription)")
//                    self.setAuthState(nil)
//                })
//                return
//            }
//
//            // Success
//            self.writeToTextView(status: "------------------------\n\n", message: nil)
//            print("Got registration response: \(registrationResponse.description())")
//
//            DispatchQueue.main.async(execute: {
//                callback(configuration, registrationResponse)
//                session.invalidateAndCancel()
//            })
//
//        }).resume()
        
 


        
        
