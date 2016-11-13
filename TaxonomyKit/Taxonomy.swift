/*
 *  Taxonomy.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 24/09/2016.
 *  Copyright:  © 2016 Guillem Servera (http://github.com/gservera)
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

import Foundation
import AEXML

public typealias TaxonID = String


/// The base class from which all the Taxonomy related tasks are initiated. This class
/// is not meant to be instantiated but it serves as a start node to invoke the
/// TaxonomyKit functions in your code.
public final class Taxonomy {
    
    internal init() { /* We prevent this struct from being instantiated. */ }
    
    /// Used for testing purposes. Don't change this value
    internal static var _urlSession: URLSession = URLSession.shared
    
    
    /// Sends an asynchronous request to the NCBI servers asking for every taxon identifier that
    /// matches a specific query.
    ///
    /// - Since: TaxonomyKit 1.0.
    /// - Parameters:
    ///   - query:    The user-entered search query.
    ///   - callback: A callback closure that will be called when the request completes or when
    ///               an error occurs. This closure has two parameters.
    ///   - identifiers: An array of the matching taxon IDs (may be empty) or `nil` if an error occurred.
    ///   - error: The corresponding `TaxonomyError` value if an error occurred, or `nil` instead.
    ///
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func findIdentifiers(for query: String,
        callback: @escaping (_ identifiers: [TaxonID]?, _ error: TaxonomyError?) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.search(query: query)
        let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
            if error == nil {
                guard let response = response as? HTTPURLResponse, let data = data else {
                    callback(nil, .unknownError)
                    return
                }
                switch response.statusCode {
                case 200:
                    do {
                        let JSON = try JSONSerialization.jsonObject(with: data)
                        guard let casted = JSON as? [String:[String:Any]] else {
                            callback(nil, .unknownError) // Unknown JSON structure
                            return
                        }
                        if let list = casted["esearchresult"]?["idlist"] as? [String] {
                            callback(list, nil)
                        } else {
                            callback(nil, .unknownError) // Unknown JSON structure
                        }
                    } catch _ {
                        callback(nil, .parseError(message: "Could not parse JSON data"))
                    }
                default:
                    callback(nil, .unexpectedResponseError(code: response.statusCode))
                }
            } else if let rootError = error {
                callback(nil, .networkError(underlyingError: rootError))
            }
        }
        task.resume()
        return task
    }
    
    
    /// Sends an asynchronous request to the NCBI servers asking for record names spelled 
    /// similarly to an unmatched query.
    ///
    /// - Since: TaxonomyKit 1.0.
    /// - Parameters:
    ///   - failedQuery: The user-entered and unmatched search query. If the query is valid, 
    ///                  the callback will be called with a `nil` value.
    ///   - callback: A callback closure that will be called when the request completes or when
    ///               an error occurs. This closure has two parameters.
    ///   - suggestion: The first suggested candidate or `nil` if no alternative names were found 
    ///                 or if an error occurred.
    ///   - error: The corresponding `TaxonomyError` value if an error occurred.
    ///
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func findSimilarSpelledCandidates(for failedQuery: String,
        callback: @escaping (_ suggestion: String?, _ error: TaxonomyError?) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.spelling(failedQuery: failedQuery.lowercased())
        let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
            if error == nil {
                guard let response = response as? HTTPURLResponse, let data = data else {
                    callback(nil, .unknownError)
                    return
                }
                switch response.statusCode {
                case 200:
                    do {
                        let xmlDoc = try AEXMLDocument(xml: data)
                        if let suggestedQuery = xmlDoc["eSpellResult"]["CorrectedQuery"].value {
                            callback(suggestedQuery, nil)
                        } else if xmlDoc["eSpellResult"].count == 1 {
                            //Either the original query is valid or no candidates were found.
                            callback(nil, nil)
                        } else {
                            callback(nil, .unknownError)
                        }
                    } catch _ {
                        callback(nil, .parseError(message: "Could not parse XML data"))
                    }
                default:
                    callback(nil, .unexpectedResponseError(code: response.statusCode))
                }
            } else if let rootError = error {
                callback(nil, .networkError(underlyingError: rootError))
            }
        }
        task.resume()
        return task
        
    }
    
    
    /// Sends an asynchronous request to the NCBI servers asking for the taxon and lineage
    /// info for a given NCBI internal identifier.
    ///
    /// - Since: TaxonomyKit 1.0.
    /// - Parameters:
    ///   - id:       The NCBI internal identifier.
    ///   - callback: A callback closure that will be called when the request completes or when 
    ///               an error occurs. This closure has two parameters.
    ///   - taxon: The retrieved `Taxon` object or `nil` if an error occurred.
    ///   - error: The corresponding `TaxonomyError` value if an error occurred, or `nil` instead.
    ///
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func downloadTaxon(withIdentifier id: TaxonID,
        callback: @escaping (_ taxon: Taxon?, _ error: TaxonomyError?) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.download(identifier: id)
        let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
            if error == nil {
                guard let response = response as? HTTPURLResponse, let data = data else {
                    callback(nil, .unknownError)
                    return
                }
                switch response.statusCode {
                case 200:
                    do {
                        let xmlDoc = try AEXMLDocument(xml: data)
                        let taxonRoot = xmlDoc["TaxaSet"]["Taxon"]
                        guard taxonRoot.count > 0 else {
                            callback(nil, .unknownError)
                            return
                        }
                        let nameOpt = taxonRoot["ScientificName"].value
                        //TODO: Multiple common names (implode?)
                        let commonName = taxonRoot["OtherNames"]["CommonName"].value
                        let rankOpt = taxonRoot["Rank"].value
                        let mainCodeOpt = taxonRoot["GeneticCode"]["GCName"].value
                        let mitoCodeOpt = taxonRoot["MitoGeneticCode"]["MGCName"].value
                        
                        guard let name = nameOpt, let rank = rankOpt, let mainCode = mainCodeOpt, let mitoCode = mitoCodeOpt else {
                            throw TaxonomyError.parseError(message: "Could not parse XML data")
                        }
                        
                        var taxon = Taxon(identifier: id, name: name, rank: rank,
                                          geneticCode: mainCode, mitochondrialCode: mitoCode)
                        taxon.commonName = commonName
                        
                        var lineage: [TaxonLineageItem] = []
                        if let lineageItems = taxonRoot["LineageEx"]["Taxon"].all {
                            for lineageItem in lineageItems {
                                let itemIdOpt = lineageItem["TaxId"].value
                                let itemNameOpt = lineageItem["ScientificName"].value
                                let itemRankOpt = lineageItem["Rank"].value
                                
                                guard let itemId = itemIdOpt, let itemName = itemNameOpt, let itemRank = itemRankOpt else {
                                    throw TaxonomyError.parseError(message: "Could not parse XML data")
                                }
                                
                                let item = TaxonLineageItem(identifier: itemId, name: itemName, rank: itemRank)
                                lineage.append(item)
                            }
                            taxon.lineageItems = lineage
                        }
                        callback(taxon, nil)
                    } catch _ {
                        callback(nil, .parseError(message: "Could not parse XML data"))
                    }
                case 400:
                    callback(nil, .badRequest(identifier: id))
                default:
                    callback(nil, .unexpectedResponseError(code: response.statusCode))
                }
            } else if let rootError = error {
                callback(nil, .networkError(underlyingError: rootError))
            }
        }
        task.resume()
        return task
    }
    
    
    /// Sends an asynchronous request to the NBCBI servers asking for external links related
    /// to a given taxon identifier.
    ///
    /// - Since: TaxonomyKit 1.1.
    /// - Parameters:
    ///   - id: The NCBI internal identifier.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has two parameters, the first is an array
    ///               of the retrieved links or `nil` if an error occurred. In that case, the second
    ///               parameter will be set to the corresponding `TaxonomyError` value.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func findLinkedResources(for id: TaxonID,
                                                        callback: @escaping ([ExternalLink]?, TaxonomyError?) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.links(identifier: id)
        let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
            if error == nil {
                guard let response = response as? HTTPURLResponse, let data = data else {
                    callback(nil, .unknownError)
                    return
                }
                
                if response.statusCode == 200 {
                    do {
                        let xmlDoc = try AEXMLDocument(xml: data)
                        let linkRoot = xmlDoc["eLinkResult"]["LinkSet"]["IdUrlList"]["IdUrlSet"]["ObjUrl"]
                        guard linkRoot.count > 0, let linkNodes = linkRoot.all else {
                            let linkRoot = xmlDoc["eLinkResult"]["LinkSet"]["IdUrlList"]["IdUrlSet"]
                            if let zeroInfo = linkRoot["Info"].value {
                                if zeroInfo.hasPrefix("Incorrect UID") {
                                    callback(nil, .badRequest(identifier: id))
                                    return
                                }
                            }
                            callback(nil, .unknownError)
                            return
                        }
                        var links: [ExternalLink] = []
                        for linkNode in linkNodes {
                            let title = linkNode["LinkName"].value
                            let urlStringOpt = linkNode["Url"].value
                            let srcIdOpt = linkNode["Provider"]["Id"].value
                            let srcNameOpt = linkNode["Provider"]["Name"].value
                            let srcAbbrOpt = linkNode["Provider"]["NameAbbr"].value
                            let srcURLStringOpt = linkNode["Provider"]["Url"].value
                            
                            guard let urlString = urlStringOpt,
                                let srcId = srcIdOpt,
                                let srcName = srcNameOpt,
                                let srcAbbr = srcAbbrOpt,
                                let srcURLString = srcURLStringOpt else {
                                    throw TaxonomyError.parseError(message: "Could not parse XML data. Missing data.")
                            }
                            
                            guard let url = URL(string: urlString), let srcURL = URL(string: srcURLString) else {
                                throw TaxonomyError.parseError(message: "Could not parse XML data.")
                            }
                            
                            let linkProvider = ExternalLink.Provider(id: srcId, name: srcName, abbreviation: srcAbbr, url: srcURL)
                            let linkOut = ExternalLink(url: url, title: title, provider: linkProvider)
                            links.append(linkOut)
                        }
                        
                        callback(links, nil)
                    } catch _ {
                        callback(nil, .parseError(message: "Could not parse XML data"))
                    }
                } else {
                    callback(nil, .unexpectedResponseError(code: response.statusCode))
                }
            } else if let rootError = error {
                callback(nil, .networkError(underlyingError: rootError))
            }
        }
        task.resume()
        return task
    }
}
