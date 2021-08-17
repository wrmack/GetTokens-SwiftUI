//
//  TokenRequest.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 31/07/21.
//

import Foundation

struct TokenPayload: Codable {
    var htu: String
    var htm: String
    var jti: String
    var iat: Int
}

struct KeyPair {
    var privateKey: SecKey
    var publicKey: SecKey
}

class TokenRequest: NSObject {
    
    
    /// The service's configuration.
    ///
    /// Configurations may be created manually, or via an OpenID Connect Discovery Document.
    /// - remark: This configuration specifies how to connect to a particular OAuth provider.
    private(set) var configuration:OPConfiguration?
    
    /// The type of token being sent to the token endpoint, i.e. "authorization_code" for the
    /// authorization code exchange, or "refresh_token" for an access token refresh request.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-4.1.3), and
    ///  [here](https://www.google.com/url?sa=D&q=https%3A%2F%2Ftools.ietf.org%2Fhtml%2Frfc6749%23section-6)
    /// - remark: `grant_type`
    private(set) var grantType: String?
    
    /// The authorization code received from the authorization server.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-4.1.3)
    /// - remark: `code`
    private(set) var authorizationCode: String?
    
    /// The client's redirect URI.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-4.1.3)
    /// - remark: `redirect_uri`
    private(set) var redirectURL: URL?
    
    /// The client identifier.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-4.1.3)
    /// - remark: `client_id`
    private(set) var clientID = ""
    
    /// The client secret.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-2.3.1)
    /// - remark: `client_secret`
    private(set) var clientSecret: String?
    
    /// The value of the scope parameter is expressed as a list of space-delimited,
    /// case-sensitive strings.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-3.3)
    /// - remark: `scope`
    private(set) var scope: String?
    
    /// The refresh token, which can be used to obtain new access tokens using the same
    /// authorization grant.
    /// - remark: `refresh_token`
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-5.1)
    ///
    private(set) var refreshToken: String?
    
    /// The PKCE code verifier used to redeem the authorization code.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc7636#section-4.3)
    /// - remark: `code_verifier`
    private(set) var codeVerifier: String?
    
    /// The client's additional token request parameters.
     ///
//    private(set) var additionalParameters: [String : AnyCodable]?
    
    private(set) var nonce: String?
    private(set) var dpopToken: String?
    private(set) var dpopKeyPair: KeyPair?
    
    
    convenience init(configuration: OPConfiguration?, grantType: String?, authorizationCode code: String?, redirectURL: URL?, clientID: String?, clientSecret: String?, scopes: [String]?, refreshToken: String?, codeVerifier: String?, nonce: String?) {
        self.init(configuration: configuration, grantType: grantType, authorizationCode: code, redirectURL: redirectURL, clientID: clientID, clientSecret: clientSecret, scope: ScopeUtilities.scopes(withArray: scopes), refreshToken: refreshToken, codeVerifier: codeVerifier, nonce: nonce)
    }
    
    init(configuration: OPConfiguration?, grantType: String?, authorizationCode code: String?, redirectURL: URL?, clientID: String?, clientSecret: String?, scope: String?, refreshToken: String?, codeVerifier: String?, nonce: String?) {
        super.init()
        
        self.configuration = configuration
        self.grantType = grantType!
        authorizationCode = code
        self.redirectURL = redirectURL
        self.clientID = clientID!
        self.clientSecret = clientSecret
        self.scope = scope
        self.refreshToken = refreshToken
        self.codeVerifier = codeVerifier
        self.nonce = nonce
//        self.additionalParameters = additionalParameters // copyItems: true
        // Additional validation for the authorization_code grant type
        if self.grantType == kGrantTypeAuthorizationCode { 
            // redirect URI must not be nil
            if self.redirectURL == nil {
                fatalError(OIDOAuthExceptionInvalidTokenRequestNullRedirectURL)
                //             NSException.raise(OIDOAuthExceptionInvalidTokenRequestNullRedirectURL, format: "%@", OIDOAuthExceptionInvalidTokenRequestNullRedirectURL, nil)
            }
        }
    }
    
    
    func description(request: URLRequest) -> String? {
        let request = request
        var requestBody: String? = nil
        if let aBody = request.httpBody {
            requestBody = String(data: aBody, encoding: .utf8)
        }
        if let anURL = request.url {
            return String(format: "<%@: %p, request: <URL: %@, HTTPBody: %@>>", NSStringFromClass(type(of: self).self), self, anURL as CVarArg, requestBody ?? "")
        }
        return nil
    }
    
    /// Constructs the request URI.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-4.1.3)
    /// - returns:  A URL representing the token request.
    func tokenRequestURL() -> URL {
        return configuration!.tokenEndpoint!
    }
    
    /// Constructs the request body data by combining the request parameters using the
    ///  "application/x-www-form-urlencoded" format.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-4.1.3)
    /// - returns: The data to pass to the token request URL.
    func tokenRequestBody() -> QueryUtilities {
        let body = QueryUtilities()
        // Add parameters, as applicable.
        if grantType != nil {
            body.addParameter(kGrantTypeKey, value: grantType)
        }
//        if scope != nil {
//            query.addParameter(kScopeKey, value: scope)
//        }
        if redirectURL != nil {
            body.addParameter(kRedirectURLKey, value: redirectURL!.absoluteString)
        }
//        if refreshToken != nil {
//            query.addParameter(kRefreshTokenKey, value: refreshToken)
//        }
        if authorizationCode != nil {
            body.addParameter(kAuthorizationCodeKey, value: authorizationCode)
        }
        if codeVerifier != nil {
            body.addParameter(kCodeVerifierKey, value: codeVerifier)
        }

        body.addParameter(kClientIDKey, value: clientID)
        body.addParameter(kClientSecretKey, value: clientSecret)
    
        // Add any additional parameters the client has specified.
//        query.addParameters(additionalParameters)
        return body
    }

    
    func urlRequest()-> URLRequest {
        let kHTTPPost = "POST"
        let kHTTPContentTypeHeaderKey = "Content-Type"
        let kHTTPContentTypeHeaderValue = "application/x-www-form-urlencoded; charset=UTF-8"
        let kHTTPDPoPHeaderKey = "DPoP"
        let kHTTPDPoPHeaderValue =  dPoPToken()
        let tokenRequestURL = self.tokenRequestURL()
        var URLRequestA = URLRequest(url: tokenRequestURL)
        URLRequestA.httpMethod = kHTTPPost
        URLRequestA.setValue(kHTTPContentTypeHeaderValue, forHTTPHeaderField: kHTTPContentTypeHeaderKey)
        URLRequestA.setValue(kHTTPDPoPHeaderValue, forHTTPHeaderField: kHTTPDPoPHeaderKey)
        let bodyParameters = tokenRequestBody()
        var httpHeaders = [String : String]()
        let bodyString = bodyParameters.urlEncodedParameters()
        let body: Data? = bodyString.data(using: .utf8)
        URLRequestA.httpBody = body!
        for header in httpHeaders {
            URLRequestA.setValue(httpHeaders[header.key], forHTTPHeaderField: header.key)
        }
        return URLRequestA
    }
    
    /// Generates a token
    ///
    /// - note: See JOSE [JWS](https://github.com/airsidemobile/JOSESwift/wiki/jws)
    func dPoPToken() -> String? {
        
        // Generate keys
//        let attributes: [String: Any] =
//            [kSecAttrKeyType as String:  kSecAttrKeyTypeRSA,
//             kSecAttrKeySizeInBits as String: 256]
        
        let tag = "com.wm.POD-browser".data(using: .utf8)!
        let attributes: [String: Any] =
            [kSecAttrKeyType as String:  kSecAttrKeyTypeRSA,
             kSecAttrKeySizeInBits as String: 2048,
             kSecPrivateKeyAttrs as String:
                [kSecAttrApplicationTag as String: tag]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            print(error!.takeRetainedValue() as Error)
            return nil
        }

        let publicKey = SecKeyCopyPublicKey(privateKey)!
        dpopKeyPair = KeyPair(privateKey: privateKey, publicKey: publicKey)

        
        // Form JWK
        let jwkPublicKey = try! RSAPublicKey(publicKey: publicKey)
        
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
            htu: configuration!.tokenEndpoint!.absoluteString,
            htm: "POST",
            jti: randomIdentifier!.base64EncodedString(),
            iat: Int(Date().timeIntervalSince1970)
        )
        let jsonPayload = try? JSONEncoder().encode(tokenPayload)
        let payload = Payload(jsonPayload!)
        
        // Signer
        let signer = Signer(signingAlgorithm: .RS256, key: privateKey)
        var jws: JWS?
        do {
            jws = try JWS(header: header, payload: payload, signer: signer!)
        } catch {
            print("jws error \(error)")
        }
        let dpopToken = jws!.compactSerializedString
        self.dpopToken = dpopToken
        return dpopToken
    }

}

