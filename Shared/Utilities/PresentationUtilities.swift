//
//  PresentationUtilities.swift
//  GetTokens-SwiftUI (macOS)
//
//  Created by Warwick McNaughton on 8/08/21.
//

import Foundation

// MARK: String constants

let kRule1 = "***********************************************\n"
let kRule2 = "-----------------------------------------------\n"

let kDiscoveryHeader = """
Stage 1: Discovery

The app requests the identity provider's configuration endpoint .well-known/openid-configuration \
to get information for subsequent requests.

The response is JSON data.

Those providers who conform to the Solid-OIDC protocol will \
include in the response: "solid_oidc_supported": "https://solidproject.org/TR/solid-oidc"
"""

let kRegistrationHeader = """
Stage 2: Dynamic registration

The client app ("Get tokens") is not already registered with the OpenID Provider. We \
use OpenID's dynamic registration protocol to make a POST request using JSON data.

application_type
The options are 'web' or 'native'.  This is a native application.

redirect_uris
The identity provider / authorizing server will later use an external user agent (Safari) to authenticate the \
user (the user will be asked to log on to the provider account). The client will then be redirected to the \
redirect uri submitted with the authorization request. At this stage we register our redirect \
uri(s).  A native app must use a custom uri (or localhost).

token_endpoint_auth_method
How we will be authenticated later when requesting a token from the token endpoint. This \
normally involves a client_secret associated with a client_id.  Best practice for \
native apps is to not use a client_secret [RFC 8252] so we set this to 'none'.

client_name
Human-readable string name of the client to be presented to the end-user during \
authorization [RFC 7591]. The client is our app ('Get tokens').

response_types
We will be using the Authorization Code Flow where all tokens will be returned from the \
token endpoint, so set this to 'code'.

grant_types
An authorization grant is a credential representing the resource owner's authorization to \
access its protected resources.  It is used by the client to obtain an access token (RFC 6749).
We register for two types: authorization_code and refresh_token.  

The OpenID Provider responds confirming the data it has regiestered and provides a 'client_id'.

"""

let kAuthorizationHeader = """
Stage 3: Get authorization code

We request an authorization code that can be used to later request access and id tokens.\
The identity provider provides the authorization code on the basis the end-user (the user of this app) has \
been authenticated (by logging in) and has provided consent to access resources.

This is a GET request with a query string.

The request implements Proof Key for Code Exchange (RFC 6736) or PKCE.  'Code exchange' refers \
to when the authorization code is exchanged for tokens. Without a 'Proof key' being required, \
an attacker might intercept the grant of the authorization code and use the code to obtain tokens. \
We generate a random string - the 'code_verifier'. We hash it with SHA256 and base64urlencode it to \
form the 'code_challenge'.  We send the code_challenge to the identity provider.  When we request \
tokens we send the code_verifier and the token server checks it is correct by hashing and encoding \
it and comparing with the code_challenge.


response_type
Set to 'code' (only want an authorization code and will make a separate request for tokens).

redirect_uri
The uri the authorizing server will return the client to once the user has been authenticated \
through logging on to the Solid Identity Provider and providing consent to use resources.

scope
The previous discovery shows the scope that is offered by the provider.
   open_id: implements the OIDC extension to OAuth; an id_token is returned from the token endpoint \
in addtion to an access token.
   profile: Solid-OIDC WebID (Solid OIDC Primer)
   offline_access: required to get a refresh token (Solid OIDC Primer)

client_id
The client_id issued when registering.

state
Opaque value used to maintain state between the request and the callback.

code_challenge_method, code_challenge
Required by PKCE (above)

The OpenID Provider provides a login page. After successful login, the provider redirects to the 'redirect_uri' \
with a query string appended to the url containing an authorization code and the state.

The app will use the authorization code to request tokens.
"""

let kTokenHeader = """
Stage 4: Get tokens

The app makes a POST request for tokens using the authorization code.  It also uses the Demonstrating Proof of Possession \
(DPoP) mechanism (an IETF draft) in which tokens that are issued to the client are bound to a client's public key. \
When the app later presents the token to a resource provider, the client demonstrates it holds the private key. \
This gives assurance to the resource provider that the client presenting the access token is the same client to \
whom it was granted.

The request header includes a "DPoP" key with a JWT (JSON Web Token) as its value. The JWT includes the public key as a \
JWK (JSON Web Key).

The request body includes:

redirect_uri
As before

grant_type
Set to 'authorization_code'.  We are using the authorization code to request tokens. \
We also registered 'refresh_token' as a grant_type and could use this as the grant_type \
once it is granted.

code
The authorization code provided in the previous stage

client_id
As before

code_verifier
The code verifier part of the PKCE mechanism explained above.


The Identity Provider returns an access_token, id_token and optionally a refresh_token.  The access token can \
be used for accessing protected resources.

"""

let kUserInfoHeader = """
Userinfo

We can now get userinfo by presenting the DPoP access token.

The request header includes two headers:
- a "DPoP" key with a JWT (JSON Web Token) as its value. The JWT includes the public key as a \
JWK (JSON Web Key)
- an "Authorization" key with the DPoP access token issued above as its value.

"""



