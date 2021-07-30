//
//  ContentInteractor.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 30/07/21.
//

import Foundation
import Combine

struct Config: Codable {
    var issuer: String
    var jwks_uri: String
}

class ContentInteractor {
    private var cancellable: AnyCancellable?
    
    func fetchConfiguration(providerPath: String, presenter: ContentPresenter) {
        
        // Create URL from input string
        guard let providerURL = URL(string: providerPath) else {
            print("Error creating URL for : \(providerPath)")
            return
        }
        let discoveryURL = providerURL.appendingPathComponent(".well-known/openid-configuration")
        
        // Create url session publisher
        // It returns a tuple comprising data, response
        // tryMap() checks the response for correct status code and returns the data
        // sink() receives only the data
        cancellable = URLSession.shared
            .dataTaskPublisher(for: discoveryURL)
            .receive(on: DispatchQueue.main)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }
                return element.data
                }
//            .decode(type: Config.self, decoder: JSONDecoder())
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        print("Success")
                    }
                },
                receiveValue: { [self] data in
                    print("Value: \(data)")
                    updateConfigModel(data: data)
                    presenter.presentData(data: data)
                }
            )
        

    }
 
    func updateConfigModel(data: Data) {
        do {
            let config = try JSONDecoder().decode(Config.self, from: data)
            print("Config: \(config)")
        }catch {
            print("Error")
        }
    }
}
        
        
        
//
//
//        guard let providerURL = URL(string: providerPath) else {
//            print("Error creating URL for : \(providerPath)")
//            return
//        }
//        let discoveryURL = providerURL.appendingPathComponent(".well-known/openid-configuration")
//
//        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
//        session.dataTask(with: discoveryURL, completionHandler: {data, response, error in
//
//            // Check for error
//            var error = error as NSError?
//            if error != nil || data == nil {
//                let errorDescription = "Connection error fetching discovery document \(discoveryURL): \(String(describing: error?.localizedDescription))."
//                error = ErrorUtilities.error(code: ErrorCode.NetworkError, underlyingError: error! as NSError, description: errorDescription)
//                DispatchQueue.main.async {
//                    print("Error retrieving discovery document: \(error!.localizedDescription)")
//                    print(error!)
//                }
//                return
//            }
//            // Check for correct status code
//            let urlResponse = response as! HTTPURLResponse
//            if (urlResponse.statusCode != 200) {
//                let URLResponseError = ErrorUtilities.HTTPError(HTTPResponse: urlResponse, data: data)
//                let errorDescription = "Non-200 HTTP response \(urlResponse.statusCode) fetching discovery document \(discoveryURL)."
//                let err = ErrorUtilities.error(code: ErrorCode.NetworkError, underlyingError: URLResponseError, description: errorDescription)
//                DispatchQueue.main.async {
//                    print("Error retrieving discovery document: \(err.localizedDescription)")
//                }
//                return
//            }

//            
//            let configuration = ProviderConfiguration(JSONData: data!, error: error)
//            if error != nil {
//                let errorDescription = "JSON error parsing document at \(discoveryURL): \(String(describing: error?.localizedDescription))"
//                error = ErrorUtilities.error(code: ErrorCode.NetworkError, underlyingError: error, description: errorDescription)
//                DispatchQueue.main.async {
//                    print("Error retrieving discovery document: \(error!.localizedDescription)")
//                }
//                return
//            }
            
//            DispatchQueue.main.async {
//                callback(configuration)
//                session.invalidateAndCancel()
//            }
//        }).resume()
//    }
    
//    func writeToTextView(status: String?, message: Any?) {
//        var userInfo = [String : Any]()
//        if status != nil {
//            userInfo["status"] = status
//        }
//        if message != nil {
//            userInfo["message"] = message
//        }
//
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MessageNotification"), object: nil, userInfo: userInfo as [AnyHashable : Any])
//    }
//}
