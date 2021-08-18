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
        
        // For debugging
//        Print("ContentView body called")
        
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
                    ScrollView {
                      ForEach(presenter.displayData, id: \.self) { content in
                         DisplayRowContent(rowContent: content)
                        
//                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                      }

                    }
                    .background(Color.white)
   
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
            .background(Color.white)
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

// For debugging
extension View {
   func Print(_ vars: Any...) -> some View {
      for v in vars { print(v) }
      return EmptyView()
   }
}

// Create a ContentPresenter with data just for preview purposes

class PreviewContentPresenter: ContentPresenter {
    var presenter: ContentPresenter // This is what we need to pass to ContentView
    
    override init() {
        self.presenter = ContentPresenter()
        presenter.displayTitle = "Title"
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
