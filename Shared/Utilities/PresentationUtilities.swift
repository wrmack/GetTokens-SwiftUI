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
We use OpenID's dynamic registration protocol. A POST request is made using JSON data:
{
  "grant_types" : ["authorization_code"],
  "application_type" : "native",
  "token_endpoint_auth_method" : "client_secret_post",
  "response_types" : ["code"],
  "client_name" : "Get tokens",
  "redirect_uris" : ["com.wm.get-tokens:/mypath"]
}

The response provides us a client id and a client secret by the OpenID Provider.
"""

let kAuthorizationHeader = """
Stage 3: Get authorization code \n
A GET request with query.
eg: https://solidcommunity.net/authorize?
     client_id=*********...&
     state=*********...&
     nonce=*********...&
     response_type=code&
     redirect_uri=com.wm.get-tokens:/mypath&
     code_challenge=********...&
     scope=openid profile offline_access&
     code_challenge_method=S256
The OpenID Provider provides a login page. After \
successful login, the provider redirects to the redirect url \
with a query string appended to the url containing:
code : *********&
state : *********

The app will use the code to request tokens.
"""

let kTokenHeader = """
Stage 4: Get tokens \n
The app makes POST request.
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
