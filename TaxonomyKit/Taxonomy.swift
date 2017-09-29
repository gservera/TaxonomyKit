/*
 *  Taxonomy.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 24/09/2016.
 *  Copyright:  © 2016-2017 Guillem Servera (https://github.com/gservera)
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

/// A numeric string representing an entrez record.
public typealias TaxonID = Int


/// The generic wrapper type returned by all TaxonomyKit newtorking methods. It 
/// represents either a success or a failure of the mentioned network request.
///
/// - Since: TaxonomyKit 1.2.
public enum TaxonomyResult<T> {
    
    /// The request succeeded returning the associated value of type `T`.
    case success(T)
    
    /// The request failed due to the associated error value.
    case failure(TaxonomyError)
}


/// The base class from which all the NCBI related tasks are initiated. This class
/// is not meant to be instantiated but it serves as a start node to invoke the
/// TaxonomyKit functions in your code.
public class Taxonomy {
    
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
    ///               an error occurs. This closure has a `TaxonomyResult<[TaxonID]>` parameter
    ///               that contains an array with the found IDs when the request succeeds.
    ///
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func findIdentifiers(for query: String,
        callback: @escaping (_ result: TaxonomyResult<[TaxonID]>) -> Void) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.search(query: query)
        let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
            
            guard let data = filter(response, data, error, callback) else { return }
            
            do {
                let JSON = try JSONSerialization.jsonObject(with: data)
                guard let casted = JSON as? [String:[String:Any]] else {
                    callback(.failure(.unknownError)) // Unknown JSON structure
                    return
                }
                if let list = casted["esearchresult"]?["idlist"] as? [String] {
                    let mapped: [TaxonID] = list.map { Int($0)! }
                    callback(.success(mapped))
                } else {
                    callback(.failure(.unknownError)) // Unknown JSON structure
                }
            } catch _ {
                callback(.failure(.parseError(message: "Could not parse JSON data")))
            }
        }
        return task.resumed()
    }
    
    
    /// Sends an asynchronous request to the NCBI servers asking for record names spelled
    /// similarly to an unmatched query.
    ///
    /// - Since: TaxonomyKit 1.0.
    /// - Parameters:
    ///   - failedQuery: The user-entered and unmatched search query. If the query is valid,
    ///                  the callback will be called with a `nil` value.
    ///   - callback: A callback closure that will be called when the request completes or when
    ///               an error occurs. This closure has a `TaxonomyResult<String?>` parameter
    ///               that contains the first suggested candidate (or nil if no suggestions were
    ///               made) when the request succeeds.
    ///
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func findSimilarSpelledCandidates(for failedQuery: String,
        callback: @escaping (_ result: TaxonomyResult<String?>) -> Void) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.spelling(failedQuery: failedQuery.lowercased())
        let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
            
            guard let data = filter(response, data, error, callback) else { return }
            
            do {
                let xmlDoc = try AEXMLDocument(xml: data)
                if let suggestedQuery = xmlDoc["eSpellResult"]["CorrectedQuery"].value {
                    callback(.success(suggestedQuery))
                } else if xmlDoc["eSpellResult"].count == 1 {
                    //Either the original query is valid or no candidates were found.
                    callback(.success(nil))
                } else {
                    callback(.failure(.unknownError))
                }
            } catch _ {
                callback(.failure(.parseError(message: "Could not parse XML data")))
            }
        }
        return task.resumed()
    }
    
    
    /// Sends an asynchronous request to the NCBI servers asking for the taxon and lineage
    /// info for a given NCBI internal identifier.
    ///
    /// - Since: TaxonomyKit 1.0.
    /// - Parameters:
    ///   - id: The NCBI internal identifier.
    ///   - callback: A callback closure that will be called when the request completes or when
    ///               an error occurs. This closure has a `TaxonomyResult<Taxon>` parameter that
    ///               contains the retrieved taxon when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func downloadTaxon(withIdentifier id: TaxonID,
        callback: @escaping (_ result: TaxonomyResult<Taxon>) -> Void) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.download(identifier: id)
        let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
            
            guard let data = filter(response, data, error, callback) else { return }
            
            do {
                let xmlDoc = try AEXMLDocument(xml: data)
                let taxonRoot = xmlDoc["TaxaSet"]["Taxon"]
                guard taxonRoot.count > 0 else {
                    callback(.failure(.unknownError))
                    return
                }
                
                let nameOpt = taxonRoot["ScientificName"].value
                let commonNames = taxonRoot["OtherNames"]["CommonName"].all ?? []
                let genbankCommonName = taxonRoot["OtherNames"]["GenbankCommonName"].value
                let synonyms = taxonRoot["OtherNames"]["Synonym"].all ?? []
                let rankOpt = taxonRoot["Rank"].value
                let mainCodeOpt = taxonRoot["GeneticCode"]["GCName"].value
                let mitoCodeOpt = taxonRoot["MitoGeneticCode"]["MGCName"].value
                
                guard let name = nameOpt, let rank = rankOpt, let mainCode = mainCodeOpt, let mitoCode = mitoCodeOpt else {
                    throw TaxonomyError.parseError(message: "Could not parse XML data")
                }
                let rankValue = TaxonomicRank(rawValue: rank)
                var taxon = Taxon(identifier: id, name: name, rank: rankValue, geneticCode: mainCode, mitochondrialCode: mitoCode)
                taxon.commonNames = commonNames.map {$0.value ?? ""}
                taxon.genbankCommonName = genbankCommonName
                taxon.synonyms = synonyms.map {$0.value ?? ""}
                
                var lineage: [TaxonLineageItem] = []
                if let lineageItems = taxonRoot["LineageEx"]["Taxon"].all {
                    for lineageItem in lineageItems {
                        let itemIdOpt = lineageItem["TaxId"].value
                        let itemNameOpt = lineageItem["ScientificName"].value
                        let itemRankOpt = lineageItem["Rank"].value
                        
                        guard let itemIdStr = itemIdOpt, let itemId = Int(itemIdStr), let itemName = itemNameOpt, let itemRank = itemRankOpt else {
                            throw TaxonomyError.parseError(message: "Could not parse XML data")
                        }
                        let itemRankValue = TaxonomicRank(rawValue: itemRank)
                        let item = TaxonLineageItem(identifier: itemId, name: itemName, rank: itemRankValue)
                        lineage.append(item)
                    }
                    taxon.lineageItems = lineage
                }
                callback(.success(taxon))
            } catch _ {
                callback(.failure(.parseError(message: "Could not parse XML data")))
            }
        }
        return task.resumed()
    }

    
    /// Sends an asynchronous request to the NCBI servers asking for external links related
    /// to a given taxon identifier.
    ///
    /// - Since: TaxonomyKit 1.1.
    /// - Parameters:
    ///   - id: The NCBI internal identifier.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<[ExternalLink]>`
    ///               parameter that contains an array with the retrieved links when the
    ///               request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func findLinkedResources(for id: TaxonID,
        callback: @escaping (TaxonomyResult<[ExternalLink]>) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.links(identifier: id)
        let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
            
            guard let data = filter(response, data, error, callback) else { return }
            
            do {
                let xmlDoc = try AEXMLDocument(xml: data)
                let linkRoot = xmlDoc["eLinkResult"]["LinkSet"]["IdUrlList"]["IdUrlSet"]["ObjUrl"]
                guard linkRoot.count > 0, let linkNodes = linkRoot.all else {
                    callback(.failure(.unknownError))
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
                    
                    guard let urlString = urlStringOpt, let srcId = srcIdOpt, let srcName = srcNameOpt,
                        let srcAbbr = srcAbbrOpt, let srcURLString = srcURLStringOpt else {
                            throw TaxonomyError.parseError(message: "Could not parse XML data. Missing data.")
                    }
                    
                    guard let url = URL(string: urlString), let srcURL = URL(string: srcURLString) else {
                        throw TaxonomyError.parseError(message: "Could not parse XML data.")
                    }
                    
                    let linkProvider = ExternalLink.Provider(id: srcId, name: srcName, abbreviation: srcAbbr, url: srcURL)
                    let linkOut = ExternalLink(url: url, title: title, provider: linkProvider)
                    links.append(linkOut)
                }
                
                callback(.success(links))
            } catch _ {
                callback(.failure(.parseError(message: "Could not parse XML data")))
            }
        }
        return task.resumed()
    }    
}


// MARK: - Internal methods

internal func filter<T>(_ response: URLResponse?, _ data: Data?, _ error: Error?,
                       _ callback: @escaping (TaxonomyResult<T>) -> Void) -> Data? {
    if let error = error as NSError? {
        if error.code != NSURLErrorCancelled {
            callback(.failure(.networkError(underlyingError: error)))
        }
        return nil
    }
    guard let response = response as? HTTPURLResponse, let data = data else {
        callback(.failure(.unknownError))
        return nil
    }
    guard response.statusCode == 200 else {
        callback(.failure(.unexpectedResponse(code: response.statusCode)))
        return nil
    }
    return data
}


internal extension URLSessionDataTask {
    /// A convenience method that simplifies resuming and returning a `URLSessionDataTask` object.
    func resumed() -> URLSessionDataTask {
        self.resume()
        return self
    }
}
