/*
 *  TaxonomyRequest.swift
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

internal enum TaxonomyRequest {
    case download(identifier: TaxonID)
    case links(identifier: TaxonID)
    case scientificNameGuess(query: String, language: WikipediaLanguage)
    case search(query: String)
    case spelling(failedQuery: String)
    case wikipediaAbstract(query: String, richText: Bool, language: WikipediaLanguage)
    case wikipediaFullRecord(query: String, richText: Bool, thumbnailWidth: Int, language: WikipediaLanguage)
    case wikipediaThumbnail(query: String, width: Int, language: WikipediaLanguage)
    case knownWikipediaAbstract(id: String, richText: Bool, language: WikipediaLanguage)
    case knownWikipediaThumbnail(id: String, width: Int, language: WikipediaLanguage)
    case knownWikipediaFullRecord(id: String, richText: Bool, thumbnailWidth: Int, language: WikipediaLanguage)
    
    var url: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "eutils.ncbi.nlm.nih.gov"
        var queryItems = [URLQueryItem(name: "db", value: "taxonomy")]
        switch self {
        case .download(let identifier):
            components.path = "/entrez/eutils/efetch.fcgi"
            queryItems.append(URLQueryItem(name: "id", value: "\(identifier)"))
        case .links(let identifier):
            components.path = "/entrez/eutils/elink.fcgi"
            queryItems += [
                URLQueryItem(name: "id", value: "\(identifier)"),
                URLQueryItem(name: "dbfrom", value: "taxonomy"),
                URLQueryItem(name: "cmd", value: "llinks")
            ]
        case .search(let query):
            components.path = "/entrez/eutils/esearch.fcgi"
            queryItems += [
                URLQueryItem(name: "term", value: query),
                URLQueryItem(name: "retmode", value: "json")
            ]
        case .spelling(let query): components.path = "/entrez/eutils/espell.fcgi"
            queryItems.append(URLQueryItem(name: "term", value: query))
        case .scientificNameGuess(let query, let lang):
            components.host = "\(lang.subdomain).wikipedia.org"
            components.path = "/w/api.php"
            queryItems = [
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "prop", value: "extracts"),
                URLQueryItem(name: "exintro", value: ""),
                URLQueryItem(name: "explaintext", value: ""),
                URLQueryItem(name: "titles", value: query),
                URLQueryItem(name: "redirects", value: "1"),
            ]
        case .knownWikipediaAbstract(let id, let useRichText, let lang):
            components.host = "\(lang.subdomain).wikipedia.org"
            components.path = "/w/api.php"
            queryItems = [
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "prop", value: "extracts"),
                URLQueryItem(name: "exintro", value: ""),
                URLQueryItem(name: "pageids", value: id),
                URLQueryItem(name: "redirects", value: "1"),
            ]
            if !useRichText {
                queryItems.append(URLQueryItem(name: "explaintext", value: ""))
            }
        case .knownWikipediaThumbnail(let id, let width, let lang):
            components.host = "\(lang.subdomain).wikipedia.org"
            components.path = "/w/api.php"
            queryItems = [
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "prop", value: "pageimages"),
                URLQueryItem(name: "pithumbsize", value: "\(width)"),
                URLQueryItem(name: "pageids", value: id),
                URLQueryItem(name: "redirects", value: "1"),
            ]
        case .knownWikipediaFullRecord(let id, let useRichText, let width, let lang):
            components.host = "\(lang.subdomain).wikipedia.org"
            components.path = "/w/api.php"
            queryItems = [
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "prop", value: "extracts|pageimages"),
                URLQueryItem(name: "exintro", value: ""),
                URLQueryItem(name: "pithumbsize", value: "\(width)"),
                URLQueryItem(name: "pageids", value: id),
                URLQueryItem(name: "redirects", value: "1"),
            ]
            if !useRichText {
                queryItems.append(URLQueryItem(name: "explaintext", value: ""))
            }
        case .wikipediaAbstract(let query, let useRichText, let lang):
            components.host = "\(lang.subdomain).wikipedia.org"
            components.path = "/w/api.php"
            queryItems = [
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "prop", value: "extracts"),
                URLQueryItem(name: "exintro", value: ""),
                URLQueryItem(name: "titles", value: query),
                URLQueryItem(name: "redirects", value: "1"),
            ]
            if !useRichText {
                queryItems.append(URLQueryItem(name: "explaintext", value: ""))
            }
        case .wikipediaThumbnail(let query, let width, let lang):
            components.host = "\(lang.subdomain).wikipedia.org"
            components.path = "/w/api.php"
            queryItems = [
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "prop", value: "pageimages"),
                URLQueryItem(name: "pithumbsize", value: "\(width)"),
                URLQueryItem(name: "titles", value: query),
                URLQueryItem(name: "redirects", value: "1"),
            ]
        case .wikipediaFullRecord(let query, let useRichText, let width, let lang):
            components.host = "\(lang.subdomain).wikipedia.org"
            components.path = "/w/api.php"
            queryItems = [
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "action", value: "query"),
                URLQueryItem(name: "prop", value: "extracts|pageimages"),
                URLQueryItem(name: "exintro", value: ""),
                URLQueryItem(name: "pithumbsize", value: "\(width)"),
                URLQueryItem(name: "titles", value: query),
                URLQueryItem(name: "redirects", value: "1"),
            ]
            if !useRichText {
                queryItems.append(URLQueryItem(name: "explaintext", value: ""))
            }
        }
        
        components.queryItems = queryItems
        return components.url!
    }
}
