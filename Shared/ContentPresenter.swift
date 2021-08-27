//
//  ContentPresenter.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 30/07/21.
//

import Foundation
import Combine


struct RowData: Hashable {
    var header = ""
    var content = ""
}



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
    

    // Discovery stage
    // The request is an url and response is JSON data.
    func presentResponse(url: URL, jsonData: Data, flowStage: String) {
        let header = getHeader(flowStage)
        let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: [])
        let json = try! JSONSerialization.data(withJSONObject: jsonObject!, options: [.withoutEscapingSlashes, .prettyPrinted])
        let prettyPrintedString = String(data: json, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue) )!
        let newContent = "The request is to:\n\(url.absoluteString)\n\nThe response is:\n\n" + prettyPrintedString
        let newRowData = RowData(header: header, content: newContent)
        displayTitle = ""
        displayData.append(newRowData)
        print("\n\(flowStage) request is to:\n\(url.absoluteString)")
        print("\nResponse from \(flowStage):\n\(prettyPrintedString)")
    }
    
    // Request in form of URLRequest
    // Registration, token exchange and userinfo requests
    func presentRequest(urlRequest: URLRequest, flowStage: String) {
        let header = getHeader(flowStage)
        var requestPrettyPrintedString = ""
        if urlRequest.httpMethod == "POST" && urlRequest.httpBody != nil {
            // The body is JSON data
            if let jsonObject = try? JSONSerialization.jsonObject(with: urlRequest.httpBody!, options: []) {
                let jsonData = try! JSONSerialization.data(withJSONObject: jsonObject, options: [.withoutEscapingSlashes, .prettyPrinted])
                requestPrettyPrintedString = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
            }
            // The body is a string with key-value pairs separated by '&'
            else {
                requestPrettyPrintedString = String(data: urlRequest.httpBody!, encoding: .utf8)!
                    .components(separatedBy: "&")
                    .joined(separator: "&\n")
            }
        }
        let headerFieldsString = urlRequest.allHTTPHeaderFields!.map {
            "\"" + $0.0 + "\"" + ": " + "\"" + $0.1 + "\""
        }.joined(separator: ",\n")
        
        let newContent = """
            The request is to: \(urlRequest.url!.absoluteString)
            http method: \(urlRequest.httpMethod!)
            http headers: [\n\(headerFieldsString)\n]
            http body: \n\(requestPrettyPrintedString)
            
            """
        let newRowData = RowData(header: header, content: newContent)
        displayData.append(newRowData)
    }
    
    // Request is an url containing a query
    // Authorization request
    func presentRequest(url: URL, flowStage: String) {
        let header = getHeader(flowStage)
        let queryString = getQueryString(url)
        let newContent = "The request is to:\n\(url.absoluteString)\n\nSummary - the request's query components:\n\n\(queryString)\n"
        let newRowData = RowData(header: header, content: newContent)
        displayData.append(newRowData)
        print("\n\(flowStage) \(newContent)")
    }
    
    // Registration, token exchange and userinfo responses
    func presentResponse(jsonData: Data) {
        let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: [])
        let json = try! JSONSerialization.data(withJSONObject: jsonObject!, options: [.withoutEscapingSlashes, .prettyPrinted])
        let responsePrettyPrintedString = String(data: json, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        let responseString = "\nThe response is:\n\n \(responsePrettyPrintedString)"

        let lastRowData = displayData.removeLast()
        let lastContent = lastRowData.content
        let updatedContent = lastContent.appending(responseString)
        let newRowData = RowData(header: lastRowData.header, content: updatedContent)
        displayData.append(newRowData)
        displayTitle = ""
    }
    
    // Authorization response
    func presentResponse(url: URL) {
        let responseQueryString = getQueryString(url)
        let responseString = "\nThe response is:\n\(url.absoluteString) \n\nSummary - response components: \n\n\(responseQueryString)"
        
        let lastRowData = displayData.removeLast()
        let lastContent = lastRowData.content
        let updatedContent = lastContent.appending(responseString)
        let newRowData = RowData(header: lastRowData.header, content: updatedContent)
        displayData.append(newRowData)
        displayTitle = ""
    }
    
    func presentError(error: Error) {
        let lastRowData = displayData.removeLast()
        let lastContent = lastRowData.content
        let updatedContent = lastContent.appending("""
            
            ERROR: \(error.localizedDescription)
            
            """
        )
        let newRowData = RowData(header: lastRowData.header, content: updatedContent)
        displayData.append(newRowData)
    }
    
    
    // Helpers
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
        case "Userinfo":
            header = kUserInfoHeader
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
            let suff = item == queryItems!.last ? "" : "&\n"
            str = str + item.name + "=" + item.value! + suff
        })
        
        return str
    }
}
