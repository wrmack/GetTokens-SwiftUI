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
to get information for subsequent requests.

The response is JSON data.

Those providers who conform to the Solid-OIDC protocol will \
include in the response: "solid_oidc_supported": "https://solidproject.org/TR/solid-oidc"
"""

let kRegistrationHeader = """
Stage 2: Dynamic registration \n
The client app ("Get tokens") is not already registered with the OpenID Provider. We \
register the client using OpenID's dynamic registration protocol. A POST request is made using JSON data.

The OpenID Provider responds with a client id.
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
The app makes a POST request using the authorization code.
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
