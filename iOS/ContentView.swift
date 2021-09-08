//
//  ContentView.swift
//  Shared
//
//  Created by Warwick McNaughton on 30/07/21.
//

import SwiftUI

struct Provider: Hashable {
    var pickerText: String
    var path: String
}


/// The iOS main app view.  Responsible for displaying the UI.
///
/// `ContentView` works with `ContentInteractor` and `ContentPresenter`.
///
/// `ContentInteractor` is responsible for interacting with the data model and the network.
///
/// `ContentPresenter` is responsible for formatting data it receives from `ContentInteractor`
/// so that it is ready for presentation by `ContentView`. It is initialised as a `@StateObject`
/// to ensure there is only one instance and it notifies new content through a publisher.
///
/// This pattern is based on the VIP (View-Interactor-Presenter) and VMVM (View-Model-ViewModel) patterns.
struct ContentView: View {
    let providers = [
        Provider(pickerText: "None", path: ""),
        Provider(pickerText: "solidcommunity.net", path: "https://solidcommunity.net"),
        Provider(pickerText: "inrupt.com", path: "https://broker.pod.inrupt.com"),
        Provider(pickerText: "inrupt.net", path: "https://inrupt.net"),
        Provider(pickerText: "solidweb.org", path: "https://solidweb.org"),
        Provider(pickerText: "trinpod.us", path: "https://trinpod.us")
    ]
    var interactor = ContentInteractor()
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @EnvironmentObject var authState: AuthState
    @StateObject var presenter = ContentPresenter()
    @State var selectedProvider = Provider(pickerText: "None", path: "")
    @State var selectedProviderStr = ""
    @State var showInfo = false

    
    var body: some View {
        
        // For debugging
//        Print("ContentView body called")
        ZStack {
            VStack(alignment: .center) {
                if verticalSizeClass == .regular {
                    Spacer().fixedSize().frame(height: 50)
                } else {
                    Spacer().fixedSize().frame(height: 20)
                }
                // Select provider
                HStack {
                    Picker("Select", selection: $selectedProvider) {
                        ForEach(providers, id: \.self) { item in
                            Text(item.pickerText)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(Color(red: 0.9, green: 0.9, blue: 1.0))
                    .onChange(of: selectedProvider, perform: { value in
                        fetchConfig(selectedProvider: value)
                    })
                    Text("your provider")
                    if verticalSizeClass != .regular {
                        Spacer().fixedSize().frame(width: 20)
                        Text(selectedProviderStr)
                            .foregroundColor(.white)
                    }
                    Image(systemName: "info.circle")
                        .onTapGesture {
                            showInfo = showInfo ? false : true
                        }
                }
                if verticalSizeClass == .regular {
                    Spacer().fixedSize().frame(height: 20)
                    Text(selectedProviderStr)
                    Spacer().fixedSize().frame(height: 50)
                }

                // Display provider responses
                HStack(alignment:.top) {
                    Spacer().fixedSize().frame(width: 20)
                    VStack{
                        Text(presenter.displayTitle)
                            .font(.system(size: 16))
                        List {

                          ForEach(presenter.displayData, id: \.self) { content in
                             DisplayRowContent(rowContent: content)
                                .listRowInsets(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
                          }
                        }
                        .background(Color.white)
                        .listStyle(PlainListStyle())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.white)
                    .foregroundColor(Color.black)
                    Spacer().fixedSize().frame(width: 20)
                }

                Spacer().fixedSize().frame(height: 50)
            }
            .background(BACKGROUND_MAIN)
            .edgesIgnoringSafeArea([.all])
            VStack {
                if showInfo {
                    Spacer().fixedSize().frame(height:60)
                    HStack {
                        Spacer()
                        Text(
                            """
                            The authorization stage requires you to log in. In order to view the full flow you need to have an account with the selected provider.  If you do not have an account you will still be able to view the discovery and registration stages.
                            """
                        )
                        .font(Font.system(.callout))
                        .multilineTextAlignment(.leading)
                        .padding()
                        .background(Color(white: 0.95))
                        .border(Color.gray)
                        .cornerRadius(10.0)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
    struct DisplayRowContent: View {
        var rowContent: RowData
        var body: some View {
            VStack{
                Divider()
                    .frame(height: 4)
                    .background(Color(white: 0.4, opacity: 0.8))
                Text(rowContent.header)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .font(.system(size: 12, weight: .semibold))
                Divider()
                    .frame(height: 2)
                    .background(Color(white: 0.4, opacity: 0.8))
                Text(rowContent.content)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .font(.system(size: 12, weight: .regular))
            }
        }
    }
    
    func fetchConfig(selectedProvider: Provider) {
        interactor.discoverConfiguration(providerPath: selectedProvider.path, presenter: presenter, authState: authState)
    }

}

// MARK: - Debugging


extension View {
    /// Prints to console.
    /// Use in SwiftUI views instead of `print()`.
   func Print(_ vars: Any...) -> some View {
      for v in vars { print(v) }
      return EmptyView()
   }
}


// MARK: - Preview

// Create a ContentPresenter with data just for preview purposes

class PreviewContentPresenter: ContentPresenter {
    var presenter: ContentPresenter // This is what we need to pass to ContentView
    
    override init() {
        self.presenter = ContentPresenter()
        presenter.displayData = [RowData(
            header: kDiscoveryHeader,
            content:"""
            {
                "grant_types" : ["authorization_code"],
                "application_type" : "native",
                "token_endpoint_auth_method" : "client_secret_post",
                "response_types" : ["code"],
                "client_name" : "Get tokens",
                "redirect_uris" : ["com.wm.get-tokens:/mypath"]
            }
            """
        )]
    }
}

struct ContentView_Previews: PreviewProvider {
    
    @StateObject static var newPresenter = PreviewContentPresenter()
    
    static var previews: some View {
        ContentView(presenter: newPresenter.presenter, selectedProvider: Provider(pickerText: "solidcommunity.net", path: "https://solidcommunity.net"), showInfo: true)
    }

}
