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

struct TokenRequest {
    
    
    /// The service's configuration.
    private(set) var configuration:OPConfiguration?
    
    /// The type of token being sent to the token endpoint, i.e. "authorization_code" for the
    /// authorization code exchange, or "refresh_token" for an access token refresh request.
    private(set) var grantType: String?
    
    /// The authorization code received from the authorization server.
    private(set) var authorizationCode: String?
    
    /// The client's redirect URI.
    private(set) var redirectURL: URL?
    
    /// The client identifier.
    private(set) var clientID: String?
    
    /// The PKCE code verifier used to redeem the authorization code.
    private(set) var codeVerifier: String?

    private(set) var dpopToken: String?
    private(set) var dpopKeyPair: KeyPair?

    
    init(configuration: OPConfiguration?,
        grantType: String?,
        authorizationCode: String?,
        redirectURL: URL?,
        clientID: String?,
        codeVerifier: String?
    ) {
        self.configuration = configuration!
        self.grantType = grantType!
        self.authorizationCode = authorizationCode!
        self.redirectURL = redirectURL!
        self.clientID = clientID!
        self.codeVerifier = codeVerifier!
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

        if grantType != nil {
            body.addParameter(kGrantTypeKey, value: grantType)
        }
        if redirectURL != nil {
            body.addParameter(kRedirectURLKey, value: redirectURL!.absoluteString)
        }
        if authorizationCode != nil {
            body.addParameter(kAuthorizationCodeKey, value: authorizationCode)
        }
        if codeVerifier != nil {
            body.addParameter(kCodeVerifierKey, value: codeVerifier)
        }
        if clientID != nil {
            body.addParameter(kClientIDKey, value: clientID)
        }
    
        return body
    }

    
    mutating func urlRequest()-> URLRequest {
        let kHTTPPost = "POST"
        let kHTTPContentTypeHeaderKey = "Content-Type"
        let kHTTPContentTypeHeaderValue = "application/x-www-form-urlencoded; charset=UTF-8"
        let kHTTPDPoPHeaderKey = "DPoP"
        let kHTTPDPoPHeaderValue =  dPoPToken()
        let tokenRequestURL = self.tokenRequestURL()
        var URLRequest = URLRequest(url: tokenRequestURL)
        URLRequest.httpMethod = kHTTPPost
        URLRequest.setValue(kHTTPContentTypeHeaderValue, forHTTPHeaderField: kHTTPContentTypeHeaderKey)
        URLRequest.setValue(kHTTPDPoPHeaderValue, forHTTPHeaderField: kHTTPDPoPHeaderKey)
        let bodyParameters = tokenRequestBody()
        let httpHeaders = [String : String]()
        let bodyString = bodyParameters.urlEncodedParameters()
        let body: Data? = bodyString.data(using: .utf8)
        URLRequest.httpBody = body!
        for header in httpHeaders {
            URLRequest.setValue(httpHeaders[header.key], forHTTPHeaderField: header.key)
        }
        return URLRequest
    }
    
    
    /// Generates a DPoP token
    ///
    /// - note: See JOSE [JWS](https://github.com/airsidemobile/JOSESwift/wiki/jws)
    mutating func dPoPToken() -> String? {
        
        // Generate keys
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

