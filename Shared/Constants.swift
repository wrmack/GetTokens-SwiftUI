//
//  Constants.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 30/07/21.
//

import Foundation
import SwiftUI

let BACKGROUND_MAIN = Color(red: 0.9,green: 0.2,blue: 0.2)

let kIssuerKey = "issuer"
let kAuthorizationEndpointKey = "authorization_endpoint"
let kTokenEndpointKey = "token_endpoint"
let kUserinfoEndpointKey = "userinfo_endpoint"
let kJWKSURLKey = "jwks_uri"
let kRegistrationEndpointKey = "registration_endpoint"
let kScopesSupportedKey = "scopes_supported"
let kResponseTypesSupportedKey = "response_types_supported"
let kResponseModesSupportedKey = "response_modes_supported"
let kGrantTypesSupportedKey = "grant_types_supported"
let kACRValuesSupportedKey = "acr_values_supported"
let kSubjectTypesSupportedKey = "subject_types_supported"
let kIDTokenSigningAlgorithmValuesSupportedKey = "id_token_signing_alg_values_supported"
let kIDTokenEncryptionAlgorithmValuesSupportedKey = "id_token_encryption_alg_values_supported"
let kIDTokenEncryptionEncodingValuesSupportedKey = "id_token_encryption_enc_values_supported"
let kUserinfoSigningAlgorithmValuesSupportedKey = "userinfo_signing_alg_values_supported"
let kUserinfoEncryptionAlgorithmValuesSupportedKey = "userinfo_encryption_alg_values_supported"
let kUserinfoEncryptionEncodingValuesSupportedKey = "userinfo_encryption_enc_values_supported"
let kRequestObjectSigningAlgorithmValuesSupportedKey = "request_object_signing_alg_values_supported"
let kRequestObjectEncryptionAlgorithmValuesSupportedKey = "request_object_encryption_alg_values_supported"
let kRequestObjectEncryptionEncodingValuesSupported = "request_object_encryption_enc_values_supported"
let kTokenEndpointAuthMethodsSupportedKey = "token_endpoint_auth_methods_supported"
let kTokenEndpointAuthSigningAlgorithmValuesSupportedKey = "token_endpoint_auth_signing_alg_values_supported"
let kDisplayValuesSupportedKey = "display_values_supported"
let kClaimTypesSupportedKey = "claim_types_supported"
let kClaimsSupportedKey = "claims_supported"
let kServiceDocumentationKey = "service_documentation"
let kClaimsLocalesSupportedKey = "claims_locales_supported"
let kUILocalesSupportedKey = "ui_locales_supported"
let kClaimsParameterSupportedKey = "claims_parameter_supported"
let kRequestParameterSupportedKey = "request_parameter_supported"
let kRequestURIParameterSupportedKey = "request_uri_parameter_supported"
let kRequireRequestURIRegistrationKey = "require_request_uri_registration"
let kOPPolicyURIKey = "op_policy_uri"
let kOPTosURIKey = "op_tos_uri"

let kConfigurationKey = "configuration"
let kInitialAccessToken = "initial_access_token"
let kRedirectURIsKey = "redirect_uris"
let kResponseTypesKey = "response_types"
let kGrantTypesKey = "grant_types"
let kSubjectTypeKey = "subject_type"
let kAdditionalParametersKey = "additionalParameters"
let kApplicationTypeNative = "native"

let kResponseTypeKey = "response_type"
let kClientIDKey = "client_id"
let kClientSecretKey = "client_secret"
let kScopeKey = "scope"
let kRedirectURLKey = "redirect_uri"
let kStateKey = "state"
let kNonceKey = "nonce"
let kCodeVerifierKey = "code_verifier"
let kCodeChallengeKey = "code_challenge"
let kCodeChallengeMethodKey = "code_challenge_method"
let OIDOAuthorizationRequestCodeChallengeMethodS256 = "S256"
let kStateSizeBytes: Int = 32
let kCodeVerifierBytes: Int = 32


let kGrantTypeKey = "grant_type"
let kAuthorizationCodeKey = "code"
let kRefreshTokenKey = "refresh_token"
let kGrantTypeAuthorizationCode = "authorization_code"
let kPublicKey = "request"   // POP
let kTokenType = "token_type"   // POP
let kKeyOps = "key_ops"  // POP

let kTokenEndpointAuthenticationMethodParam = "token_endpoint_auth_method"
let kApplicationTypeParam = "application_type"
let kRedirectURIsParam = "redirect_uris"
let kResponseTypesParam = "response_types"
let kGrantTypesParam = "grant_types"
let kSubjectTypeParam = "subject_type"
let kClientNameParam = "client_name"

let kResponseTypeCode = "code"
let kResponseTypeToken = "token"
let kResponseTypeIDToken = "id_token"


 let kAccessTokenKey = "access_token"
 let kExpiresInKey = "expires_in"
 let kTokenTypeKey = "token_type"
 let kIDTokenKey = "id_token"
 let kRequestKey = "request"
 let kTokenExchangeRequestException = """
Attempted to create a token exchange request from an authorization response with no \
authorization code.
"""


let kNeedsTokenRefreshKey = "needsTokenRefresh"
let kLastAuthorizationResponseKey = "lastAuthorizationResponse"
let kLastTokenResponseKey = "lastTokenResponse"
let kAuthorizationErrorKey = "authorizationError"
let kRefreshTokenRequestException = "Attempted to create a token refresh request from a token response with no refresh token."
let kGrantTypeRefreshToken = "refresh_token"
