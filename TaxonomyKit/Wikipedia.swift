/*
 *  Wikipedia.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 17/09/2017.
 *  Copyright:  © 2017 Guillem Servera (https://github.com/gservera)
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

public struct Wikipedia {
    
    private let language: WikipediaLanguage
    
    public init(language: WikipediaLanguage = WikipediaLanguage()) {
        self.language = language
    }
    
    /// Sends an asynchronous request to Wikipedia servers asking for metadata such as an extract
    /// and the Wikipedia page URL for a concrete a taxon.
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
    @discardableResult public func retrieveAbstract(for taxon: Taxon,
                                                    useRichText: Bool = false,
                                                    callback: @escaping (TaxonomyResult<WikipediaResult?>) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.wikipediaAbstract(query: taxon.name, richText: useRichText, language: language)
        return retrieveAbstract(with: request, callback: callback)
    }
    
    
    /// Sends an asynchronous request to Wikipedia servers asking for metadata such as an extract
    /// and the Wikipedia page URL for a concrete a taxon.
    ///
    /// - Since: TaxonomyKit 1.5.
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
    @discardableResult public func retrieveAbstract(for id: String,
                                                           useRichText: Bool = false,
                                                           callback: @escaping (TaxonomyResult<WikipediaResult?>) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.knownWikipediaAbstract(id: id, richText: useRichText, language: language)
        return retrieveAbstract(with: request, callback: callback)
    }
    
    private func retrieveAbstract(with request: TaxonomyRequest, callback: @escaping (TaxonomyResult<WikipediaResult?>) -> ()) -> URLSessionDataTask {
        let language = self.language
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
                    var wikiResult = WikipediaResult(language: language, identifier: id, title: page.title)
                    wikiResult.extract = extract
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
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<Data?>`
    ///               parameter that contains a wrapper with the requested image data (or `nil` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public func retrieveThumbnail(for id: String,
                                                            width: Int,
                                                            callback: @escaping (TaxonomyResult<Data?>) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.knownWikipediaThumbnail(id: id, width: width, language: language)
        return retrieveThumbnail(with: request, callback: callback)
    }
    
    
    /// Sends an asynchronous request to Wikipedia servers asking for the Wikipedia page
    /// thumbnail for a concrete a taxon.
    ///
    /// - Since: TaxonomyKit 1.4.
    /// - Parameters:
    ///   - taxon: The taxon for which to retrieve Wikipedia thumbnail.
    ///   - width: The max width in pixels of the image that the Wikipedia API should return.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<Data?>`
    ///               parameter that contains a wrapper with the requested image data (or `nil` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public func retrieveThumbnail(for taxon: Taxon,
                                                            width: Int,
                                                            callback: @escaping (TaxonomyResult<Data?>) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.wikipediaThumbnail(query: taxon.name, width: width, language: language)
        return retrieveThumbnail(with: request, callback: callback)
    }
    
    
    private func retrieveThumbnail(with request: TaxonomyRequest, callback: @escaping (TaxonomyResult<Data?>) -> ()) -> URLSessionDataTask {
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
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<Data?>`
    ///               parameter that contains a wrapper with the requested image data (or `nil` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public func retrieveFullRecord(for id: String,
                                                             width: Int,
                                                             inlineImage: Bool = false,
                                                             useRichText: Bool = false,
                                                             callback: @escaping (TaxonomyResult<WikipediaResult?>) -> ()) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.knownWikipediaFullRecord(id: id, richText: useRichText, thumbnailWidth: width, language: language)
        return retrieveFullRecord(with: request, inlineImage: inlineImage, useRichText: useRichText, callback: callback)
    }
    
    
    /// Sends an asynchronous request to Wikipedia servers asking for the Wikipedia page
    /// thumbnail for a concrete a taxon.
    ///
    /// - Since: TaxonomyKit 1.5.
    /// - Parameters:
    ///   - taxon: The taxon for which to retrieve Wikipedia thumbnail.
    ///   - width: The max width in pixels of the image that the Wikipedia API should return.
    ///   - callback: A callback closure that will be called when the request completes or
    ///               if an error occurs. This closure has a `TaxonomyResult<Data?>`
    ///               parameter that contains a wrapper with the requested image data (or `nil` if
    ///               no results are found) when the request succeeds.
    /// - Warning: Please note that the callback may not be called on the main thread.
    /// - Returns: The `URLSessionDataTask` object that has begun handling the request. You
    ///            may keep a reference to this object if you plan it should be canceled at some
    ///            point.
    @discardableResult public func retrieveFullRecord(for taxon: Taxon,
                                                      width: Int,
                                                      inlineImage: Bool = false,
                                                      useRichText: Bool = false,
                                                      callback: @escaping (TaxonomyResult<WikipediaResult?>) -> Void) -> URLSessionDataTask {
        
        let request = TaxonomyRequest.wikipediaFullRecord(query: taxon.name, richText: useRichText, thumbnailWidth: width, language: language)
        return retrieveFullRecord(with: request, inlineImage: inlineImage, useRichText: useRichText, callback: callback)
    }
    
    private func retrieveFullRecord(with request: TaxonomyRequest,
                                    inlineImage: Bool = false,
                                    useRichText: Bool = false,
                                    callback: @escaping (TaxonomyResult<WikipediaResult?>) -> Void) -> URLSessionDataTask {
        let task = Taxonomy._urlSession.dataTask(with: request.url) { (data, response, error) in
            
            let language = self.language
            guard let data = filter(response, data, error, callback) else { return }
            
            do {
                let decoder = JSONDecoder()
                let wikipediaResponse = try decoder.decode(WikipediaResponse.self, from: data)
                
                guard let page = wikipediaResponse.query.pages.values.first else {
                    callback(.failure(.unknownError)) // Unknown JSON structure
                    return
                }
                
                guard !page.isMissing, let id = page.id, let extract = page.extract else {
                    callback(.success(nil))
                    return
                }
                var wikiResult = WikipediaResult(language: language, identifier: id, title: page.title)
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
                    wikiResult.pageImageUrl = thumbnail.source
                    wikiResult.pageImageData = downloadedImage
                }
                
                if useRichText {
                    wikiResult.attributedExtract = WikipediaAttributedExtract(htmlString: extract)
                } else {
                    wikiResult.extract = extract
                }
                
                callback(.success(wikiResult))
            } catch let error {
                callback(.failure(.parseError(message: "Could not parse JSON data. Error: \(error)")))
            }
        }
        task.resume()
        return task
    }
    
}
