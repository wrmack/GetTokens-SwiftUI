//
//  ContentPresenter.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 30/07/21.
//

import Foundation
import Combine

/// `ContentPresenter` is responsible for formatting data it receives from `ContentInteractor`
/// so that it is ready for presentation by `ContentView`.
///
/// This pattern is based on the VIP (View-Interactor-Presenter).
/// - `ContentView` is the main app UI view. It works with `ContentInteractor` and `ContentPresenter`.
///
/// - `ContentInteractor` is responsible for interacting with the data model and the network.
///
/// - `ContentPresenter` is responsible for formatting data it receives from `ContentInteractor`
/// so that it is ready for presentation by `ContentView`. It is initialised in `ContentView` as a `@StateObject`
/// to ensure there is only one instance and it notifies new content through a publisher.
///
class ContentPresenter: ObservableObject {
    
    @Published var displayTitle = ""
    @Published var displayData = [RowData]()
    
    func presentTitle(title: String) {
        displayTitle = title
    }
    
    // The request is just an url and response is data.
    // Discovery stage
    func presentResponse(data: Data, url: URL, flowStage: String) {
        let header = getHeader(flowStage)
        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [])
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonObject!, options: [.withoutEscapingSlashes, .prettyPrinted])
        let prettyPrintedString = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue) )!
        let newContent = "The request is to:\n\(url.absoluteString)\n\nThe response is:\n\n" + prettyPrintedString
        let newRowData = RowData(header: header, content: newContent)
        displayTitle = ""
        displayData.append(newRowData)
        print("\n\(flowStage) request is to:\n\(url.absoluteString)")
        print("\nResponse from \(flowStage):\n\(prettyPrintedString)")
    }
    
    // Request is an URLRequest.
    func presentResponse(data: Data, urlRequest: URLRequest, flowStage: String) {
        let header = getHeader(flowStage)
        var requestPrettyPrintedString = ""
        if urlRequest.httpMethod == "POST" && urlRequest.httpBody != nil {
            if let jsonObject = try? JSONSerialization.jsonObject(with: urlRequest.httpBody!, options: []) {
                let jsonData = try! JSONSerialization.data(withJSONObject: jsonObject, options: [.withoutEscapingSlashes, .prettyPrinted])
                requestPrettyPrintedString = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
            }
        }
        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [])
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonObject!, options: [.withoutEscapingSlashes, .prettyPrinted])
        let responsePrettyPrintedString = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        let newContent = """
            The request is to: \(urlRequest.url!.absoluteString)
            http method: \(urlRequest.httpMethod!)
            http headers: \(urlRequest.allHTTPHeaderFields!)
            http body: \n\(requestPrettyPrintedString)
            
            The response is:\n\n \(responsePrettyPrintedString)
            """
        let newRowData = RowData(header: header, content: newContent)
        displayTitle = ""
        displayData.append(newRowData)
        print("\n\(flowStage) request is to:\n\(urlRequest.url!.absoluteString)")
        print("\nResponse from \(flowStage):\n\(responsePrettyPrintedString)")
    }
    
    // Request is an url and response is an url
    func presentResponse(dataURL: URL, url: URL, flowStage: String) {
        let header = getHeader(flowStage)
        let queryString = getQueryString(url)
        let responseString = getQueryString(dataURL)
        let newContent = "The request is to:\n\(url.absoluteString)\n\nSummary - the request's query components:\n\n\(queryString)\nThe response is:\n\(dataURL.absoluteString) \n\nSummary - response components: \n\n\(responseString)"
        let newRowData = RowData(header: header, content: newContent)
        displayTitle = ""
        displayData.append(newRowData)
        print("\n\(flowStage) \(newContent)")
    }
    
    // Helper
    func getHeader(_ flowStage: String) -> String {
        var header = ""
        switch flowStage {
        case "Discovery":
            header = kDiscoveryHeader
        case "Registration":
            header = kRegistrationHeader
        case "Authorization":
            header = kAuthorizationHeader
        case "Tokens":
            header = kTokenHeader
        default:
            header = ""
        }
        return header
    }
    
    func getQueryString(_ url: URL) -> String {
        
        var str = ""
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems
        queryItems!.forEach({item in
            str = str + item.name + ": " + item.value! + "\n"
        })
        
        return str
    }
}
