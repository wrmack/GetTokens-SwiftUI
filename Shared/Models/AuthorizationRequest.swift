//
//  AuthorizationRequest.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 31/07/21.
//

import Foundation


class AuthorizationRequest: NSObject  {
    
   
    private let OIDOAuthUnsupportedResponseTypeMessage = "The response_type \"%@\" isn't supported. AppAuth only supports the \"code\" or \"code id_token\" response_type."
    
    private(set) var configuration: OPConfiguration?
    
    /// The expected response type.
    ///
    /// Generally 'code' if pure OAuth, otherwise a space-delimited list of of response
    /// types including 'code', 'token', and 'id_token' for OpenID Connect.
    ///
    /// See [IETF]( https://tools.ietf.org/html/rfc6749#section-3.1.1), [OpenID](http://openid.net/specs/openid-connect-core-1_0.html#rfc.section.3)
    /// - remark: `response_type`
    private(set) var responseType = ""
    
    /// The client identifier.
    ///
    /// See IETF: [rfc6749](https://tools.ietf.org/html/rfc6749#section-2.2)
    /// - remark: `client_id`
    private(set) var clientID = ""
    
    /// The client secret.
    ///
    ///  The client secret is used to prove that identity of the client when exchaning an
    ///  authorization code for an access token.
    ///
    /// The client secret is not passed in the authorizationRequestURL. It is only used when
    /// exchanging the authorization code for an access token.
    ///
    /// See IETF: [rfc6749](https://tools.ietf.org/html/rfc6749#section-2.3.1)
    ///  - remark: `client_secret`
    private(set) var clientSecret: String?
    
    /// The value of the scope parameter is expressed as a list of space-delimited,
    /// case-sensitive strings.
    ///
    /// See IETF: [rfc6749](https://tools.ietf.org/html/rfc6749#section-3.3)
    ///- remark: `scope`
    private(set) var scope: String?
    
    /// The client's redirect URI.
    ///
    /// See IETF: [rfc6749](https://tools.ietf.org/html/rfc6749#section-3.1.2)
    /// - remark: `redirect_uri`
    private(set) var redirectURL: URL?
    
    /// An opaque value used by the client to maintain state between the request and callback.
    ///
    /// If this value is not explicitly set, this library will automatically add state and
    /// perform appropriate validation of the state in the authorization response. It is recommended
    /// that the default implementation of this parameter be used wherever possible. Typically used
    /// to prevent CSRF attacks, as recommended in RFC6819 Section 5.3.5.
    ///
    /// See IETF: [rfc6749](https://tools.ietf.org/html/rfc6749#section-4.1.1),
    /// [rfc6819](https://tools.ietf.org/html/rfc6819#section-5.3.5)
    /// - remark: `state`
    private(set) var state: String?
    
    /// String value used to associate a Client session with an ID Token, and to mitigate replay
    /// attacks. The value is passed through unmodified from the Authentication Request to the ID
    /// Token. Sufficient entropy MUST be present in the nonce values used to prevent attackers from
    /// guessing values.
    ///
    /// If this value is not explicitly set, this library will automatically add nonce and
    /// perform appropriate validation of the nonce in the ID Token.
    ///
    /// See: [OpenID](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest)
    /// - remark: nonce
    private(set) var nonce: String?
    
    /// The PKCE code verifier.
    ///
    ///  The code verifier itself is not included in the authorization request that is sent
    /// on the wire, but needs to be in the token exchange request.
    /// `OIDAuthorizationResponse.tokenExchangeRequest` will create a `OIDTokenRequest` that
    /// includes this parameter automatically.
    ///
    /// See IETF [rfc7636](https://tools.ietf.org/html/rfc7636#section-4.1)
    /// - remark: `code_verifier`
    private(set) var codeVerifier: String?
    
    /// The PKCE code challenge, derived from #codeVerifier.
    ///
    /// See IETF [rfc7636](https://tools.ietf.org/html/rfc7636#section-4.2)
    /// - remark: `code_challenge`
    private(set) var codeChallenge: String?
    
    /// The method used to compute the @c #codeChallenge
    ///
    /// See IETF [rfc7636](https://tools.ietf.org/html/rfc7636#section-4.3)
    /// - remark: `code_challenge_method`
    private(set) var codeChallengeMethod: String?
    
    /// The client's additional authorization parameters.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-3.1)
    ///
//    private(set) var additionalParameters: [String : AnyCodable]?
    
    
    
    class func isSupportedResponseType(_ responseType: String?) -> Bool {
        let codeIdToken = [kResponseTypeCode, kResponseTypeIDToken].joined(separator: " ")
        let idTokenCode = [kResponseTypeIDToken, kResponseTypeCode].joined(separator: " ")
        return (responseType == kResponseTypeCode) || (responseType == codeIdToken) || (responseType == idTokenCode)
    }
    
    
    init(configuration: OPConfiguration?, clientId clientID: String?, clientSecret: String?, scope: String?, redirectURL: URL?, responseType: String?, state: String?, nonce: String?, codeVerifier: String?, codeChallenge: String?, codeChallengeMethod: String?) {
        super.init()
        
        self.configuration = configuration
        self.clientID = clientID!
        self.clientSecret = clientSecret
        self.scope = scope
        self.redirectURL = redirectURL
        self.responseType = responseType!
        if !AuthorizationRequest.isSupportedResponseType(self.responseType) {
            assert(false, String(format: OIDOAuthUnsupportedResponseTypeMessage, self.responseType))
            return
        }
        self.state = state
//        self.nonce = nonce
        self.codeVerifier = codeVerifier
        self.codeChallenge = codeChallenge
        self.codeChallengeMethod = codeChallengeMethod
//        self.additionalParameters = additionalParameters // copyItems: true
    }
    
    convenience init(configuration: OPConfiguration?, clientId clientID: String?, clientSecret: String?, scopes: [String]?, redirectURL: URL?, responseType: String?) {
        // generates PKCE code verifier and challenge
        let codeVerifier = AuthorizationRequest.generateCodeVerifier()
        let codeChallenge = AuthorizationRequest.codeChallengeS256(forVerifier: codeVerifier)
        self.init(configuration: configuration, clientId: clientID, clientSecret: clientSecret, scope: ScopeUtilities.scopes(withArray: scopes), redirectURL: redirectURL, responseType: responseType, state: AuthorizationRequest.generateState(), nonce: AuthorizationRequest.generateState(), codeVerifier: codeVerifier, codeChallenge: codeChallenge, codeChallengeMethod: OIDOAuthorizationRequestCodeChallengeMethodS256)
    }
    
    convenience init(configuration: OPConfiguration?, clientId clientID: String?, scopes: [String]?, redirectURL: URL?, responseType: String?) {
        self.init(configuration: configuration, clientId: clientID, clientSecret: nil, scopes: scopes, redirectURL: redirectURL, responseType: responseType)
    }

    
    func description() -> String? {
        return String(format: "<%@: %p, request: %@>", NSStringFromClass(type(of: self).self), self, authorizationRequestURL as! CVarArg)
    }
    
    
    class func generateCodeVerifier() -> String? {
        return TokenUtilities.randomURLSafeString(withSize: kCodeVerifierBytes)
    }
    
    class func generateState() -> String? {
        return TokenUtilities.randomURLSafeString(withSize: kStateSizeBytes)
    }
    
    class func codeChallengeS256(forVerifier codeVerifier: String?) -> String? {
        if codeVerifier == nil {
            return nil
        }
        // generates the code_challenge per spec https://tools.ietf.org/html/rfc7636#section-4.2
        // code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))
        // NB. the ASCII conversion on the code_verifier entropy was done at time of generation.
        let sha256Verifier: Data? = TokenUtilities.sha256(codeVerifier)
        return TokenUtilities.encodeBase64urlNoPadding(sha256Verifier)
    }
    
    func authorizationRequestURL() -> URL? {
        let query = QueryUtilities()
        // Required parameters.
        query.addParameter(kResponseTypeKey, value: responseType)
        query.addParameter(kClientIDKey, value: clientID)
        // Add any additional parameters the client has specified.
//        query.addParameters(additionalParameters)
        // Add optional parameters, as applicable.
        if redirectURL != nil {
            query.addParameter(kRedirectURLKey, value: redirectURL!.absoluteString)
        }
        if scope != nil {
            query.addParameter(kScopeKey, value: scope)
        }
        if state != nil {
            query.addParameter(kStateKey, value: state)
        }
        if nonce != nil {
            query.addParameter(kNonceKey, value: nonce)
        }
        if codeChallenge != nil {
            query.addParameter(kCodeChallengeKey, value: codeChallenge)
        }
        if codeChallengeMethod != nil{
            query.addParameter(kCodeChallengeMethodKey, value: codeChallengeMethod)
        }
        // Construct the URL:
        return query.urlByReplacingQuery(in: configuration!.authorizationEndpoint)
        
        // Testing only
       // return query.urlByReplacingQuery(in: URL(string: "https://192.168.1.24:8443/authorize"))
        
    }
    
    
    func externalUserAgentRequestURL() -> URL? {
        return authorizationRequestURL()
    }
    
    
    func redirectScheme() -> String? {
        return redirectURL!.scheme
    }
}
