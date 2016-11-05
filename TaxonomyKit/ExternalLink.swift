//
//  ExternalLink.swift
//  TaxonomyKit
//
//  Created by Guillem Servera Negre on 5/11/16.
//  Copyright © 2016 Guillem Servera. All rights reserved.
//

import Foundation

public struct ExternalLink {
    
    public struct Provider {
        public let identifier: String
        public let name: String
        public let abbreviation: String
        public let url: URL
        
        public init(id: String, name: String, abbreviation: String, url: URL) {
            self.identifier = id
            self.name = name
            self.abbreviation = abbreviation
            self.url = url
        }
    }
    
    public let url: URL
    
    public let title: String
    
    public let provider: Provider
    
    public init(url: URL, title: String, provider: Provider) {
        self.url = url
        self.title = title
        self.provider = provider
    }
}
