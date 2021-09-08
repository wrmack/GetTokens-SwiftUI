//
//  TokenUtilities.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 31/07/21.
//

import Foundation
import CommonCrypto


private let kFormUrlEncodedAllowedCharacters = " *-._0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

class TokenUtilities: NSObject {
    
    
    class func base64urlNoPaddingDecode(_ base64urlNoPaddingString: String?) -> Data? {
        var body = base64urlNoPaddingString
        // Converts base64url to base64.
        let range = NSRange(location: 0, length: base64urlNoPaddingString?.count ?? 0)
        if let subRange = Range<String.Index>(range, in: body!) { body = body?.replacingOccurrences(of: "-", with: "+", options: .literal, range: subRange) }
        if let subRange = Range<String.Index>(range, in: body!) { body = body?.replacingOccurrences(of: "_", with: "/", options: .literal, range: subRange) }
        // Converts base64 no padding to base64 with padding
        while (body?.count ?? 0) % 4 != 0 {
            body?.append("=")
        }
        // Decodes base64 string.
        let decodedData = Data(base64Encoded: body ?? "", options: [])
        return decodedData
    }
    
    
    class func encodeBase64urlNoPadding(_ data: Data?) -> String? {
        var base64string = data?.base64EncodedString(options: [])
        // converts base64 to base64url
        base64string = base64string?.replacingOccurrences(of: "+", with: "-")
        base64string = base64string?.replacingOccurrences(of: "/", with: "_")
        // strips padding
        base64string = base64string?.replacingOccurrences(of: "=", with: "")
        return base64string
    }
    
    
    class func randomURLSafeString(withSize size: Int) -> String? {
        var randomData = Data(count: size)
        let dataCount = randomData.count
        let result = randomData.withUnsafeMutableBytes { (mutableBytes: UnsafeMutableRawBufferPointer)  in
            SecRandomCopyBytes(kSecRandomDefault, dataCount, mutableBytes.baseAddress!)
        }

        if result != errSecSuccess {
            return nil
        }
        return self.encodeBase64urlNoPadding(randomData)
    }
    
    
    class func sha256(_ inputString: String?) -> Data? {
        let verifierData = inputString?.data(using: .utf8) as NSData?
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hashValue = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(verifierData?.bytes, CC_LONG((verifierData?.length)!), &hashValue)
        return NSData(bytes: hashValue, length: digestLength) as Data
    }
    
    
    class func redact(_ inputString: String?) -> String? {
        if inputString == nil {
            return nil
        }
        switch (inputString?.count ?? 0) {
        case 0:
            return ""
        case 1...8:
            return "[redacted]"
        case 9:
            fallthrough
        default:
            return ((inputString as NSString?)?.substring(to: 6) ?? "") + ("...[redacted]")
        }
    }
    
    class func formUrlEncode(_ inputString: String?) -> String {
        // https://www.w3.org/TR/html5/sec-forms.html#application-x-www-form-urlencoded-encoding-algorithm
        // Following the spec from the above link, application/x-www-form-urlencoded percent encode all
        // the characters except *-._A-Za-z0-9
        // Space character is replaced by + in the resulting bytes sequence
        if (inputString?.count ?? 0) == 0 {
            return inputString!
        }
        let allowedCharacters = CharacterSet(charactersIn: kFormUrlEncodedAllowedCharacters)
        // Percent encode all characters not present in the provided set.
        let encodedString = inputString?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        // Replace occurences of space by '+' character
        return (encodedString?.replacingOccurrences(of: " ", with: "+"))!
    }
    
    
    class func parseJWTSection(_ sectionString: String?) -> [String : NSObject]? {
        let decodedData: Data? = self.base64urlNoPaddingDecode(sectionString)
        // Parses JSON.
        var object: Any? = nil
        if let aData = decodedData {
            do {
                object = try JSONSerialization.jsonObject(with: aData, options: [])
            }
            catch {
                print("Error \(error) parsing token payload \(String(describing: sectionString))")
            }
        }
        
        if (object is [String : NSObject]) {
            return object as? [String : NSObject]
        }
        return nil
    }

}


class TokenManager {
    
    var authState: AuthState?
    
    /// Number of seconds the access token is refreshed before it actually expires.
    private let kExpiryTimeTolerance: Int = 60
    
    
    init(authState: AuthState) {
        self.authState = authState
    }
    
    
    func perform(tokenRequest request: TokenRequest?, originalAuthorizationResponse authorizationResponse: AuthorizationResponse?, callback: @escaping (TokenResponse?, NSError?) -> Void) {
        
        var request = request
        
        let URLRequest: URLRequest = request!.urlRequest()
 
        let session = URLSession.shared

        session.dataTask(with: URLRequest, completionHandler: { data, response, error in
            
            if error != nil {
                // A network error or server error occurred.
                var errorDescription: String? = nil
                if let anURL = URLRequest.url {
                    errorDescription = "Connection error making token request to '\(anURL)': \(error?.localizedDescription ?? "")."
                }
                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.NetworkError, underlyingError: error as NSError?, description: errorDescription)
                DispatchQueue.main.async(execute: {
                    callback(nil, returnedError)
                })
                return
            }
            
            //  The converted code is limited to 2 KB.
            //  Upgrade your plan to remove this limitation.
            //
            let HTTPURLResponse = response as? HTTPURLResponse
            let statusCode: Int? = HTTPURLResponse?.statusCode
            //         AppAuthRequestTrace("Token Response: HTTP Status %d\nHTTPBody: %@", Int(statusCode ?? 0), String(data: data, encoding: .utf8))
            if statusCode != 200 {
                // A server error occurred.
                let serverError = ErrorUtilities.HTTPError(HTTPResponse: HTTPURLResponse!, data: data)
                // HTTP 4xx may indicate an RFC6749 Section 5.2 error response, attempts to parse as such.
                if statusCode! >= 400 && statusCode! < 500 {
 
                    let json = ((try? JSONSerialization.jsonObject(with: data!, options: []) as? [String : (NSObject & NSCopying)]) as [String : (NSObject & NSCopying)]??)
                    // If the HTTP 4xx response parses as JSON and has an 'error' key, it's an OAuth error.
                    // These errors are special as they indicate a problem with the authorization grant.
                    if json?![OIDOAuthErrorFieldError] != nil {
                        let oauthError = ErrorUtilities.OAuthError( OAuthErrorDomain: OIDOAuthTokenErrorDomain, OAuthResponse: json!, underlyingError: serverError)
                        DispatchQueue.main.async(execute: {
                            callback(nil, oauthError)
                        })
                        return
                    }
                }
                
                // Status code indicates this is an error, but not an RFC6749 Section 5.2 error.
                var errorDescription: String? = nil
                if let anURL = URLRequest.url {
                    errorDescription = "Non-200 HTTP response (\(statusCode!)) making token request to '\(anURL)'."
                }
                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.ServerError, underlyingError: serverError, description: errorDescription)
                DispatchQueue.main.async(execute: {
                    callback(nil, returnedError)
                })
                return
            }
            
            //           let jsonDeserializationError: NSError?
            let json = ((try? JSONSerialization.jsonObject(with: data!, options: []) as? [String : (NSObject & NSCopying)]) as [String : (NSObject & NSCopying)]??)
            //            if jsonDeserializationError != nil {
            //                // A problem occurred deserializing the response/JSON.
            //                let errorDescription = "JSON error parsing token response: \(jsonDeserializationError?.localizedDescription ?? "")"
            //                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.JSONDeserializationError, underlyingError: jsonDeserializationError, description: errorDescription)
            //                DispatchQueue.main.async {
            //                    callback(nil, returnedError)
            //                }
            //                return
            //            }
            let tokenResponse = TokenResponse(request: request, parameters: json!)
            
            //            if tokenResponse == nil {
            //                // A problem occurred constructing the token response from the JSON.
            //                let returnedError: NSError? = ErrorUtilities.error(code: ErrorCode.TokenResponseConstructionError, underlyingError: jsonDeserializationError, description: "Token response invalid.")
            //                DispatchQueue.main.async {
            //                    callback(nil, returnedError)
            //                }
            //                return
            //            }
            
            
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
                        callback(nil, invalidIDToken)
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
                        callback(nil, invalidIDToken)
                    })
                    return
                }
                
                // OpenID Connect Core Section 3.1.3.7. rule #3
                // Validates that the audience of the ID Token matches the client ID.
                let clientID = tokenResponse.request!.clientID
                if !idToken!.audience!.contains(clientID!) {
                    let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: "Audience mismatch")
                    DispatchQueue.main.async(execute: {
                        callback(nil, invalidIDToken)
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
                        callback(nil, invalidIDToken)
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
                        callback(nil, invalidIDToken)
                    })
                    return
                }
                
                // Only relevant for the authorization_code response type
                if tokenResponse.request!.grantType == kGrantTypeAuthorizationCode {
                    // OpenID Connect Core Section 3.1.3.7. rule #11
                    // Validates the nonce.
                    let nonce = authorizationResponse!.request!.nonce
                    if nonce != "" && !(idToken!.nonce == nonce) {
                        let invalidIDToken: NSError? = ErrorUtilities.error(code: ErrorCode.IDTokenFailedValidationError, underlyingError: nil, description: "Nonce mismatch")
                        DispatchQueue.main.async(execute: {
                            callback(nil, invalidIDToken)
                        })
                        return
                    }
                }
                // OpenID Connect Core Section 3.1.3.7. rules #12
                // ACR is not directly supported by AppAuth.
                // OpenID Connect Core Section 3.1.3.7. rules #12
                // max_age is not directly supported by AppAuth.
                
            }
            
            // Success
            DispatchQueue.main.async(execute: {
                callback(tokenResponse, nil)
            })
            
        }).resume()
    }
}
