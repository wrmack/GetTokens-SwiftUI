#  Get tokens

This code produces an iOS app and a macOS app.  It has two basic functions:
- the app itself displays a read-out of a Solid-OIDC flow using a selection of Solid OIDC Providers
- the code may be useful to developers creating Solid apps using the Apple ecosytem and the Swift programming language

## Design

Code architecture is based on the VIP (View-Interactor-Presenter) and VMVM (View-Model-ViewModel) patterns.

The main UI view is `ContentView` which works with `ContentInteractor` and `ContentPresenter`.

`ContentInteractor` is responsible for interacting with the data model and the network.

 `ContentPresenter` is responsible for formatting data it receives from `ContentInteractor`
 so that it is ready for presentation by `ContentView`. `ContentView` initialises `ContentPresenter` as a `@StateObject`
 to ensure there is only one instance. `ContentPresenter` notifies new content through publishers.

### State
Data we want to track is kept in AuthState in the `State` folder.  There is no persistent storage of data.

### Models
`ContentInteractor` makes network requests and receives responses. Models for these requests and responses are kept as separate files in the `Models` folder.

### Utilities
The `Utilities` folder contains the JOSESwift library and other utilities used by the main code.


## Acknowledgements
"Get tokens" makes use of the [JOSESwift library](https://github.com/airsidemobile/JOSESwift) for managing JSON Web Tokens (JWT).

OpenID's [AppAuth for iOS](https://openid.github.io/AppAuth-iOS/) was very useful for the iOS implementation of OIDC.

Solid specific specifications as contained in:
- [Solid-OIDC spec](https://solid.github.io/solid-oidc/)
- [Solid OIDC Primer](https://solid.github.io/solid-oidc/primer/)
- [Solid OIDC-Provider](https://github.com/solid/solid-oidc-provider)

