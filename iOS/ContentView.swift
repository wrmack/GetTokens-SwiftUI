//
//  ContentView.swift
//  Shared
//
//  Created by Warwick McNaughton on 30/07/21.
//

import SwiftUI


/// The main app view.  Responsible for displaying the UI.
///
/// `ContentView` works with `ContentInteractor` and `ContentPresenter`.
///
/// `ContentInteractor` is responsible for interacting with the data model and the network.
///
/// `ContentPresenter` is responsible for formatting data it receives from `ContentInteractor`
/// so that it is ready for presentation by `ContentView`. It is initialised as a `@StateObject`
/// to ensure there is only one instance and it notifies new content through a publisher.
///
/// This pattern is based on VIP (View-Interactor-Presenter) and VMVM (View-Model-ViewModel) patterns.
struct ContentView: View {
    var solidCommunity = Solid_community()
    var inruptCom = Inrupt_com()
    var inruptNet = Inrupt_net()
    var interactor = ContentInteractor()
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @EnvironmentObject var authState: AuthState
    @StateObject var presenter = ContentPresenter()
    @State var selectedProvider: Provider
    @State var selectedProviderStr = ""


    
    var body: some View {
        
        // For debugging
//        Print("ContentView body called")

        VStack(alignment: .center) {
            if verticalSizeClass == .regular {
                Spacer().fixedSize().frame(height: 50)
            } else {
                Spacer().fixedSize().frame(height: 20)
            }
            // Select provider
            HStack {
                Picker("Select", selection: $selectedProvider) {
                    Text(solidCommunity.pickerText).tag(Provider.solidcommunity_net)
                    Text(inruptCom.pickerText).tag(Provider.inrupt_com)
                    Text(inruptNet.pickerText).tag(Provider.inrupt_net)
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedProvider, perform: { value in
                    fetchConfig(selectedProvider: value)
                })
                Text("your provider")
                if verticalSizeClass != .regular {
                    Spacer().fixedSize().frame(width: 20)
                    Text(selectedProviderStr)
                        .foregroundColor(.white)
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
        var providerPath: String
        
        switch selectedProvider {
        case Provider.solidcommunity_net :
            providerPath = solidCommunity.path
        case Provider.inrupt_com :
            providerPath = inruptCom.path
        case Provider.inrupt_net :
            providerPath = inruptNet.path
        default:
            providerPath = solidCommunity.path
        }
        selectedProviderStr = providerPath
        interactor.fetchConfiguration(providerPath: providerPath, presenter: presenter, authState: authState)
    }

}

// MARK: - Debugging

extension View {
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
        ContentView(presenter: newPresenter.presenter, selectedProvider: Provider.solidcommunity_net)
    }

}
