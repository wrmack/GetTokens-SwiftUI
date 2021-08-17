//
//  OPConfiguration.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 30/07/21.
//

import Foundation


struct OPConfiguration {
    
    // MARK: - Properties
    
    var discoveryDictionary: [String : Any]?
    var authorizationEndpoint: URL?
    var tokenEndpoint: URL?
    var issuer: URL?
    var registrationEndpoint: URL?
    var userInfoEndpoint: URL?
    
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
