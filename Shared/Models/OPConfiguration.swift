//
//  OPConfiguration.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 30/07/21.
//

import Foundation

/*! Field keys associated with an OpenID Connect Discovery Document. */
fileprivate let kIssuerKey = "issuer"
fileprivate let kAuthorizationEndpointKey = "authorization_endpoint"
fileprivate let kTokenEndpointKey = "token_endpoint"
fileprivate let kUserinfoEndpointKey = "userinfo_endpoint"
fileprivate let kJWKSURLKey = "jwks_uri"
fileprivate let kRegistrationEndpointKey = "registration_endpoint"
fileprivate let kScopesSupportedKey = "scopes_supported"
fileprivate let kResponseTypesSupportedKey = "response_types_supported"
fileprivate let kResponseModesSupportedKey = "response_modes_supported"
fileprivate let kGrantTypesSupportedKey = "grant_types_supported"
fileprivate let kACRValuesSupportedKey = "acr_values_supported"
fileprivate let kSubjectTypesSupportedKey = "subject_types_supported"
fileprivate let kIDTokenSigningAlgorithmValuesSupportedKey = "id_token_signing_alg_values_supported"
fileprivate let kIDTokenEncryptionAlgorithmValuesSupportedKey = "id_token_encryption_alg_values_supported"
fileprivate let kIDTokenEncryptionEncodingValuesSupportedKey = "id_token_encryption_enc_values_supported"
fileprivate let kUserinfoSigningAlgorithmValuesSupportedKey = "userinfo_signing_alg_values_supported"
fileprivate let kUserinfoEncryptionAlgorithmValuesSupportedKey = "userinfo_encryption_alg_values_supported"
fileprivate let kUserinfoEncryptionEncodingValuesSupportedKey = "userinfo_encryption_enc_values_supported"
fileprivate let kRequestObjectSigningAlgorithmValuesSupportedKey = "request_object_signing_alg_values_supported"
fileprivate let kRequestObjectEncryptionAlgorithmValuesSupportedKey = "request_object_encryption_alg_values_supported"
fileprivate let kRequestObjectEncryptionEncodingValuesSupported = "request_object_encryption_enc_values_supported"
fileprivate let kTokenEndpointAuthMethodsSupportedKey = "token_endpoint_auth_methods_supported"
fileprivate let kTokenEndpointAuthSigningAlgorithmValuesSupportedKey = "token_endpoint_auth_signing_alg_values_supported"
fileprivate let kDisplayValuesSupportedKey = "display_values_supported"
fileprivate let kClaimTypesSupportedKey = "claim_types_supported"
fileprivate let kClaimsSupportedKey = "claims_supported"
fileprivate let kServiceDocumentationKey = "service_documentation"
fileprivate let kClaimsLocalesSupportedKey = "claims_locales_supported"
fileprivate let kUILocalesSupportedKey = "ui_locales_supported"
fileprivate let kClaimsParameterSupportedKey = "claims_parameter_supported"
fileprivate let kRequestParameterSupportedKey = "request_parameter_supported"
fileprivate let kRequestURIParameterSupportedKey = "request_uri_parameter_supported"
fileprivate let kRequireRequestURIRegistrationKey = "require_request_uri_registration"
fileprivate let kOPPolicyURIKey = "op_policy_uri"
fileprivate let kOPTosURIKey = "op_tos_uri"


class OPConfiguration {
    // MARK: - Properties
    
    var discoveryDictionary: [String : Any]?
    var authorizationEndpoint: URL?
    var tokenEndpoint: URL?
    var issuer: URL?
    var registrationEndpoint: URL?
    
    
    convenience init(JSONData: Data) {
        var jsonError: NSError?
        var json: [String : Any]?
        do {
            json = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as? [String : Any]
        }
        catch {
            jsonError = ErrorUtilities.error(code: ErrorCode.JSONDeserializationError, underlyingError: jsonError, description: jsonError?.localizedDescription)
        }
        
        self.init(serviceDiscoveryDictionary: json!, error: jsonError)
    }
    
    convenience init(serviceDiscoveryDictionary: [String : Any], error: NSError?) {
        self.init()
        var error = error
        if OPConfiguration.dictionaryHasRequiredFields(dictionary: serviceDiscoveryDictionary, error: &error) == false {
            return
        }
        
        self.discoveryDictionary = serviceDiscoveryDictionary
        authorizationEndpoint = URL(string: discoveryDictionary![kAuthorizationEndpointKey]! as! String)
        tokenEndpoint = URL(string: discoveryDictionary![kTokenEndpointKey]! as! String)
        issuer = URL(string: discoveryDictionary![kIssuerKey]! as! String)
        registrationEndpoint = URL(string: discoveryDictionary![kRegistrationEndpointKey]! as! String)
    }
    
    // MARK: - Utilities
    
    static func dictionaryHasRequiredFields(dictionary: [String : Any], error: inout NSError?)-> Bool {
        
        let requiredFields = [
            kIssuerKey,
            kAuthorizationEndpointKey,
            kTokenEndpointKey,
            kJWKSURLKey,
            kResponseTypesSupportedKey,
            kSubjectTypesSupportedKey,
            kIDTokenSigningAlgorithmValuesSupportedKey
        ]
        
        for field in requiredFields {
            if dictionary[field] == nil {
                if error != nil {
                    let errorText = "Missing field: \(field)"
                    error = ErrorUtilities.error(code: ErrorCode.InvalidDiscoveryDocument, underlyingError: nil, description: errorText)
                }
                return false
            }
        }
        
        let requiredURLFields = [
            kIssuerKey,
            kTokenEndpointKey,
            kJWKSURLKey
        ]
        
        for field in requiredURLFields {
            if URL(string: dictionary[field] as! String) == nil {
                if error != nil {
                    let errorText = "Invalid URL: \(field)"
                    error = ErrorUtilities.error(code: ErrorCode.InvalidDiscoveryDocument, underlyingError: nil, description: errorText)
                }
                return false
            }
        }
        return true
    }
    
}
