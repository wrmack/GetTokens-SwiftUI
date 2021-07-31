//
//  AuthState.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 31/07/21.
//

import Foundation

class AuthState: ObservableObject {
    let kRedirectURI = "com.wm.POD-browser:/mypath"
    var opConfig: OPConfiguration?
    var registrationResponse: RegistrationResponse?
}
