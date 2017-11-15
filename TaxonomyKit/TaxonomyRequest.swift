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
        var components: URLComponents
        switch self {
        case .download(let identifier):
            components = URLComponents()
            components.scheme = "https"
            components.host = "eutils.ncbi.nlm.nih.gov"
            components.path = "/entrez/eutils/efetch.fcgi"
            components.queryItems = [
                URLQueryItem(name: "db", value: "taxonomy"),
                URLQueryItem(name: "id", value: "\(identifier)")
            ]
        case .links(let identifier):
            components = URLComponents()
            components.scheme = "https"
            components.host = "eutils.ncbi.nlm.nih.gov"
            components.path = "/entrez/eutils/elink.fcgi"
            components.queryItems = [
                URLQueryItem(name: "db", value: "taxonomy"),
                URLQueryItem(name: "id", value: "\(identifier)"),
                URLQueryItem(name: "dbfrom", value: "taxonomy"),
                URLQueryItem(name: "cmd", value: "llinks")
            ]
        case .search(let query):
            components = URLComponents()
            components.scheme = "https"
            components.host = "eutils.ncbi.nlm.nih.gov"
            components.path = "/entrez/eutils/esearch.fcgi"
            components.queryItems = [
                URLQueryItem(name: "db", value: "taxonomy"),
                URLQueryItem(name: "term", value: query),
                URLQueryItem(name: "retmode", value: "json")
            ]
        case .spelling(let query):
            components = URLComponents()
            components.scheme = "https"
            components.host = "eutils.ncbi.nlm.nih.gov"
            components.path = "/entrez/eutils/espell.fcgi"
            components.queryItems = [
                URLQueryItem(name: "db", value: "taxonomy"),
                URLQueryItem(name: "term", value: query)
            ]

        case .scientificNameGuess(let query, let lang):
            components = wikipediaComponents(for: .extract(useRichText: false), query: query, language: lang)

        case .wikipediaAbstract(let query, let useRichText, let lang):
            components = wikipediaComponents(for: .extract(useRichText: useRichText), query: query, language: lang)

        case .wikipediaThumbnail(let query, let width, let lang):
            components = wikipediaComponents(for: .thumbnail(width: width), query: query, language: lang)

        case .wikipediaFullRecord(let query, let rtf, let width, let lang):
            components = wikipediaComponents(for: .full(useRichText: rtf, width: width), query: query, language: lang)

        case .knownWikipediaAbstract(let id, let rtf, let lang):
            components = wikipediaComponents(for: .extract(useRichText: rtf), pageID: id, language: lang)

        case .knownWikipediaThumbnail(let id, let width, let lang):
            components = wikipediaComponents(for: .thumbnail(width: width), pageID: id, language: lang)

        case .knownWikipediaFullRecord(let id, let rtf, let width, let lang):
            components = wikipediaComponents(for: .full(useRichText: rtf, width: width), pageID: id, language: lang)
        }

        return components.url!
    }

    private enum WikipediaRequestType {
        case extract(useRichText: Bool)
        case thumbnail(width: Int)
        case full(useRichText: Bool, width: Int)

        var queryItems: [URLQueryItem] {
            var queryItems: [URLQueryItem] = []
            switch self {
            case .extract(let prefersRichText):
                queryItems += [
                    URLQueryItem(name: "prop", value: "extracts"),
                    URLQueryItem(name: "exintro", value: "")
                ]
                if !prefersRichText {
                    queryItems.append(URLQueryItem(name: "explaintext", value: ""))
                }
            case .thumbnail(let width):
                queryItems += [
                    URLQueryItem(name: "prop", value: "pageimages"),
                    URLQueryItem(name: "pithumbsize", value: "\(width)")
                ]
            case .full(let prefersRichText, let width):
                queryItems += [
                    URLQueryItem(name: "prop", value: "extracts|pageimages"),
                    URLQueryItem(name: "exintro", value: ""),
                    URLQueryItem(name: "pithumbsize", value: "\(width)")
                ]
                if !prefersRichText {
                    queryItems.append(URLQueryItem(name: "explaintext", value: ""))
                }
            }
            return queryItems
        }
    }

    private func wikipediaComponents(for type: WikipediaRequestType, pageID: String? = nil,
                                     query: String? = nil, language: WikipediaLanguage) -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "\(language.subdomain).wikipedia.org"
        components.path = "/w/api.php"
        var queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "redirects", value: "")
        ]
        if let pageID = pageID {
            queryItems.append(URLQueryItem(name: "pageids", value: pageID))
        } else if let query = query {
            queryItems.append(URLQueryItem(name: "titles", value: query))
        }
        queryItems += type.queryItems
        components.queryItems = queryItems
        return components
    }
}
