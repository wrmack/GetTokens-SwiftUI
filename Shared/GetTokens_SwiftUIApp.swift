//
//  GetTokens_SwiftUIApp.swift
//  Shared
//
//  Created by Warwick McNaughton on 30/07/21.
//

import SwiftUI

@main
struct GetTokens_SwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthState())
        }
    }
}
