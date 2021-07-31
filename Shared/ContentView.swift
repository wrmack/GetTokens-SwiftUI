//
//  ContentView.swift
//  Shared
//
//  Created by Warwick McNaughton on 30/07/21.
//

import SwiftUI



// Provider info
struct Solid_community {
    var pickerText = "solidcommunity.net"
    var path = "https://solidcommunity.net"
}
struct Inrupt_com {
    var pickerText = "inrupt.com"
    var path = "https://broker.pod.inrupt.com"
}
struct Inrupt_net {
    var pickerText = "inrupt.net"
    var path = "https://inrupt.net"
}

// Picker items
enum Provider: String, CaseIterable, Identifiable {
    case none
    case solidcommunity_net
    case inrupt_com
    case inrupt_net

    var id: String { self.rawValue }
}

/// The main app view.  Responsible for displaying the UI.
///
/// `ContentView` works with `ContentInteractor` and `ContentPresenter`.
///
/// `ContentInteractor` is responsible for interacting with the data model and the network.
///
/// `ContentPresenter` is responsible for formatting data it receives from `ContentInteractor`
/// so that it is ready for presentation by `ContentView`. It is initialised as a `@StateObject`
/// to ensure there is only one instance and it notifies new content through a publisher.
struct ContentView: View {
    var solidCommunity = Solid_community()
    var inruptCom = Inrupt_com()
    var inruptNet = Inrupt_net()
    var interactor = ContentInteractor()
    
    @EnvironmentObject var authState: AuthState
    @StateObject var presenter = ContentPresenter()
    @State var selectedProvider: Provider
    @State var selectedProviderStr = ""
    @State var displayTitle = ""

    
    var body: some View {
        Print("ContentView body called")
        VStack(alignment: .center) {
            Spacer().fixedSize().frame(height: 50)
            
            // Select provider
            HStack {
                Picker("Select", selection: $selectedProvider) {
                    Text(solidCommunity.pickerText).tag(Provider.solidcommunity_net)
                    Text(inruptCom.pickerText).tag(Provider.inrupt_com)
                    Text(inruptNet.pickerText).tag(Provider.inrupt_net)
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedProvider, perform: { value in
                    displayTitle = "Fetching configuration"
                    fetchConfig(selectedProvider: value)
                })
                Text("your provider")
            }
            Spacer().fixedSize().frame(height: 20)
            Text(selectedProviderStr)
            Spacer().fixedSize().frame(height: 50)
            
            // Display provider responses
            HStack(alignment:.top) {
                Spacer().fixedSize().frame(width: 20)
                VStack{
                    Text(displayTitle)
                        .font(.system(size: 20))
                    ScrollView([.vertical, .horizontal]) {
                        Text(presenter.displayData)
                            .font(.system(size: 10))
                    }
                }
                .padding()
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

// For debugging
extension View {
   func Print(_ vars: Any...) -> some View {
      for v in vars { print(v) }
      return EmptyView()
   }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selectedProvider: Provider.none)
    }
}
