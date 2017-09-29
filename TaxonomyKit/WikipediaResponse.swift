/*
 *  WikipediaResponse.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 09/06/2017.
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

internal struct WikipediaResponse: Codable {
    
    struct Query: Codable {
        
        struct Page: Codable {
            
            struct Thumbnail: Codable {
                let source: URL
                let width: Int
                let height: Int
            }
            
            let thumbnail: Thumbnail?
            
            let extract: String?
            let id: Int?
            let title: String
            
            enum CodingKeys : String, CodingKey {
                case id = "pageid", title, extract, thumbnail
            }
            
            var isMissing: Bool {
                return id == -1 || id == nil
            }
            
        }
        
        struct Redirect: Codable {
            let from: String
            let to: String
        }
        
        let pages: [Int:WikipediaResponse.Query.Page]
        let redirects: [WikipediaResponse.Query.Redirect]
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let redirects = try container.decodeIfPresent(Array<WikipediaResponse.Query.Redirect>.self, forKey: .redirects) {
                self.redirects = redirects
            } else {
                self.redirects = []
            }
            self.pages = try container.decode(Dictionary<Int,WikipediaResponse.Query.Page>.self, forKey: .pages)
        }
    }
    let query: Query
    let warnings: [String:[String:String]]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let warnings = try container.decodeIfPresent(Dictionary<String,Dictionary<String,String>>.self, forKey: .warnings) {
            self.warnings = warnings
        } else {
            self.warnings = [:]
        }
        self.query = try container.decode(WikipediaResponse.Query.self, forKey: .query)
    }
}
