//
//  RegistrationResponse.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 31/07/21.
//

import Foundation


struct RegistrationResponse {
      
    var request: RegistrationRequest?
    var clientID: String?
    var clientIDIssuedAt: Date?
    var clientSecret: String?
    var clientSecretExpiresAt: Date?
    var registrationAccessToken: String?
    var registrationClientURI: URL?
    var tokenEndpointAuthenticationMethod: String?
    var additionalParameters = [String : Any]()
    
}


// TODO: - Implement Codable -


//    func description() -> String {
//        //        return String(format: """
//        //    <%@: %p, clientID: "%@", clientIDIssuedAt: %@, \
//        //    clientSecret: %@, clientSecretExpiresAt: "%@", \
//        //    registrationAccessToken: "%@", \
//        //    registrationClientURI: "%@", \
//        //    additionalParameters: %@, request: %@>
//        //    """, NSStringFromClass(type(of: self).self), self, clientID!, clientIDIssuedAt! as CVarArg, OIDTokenUtilities.redact(clientSecret)!, clientSecretExpiresAt! as CVarArg, OIDTokenUtilities.redact(registrationAccessToken)!, registrationClientURI! as CVarArg, additionalParameters!, request as! CVarArg)
//
//        let d =  "\n=============\nOIDRegistrationResponse \nclientID: \(clientID!) \nclientIDIssuedAt: \(String(describing: clientIDIssuedAt)) \nclientSecret: \(TokenUtilities.redact(clientSecret)!) \nclientSecretExpiresAt: \(String(describing: clientSecretExpiresAt)) \nregistrationAccessToken: \(String(describing: TokenUtilities.redact(registrationAccessToken))) \nregistrationClientURI: \(String(describing: registrationClientURI)) \nadditionalParameters: \(additionalParameters) \nrequest: \(request!.description)\n============="
//        return d
//    }
