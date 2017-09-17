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


/// The base class from which all the Taxonomy related tasks are initiated. This class
/// is not meant to be instantiated but it serves as a start node to invoke the
/// TaxonomyKit functions in your code.
public struct Taxonomy {
    
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
        callback: @escaping (_ result: TaxonomyResult<[TaxonID]>) -> ()) -> URLSessionDataTask {
        
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
    ///               an error occurs. This closure has a `TaxonomyResult<String?>` parameter
    ///               that contains the first suggested candidate (or nil if no suggestions were
    ///               made) when the request succeeds.
    ///
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func findSimilarSpelledCandidates(for failedQuery: String,
                                                                       callback: @escaping (_ result: TaxonomyResult<String?>) -> ()) -> URLSessionDataTask {
        
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
        task.resume()
        return task
        
    }
    
    
    /// Attempts to guess scientific names that could match a specific query using info from
    /// the corresponding Wikipedia article.
    ///
    /// - Since: TaxonomyKit 1.5.
    /// - Parameters:
    ///   - query: The query for which to retrieve Wikipedia metadata.
    ///   - language: The language that should be used to search Wikipedia.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<[String]>`
    ///               parameter that contains a wrapper with the found names (or `[]` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func findPossibleScientificNames(matching query: String,
                                                                      language: WikipediaLanguage = WikipediaLanguage(),
                                                                      callback: @escaping (_ result: TaxonomyResult<[String]>) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.scientificNameGuess(query: query, language: language)
        let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
            
            guard let data = filter(response, data, error, callback) else { return }
            
            do {
                let JSON = try JSONSerialization.jsonObject(with: data)
                guard let casted = JSON as? [String:Any] else {
                    callback(.failure(.unknownError)) // Unknown JSON structure
                    return
                }
                if let pages = ((casted["query"] as? [String:Any])?["pages"] as? [String:[String:Any]]) {
                    if let (firstID, firstDict) = pages.first {
                        if firstID == "-1" || firstDict["extract"] == nil {
                            callback(.success([]))
                        } else {
                            let title = firstDict["title"] as! String
                            var names: [String] = []
                            if title != query && title.components(separatedBy: " ").count > 1 {
                                names.append(firstDict["title"] as! String)
                            }
                            let extract = firstDict["extract"] as! NSString
                            let firstOpeningParenthesis = extract.range(of: "(").location
                            if firstOpeningParenthesis != NSNotFound {
                                let stopChars: CharacterSet = CharacterSet(charactersIn: ".,()[]{}\n")
                                let closingParenthesis = extract.rangeOfCharacter(from: stopChars, options: [], range: NSMakeRange(firstOpeningParenthesis+1, extract.length-firstOpeningParenthesis-1)).location
                                if closingParenthesis != NSNotFound {
                                    let substring = extract.substring(with: NSMakeRange(firstOpeningParenthesis+1, closingParenthesis-firstOpeningParenthesis-1)).trimmingCharacters(in: CharacterSet.whitespaces)
                                    if substring.components(separatedBy: " ").count < 4 && !names.contains(substring) {
                                        names.append(substring)
                                    }
                                }
                            }
                            callback(.success(names))
                        }
                    } else {
                        callback(.failure(.unknownError)) // Unknown JSON structure
                    }
                } else {
                    callback(.failure(.unknownError)) // Unknown JSON structure
                }
            } catch _ {
                callback(.failure(.parseError(message: "Could not parse JSON data")))
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
    ///   - taxon: The taxon for which to retrieve Wikipedia metadata.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<WikipediaResult?>`
    ///               parameter that contains a wrapper with the requested metadata (or `nil` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public static func downloadTaxon(withIdentifier id: TaxonID,
        callback: @escaping (_ result: TaxonomyResult<Taxon>) -> ()) -> URLSessionDataTask {
        
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
                var taxon = Taxon(identifier: id, name: name, rank: rankValue,
                                  geneticCode: mainCode, mitochondrialCode: mitoCode)
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
        task.resume()
        return task
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
                
                callback(.success(links))
            } catch _ {
                callback(.failure(.parseError(message: "Could not parse XML data")))
            }
        }
        task.resume()
        return task
    }
    
    public struct Wikipedia {
        private init() {}
        
        /// Sends an asynchronous request to Wikipedia servers asking for metadata such as an extract
        /// and the Wikipedia page URL for a concrete a taxon.
        ///
        /// - Since: TaxonomyKit 1.3.
        /// - Parameters:
        ///   - taxon: The taxon for which to retrieve Wikipedia metadata.
        ///   - language: The language that should be used to search Wikipedia.
        ///   - callback: A callback closure that will be called when the request completes or
        ///               if an error occurs. This closure has a `TaxonomyResult<WikipediaResult?>`
        ///               parameter that contains a wrapper with the requested metadata (or `nil` if
        ///               no results are found) when the request succeeds.
        /// - Warning: Please note that the callback may not be called on the main thread.
        /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
        ///            may keep a reference to this object if you plan it should be canceled at some
        ///            point.
        @discardableResult public static func retrieveAbstract(for taxon: Taxon,
                                                               language: WikipediaLanguage = WikipediaLanguage(),
                                                               useRichText: Bool = false,
                                                               callback: @escaping (TaxonomyResult<WikipediaResult?>) -> ()) -> URLSessionDataTask {
            
            let request = TaxonomyRequest.wikipediaAbstract(query: taxon.name, richText: useRichText, language: language)
            return retrieveAbstract(with: request, language: language, callback: callback)
        }
        
        
        /// Sends an asynchronous request to Wikipedia servers asking for metadata such as an extract
        /// and the Wikipedia page URL for a concrete a taxon.
        ///
        /// - Since: TaxonomyKit 1.5.
        /// - Parameters:
        ///   - taxon: The taxon for which to retrieve Wikipedia metadata.
        ///   - language: The language that should be used to search Wikipedia.
        ///   - callback: A callback closure that will be called when the request completes or
        ///               if an error occurs. This closure has a `TaxonomyResult<WikipediaResult?>`
        ///               parameter that contains a wrapper with the requested metadata (or `nil` if
        ///               no results are found) when the request succeeds.
        /// - Warning: Please note that the callback may not be called on the main thread.
        /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
        ///            may keep a reference to this object if you plan it should be canceled at some
        ///            point.
        @discardableResult public static func retrieveAbstract(for id: String,
                                                               language: WikipediaLanguage = WikipediaLanguage(),
                                                               useRichText: Bool = false,
                                                               callback: @escaping (TaxonomyResult<WikipediaResult?>) -> ()) -> URLSessionDataTask {
            
            let request = TaxonomyRequest.knownWikipediaAbstract(id: id, richText: useRichText, language: language)
            return retrieveAbstract(with: request, language: language, callback: callback)
        }
        
        private static func retrieveAbstract(with request: TaxonomyRequest,
                                             language: WikipediaLanguage = WikipediaLanguage(),
                                             callback: @escaping (TaxonomyResult<WikipediaResult?>) -> ()) -> URLSessionDataTask {
            let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
                
                guard let data = filter(response, data, error, callback) else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let wikipediaResponse = try decoder.decode(WikipediaResponse.self, from: data)
                    if let page = wikipediaResponse.query.pages.values.first {
                        guard !page.isMissing, let id = page.id, let extract = page.extract else {
                            callback(.success(nil))
                            return
                        }
                        let wikiResult = WikipediaResult(language: language, identifier: id, extract: extract, title: page.title)
                        callback(.success(wikiResult))
                    } else {
                        callback(.failure(.unknownError)) // Unknown JSON structure
                    }
                } catch _ {
                    callback(.failure(.parseError(message: "Could not parse JSON data")))
                }
            }
            task.resume()
            return task
        }
        
        
        /// Sends an asynchronous request to Wikipedia servers asking for the Wikipedia page
        /// thumbnail for a concrete wikipedia page.
        ///
        /// - Since: TaxonomyKit 1.4.
        /// - Parameters:
        ///   - taxon: The taxon for which to retrieve Wikipedia thumbnail.
        ///   - width: The max width in pixels of the image that the Wikipedia API should return.
        ///   - language: The language that should be used to search Wikipedia.
        ///   - callback: A callback closure that will be called when the request completes or
        ///               if an error occurs. This closure has a `TaxonomyResult<Data?>`
        ///               parameter that contains a wrapper with the requested image data (or `nil` if
        ///               no results are found) when the request succeeds.
        /// - Warning: Please note that the callback may not be called on the main thread.
        /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
        ///            may keep a reference to this object if you plan it should be canceled at some
        ///            point.
        @discardableResult public static func retrieveThumbnail(for id: String,
                                                                width: Int,
                                                                language: WikipediaLanguage = WikipediaLanguage(),
                                                                callback: @escaping (TaxonomyResult<Data?>) -> ()) -> URLSessionDataTask {
            
            let request = TaxonomyRequest.knownWikipediaThumbnail(id: id, width: width, language: language)
            return retrieveThumbnail(with: request, language: language, callback: callback)
        }
        
        
        /// Sends an asynchronous request to Wikipedia servers asking for the Wikipedia page
        /// thumbnail for a concrete a taxon.
        ///
        /// - Since: TaxonomyKit 1.4.
        /// - Parameters:
        ///   - taxon: The taxon for which to retrieve Wikipedia thumbnail.
        ///   - width: The max width in pixels of the image that the Wikipedia API should return.
        ///   - language: The language that should be used to search Wikipedia.
        ///   - callback: A callback closure that will be called when the request completes or
        ///               if an error occurs. This closure has a `TaxonomyResult<Data?>`
        ///               parameter that contains a wrapper with the requested image data (or `nil` if
        ///               no results are found) when the request succeeds.
        /// - Warning: Please note that the callback may not be called on the main thread.
        /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
        ///            may keep a reference to this object if you plan it should be canceled at some
        ///            point.
        @discardableResult public static func retrieveThumbnail(for taxon: Taxon,
                                                                width: Int,
                                                                language: WikipediaLanguage = WikipediaLanguage(),
                                                                callback: @escaping (TaxonomyResult<Data?>) -> ()) -> URLSessionDataTask {
            
            let request = TaxonomyRequest.wikipediaThumbnail(query: taxon.name, width: width, language: language)
            return retrieveThumbnail(with: request, language: language, callback: callback)
        }
        
        
        private static func retrieveThumbnail(with request: TaxonomyRequest,
                                              language: WikipediaLanguage = WikipediaLanguage(),
                                              callback: @escaping (TaxonomyResult<Data?>) -> ()) -> URLSessionDataTask {
            let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
                
                guard let data = filter(response, data, error, callback) else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let wikipediaResponse = try decoder.decode(WikipediaResponse.self, from: data)
                    if let page = wikipediaResponse.query.pages.values.first {
                        guard !page.isMissing, let thumbnail = page.thumbnail else {
                            callback(.success(nil))
                            return
                        }
                        var downloadedImage: Data?
                        let semaphore = DispatchSemaphore(value: 0)
                        let dlSession = URLSession(configuration: .default)
                        let dlTask = dlSession.dataTask(with: thumbnail.source) { (dlData, dlResponse, dlError) in
                            if (dlResponse as! HTTPURLResponse).statusCode == 200 && dlError == nil {
                                downloadedImage = dlData
                            }
                            semaphore.signal()
                        }
                        dlTask.resume()
                        _ = semaphore.wait(timeout: .distantFuture)
                        
                        if let data = downloadedImage {
                            callback(.success(data))
                        } else {
                            callback(.failure(.unknownError)) // Could not download image
                        }
                    } else {
                        callback(.failure(.unknownError)) // Unknown JSON structure
                    }
                } catch let error {
                    callback(.failure(.parseError(message: "Could not parse JSON data. Error: \(error)")))
                }
            }
            task.resume()
            return task
        }
        
        /// Sends an asynchronous request to Wikipedia servers asking for the Wikipedia page
        /// thumbnail for a concrete wikipedia page.
        ///
        /// - Since: TaxonomyKit 1.5.
        /// - Parameters:
        ///   - taxon: The taxon for which to retrieve Wikipedia thumbnail.
        ///   - width: The max width in pixels of the image that the Wikipedia API should return.
        ///   - language: The language that should be used to search Wikipedia.
        ///   - callback: A callback closure that will be called when the request completes or
        ///               if an error occurs. This closure has a `TaxonomyResult<Data?>`
        ///               parameter that contains a wrapper with the requested image data (or `nil` if
        ///               no results are found) when the request succeeds.
        /// - Warning: Please note that the callback may not be called on the main thread.
        /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
        ///            may keep a reference to this object if you plan it should be canceled at some
        ///            point.
        @discardableResult public static func retrieveFullRecord(for id: String,
                                                                 width: Int,
                                                                 inlineImage: Bool = false,
                                                                 language: WikipediaLanguage = WikipediaLanguage(),
                                                                 useRichText: Bool = false,
                                                                 callback: @escaping (TaxonomyResult<WikipediaResult?>) -> ()) -> URLSessionDataTask {
            
            let request = TaxonomyRequest.knownWikipediaFullRecord(id: id, richText: useRichText, thumbnailWidth: width, language: language)
            return retrieveFullRecord(with: request, inlineImage: inlineImage, language: language, useRichText: useRichText, callback: callback)
        }
        
        
        /// Sends an asynchronous request to Wikipedia servers asking for the Wikipedia page
        /// thumbnail for a concrete a taxon.
        ///
        /// - Since: TaxonomyKit 1.5.
        /// - Parameters:
        ///   - taxon: The taxon for which to retrieve Wikipedia thumbnail.
        ///   - width: The max width in pixels of the image that the Wikipedia API should return.
        ///   - language: The language that should be used to search Wikipedia.
        ///   - callback: A callback closure that will be called when the request completes or
        ///               if an error occurs. This closure has a `TaxonomyResult<Data?>`
        ///               parameter that contains a wrapper with the requested image data (or `nil` if
        ///               no results are found) when the request succeeds.
        /// - Warning: Please note that the callback may not be called on the main thread.
        /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
        ///            may keep a reference to this object if you plan it should be canceled at some
        ///            point.
        @discardableResult public static func retrieveFullRecord(for taxon: Taxon,
                                                                 width: Int,
                                                                 inlineImage: Bool = false,
                                                                 language: WikipediaLanguage = WikipediaLanguage(),
                                                                 useRichText: Bool = false,
                                                                 callback: @escaping (TaxonomyResult<WikipediaResult?>) -> Void) -> URLSessionDataTask {
            
            let request = TaxonomyRequest.wikipediaFullRecord(query: taxon.name, richText: useRichText, thumbnailWidth: width, language: language)
            return retrieveFullRecord(with: request, inlineImage: inlineImage, language: language, useRichText: useRichText, callback: callback)
        }
        
        private static func retrieveFullRecord(with request: TaxonomyRequest,
                                               inlineImage: Bool = false,
                                               language: WikipediaLanguage = WikipediaLanguage(),
                                               useRichText: Bool = false,
                                               callback: @escaping (TaxonomyResult<WikipediaResult?>) -> ()) -> URLSessionDataTask {
            let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
                
                guard let data = filter(response, data, error, callback) else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let wikipediaResponse = try decoder.decode(WikipediaResponse.self, from: data)
                    if let page = wikipediaResponse.query.pages.values.first {
                        guard !page.isMissing, let id = page.id, let extract = page.extract else {
                            callback(.success(nil))
                            return
                        }
                        if let thumbnail = page.thumbnail {
                            var downloadedImage: Data? = nil
                            if inlineImage {
                                let semaphore = DispatchSemaphore(value: 0)
                                let dlSession = URLSession(configuration: .default)
                                let dlTask = dlSession.dataTask(with: thumbnail.source) { (dlData, dlResponse, dlError) in
                                    if (dlResponse as! HTTPURLResponse).statusCode == 200 && dlError == nil {
                                        downloadedImage = dlData
                                    }
                                    semaphore.signal()
                                }
                                dlTask.resume()
                                _ = semaphore.wait(timeout: .distantFuture)
                            }
                            var wikiResult: WikipediaResult
                            if useRichText {
                                let attributedExtract = WikipediaAttributedExtract(htmlString: extract)
                                wikiResult = WikipediaResult(language: language, identifier: id, extract: attributedExtract, title: page.title, imageUrl: thumbnail.source, imageData: downloadedImage)
                            } else {
                                wikiResult = WikipediaResult(language: language, identifier: id, extract: extract, title: page.title, imageUrl: thumbnail.source, imageData: downloadedImage)
                            }
                            callback(.success(wikiResult))
                        } else {
                            var wikiResult: WikipediaResult
                            if useRichText {
                                let attributedExtract = WikipediaAttributedExtract(htmlString: extract)
                                wikiResult = WikipediaResult(language: language, identifier: id, extract: attributedExtract, title: page.title)
                            } else {
                                wikiResult = WikipediaResult(language: language, identifier: id, extract: extract, title: page.title)
                            }
                            callback(.success(wikiResult))
                        }
                    } else {
                        callback(.failure(.unknownError)) // Unknown JSON structure
                    }
                } catch let error {
                    callback(.failure(.parseError(message: "Could not parse JSON data. Error: \(error)")))
                }
            }
            task.resume()
            return task
        }
    }
    
}

private func filter<T>(_ response: URLResponse?, _ data: Data?, _ error: Error?,
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
