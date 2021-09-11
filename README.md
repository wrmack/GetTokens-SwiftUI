#  Get tokens

<a href="https://apps.apple.com/us/app/get-tokens/id1585088360?mt=12&amp;itsct=apps_box_badge&amp;itscg=30200" style="display: inline-block; overflow: hidden; border-top-left-radius: 13px; border-top-right-radius: 13px; border-bottom-right-radius: 13px; border-bottom-left-radius: 13px; width: 250px; height: 83px;"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-mac-app-store/black/en-us?size=250x83&amp;releaseDate=1631318400&h=b65ef15c992a18e9ac8528d1a720d7ac" alt="Download on the Mac App Store" style="border-top-left-radius: 13px; border-top-right-radius: 13px; border-bottom-right-radius: 13px; border-bottom-left-radius: 13px; width: 250px; height: 83px;"></a>

For Solid developers who do not develop using the Apple platform but do have a recent Macbook, Get tokens can be downloaded from the Apple App Store.

This code produces an iOS app and a macOS app.  It has two basic functions:
- the app itself displays a read-out of a Solid-OIDC flow using a selection of Solid OIDC Providers
- the code may be useful to developers creating Solid apps using the Apple ecosytem and the Swift programming language



## Design

Code architecture is based on the VIP (View-Interactor-Presenter) pattern.

- (V): The main UI view is `ContentView` which works with `ContentInteractor` and `ContentPresenter`. 

- (I): `ContentInteractor` is responsible for interacting with the data model and the network.

- (P): `ContentPresenter` is responsible for formatting data it receives from `ContentInteractor`
 so that it is ready for presentation by `ContentView`. `ContentView` initialises `ContentPresenter` as a `@StateObject`
 to ensure there is only one instance. `ContentPresenter` notifies new content through publishers.

### State
Data we want to track is kept in `AuthState` in the `State` folder.  There is no persistent storage of data.

### Models
`ContentInteractor` makes network requests and receives responses. Models for these requests and responses are kept as separate files in the `Models` folder.

### Utilities
The `Utilities` folder contains the JOSESwift library and other utilities used by the main code.



## Specifications
The specifications relevant to each stage.

### Discovery
- [OpenID Connect](https://openid.net/specs/openid-connect-discovery-1_0.html) Discovery

### Registration
- [OpenID Connect](https://openid.net/specs/openid-connect-registration-1_0.html) Dynamic Client Registration 1.0
- [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-2) The OAuth 2.0 Authorization Framework - 2.0 Client registration
- [RFC 7591](https://www.rfc-editor.org/rfc/rfc7591) OAuth 2.0 Dynamic Client Registration Protocol
- [RFC 8252](https://datatracker.ietf.org/doc/html/rfc8252#section-8.4) OAuth 2.0 for Native Apps - 8.4 Registration of Native App Clients
- [Solid-OIDC](https://solid.github.io/solid-oidc/#clientids-oidc) 5.3 OIDC Registration

### Authorization
- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html#CodeFlowAuth) 3.1 Authentication using the Authorization Code Flow
- [RFC 6749](https://www.rfc-editor.org/rfc/rfc6749#section-4.1) The OAuth 2.0 Authorization Framework - 4.1.  Authorization Code Grant
- [RFC 8252](https://datatracker.ietf.org/doc/html/rfc8252) OAuth 2.0 for Native Apps
- [RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636) Proof Key for Code Exchange by OAuth Public Clients
- [Solid-OIDC](https://solid.github.io/solid-oidc/) (nothing about getting getting authenticated and receiving authorization code)

### Token exchange
- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html#TokenEndpoint) 3.1.3 Token endpoint
- [RFC 6749](https://www.rfc-editor.org/rfc/rfc6749#section-4.1.3) The OAuth 2.0 Authorization Framework - 4.1.3  Access token request
- [RFC 8693](https://datatracker.ietf.org/doc/html/rfc8693) OAuth 2.0 Token exchange
- [IETF draft](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-dpop-03) OAuth 2.0 Demonstrating Proof-of-Possession at the Application Layer (DPoP)
- [Solid-OIDC](https://solid.github.io/solid-oidc/#tokens) 6. Token instantiation

### Accessing protected resources


## Acknowledgements
"Get tokens" makes use of the [JOSESwift library](https://github.com/airsidemobile/JOSESwift) for managing JSON Web Tokens (JWT).

OpenID's [AppAuth for iOS](https://openid.github.io/AppAuth-iOS/) was very useful for the iOS implementation of OIDC.

Solid specific specifications as contained in:
- [Solid-OIDC spec](https://solid.github.io/solid-oidc/)
- [Solid OIDC Primer](https://solid.github.io/solid-oidc/primer/)
- [Solid OIDC-Provider](https://github.com/solid/solid-oidc-provider)


## Privacy policy
"Get tokens" does not store any personal information.   The purpose of the app is to display authentication data, including access tokens.   Such tokens grant access to protected resources and so users must be careful to not allow unauthorized access to the display or copies of the display.

## Licence
```
MIT License

Copyright (c) 2021 Warwick McNaughton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
