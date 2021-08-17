//
//  ContentPresenter.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 30/07/21.
//

import Foundation
import Combine


class ContentPresenter: ObservableObject {
    
    @Published var displayTitle = ""
    @Published var displayData = [RowData]()
    
    func presentTitle(title: String) {
        displayTitle = title
    }
    
    func presentData(data: Data, requestUrl: URL, flowStage: String) {
        var header = ""
        switch flowStage {
        case "discovery":
            header = kDiscoveryHeader
        case "registration":
            header = kRegistrationHeader
        case "authorization":
            header = kAuthorizationHeader
        case "tokens":
            header = kTokenHeader
        case "userinfo":
            header = kUserInfoHeader 
        default:
            header = ""
        }
        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [])
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonObject!, options: [.withoutEscapingSlashes, .prettyPrinted])
        let prettyPrintedString = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue) )!
        let newContent = "The request is to:\n\(requestUrl.absoluteString)\n\nThe response is:\n\n" + prettyPrintedString
        let newRowData = RowData(header: header, content: newContent)
        displayData.append(newRowData)
        print("\n\(flowStage) request is to:\n\(requestUrl.absoluteString)")
        print("\nResponse from \(flowStage):\n\(prettyPrintedString)")
    }
    
    func presentDataFromURL(dataURL: URL, requestUrl: URL, flowStage: String) {
        var header = ""
        switch flowStage {
        case "discovery":
            header = kDiscoveryHeader
        case "registration":
            header = kRegistrationHeader
        case "authorization":
            header = kAuthorizationHeader
        case "tokens":
            header = kTokenHeader
        default:
            header = ""
        }
        var str = ""
        let components = URLComponents(url: dataURL, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems
        queryItems!.forEach({item in
            str = str + item.name + ": " + item.value! + "\n"
        })
        let newContent = "The request is to:\n\(requestUrl.absoluteString)\n\nThe response is:\n\n"  + str
        let newRowData = RowData(header: header, content: newContent)
        displayData.append(newRowData)
        print("\n\(flowStage) request is to:\n\(requestUrl.absoluteString)")
        print("\nResponse from \(flowStage):\n\(str)")
    }
}
