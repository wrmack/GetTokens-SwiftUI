//
//  QueryUtilities.swift
//  GetTokens-SwiftUI
//
//  Created by Warwick McNaughton on 31/07/21.
//

import Foundation


private let kQueryStringParamAdditionalDisallowedCharacters = "=&+"



class QueryUtilities: NSObject {
    
    ///  A dictionary of parameter names and values representing the contents of the query.
    var parameters: [String : [String]] = [:]
    
    ///  The parameter names in the query.
    private(set) var parameterNames: [String] = []
    
    ///  The parameters represented as a dictionary.
    ///
    /// All values are `NSString` except for parameters which contain multiple values, in
    /// which case the value is an `NSArray<NSString *>` .
    var dictionaryValue: [String : (NSObject & NSCopying)] = [:]
    
    
    convenience init(url URL: URL) {
        self.init()
        
        // If NSURLQueryItem is available, use it for deconstructing the new URL. (iOS 8+)
        
        var components = URLComponents(url: URL, resolvingAgainstBaseURL: false)
        
        // As OAuth uses application/x-www-form-urlencoded encoding, interprets '+' as a space
        // in addition to regular percent decoding. https://url.spec.whatwg.org/#urlencoded-parsing
        let tmpComp = components?.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%20")
        components?.percentEncodedQuery = tmpComp
        
        // NB. queryItems are already percent decoded
        let queryItems = components?.queryItems
        for queryItem in queryItems!  {
            addParameter(queryItem.name, value: queryItem.value)
        }
    }
    
    func parameterKeys() -> [String]? {
        return Array(parameters.keys)
    }
    
    func getDictionaryValue() -> [String : NSObject & NSCopying] {
        // This method will flatten arrays in our _parameters' values if only one value exists.
        var values: [String : (NSObject & NSCopying)] = [:]
        for parameter in parameters.keys {
            let value = parameters[parameter]!
            if value.count == 1 {
                values[parameter] = value.first as (NSObject & NSCopying)?
            } else {
                values[parameter] = value as (NSObject & NSCopying)
            }
        }
        return values
    }
    
    
    func values(forParameter parameter: String?) -> [String]? {
        return parameters[parameter!]
    }
    
    
    func addParameter(_ parameter: String?, value: String?) {
        var parameterValues = parameters[parameter!]
        if parameterValues == nil {
            parameterValues = [String]()
            parameters[parameter!] = parameterValues
        }
        parameterValues?.append(value!)
        parameters[parameter!] = parameterValues
    }
    
    
    /// Builds a query items array that can be set to @c NSURLComponents.queryItems
    ///
    /// The parameter names and values are NOT URL encoded.
    /// - returns:  An array of unencoded `NSURLQueryItem` objects.
    func queryItems()->[URLQueryItem] {
        var queryParameters = [URLQueryItem]()
        for parameterName in parameters.keys {
            let values = parameters[parameterName]
            for value in values! {
                let item = URLQueryItem(name: parameterName, value: value)
                queryParameters.append(item)
            }
        }
        return queryParameters
    }
    
    class func urlParamValueAllowedCharacters() -> CharacterSet? {
        // Starts with the standard URL-allowed character set.
        var allowedParamCharacters = CharacterSet.urlQueryAllowed
        // Removes additional characters we don't want to see in the query component.
        allowedParamCharacters.remove(charactersIn: kQueryStringParamAdditionalDisallowedCharacters)
        return allowedParamCharacters
    }
    
    
    /// Builds a query string that can be set to @c NSURLComponents.percentEncodedQuery
    ///
    /// This string is percent encoded, and shouldn't be used with `NSURLComponents.query`.
    /// - returns: A percentage encoded query string.
    func percentEncodedQueryString() -> String {
        var parameterizedValues: [String] = []
        // Starts with the standard URL-allowed character set.
        let allowedParamCharacters: CharacterSet? = QueryUtilities.urlParamValueAllowedCharacters()
        for parameterName: String? in parameters.keys {
            var encodedParameterName: String? = nil
            if let aCharacters = allowedParamCharacters {
                encodedParameterName = parameterName?.addingPercentEncoding(withAllowedCharacters: aCharacters)
            }
            let values = parameters[parameterName!]
            for value: String in values! {
                var encodedValue: String? = nil
                if let aCharacters = allowedParamCharacters {
                    encodedValue = value.addingPercentEncoding(withAllowedCharacters: aCharacters)
                }
                let parameterizedValue = "\(encodedParameterName ?? "")=\(encodedValue ?? "")"
                parameterizedValues.append(parameterizedValue)
            }
        }
        let queryString = parameterizedValues.joined(separator: "&")
        return queryString
    }
    
    
    func urlEncodedParameters() -> String {
        var components = URLComponents()
        components.queryItems = queryItems()
        var encodedQuery = components.percentEncodedQuery
        // NSURLComponents.percentEncodedQuery creates a validly escaped URL query component, but
        // doesn't encode the '+' leading to potential ambiguity with application/x-www-form-urlencoded
        // encoding. Percent encodes '+' to avoid this ambiguity.
        encodedQuery = encodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return encodedQuery!
    }
    
    
    func urlByReplacingQuery(in URL: URL?) -> URL? {
        var components: URLComponents? = nil
        if let anURL = URL {
            components = URLComponents(url: anURL, resolvingAgainstBaseURL: false)
        }
        // Replaces encodedQuery component
        let queryString = urlEncodedParameters()
        components?.percentEncodedQuery = queryString
        let URLWithParameters: URL? = components?.url
        return URLWithParameters
    }
    
    
    
    func description() -> String? {
        return String(format: "<%@: %p, parameters: %@>", NSStringFromClass(type(of: self).self), self, parameters)
    }
}

