//
//  AuthState.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 31/07/21.
//

import Foundation



class AuthState: ObservableObject {
    let kRedirectURI = "com.wm.get-tokens:/mypath"
    var opConfig: OPConfiguration?
    var registrationResponse: RegistrationResponse?
    var authorizationResponse: AuthorizationResponse?
    var tokenResponse: TokenResponse?
    
    /*! @brief Array of pending actions (use @c _pendingActionsSyncObject to synchronize access).
     */
    var pendingActions: [AnyHashable]? = []
    
    /*! @brief If YES, tokens will be refreshed on the next API call regardless of expiry.
     */
    var needsTokenRefresh = false
    
    
    // MARK: - Update AuthState helpers
        
    func updateAuthStateWithConfig(JSONData: Data) {

        var jsonError: NSError?
        var json: [String : Any]?
        do {
            json = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as? [String : Any]
        }
        catch {
            jsonError = ErrorUtilities.error(code: ErrorCode.JSONDeserializationError, underlyingError: jsonError, description: jsonError?.localizedDescription)
        }

        if OPConfiguration.dictionaryHasRequiredFields(dictionary: json!, error: &jsonError) == false {
                return
            }
            
        var opConfig = OPConfiguration()
        opConfig.discoveryDictionary = json!
        opConfig.authorizationEndpoint = URL(string: opConfig.discoveryDictionary![kAuthorizationEndpointKey]! as! String)
        opConfig.tokenEndpoint = URL(string: opConfig.discoveryDictionary![kTokenEndpointKey]! as! String)
        opConfig.issuer = URL(string: opConfig.discoveryDictionary![kIssuerKey]! as! String)
        opConfig.registrationEndpoint = URL(string: opConfig.discoveryDictionary![kRegistrationEndpointKey]! as! String)
        opConfig.userInfoEndpoint = URL(string: opConfig.discoveryDictionary![kUserinfoEndpointKey]! as! String)

        self.opConfig = opConfig
    }
    
    func updateAuthStateWithRegistration(request: RegistrationRequest, data: Data) {
        
        let ClientIDParam = "client_id"
        let ClientIDIssuedAtParam = "client_id_issued_at"
        let ClientSecretParam = "client_secret"
        let ClientSecretExpirestAtParam = "client_secret_expires_at"
        let RegistrationAccessTokenParam = "registration_access_token"
        let RegistrationClientURIParam = "registration_client_uri"
        let kRequestKey = "request"
        //private let kAdditionalParametersKey = "additionalParameters"
        
        
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
        var registrationResponse = RegistrationResponse()
        
        registrationResponse.request = request
            for parameter in json! {
                switch parameter.key {
                case ClientIDParam:
                    registrationResponse.clientID = json![ClientIDParam] as? String
                case ClientIDIssuedAtParam:
                    let rawDate = json![ClientIDIssuedAtParam]
                    registrationResponse.clientIDIssuedAt = Date(timeIntervalSince1970: TimeInterval(Int64(truncating: rawDate as! NSNumber)))
                case ClientSecretParam:
                    registrationResponse.clientSecret = json![ClientSecretParam] as? String
                case ClientSecretExpirestAtParam :
                    let rawDate = json![ClientSecretExpirestAtParam]
                    registrationResponse.clientSecretExpiresAt = Date(timeIntervalSinceNow: TimeInterval(Int64(truncating: rawDate as! NSNumber)))
                case RegistrationAccessTokenParam:
                    registrationResponse.registrationAccessToken = json![RegistrationAccessTokenParam] as? String
                case RegistrationClientURIParam:
                    registrationResponse.registrationClientURI = URL(string: json![RegistrationClientURIParam] as! String)
                case RegistrationAccessTokenParam:
                    registrationResponse.tokenEndpointAuthenticationMethod = json![RegistrationAccessTokenParam] as? String
                default:
                    registrationResponse.additionalParameters[parameter.key] = parameter.value
                }
            }
            //let additionalParameters = OIDFieldMapping.remainingParameters(withMap: RegistrationResponse.sharedFieldMap, parameters: parameters, instance: self)
            //self.additionalParameters = additionalParameters
            
            
            // If client_secret is issued, client_secret_expires_at is REQUIRED,
            // and the response MUST contain "[...] both a Client Configuration Endpoint
            // and a Registration Access Token or neither of them"
        
        // TODO: Uncomment this when Inrupt's ESS complies with the requirement.
//        if (registrationResponse.clientSecret != nil && registrationResponse.clientSecretExpiresAt == nil) {return}
            
        if (!(registrationResponse.registrationClientURI != nil && registrationResponse.registrationAccessToken != nil) && !(registrationResponse.registrationClientURI == nil && registrationResponse.registrationAccessToken == nil)) {
                return
            }
        
        if registrationResponse == nil {
            // A problem occurred constructing the registration response from the JSON.
            let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.RegistrationResponseConstructionError, underlyingError: nil, description: "Registration response invalid.")
            DispatchQueue.main.async(execute: {
                print("Registration error: \(returnedError!.localizedDescription)")
//                self.setAuthState(nil)
            })
            return
        }
        self.registrationResponse = registrationResponse
    }

    func updateAuthStateWithAuthorization(request: AuthorizationRequest, url: URL) {
        let query = QueryUtilities(url:url)
        var error: NSError?
        var response: AuthorizationResponse? = nil
        query.dictionaryValue = query.getDictionaryValue()
        
        // checks for an OAuth error response as per RFC6749 Section 4.1.2.1
        if (query.dictionaryValue[OIDOAuthErrorFieldError] != nil) {
            error = ErrorUtilities.OAuthError(OAuthErrorDomain: OIDOAuthAuthorizationErrorDomain, OAuthResponse: query.dictionaryValue, underlyingError: nil)
        }
        // no error, should be a valid OAuth 2.0 response
        if error == nil {
            response = AuthorizationResponse(request: request, parameters: query.dictionaryValue)
            // verifies that the state in the response matches the state in the request, or both are nil
            //if !OIDIsEqualIncludingNil(x: request!.state, y: response?.state) {
            if request.state != response!.state {
                var userInfo = query.dictionaryValue
                if let aState = response?.state, let aResponse = response {
                    userInfo[NSLocalizedDescriptionKey] = """
                        State mismatch, expecting \(request.state!) but got \(aState) in authorization \
                        response \(aResponse)
                        """ as (NSObject & NSCopying)
                }
                response = nil
                error = NSError(domain: OIDOAuthAuthorizationErrorDomain, code: ErrorCodeOAuthAuthorization.ClientError.rawValue, userInfo: userInfo)
            }
            if response != nil {
                if (request.responseType == kResponseTypeCode) {
                    self.authorizationResponse = response
                    // Exchanges the authorization response for tokens
//                    self.fetchTokensFromTokenEndpoint(authorizationResponse: response) { authState, error in
//                        callback(authState, error)
                    }
                }

            }
        }

    func updateAuthStateWithTokens(tokenExchangeRequest: TokenRequest, JSONData: Data) {
        var json: Any
        var jsonDeserializationError: Error?
        do {
            json = try JSONSerialization.jsonObject(with: JSONData, options: [])
        //            if jsonDeserializationError != nil {
        //                // A problem occurred deserializing the response/JSON.
        //                let errorDescription = "JSON error parsing token response: \(jsonDeserializationError?.localizedDescription ?? "")"
        //                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.JSONDeserializationError, underlyingError: jsonDeserializationError, description: errorDescription)
        //                DispatchQueue.main.async {
        //                    callback(nil, returnedError)
        //                }
        //                return
        //            }
        }
        catch {
            jsonDeserializationError = error
            let errorDescription = "JSON error parsing token response: \(jsonDeserializationError?.localizedDescription ?? "")"
            let returnedError = ErrorUtilities.error(code: ErrorCode.JSONDeserializationError, underlyingError: jsonDeserializationError as NSError?, description: errorDescription)

            DispatchQueue.main.async {
                print("Token error: \(returnedError.localizedDescription)")
            }
            return
        }
        
        let tokenResponse = TokenResponse(request: tokenExchangeRequest, parameters: json as! [String : Any])
        
        if tokenResponse == nil {
            // A problem occurred constructing the token response from the JSON.
            let returnedError = ErrorUtilities.error(code: ErrorCode.TokenResponseConstructionError, underlyingError: jsonDeserializationError as NSError?, description: "Token response invalid.")
            DispatchQueue.main.async {
                print("Token error: \(returnedError.localizedDescription)")
            }
            return
        }
        
        
        // If an ID Token is included in the response, validates the ID Token following the rules
        // in OpenID Connect Core Section 3.1.3.7 for features that AppAuth directly supports
        // (which excludes rules #1, #4, #5, #7, #8, #12, and #13). Regarding rule #6, ID Tokens
        // received by this class are received via direct communication between the Client and the Token
        // Endpoint, thus we are exercising the option to rely only on the TLS validation. AppAuth
        // has a zero dependencies policy, and verifying the JWT signature would add a dependency.
        // Users of the library are welcome to perform the JWT signature verification themselves should
        // they wish.
        if tokenResponse.idToken != nil {
            let idToken = IDToken(idTokenString: tokenResponse.idToken)
            
            if idToken == nil {
                let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenParsingError, underlyingError: nil, description: "ID Token parsing failed")
                DispatchQueue.main.async(execute: {
                    print("Token error: \(invalidIDToken!.localizedDescription)")
                })
                return
            }
        
            // OpenID Connect Core Section 3.1.3.7. rule #1
            // Not supported: AppAuth does not support JWT encryption.
            
            // OpenID Connect Core Section 3.1.3.7. rule #2
            // Validates that the issuer in the ID Token matches that of the discovery document.
            let issuer: URL? = tokenResponse.request!.configuration!.issuer
                if issuer != nil && !(idToken!.issuer == issuer) {
                let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: "Issuer mismatch")
                DispatchQueue.main.async(execute: {
                    print("Token error: \(invalidIDToken!.localizedDescription)")
                })
                return
            }
        
            // OpenID Connect Core Section 3.1.3.7. rule #3
            // Validates that the audience of the ID Token matches the client ID.
            let clientID = tokenResponse.request!.clientID
            if !idToken!.audience!.contains(clientID) {
                let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: "Audience mismatch")
                DispatchQueue.main.async(execute: {
                    print("Token error: \(invalidIDToken!.localizedDescription)")
                })
                return
            }
        
            // OpenID Connect Core Section 3.1.3.7. rules #4 & #5
            // Not supported.
            
            // OpenID Connect Core Section 3.1.3.7. rule #6
            // As noted above, AppAuth only supports the code flow which results in direct communication
            // of the ID Token from the Token Endpoint to the Client, and we are exercising the option to
            // use TSL server validation instead of checking the token signature. Users may additionally
            // check the token signature should they wish.
            
            // OpenID Connect Core Section 3.1.3.7. rules #7 & #8
            // Not applicable. See rule #6.
            
            // OpenID Connect Core Section 3.1.3.7. rule #9
            // Validates that the current time is before the expiry time.
            let expiresAtDifference: TimeInterval = idToken!.expiresAt!.timeIntervalSinceNow
            if expiresAtDifference < 0 {
                let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: "ID Token expired")
                DispatchQueue.main.async(execute: {
                    print("Token error: \(invalidIDToken!.localizedDescription)")
                })
                return
            }
            // OpenID Connect Core Section 3.1.3.7. rule #10
            // Validates that the issued at time is not more than +/- 10 minutes on the current time.
            let issuedAtDifference: TimeInterval = idToken!.issuedAt!.timeIntervalSinceNow
            if abs(Float(issuedAtDifference)) > 600 {
                let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: """
                Issued at time is more than 5 minutes before or after \
                the current time
                """)
                DispatchQueue.main.async(execute: {
                    print("Token error: \(invalidIDToken!.localizedDescription)")
                })
                return
            }
            
            // Only relevant for the authorization_code response type
            if tokenResponse.request!.grantType == kGrantTypeAuthorizationCode {
                // OpenID Connect Core Section 3.1.3.7. rule #11
                // Validates the nonce.
                let nonce = self.authorizationResponse!.request!.nonce
                if nonce != "" && !(idToken!.nonce == nonce) {
                    let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: "Nonce mismatch")
                    DispatchQueue.main.async(execute: {
                        print("Token error: \(invalidIDToken!.localizedDescription)")
                    })
                    return
                }
            }
            // OpenID Connect Core Section 3.1.3.7. rules #12
            // ACR is not directly supported by AppAuth.
            // OpenID Connect Core Section 3.1.3.7. rules #12
            // max_age is not directly supported by AppAuth.
            
            self.tokenResponse = tokenResponse
        
        }
    }
    
    
    
    
    // MARK: - OAuth Requests
//    func tokenRefreshRequest() -> TokenRequest? {
//        return tokenRefreshRequest(withAdditionalParameters: nil)
//    }
//    
//    
//    func tokenRefreshRequest(withAdditionalParameters additionalParameters: [String : AnyCodable]?) -> TokenRequest? {
//        // TODO: Add unit test to confirm exception is thrown when expected
//        if !(tokenResponse?.refreshToken != nil) {
//            ErrorUtilities.raiseException(name: kRefreshTokenRequestException)
//        }
//        return TokenRequest(configuration: authorizationResponse!.request!.configuration, grantType: kGrantTypeRefreshToken, authorizationCode: nil, redirectURL: nil, clientID: authorizationResponse!.request!.clientID, clientSecret:authorizationResponse!.request!.clientSecret, scope: nil, refreshToken: tokenResponse?.refreshToken, codeVerifier: nil, nonce: nil)
//    }
}

class AuthStatePendingAction: NSObject {
    
    
    private(set) var action: ((String?, String?, Error?) -> Void?)?
    private(set) var dispatchQueue: DispatchQueue?
    
    
    init(action: @escaping (String?, String?, Error?) -> Void, andDispatchQueue dispatchQueue: DispatchQueue) {
        super.init()
        
        self.action = action
        self.dispatchQueue = dispatchQueue
    }
}
