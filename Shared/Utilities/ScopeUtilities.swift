//
//  ScopeUtilities.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 31/07/21.
//

import Foundation

let kScopeOpenID = "openid"
let kScopeProfile = "profile"
let kScopeWebID = "webid"
let kScopeEmail = "email"
let kScopeAddress = "address"
let kScopePhone = "phone"
let kScopeOfflineAccess = "offline_access"



class ScopeUtilities: NSObject {
    
    static let disallowedScopeCharacters: CharacterSet? = {
        var disallowedCharacters = CharacterSet()
        var allowedCharacters = CharacterSet()
        allowedCharacters.insert(charactersIn: "\u{0023}"..."\u{005B}")
        allowedCharacters.insert(charactersIn: "\u{005D}"..."\u{007E}")
        allowedCharacters.insert("\u{0021}")
        disallowedCharacters = allowedCharacters.inverted
        return disallowedCharacters
    }()
    
    
    
    class func scopes(withArray scopes: [String]?) -> String? {
        let disallowedCharacters = ScopeUtilities.disallowedScopeCharacters
        for scope in scopes! {
            assert((scope.count) != 0, "Found illegal empty scope string.")
            if let aCharacters = disallowedCharacters {
                assert(Int((scope as NSString?)?.rangeOfCharacter(from: aCharacters).location ?? 0) == NSNotFound, "Found illegal character in scope string.")
            }
        }
        let scopeString = scopes?.joined(separator: " ")
        return scopeString
    }
    
    
    class func scopesArray(with scopes: String?) -> [String]? {
        return scopes?.components(separatedBy: " ")
    }
}

