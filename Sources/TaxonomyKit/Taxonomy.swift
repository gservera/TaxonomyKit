/*
 *  Taxonomy.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 24/09/2016.
 *  Copyright:  © 2016-2019 Guillem Servera (https://github.com/gservera)
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

/// A numeric string representing an entrez record.
public typealias TaxonID = Int

/// The base class from which all the NCBI related tasks are initiated. This class
/// is not meant to be instantiated but it serves as a start node to invoke the
/// TaxonomyKit functions in your code.
public final class Taxonomy {

    internal init() { /* We prevent this struct from being instantiated. */ }

    /// The used network session. Editable for testing purposes.
    internal static var internalUrlSession: URLSessionProtocol = makeUrlSession()

    /// Creates a network session that supports connectivity waiting.
    internal static func makeUrlSession() -> URLSession {
        let defaultSessionConfiguration = URLSessionConfiguration.default
        if #available(OSX 10.13, iOSApplicationExtension 11.0, *) {
            defaultSessionConfiguration.waitsForConnectivity = true
        }
        return URLSession(configuration: defaultSessionConfiguration)
    }

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
    @discardableResult
    public static func findIdentifiers(for query: String,
                        callback: @escaping(_ result: Result<[TaxonID], TaxonomyError>) -> Void) -> URLSessionDataTask {

        let request = TaxonomyRequest.search(query: query)
        let task = Taxonomy.internalUrlSession.dataTask(with: request.url) { data, response, error in

            guard let data = filter(response, data, error, callback) else { return }

            do {
                let JSON = try JSONSerialization.jsonObject(with: data)
                guard let casted = JSON as? [String: [String: Any]] else {
                    callback(.failure(.unknownError)) // Unknown JSON structure
                    return
                }
                if let list = casted["esearchresult"]?["idlist"] as? [String] {
                    let mapped: [TaxonID] = list.compactMap { Int($0) }
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
    @discardableResult
    public static func findSimilarSpelledCandidates(for failedQuery: String,
                         callback: @escaping (_ result: Result<String?, TaxonomyError>) -> Void) -> URLSessionDataTask {

        let request = TaxonomyRequest.spelling(failedQuery: failedQuery.lowercased())
        let task = Taxonomy.internalUrlSession.dataTask(with: request.url) { data, response, error in

            guard let data = filter(response, data, error, callback) else { return }

            do {
                let xmlDoc = try NCBIXMLDocument(xml: data)
                if xmlDoc.root["CorrectedQuery"].error != .elementNotFound {
                    //Value will be nil either the original query is valid or no candidates were found.
                    callback(.success(xmlDoc.root["CorrectedQuery"].value))
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
    /// info for a set of given NCBI internal identifiers.
    ///
    /// - Since: TaxonomyKit 1.9.
    /// - Parameters:
    ///   - identifiers: The NCBI internal identifiers.
    ///   - callback: A callback closure that will be called when the request completes or when
    ///               an error occurs. This closure has a `TaxonomyResult<[Taxon]>` parameter that
    ///               contains the retrieved taxon when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some point.
    @discardableResult
    public static func downloadTaxa(identifiers: [TaxonID],
                        callback: @escaping (_ result: Result<[Taxon], TaxonomyError>) -> Void) -> URLSessionDataTask {
        let request = TaxonomyRequest.download(identifiers: identifiers)
        let task = Taxonomy.internalUrlSession.dataTask(with: request.url) { data, response, error in
            guard let data = filter(response, data, error, callback) else { return }
            do {
                let xmlDoc = try NCBIXMLDocument(xml: data)
                let taxonRoots = xmlDoc.root["Taxon"]
                guard taxonRoots.error == nil, !taxonRoots.all.isEmpty else {
                    callback(.failure(.unknownError)); return
                }
                var taxa: [Taxon] = []
                for taxonRoot in taxonRoots.all {
                    let genbankCommonName = taxonRoot["OtherNames"]["GenbankCommonName"].value
                    let mainCodeOpt = taxonRoot["GeneticCode"]["GCName"].value
                    let mitoCodeOpt = taxonRoot["MitoGeneticCode"]["MGCName"].value
                    guard let taxonId: TaxonID = taxonRoot["TaxId"].readInt(),
                          let name = taxonRoot["ScientificName"].value, let rank = taxonRoot["Rank"].value,
                          let mainCode = mainCodeOpt, let mitoCode = mitoCodeOpt,
                          let parentId: TaxonID = taxonRoot["ParentTaxId"].readInt()
                    else { throw TaxonomyError.parseError(message: "Unexpected XML taxon data") }
                    let rankValue = TaxonomicRank(rawValue: rank)
                    var taxon = Taxon(identifier: taxonId, name: name, rank: rankValue,
                                      geneticCode: mainCode, mitochondrialCode: mitoCode)
                    taxon.commonNames = taxonRoot["OtherNames"]["CommonName"].all.compactMap { $0.value }
                    taxon.genbankCommonName = genbankCommonName
                    taxon.synonyms = taxonRoot["OtherNames"]["Synonym"].all.compactMap { $0.value }
                    taxon.parentIdentifier = parentId == 0 ? nil : parentId
                    var lineage: [TaxonLineageItem] = []
                    if taxonRoot["LineageEx"]["Taxon"].error != .elementNotFound {
                        for lineageItem in taxonRoot["LineageEx"]["Taxon"].all {
                            guard let itemIdStr = lineageItem["TaxId"].value, let itemId = Int(itemIdStr),
                                let itemName = lineageItem["ScientificName"].value,
                                let itemRank = lineageItem["Rank"].value else {
                                    throw TaxonomyError.parseError(message: "Could not parse XML data")
                            }
                            let itemRankValue = TaxonomicRank(rawValue: itemRank)
                            lineage.append(TaxonLineageItem(identifier: itemId, name: itemName, rank: itemRankValue))
                        }
                        taxon.lineageItems = lineage
                    }
                    taxa.append(taxon)
                }
                callback(.success(taxa))
            } catch _ {
                callback(.failure(.parseError(message: "Could not parse XML data")))
            }
        }
        return task.resumed()
    }

    /// Sends an asynchronous request to the NCBI servers asking for a taxon's immediate descendants
    /// matches a specific query.
    ///
    /// - Since: TaxonomyKit 1.8.
    /// - Parameters:
    ///   - taxon:    The taxon whose scientific name will be used to query for descendants.
    ///   - callback: A callback closure that will be called when the request completes or when
    ///               an error occurs. This closure has a `TaxonomyResult<[TaxonLineageItem]>` parameter
    ///               that contains an array with the found descendants when the request succeeds.
    ///
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You may
    ///            keep a reference to this object if you plan it should be canceled at some point.
    @discardableResult
    public static func downloadImmediateDescendants<T: TaxonRepresenting>(for taxon: T,
                        callback: @escaping(Result<[TaxonLineageItem], TaxonomyError>) -> Void) -> URLSessionDataTask {

        let request = TaxonomyRequest.downloadNextLevel(term: taxon.name)
        let task = Taxonomy.internalUrlSession.dataTask(with: request.url) { data, response, error in

            guard let data = filter(response, data, error, callback) else { return }

            do {
                let JSON = try JSONSerialization.jsonObject(with: data)
                guard let casted = JSON as? [String: [String: Any]] else {
                    callback(.failure(.unknownError)) // Unknown JSON structure
                    return
                }
                if let list = casted["esearchresult"]?["idlist"] as? [String] {
                    let mapped: [TaxonID] = list.compactMap { Int($0) }

                    guard !mapped.isEmpty else {
                        callback(.success([]))
                        return
                    }

                    Taxonomy.downloadTaxa(identifiers: mapped) { subtaskResult in
                        switch subtaskResult {
                        case .success(let possibleChildren):
                            let trueChildren = possibleChildren.filter { $0.parentIdentifier == taxon.identifier }
                            callback(.success(trueChildren.map {
                                TaxonLineageItem(identifier: $0.identifier, name: $0.name, rank: $0.rank)
                            }))
                        case .failure(let subtaskError):
                            callback(.failure(subtaskError))
                        }
                    }
                } else {
                    callback(.failure(.unknownError)) // Unknown JSON structure
                }
            } catch _ {
                callback(.failure(.parseError(message: "Could not parse JSON data")))
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
    ///            may keep a reference to this object if you plan it should be canceled at some point.
    @discardableResult
    public static func findLinkedResources(for identifier: TaxonID,
                        callback: @escaping (Result<[ExternalLink], TaxonomyError>) -> Void) -> URLSessionDataTask {

        let request = TaxonomyRequest.links(identifier: identifier)
        let task = Taxonomy.internalUrlSession.dataTask(with: request.url) { data, response, error in

            guard let data = filter(response, data, error, callback) else { return }

            do {
                let xmlDoc = try NCBIXMLDocument(xml: data)
                let linkRoot = xmlDoc.root["LinkSet"]["IdUrlList"]["IdUrlSet"]["ObjUrl"]
                guard linkRoot.error != .elementNotFound, !linkRoot.all.isEmpty else {
                    callback(.failure(.unknownError))
                    return
                }
                var links: [ExternalLink] = []
                for linkNode in linkRoot.all {
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

                    let provider = ExternalLink.Provider(id: srcId, name: srcName, abbreviation: srcAbbr, url: srcURL)
                    let linkOut = ExternalLink(url: url, title: title, provider: provider)
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
                        _ callback: @escaping (Result<T, TaxonomyError>) -> Void) -> Data? {
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
