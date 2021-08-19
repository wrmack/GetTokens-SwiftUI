//
//  RegistrationRequest.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 31/07/21.
//

import Foundation




struct RegistrationRequest {
    
    
    /// The service's configuration.
    ///
    /// This configuration specifies how to connect to a particular OAuth provider.
    /// Configurations may be created manually, or via an OpenID Connect Discovery Document.
    var configuration: OPConfiguration?
    
    /// The initial access token to access the Client Registration Endpoint
    /// (if required by the OpenID Provider).
    ///
    /// OAuth 2.0 Access Token optionally issued by an Authorization Server granting
    /// access to its Client Registration Endpoint. This token (if required) is
    /// provisioned out of band.
    ///
    /// Section 3 of [OpenID Connect Dynamic Client Registration 1.0](https://openid.net/specs/openid-connect-registration-1_0.html#ClientRegistration)
    var initialAccessToken: String?
    
    /// The application type to register, will always be 'native'.
    ///
    /// Reference:
    /// [Client metadata](https://openid.net/specs/openid-connect-registration-1_0.html#ClientMetadata)
    ///  - remark: `application_type`
    var applicationType = ""
    
    /// The client's redirect URI's.
    ///
    /// Reference:
    /// [IETF](https://tools.ietf.org/html/rfc6749#section-3.1.2)
    /// - remark: `redirect_uris`
    var redirectURIs: [URL] = []
    
    /// The response types to register for usage by this client.
    ///
    ///  Reference:
    /// [OpenID](http://openid.net/specs/openid-connect-core-1_0.html#Authentication)
    /// - remark: `response_types`
    var responseTypes: [String]?
    
    /// The grant types to register for usage by this client.
    ///
    ///  Reference:
    /// [OpenID](https://openid.net/specs/openid-connect-registration-1_0.html#ClientMetadata)
    /// - remark: `grant_types`
    var grantTypes: [String]?
    
    /// The subject type to to request.
    ///
    ///  Reference:
    /// [OpenID](http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes)
    /// - remark: `subject_type`
    var subjectType: String?
    
    /// The client authentication method to use at the token endpoint.
    ///
    ///  Reference:
    /// [OpenID](http://openid.net/specs/openid-connect-core-1_0.html#ClientAuthentication)
    /// - remark: `token_endpoint_auth_method`
    var tokenEndpointAuthenticationMethod: String?
    
    /// The client's additional request parameters.
    var additionalParameters: [String : String]?
    
    var clientName: String?
    
     
    func urlRequest() -> URLRequest? {
        let kHTTPPost = "POST"
        let kBearer = "Bearer"
        let kHTTPContentTypeHeaderKey = "Content-Type"
        let kHTTPContentTypeHeaderValue = "application/json"
        let kHTTPAuthorizationHeaderKey = "Authorization"
        
        let postBody: Data? = JSONString()
        if postBody == nil {
            return nil
        }
        let registrationRequestURL: URL? = configuration!.registrationEndpoint
        var URLRequestA: URLRequest? = nil
        if let anURL = registrationRequestURL {
            URLRequestA = URLRequest(url: anURL)
        }
        URLRequestA?.httpMethod = kHTTPPost
        URLRequestA?.setValue(kHTTPContentTypeHeaderValue, forHTTPHeaderField: kHTTPContentTypeHeaderKey)
        if initialAccessToken != nil {
            let value = "\(kBearer) \(initialAccessToken!)"
            URLRequestA?.setValue(value, forHTTPHeaderField: kHTTPAuthorizationHeaderKey)
        }
        URLRequestA?.httpBody = postBody
        return URLRequestA
    }
    
    
    func JSONString() -> Data? {
        // Dictionary with several key/value pairs and the above array of arrays
        var dict: [AnyHashable : Any] = [:]
        var redirectURIStrings = [String]()
        for obj in redirectURIs {
            redirectURIStrings.append(obj.absoluteString)
        }
        dict[kRedirectURIsParam] = redirectURIStrings
        dict[kApplicationTypeParam] = applicationType
        if additionalParameters != nil {
            // Add any additional parameters first to allow them
            // to be overwritten by instance values
            for (k, v) in additionalParameters! { dict[k] = v }
        }
        if responseTypes != nil {
            dict[kResponseTypesParam] = responseTypes
        }
        if grantTypes != nil {
            dict[kGrantTypesParam] = grantTypes
        }
        if subjectType != nil {
            dict[kSubjectTypeParam] = subjectType
        }
        if tokenEndpointAuthenticationMethod != nil {
            dict[kTokenEndpointAuthenticationMethodParam] = tokenEndpointAuthenticationMethod
        }
        if clientName != nil {
            dict[kClientNameParam] = clientName
        }
        let json: Data? = try? JSONSerialization.data(withJSONObject: dict, options: [])
        return json
    }
}
