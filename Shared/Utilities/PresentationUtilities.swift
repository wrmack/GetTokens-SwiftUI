//
//  PresentationUtilities.swift
//  GetTokens-SwiftUI (macOS)
//
//  Created by Warwick McNaughton on 8/08/21.
//

import Foundation

// MARK: String constants

let rule1 = "***********************************************\n"
let rule2 = "-----------------------------------------------\n"

let kDiscoveryHeader = """
Stage 1: Discovery\n
The app requests the provider's configuration endpoint .well-known/openid-configuration \
to get information for subsequent requests. The response is JSON data.
"""

let kRegistrationHeader = """
Stage 2: Dynamic registration \n
The client app ("Get tokens") is not already registered with the OpenID Provider and so has to register. \
We use OpenID's dynamic registration protocol. A POST request is made using JSON data.

The response provides us a client id and a client secret by the OpenID Provider.
"""

let kAuthorizationHeader = """
Stage 3: Get authorization code \n
A GET request with query.
The OpenID Provider provides a login page. After \
successful login, the provider redirects to the redirect url \
with a query string appended to the url containing an authorization code.

The app will use the authorization code to request tokens.
"""

let kTokenHeader = """
Stage 4: Get tokens \n
The app makes a POST request using the access code.
The OpenID Provider returns:
  token_type
  access_token
  id_token
  refresh_token
  expires_in
The access_token can be used for accessing protected resources.
"""

let kUserInfoHeader = """
Now get userinfo by presenting DPoP access token
"""


// MARK: - Struct for presenting header and content

struct RowData: Hashable {
    var header = ""
    var content = ""
}
