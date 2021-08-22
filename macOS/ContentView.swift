//
//  ContentView.swift
//  GetTokens-SwiftUI (macOS)
//
//  Created by Warwick McNaughton on 7/08/21.
//
import SwiftUI



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
    var solidCommunity = Solidcommunity_net()
    var inruptCom = Inrupt_com()
    var inruptNet = Inrupt_net()
    var solidwebOrg = Solidweb_org()
    var trinPodUs = Trinpod_us()
    var interactor = ContentInteractor()

    @EnvironmentObject var authState: AuthState
    @StateObject var presenter = ContentPresenter()
    @State var selectedProvider: Provider
    @State var selectedProviderStr = ""
    @State var showInfo = false
    
    
    var body: some View {
        
        // For debugging
//        Print("ContentView body called")
        ZStack {
            VStack(alignment: .center) {
                Spacer().fixedSize().frame(height: 30)

                // Select provider
                HStack {
                    Image("gt-icon")
                        .resizable()
                        .antialiased(true)
                        .frame(width:50,height:50)
                        .padding(.all, 20)

                    Spacer()
                    Picker("Select your provider", selection: $selectedProvider) {
                        Text(solidCommunity.pickerText).tag(Provider.solidcommunity_net)
                        Text(inruptCom.pickerText).tag(Provider.inrupt_com)
                        Text(inruptNet.pickerText).tag(Provider.inrupt_net)
                        Text(solidwebOrg.pickerText).tag(Provider.solidweb_org)
                        Text(trinPodUs.pickerText).tag(Provider.trinpod_us)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedProvider, perform: { value in
                        fetchConfig(selectedProvider: value)
                    })
                    .frame(width: 400, alignment: .center)
                    
                    Image(systemName: "info.circle")
                        .onTapGesture {
                            showInfo = showInfo ? false : true
                        }
                    Spacer()
                }

                Spacer().fixedSize().frame(height: 30)
                
                // The Copy button
                HStack {
                    Spacer()
                    Button(action: {
                        let pasteBoard = NSPasteboard.general
                        pasteBoard.clearContents()
                        var stringObj = NSString()
                        presenter.displayData.forEach({ rowdata in
                            stringObj = stringObj.appending(rowdata.header + "\n" + rowdata.content + "\n") as NSString
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
                    VStack{
                        Text(presenter.displayTitle)
                            .font(.system(size: 16))
                        ScrollView {
                          ForEach(presenter.displayData, id: \.self) { content in
                             DisplayRowContent(rowContent: content)
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
            
            // Info view - only shows if showInfo is true (info icon is pressed)
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
        case Provider.solidweb_org :
            providerPath = solidwebOrg.path
        case Provider.trinpod_us :
            providerPath = trinPodUs.path
        default:
            providerPath = solidCommunity.path
        }
        selectedProviderStr = providerPath
        interactor.discoverConfiguration(providerPath: providerPath, presenter: presenter, authState: authState)
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
        ContentView(presenter: newPresenter.presenter, selectedProvider: Provider.solidcommunity_net, showInfo: true)
    }
}
