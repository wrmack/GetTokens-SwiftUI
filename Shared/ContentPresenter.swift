//
//  ContentPresenter.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 30/07/21.
//

import Foundation
import Combine


class ContentPresenter: ObservableObject {
    
    @Published var displayData = "" 
    
    func presentData(data: Data, url: URL) {
        
        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [])
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonObject!, options: .prettyPrinted)
        let prettyPrintedString = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue) )!
        let path = url.absoluteString
        displayData = "Response from:\n\(path)\n=================================================\n\n" + prettyPrintedString
        print("ContentPresenter displayData changed: \(prettyPrintedString)")
        
//        let configuration = ConfigurationUtilities(JSONData: data!, error: error)
//        if error != nil {
//            let errorDescription = "JSON error parsing document at \(discoveryURL): \(String(describing: error?.localizedDescription))"
//            error = ErrorUtilities.error(code: ErrorCode.NetworkError, underlyingError: error, description: errorDescription)
//            DispatchQueue.main.async {
//                print("Error retrieving discovery document: \(error!.localizedDescription)")
//            }
//            return
//        }
//        print("Configuration: \(configuration)")
    }
}
