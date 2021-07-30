//
//  ContentView.swift
//  Shared
//
//  Created by Warwick McNaughton on 30/07/21.
//

import SwiftUI

enum Provider: String, CaseIterable, Identifiable {
    case solid_community
    case inrupt_com
    case inrupt_net

    var id: String { self.rawValue }
}

struct ContentView: View {
    @StateObject var presenter = ContentPresenter()
    var interactor = ContentInteractor()
    @State var config: String
    @State var selectedProvider: Provider
    
    var body: some View {
        Print("ContentView body called")
        VStack(alignment: .center) {
            Spacer().fixedSize().frame(height: 80)
            Text("Enter your provider").fontWeight(.semibold)
            
            Picker("Provider", selection: $selectedProvider) {
                Text("solidcommunity.net").tag(Provider.solid_community)
                Text("inrupt.com").tag(Provider.inrupt_com)
                Text("inrupt.net").tag(Provider.inrupt_net)
            }
            HStack {

                TextField("eg https://yourusername.inrupt.net", text: $config, onCommit: {
                    fetchConfig()
                })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.URL)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .cornerRadius(8)
                    .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 20))
            }
            Spacer().fixedSize().frame(height: 100)
            HStack {
                Spacer().fixedSize().frame(width: 20)
                ScrollView([.vertical, .horizontal]) {
                    Text(presenter.displayData)
                        .font(.system(size: 10))
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(Color.white)
                }
                .background(Color.white)
                Spacer().fixedSize().frame(width: 20)
            }
            Spacer().fixedSize().frame(height: 50)
        }
        .background(BACKGROUND_MAIN)
        .edgesIgnoringSafeArea([.all])
    }
    
    func fetchConfig() {
        interactor.fetchConfiguration(providerPath: config, presenter: presenter)
    }

}

extension View {
   func Print(_ vars: Any...) -> some View {
      for v in vars { print(v) }
      return EmptyView()
   }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(config: " ",selectedFlavor: Flavor.chocolate)
    }
}
