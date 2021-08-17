//
//  ContentView.swift
//  GetTokens-SwiftUI (macOS)
//
//  Created by Warwick McNaughton on 7/08/21.
//

import SwiftUI

struct ContentView: View {
    var solidCommunity = Solid_community()
    var inruptCom = Inrupt_com()
    var inruptNet = Inrupt_net()
    var interactor = ContentInteractor()

    @EnvironmentObject var authState: AuthState
    @StateObject var presenter = ContentPresenter()
    @State var selectedProvider: Provider
    @State var selectedProviderStr = ""
    var body: some View {
        Print("ContentView body called")
        VStack(alignment: .center) {
            Spacer().fixedSize().frame(height: 50)

            // Select provider
            HStack {
                Spacer()
                Picker("Select your provider", selection: $selectedProvider) {
                    Text(solidCommunity.pickerText).tag(Provider.solidcommunity_net)
                    Text(inruptCom.pickerText).tag(Provider.inrupt_com)
                    Text(inruptNet.pickerText).tag(Provider.inrupt_net)
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedProvider, perform: { value in
                    fetchConfig(selectedProvider: value)
                })
                .frame(width: 400, alignment: .center)
                Spacer()
            }

            Spacer().fixedSize().frame(height: 30)

            // Display provider responses
            HStack(alignment:.top) {
                Spacer().fixedSize().frame(width: 20)
                VStack{
                    Text(presenter.displayTitle)
                        .font(.system(size: 16))
                    ScrollView([.vertical]) {
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
        Group {
            ContentView(selectedProvider: Provider.none)
        }
    }
}
