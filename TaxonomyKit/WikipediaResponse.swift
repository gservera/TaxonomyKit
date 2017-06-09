//
//  WikipediaResponse.swift
//  TaxonomyKit
//
//  Created by Guillem Servera Negre on 9/6/17.
//  Copyright © 2017 Guillem Servera. All rights reserved.
//

import Foundation

internal struct WikipediaResponse: Codable {
    
    struct Query: Codable {
        
        struct Page: Codable {
            
            struct Thumbnail: Codable {
                let source: URL
                let width: Int
                let height: Int
            }
            
            var thumbnail: Thumbnail? = nil
            
            var extract: String? = nil
            var id: Int? = -1
            var title: String
            
            enum CodingKeys : String, CodingKey {
                case id = "pageid", title, extract, thumbnail
            }
            
            var isMissing: Bool {
                return id == -1
            }
            
        }
        
        var pages: [Int:WikipediaResponse.Query.Page]
        
    }
    let query: Query
    let warnings: [String:[String:String]] = [:]
    
}
