//
//  AuthorizationResponse.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 31/07/21.
//

import Foundation


class AuthorizationResponse: NSObject  {
    
    ///  The request which was serviced.
    ///
    private(set) var request: AuthorizationRequest?
    
    ///  The authorization code generated by the authorization server.
    ///
    ///  Set when the response_type requested includes 'code'.
    /// - remark: `code`
    ///
    var authorizationCode: String?
    
    ///  REQUIRED if the "state" parameter was present in the client authorization request.
    ///
    ///  The exact value received from the client.
    /// - remark: `state`
    ///
    var state: String?
    
    ///  The access token generated by the authorization server.
    ///
    ///  Set when the response_type requested includes 'token'.
    ///
    /// See [OpenID](http://openid.net/specs/openid-connect-core-1_0.html#ImplicitAuthResponse)
    /// - remark: `access_token`
    private(set) var accessToken: String?
    
    ///  The approximate expiration date & time of the access token.
    ///  Set when the response_type requested includes 'token'.
    ///
    /// See also `OIDAuthorizationResponse.accessToken`
    ///
    /// See [OpenID](http://openid.net/specs/openid-connect-core-1_0.html#ImplicitAuthResponse)
    /// - remark: `expires_in`
    private(set) var accessTokenExpirationDate: Date?
    
    ///  Typically "Bearer" when present. Otherwise, another `token_type` value that the Client has
    /// negotiated with the Authorization Server.
    ///
    ///  Set when the `response_type` requested includes 'token'.
    ///
    /// See [OpenID](http://openid.net/specs/openid-connect-core-1_0.html#ImplicitAuthResponse)
    /// - remark: `token_type`
    private(set) var tokenType: String?
    
    ///  ID Token value associated with the authenticated session.
    ///
    ///  Set when the `response_type requested` includes 'id_token'.
    ///
    /// See OpenID: [IDToken](http://openid.net/specs/openid-connect-core-1_0.html#IDToken),
    /// [ImplicitAuthResponse](http://openid.net/specs/openid-connect-core-1_0.html#ImplicitAuthResponse)
    /// - remark: `id_token`
    private(set) var idToken: String?
    
    ///  The scope of the access token.
    ///
    ///  OPTIONAL, if identical to the scopes requested, otherwise,
    /// REQUIRED.
    ///
    /// See IETF [rfc6749](https://tools.ietf.org/html/rfc6749#section-5.1)
    /// - remark: `scope`
    private(set) var scope: String?
    
    ///  Additional parameters returned from the authorization server.
     ///
//    private(set) var additionalParameters: [String : NSObject]?
    
//
    
    
    // MARK: - Initializers
    init(request: AuthorizationRequest?, parameters: [String : NSObject]?) {
        super.init()
        
        self.request = request
        
        for parameter in parameters! {
            switch parameter.key {
            case kStateKey:
                state = parameters![kStateKey] as? String
            case kAuthorizationCodeKey:
                authorizationCode = parameters![kAuthorizationCodeKey] as? String
            case kAccessTokenKey:
                accessToken = parameters![kAccessTokenKey] as? String
            case kExpiresInKey:
                let rawDate = parameters![kExpiresInKey]
                accessTokenExpirationDate = Date(timeIntervalSinceNow: TimeInterval(Int64(truncating: rawDate as! NSNumber)))
            case kTokenTypeKey:
                tokenType = parameters![kTokenTypeKey] as? String
            case kIDTokenKey:
                idToken = parameters![kIDTokenKey] as? String
            case kScopeKey:
                scope = parameters![kScopeKey] as? String
            default:
                continue
//                additionalParameters![parameter.key] = parameter.value
            }
        }
    }
    
    
    // MARK: - Codable
    
//    enum CodingKeys: String, CodingKey {
//        case request
////        case additionalParameters
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(request, forKey: CodingKeys.request)
////        let paramData = try NSKeyedArchiver.archivedData(withRootObject: additionalParameters as Any, requiringSecureCoding: true)
////        try container.encode(paramData, forKey: .additionalParameters)
//    }
//
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        request = try container.decode(AuthorizationRequest.self, forKey: .request)
////        let paramData = try container.decode(Data.self, forKey: .additionalParameters)
////        additionalParameters = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(paramData) as? [String : NSObject]
//    }

    
    // MARK: - NSObject overrides
    func description() -> String? {
        return String(format: """
        <%@: %p, authorizationCode: %@, state: "%@", accessToken: \
        "%@", accessTokenExpirationDate: %@, tokenType: %@, \
        idToken: "%@", scope: "%@", additionalParameters: %@, \
        request: %@>
        """, NSStringFromClass(type(of: self).self), self, authorizationCode!, state!, TokenUtilities.redact(accessToken)!, (accessTokenExpirationDate as CVarArg?)!, tokenType!, TokenUtilities.redact(idToken)!, scope!, request!)
    }
    
    // MARK: -
    func tokenExchangeRequest() -> TokenRequest? {
        return tokenExchangeRequest(withAdditionalParameters: nil)
    }
    
    
    func tokenExchangeRequest(withAdditionalParameters additionalParameters: [String : String]?) -> TokenRequest? {
        // TODO: add a unit test to confirm exception is thrown when expected and the request is created
        //       with the correct parameters.
        if authorizationCode == nil {
            fatalError(kTokenExchangeRequestException)
        }
        return nil    //OIDTokenRequest(configuration: request!.configuration, grantType: OIDGrantTypeAuthorizationCode, authorizationCode: authorizationCode, redirectURL: request!.redirectURL, clientID: request!.clientID, clientSecret: request!.clientSecret, scope: nil, refreshToken: nil, codeVerifier: request!.codeVerifier, additionalParameters: additionalParameters)
    }
}
