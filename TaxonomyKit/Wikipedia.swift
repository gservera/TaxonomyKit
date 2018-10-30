/*
 *  Wikipedia.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 17/09/2017.
 *  Copyright:  © 2017-2018 Guillem Servera (https://github.com/gservera)
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

/// The base class from which all the Wikipedia related tasks are initiated. This class
/// is not meant to be instantiated but it serves as a start node to invoke the
/// TaxonomyKit functions in your code.
public final class Wikipedia {

    private let language: WikipediaLanguage

    /// The max width in pixels of the image that the Wikipedia API should return. Defaults to 600.
    public var thumbnailWidth: Int = 600

    /// Set to `true` to retrieve Wikipedia extracts as an `NSAttributedString`. Default is `false`.
    public var usesRichText: Bool = false

    /// Creates a new Wikipedia instance with a given locale. Defaults to system's.
    ///
    /// - Parameter language: The `WikipediaLanguage` object that will be passed to
    ///                       every method called from this instance.
    public init(language: WikipediaLanguage = WikipediaLanguage()) {
        self.language = language
    }

    /// Attempts to guess scientific names that could match a specific query using info from
    /// the corresponding Wikipedia article.
    ///
    /// - Since: TaxonomyKit 1.5.
    /// - Parameters:
    ///   - query: The query for which to retrieve Wikipedia metadata.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<[String]>`
    ///               parameter that contains a wrapper with the found names (or `[]` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult
    public func findPossibleScientificNames(matching query: String,
                                            callback: @escaping(_ result: Result<[String]>) -> Void) -> URLSessionTask {

        let request = TaxonomyRequest.scientificNameGuess(query: query, language: language)
        let task = Taxonomy.internalUrlSession.dataTask(with: request.url) { data, response, error in

            guard let data = filter(response, data, error, callback) else { return }

            let decoder = JSONDecoder()
            guard let wikipediaResponse = try? decoder.decode(WikipediaResponse.self, from: data) else {
                callback(.failure(.parseError(message: "Could not parse JSON data")))
                return
            }

            guard let page = wikipediaResponse.query.pages.values.first else {
                callback(.failure(.unknownError)) // Unknown JSON structure
                return
            }

            guard !page.isMissing, page.identifier != nil, let extract = page.extract else {
                callback(.success([]))
                return
            }
            var names: [String] = []
            if page.title != query && page.title.components(separatedBy: " ").count > 1 {
                names.append(page.title)
            }

            if let match = extract.range(of: "\\((.*?)([.,\\(\\)\\[\\]\\{\\}])", options: .regularExpression) {
                let toBeTrimmed = CharacterSet(charactersIn: " .,()[]{}\n")
                names.append(String(extract[match].trimmingCharacters(in: toBeTrimmed)))
            }

            callback(.success(names))
        }
        return task.resumed()
    }

    /// Sends an asynchronous request to Wikipedia servers asking for metadata such as an extract
    /// and the Wikipedia page URL for a concrete taxon.
    ///
    /// - Since: TaxonomyKit 1.3.
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
    @discardableResult
    public func retrieveAbstract<T: TaxonRepresenting>(for taxon: T,
                  callback: @escaping (Result<WikipediaResult?>) -> Void) -> URLSessionTask {

        let request = TaxonomyRequest.wikipediaAbstract(query: taxon.name, richText: usesRichText, language: language)
        return retrieveAbstract(with: request, callback: callback)
    }

    /// Sends an asynchronous request to Wikipedia servers asking for metadata such as an extract
    /// and the Wikipedia page URL for a concrete Wikipedia Page ID.
    ///
    /// - Since: TaxonomyKit 1.5.
    /// - Parameters:
    ///   - identifier: The Wikipedia Page ID for which to retrieve the requested metadata.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<WikipediaResult?>`
    ///               parameter that contains a wrapper with the requested metadata (or `nil` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult
    public func retrieveAbstract(for identifier: String,
                                 callback: @escaping (Result<WikipediaResult?>) -> Void) -> URLSessionDataTask {

        let request = TaxonomyRequest.knownWikipediaAbstract(pageId: identifier,
                                                             richText: usesRichText, language: language)
        return retrieveAbstract(with: request, callback: callback)
    }

    private func retrieveAbstract(with request: TaxonomyRequest,
                                  callback: @escaping (Result<WikipediaResult?>) -> Void) -> URLSessionDataTask {
        let language = self.language
        let task = Taxonomy.internalUrlSession.dataTask(with: request.url) { data, response, error in

            guard let data = filter(response, data, error, callback) else { return }

            do {
                let decoder = JSONDecoder()
                let wikipediaResponse = try decoder.decode(WikipediaResponse.self, from: data)
                if let page = wikipediaResponse.query.pages.values.first {
                    guard !page.isMissing, let identifier = page.identifier, let extract = page.extract else {
                        callback(.success(nil))
                        return
                    }
                    var wikiResult = WikipediaResult(language: language, identifier: identifier, title: page.title)
                    if self.usesRichText {
                        wikiResult.attributedExtract = WikipediaAttributedExtract(htmlString: extract)
                    } else {
                        wikiResult.extract = extract
                    }
                    callback(.success(wikiResult))
                } else {
                    callback(.failure(.unknownError)) // Unknown JSON structure
                }
            } catch _ {
                callback(.failure(.parseError(message: "Could not parse JSON data")))
            }
        }
        return task.resumed()
    }

    /// Sends an asynchronous request to Wikipedia servers asking for the Wikipedia page
    /// thumbnail for a concrete taxon.
    ///
    /// - Since: TaxonomyKit 1.4.
    /// - Parameters:
    ///   - taxon: The taxon for which to retrieve Wikipedia thumbnail.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<Data?>`
    ///               parameter that contains a wrapper with the requested image data (or `nil` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult
    public func retrieveThumbnail<T: TaxonRepresenting>(for taxon: T,
                                                        callback: @escaping(Result<Data?>) -> Void) -> URLSessionTask {

        let request = TaxonomyRequest.wikipediaThumbnail(query: taxon.name, width: thumbnailWidth, language: language)
        return retrieveThumbnail(with: request, callback: callback)
    }

    /// Sends an asynchronous request to Wikipedia servers asking for the Wikipedia page
    /// thumbnail for a concrete Wikipedia Page ID.
    ///
    /// - Since: TaxonomyKit 1.4.
    /// - Parameters:
    ///   - identifier: The Wikipedia Page ID for which to retrieve the requested metadata.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<Data?>`
    ///               parameter that contains a wrapper with the requested image data (or `nil` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult
    public func retrieveThumbnail(for identifier: String,
                                  callback: @escaping (Result<Data?>) -> Void) -> URLSessionTask {

        let request = TaxonomyRequest.knownWikipediaThumbnail(pageId: identifier,
                                                              width: thumbnailWidth, language: language)
        return retrieveThumbnail(with: request, callback: callback)
    }

    private func retrieveThumbnail(with request: TaxonomyRequest,
                                   callback: @escaping (Result<Data?>) -> Void) -> URLSessionDataTask {
        let task = Taxonomy.internalUrlSession.dataTask(with: request.url) { data, response, error in

            guard let data = filter(response, data, error, callback) else { return }

            do {
                let decoder = JSONDecoder()
                let wikipediaResponse = try decoder.decode(WikipediaResponse.self, from: data)
                if let page = wikipediaResponse.query.pages.values.first {
                    guard !page.isMissing, let thumbnail = page.thumbnail else {
                        callback(.success(nil))
                        return
                    }

                    if let data = Wikipedia.downloadImage(from: thumbnail.source) {
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
        return task.resumed()
    }

    /// Sends an asynchronous request to Wikipedia servers asking for the Wikipedia page
    /// thumbnail and page extract for a concrete Wikipedia Page ID.
    ///
    /// - Since: TaxonomyKit 1.5.
    /// - Parameters:
    ///   - identifier: The Wikipedia Page ID for which to retrieve the requested metadata.
    ///   - inlineImage: Pass `true` to download the found thumbnail immediately. Defaults to
    ///                  `false`, which means onlu the thumbnail URL is returned.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<WikipediaResult?>`
    ///               parameter that contains a wrapper with the requested metadata (or `nil` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult
    public func retrieveFullRecord(for identifier: String, inlineImage: Bool = false,
                                   callback: @escaping (Result<WikipediaResult?>) -> Void) -> URLSessionTask {

        let request = TaxonomyRequest.knownWikipediaFullRecord(pageId: identifier, richText: usesRichText,
                                                               thumbnailWidth: thumbnailWidth, language: language)
        return retrieveFullRecord(with: request, inlineImage: inlineImage, callback: callback)
    }

    /// Sends an asynchronous request to Wikipedia servers asking for the thumbnail and extract of a
    /// page whose title matches a given taxon's scientific name.
    ///
    /// - Since: TaxonomyKit 1.5.
    /// - Parameters:
    ///   - taxon: The taxon whose scientific name will be evaluated to find a matching Wikipedia page.
    ///   - inlineImage: Pass `true` to download the found thumbnail immediately. Defaults to
    ///                  `false`, which means onlu the thumbnail URL is returned.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<WikipediaResult?>`
    ///               parameter that contains a wrapper with the requested metadata (or `nil` if
    ///               no matching Wikipedia pages are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult
    public func findPossibleMatch<T: TaxonRepresenting>(for taxon: T, inlineImage: Bool = false,
                  callback: @escaping(Result<WikipediaResult?>) -> Void) -> URLSessionTask {

        let request = TaxonomyRequest.wikipediaFullRecord(query: taxon.name, richText: usesRichText,
                                                          thumbnailWidth: thumbnailWidth, language: language)
        return retrieveFullRecord(with: request, inlineImage: inlineImage, strict: true, callback: callback)
    }

    /// Sends an asynchronous request to Wikipedia servers asking for the Wikipedia page
    /// thumbnail and page extract for a concrete taxon.
    ///
    /// - Since: TaxonomyKit 1.5.
    /// - Parameters:
    ///   - taxon: The taxon for which to retrieve Wikipedia thumbnail.
    ///   - inlineImage: Pass `true` to download the found thumbnail immediately. Defaults to
    ///                  `false`, which means onlu the thumbnail URL is returned.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<WikipediaResult?>`
    ///               parameter that contains a wrapper with the requested metadata (or `nil` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult
    public func retrieveFullRecord<T: TaxonRepresenting>(for taxon: T, inlineImage: Bool = false,
                  callback: @escaping (Result<WikipediaResult?>) -> Void) -> URLSessionTask {

        let request = TaxonomyRequest.wikipediaFullRecord(query: taxon.name, richText: usesRichText,
                                                          thumbnailWidth: thumbnailWidth, language: language)
        return retrieveFullRecord(with: request, inlineImage: inlineImage, callback: callback)
    }

    private func retrieveFullRecord(with request: TaxonomyRequest, inlineImage: Bool = false, strict: Bool = false,
                                    callback: @escaping (Result<WikipediaResult?>) -> Void) -> URLSessionDataTask {
        let task = Taxonomy.internalUrlSession.dataTask(with: request.url) { data, response, error in

            let language = self.language
            guard let data = filter(response, data, error, callback) else { return }

            guard let wikipediaResponse = try? JSONDecoder().decode(WikipediaResponse.self, from: data) else {
                callback(.failure(.parseError(message: "Could not parse JSON data.")))
                return
            }
            guard let page = wikipediaResponse.query.pages.values.first else {
                callback(.failure(.unknownError)) // Unknown JSON structure
                return
            }
            guard !page.isMissing, let pageID = page.identifier, let extract = page.extract,
                  !(strict && !wikipediaResponse.query.redirects.isEmpty) else {
                callback(.success(nil))
                return
            }
            var wikiResult = WikipediaResult(language: language, identifier: pageID, title: page.title)
            if let thumbnail = page.thumbnail {
                wikiResult.pageImageUrl = thumbnail.source
                if inlineImage {
                    wikiResult.pageImageData = Wikipedia.downloadImage(from: thumbnail.source)
                }
            }
            if self.usesRichText {
                wikiResult.attributedExtract = WikipediaAttributedExtract(htmlString: extract)
            } else {
                wikiResult.extract = extract
            }
            callback(.success(wikiResult))
        }
        return task.resumed()
    }

    static func downloadImage(from url: URL) -> Data? {
        var downloadedData: Data?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession(configuration: .default).dataTask(with: url) { dlData, dlResponse, dlError in
            downloadedData = filter(dlResponse, dlData, dlError, { (_: Result<Void>) in })
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        return downloadedData
    }

}
