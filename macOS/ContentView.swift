//
//  ContentView.swift
//  GetTokens-SwiftUI (macOS)
//
//  Created by Warwick McNaughton on 7/08/21.
//
import SwiftUI

struct Provider: Hashable {
    var pickerText: String
    var path: String
}




/// The macOS main app view.  Responsible for displaying the UI.
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

    @EnvironmentObject var authState: AuthState
    @StateObject var presenter = ContentPresenter()
    @State var selectedProvider = Provider(pickerText: "None", path: "")
    @State var selectedProviderStr = ""
    @State var showInfo = false
    @State var showWarning = false
    
    
    var body: some View {
        
        // For debugging
//        Print("ContentView body called")
        ZStack {
            VStack(alignment: .center) {
                Spacer().fixedSize().frame(height: 60)

                // Select provider
                HStack {
//                    Image("tokenIcon")
//                        .resizable()
//                        .antialiased(true)
//                        .frame(width:40,height:28)
//                        .padding(.all, 20)

                    Spacer()
                    Picker("Select your provider", selection: $selectedProvider) {
                        ForEach(providers, id: \.self) { item in
                            Text(item.pickerText)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedProvider, perform: { value in
                        if value.pickerText != "None" {
                            fetchConfig(selectedProvider: value)
                        }
                    })
                    .frame(width: 400, alignment: .center)
                    
                    Image(systemName: "info.circle")
                        .onTapGesture {
                            showInfo = showInfo ? false : true; showWarning = false
                        }
                    Image(systemName: "exclamationmark.triangle.fill")
                        .renderingMode(.original)
                        .frame(width:15,height:15)
                        .padding(.leading, 10)
                        .onTapGesture {
                            showWarning = showWarning ? false : true; showInfo = false
                        }
                    Spacer()
                }
//                .padding(.top,60)
               
                Spacer().fixedSize().frame(height: 30)
                
                // The Copy button
                HStack {
                    Spacer()
                    Button(action: {
                        let pasteBoard = NSPasteboard.general
                        pasteBoard.clearContents()
                        var stringObj = NSString()
                        presenter.displayData.forEach({ rowdata in
                            stringObj = stringObj.appending("\(kRule1)\n\(rowdata.header)\n\n\(kRule2)\n\(rowdata.content) \n\n") as NSString
                        })
                        _ = pasteBoard.writeObjects([stringObj])
                        
                    }, label: {
                        Text("Copy")
                    })
                    Spacer().fixedSize().frame(width:20)
                }
                
                // Display provider responses
                HStack(alignment:.top) {
                    Spacer().fixedSize().frame(width: 20)
                    VStack (alignment:.center){
                        Text(presenter.displayTitle)
                            .font(.system(size: 16))

                        ScrollView {
                          ForEach(presenter.displayData, id: \.self) { content in
                            DisplayRowContent(rowContent: content)
                          }

                        }
                        .background(Color.white)
                        .frame(maxWidth:.infinity)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(Color.white)
                    .foregroundColor(Color.black)
                    
                    Spacer().fixedSize().frame(width: 20)
                }
                Spacer().fixedSize().frame(height: 50)
            }
            .background(BACKGROUND_MAIN)
            .edgesIgnoringSafeArea([.all])
            
            // Info view - only shows if showInfo is true (ie info icon is pressed)
            VStack {
                if showInfo {
                    Spacer().fixedSize().frame(height:60)
                    HStack {
                        Spacer()
                        Text(
                            """
                            The authorization stage requires you to log in. In order to \
                            view the full flow you need to have an account with the selected provider.
                            If you do not have an account you will still be able to view the \
                            discovery and registration stages.
                            """
                        )
                        .font(Font.system(.callout))
                        .multilineTextAlignment(.leading)
                        .padding()
                        .background(Color(white: 0.95))
                        .foregroundColor(.black)
                        .cornerRadius(10.0)

                        Spacer()
                    }
                    .frame(width: 300)
                    Spacer()
                }
                if showWarning {
                    Spacer().fixedSize().frame(height:60)
                    HStack {
                        Spacer()
                        Text(
                            """
                            Displays secret information normally only \
                            visible to a developer using developer tools. \
                            Authorization codes and refresh tokens have been \
                            redacted to mitigate unauthorised use.
                            """
                        )
                        .font(Font.system(.callout))
                        .multilineTextAlignment(.leading)
                        .padding()
                        .background(Color(white: 0.95))
                        .foregroundColor(.black)
                        .cornerRadius(10.0)

                        Spacer()
                    }
                    .frame(width: 300)
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
//                    .lineLimit(nil)
//                    .minimumScaleFactor(0.9)  // Avoid truncating text - scales it to fit instead
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .font(.system(size: 12, weight: .regular))
            }
            .background(Color.white)
        }
    }
    
    func fetchConfig(selectedProvider: Provider) {
        interactor.discoverConfiguration(providerPath: selectedProvider.path, presenter: presenter, authState: authState)
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
        ContentView(presenter: newPresenter.presenter, selectedProvider: Provider(pickerText: "solidcommunity.net", path: "https://solidcommunity.net"), showInfo: true)
    }
}
