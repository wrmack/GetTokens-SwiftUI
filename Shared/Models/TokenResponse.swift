//
//  TokenResponse.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 6/08/21.
//

import Foundation



class TokenResponse: NSObject {
    
    /// The request which was serviced.
    ///
    private(set) var request: TokenRequest?
    
    /// The access token generated by the authorization server.
    ///
    ///  See IETF rfc6749: [4.1.4](https://tools.ietf.org/html/rfc6749#section-4.1.4),
    ///  [5.1](https://tools.ietf.org/html/rfc6749#section-5.1)
    /// - remark: `access_token`
    private(set) var accessToken: String?
    
    /// The approximate expiration date & time of the access token.
    ///
    /// also OIDTokenResponse.accessToken
    ///
    ///  See IETF rfc6749: [4.1.4](https://tools.ietf.org/html/rfc6749#section-4.1.4),
    ///  [5.1](https://tools.ietf.org/html/rfc6749#section-5.1)
    /// - remark: `expires_in`
    private(set) var accessTokenExpirationDate: Date?
    
    /// Typically "Bearer" when present. Otherwise, another token_type value that the Client has
    /// negotiated with the Authorization Server.
    ///
    ///  See IETF rfc6749: [4.1.4](https://tools.ietf.org/html/rfc6749#section-4.1.4),
    ///  [5.1](https://tools.ietf.org/html/rfc6749#section-5.1)
    /// - remark: `token_type`
    private(set) var tokenType: String?
    
    /// ID Token value associated with the authenticated session.
    ///
    /// Always present for the
    /// authorization code grant exchange when OpenID Connect is used, optional for responses to
    /// access token refresh requests. Note that AppAuth does NOT verify the JWT signature. Users
    /// of AppAuth are encouraged to verifying the JWT signature using the validation library of
    /// their choosing.
    ///
    /// OIDIDToken can be used to parse the ID Token and extract the claims. As noted,
    /// this class does not verify the JWT signature.
    ///
    ///
    /// See OpenID: [TokenResponse](http://openid.net/specs/openid-connect-core-1_0.html#TokenResponse),
    ///  [RefreshTokenResponse](http://openid.net/specs/openid-connect-core-1_0.html#RefreshTokenResponse),
    ///  [IDToken](http://openid.net/specs/openid-connect-core-1_0.html#IDToken)
    ///
    /// Also: [JWT](https://jwt.io)
    /// - remark: `id_token`
    private(set) var idToken: String?
    
    /// The refresh token, which can be used to obtain new access tokens using the same
    /// authorization grant
    ///
    /// See IETF rfc6749:
    ///  [5.1](https://tools.ietf.org/html/rfc6749#section-5.1)
    ///
    /// - remark: `refresh_token`
    private(set) var refreshToken: String?
    
    /// The scope of the access token. OPTIONAL, if identical to the scopes requested, otherwise,
    /// REQUIRED.
    ///
    /// See IETF rfc6749:
    ///  [5.1](https://tools.ietf.org/html/rfc6749#section-5.1)
    /// - remark: `scope`
    private(set) var scope: String?
    
    /// Additional parameters returned from the token server.
    ///
    private(set) var additionalParameters: [String : String ]?
    
  
    
    init(request: TokenRequest?, parameters: [String : Any ]?) {
        super.init()
        self.request = request
        
        for parameter in parameters! {
            switch parameter.key {
            case kAccessTokenKey:
                accessToken = parameters![kAccessTokenKey] as? String
            case kExpiresInKey:
                let rawDate = parameters![kExpiresInKey]
                accessTokenExpirationDate = Date(timeIntervalSinceNow: TimeInterval(Int64(truncating: rawDate as! NSNumber)))
            case kTokenTypeKey:
                tokenType = parameters![kTokenTypeKey] as? String
            case kIDTokenKey:
                idToken = parameters![kIDTokenKey] as? String
            case kRefreshTokenKey:
                refreshToken = parameters![kRefreshTokenKey] as? String
            case kScopeKey:
                scope = parameters![kScopeKey] as? String
                
            default:
                additionalParameters![parameter.key] = parameter.value as? String
            }
        }
    }
    
    
    // MARK: - Codable
    
//    enum CodingKeys: String, CodingKey {
//        case request
//        case accessToken
//        case accessTokenExpirationDate
//        case tokenType
//        case idToken
//        case refreshToken
//        case scope
//        case additionalParameters
//    }
//
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(request, forKey: CodingKeys.request)
//        try container.encode(accessToken, forKey: CodingKeys.accessToken)
//        try container.encode(accessTokenExpirationDate, forKey: .accessTokenExpirationDate)
//        try container.encode(tokenType, forKey: CodingKeys.tokenType)
//        try container.encode(idToken, forKey: .idToken)
//        try container.encode(refreshToken, forKey: .refreshToken)
//        try container.encode(scope, forKey: .scope)
//        try container.encode(additionalParameters, forKey: .additionalParameters)
//    }
//
//
//    required init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        request = try values.decode(TokenRequest.self, forKey: .request)
//        accessToken = try values.decode(String.self, forKey: .accessToken)
//        accessTokenExpirationDate = try values.decode(Date.self, forKey: .accessTokenExpirationDate)
//        tokenType = try values.decode(String.self, forKey: .tokenType)
//        idToken = try values.decode(String.self, forKey: .idToken)
//        scope = try? values.decode(String.self, forKey: .scope)
//        refreshToken = try? values.decode(String.self, forKey: .refreshToken)
//        additionalParameters = try? values.decode([String : String].self, forKey: .additionalParameters)
//    }
//
//
//
//    func description() -> String {
//        return String(format: """
//        <%@: %p, accessToken: "%@", accessTokenExpirationDate: %@, \
//        tokenType: %@, idToken: "%@", refreshToken: "%@", \
//        scope: "%@", additionalParameters: %@, request: %@>
//        """, NSStringFromClass(type(of: self).self), self, TokenUtilities.redact(accessToken)!, accessTokenExpirationDate! as CVarArg, tokenType!, TokenUtilities.redact(idToken)!, TokenUtilities.redact(refreshToken)!, scope!, additionalParameters!, request!)
//    }
}
