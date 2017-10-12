/*
 *  ExternalLink.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 05/11/2016.
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


/// The `ExternalLink` type represents an external resource related to some
/// taxon (a LinkOut item in the NCBI's terminology).
public struct ExternalLink {
    
    /// The `ExternalLink.Provider` type represents a NCBI LinkOut provider.
    public struct Provider {
        
        /// The internal NCBI identifier for the provider.
        public let identifier: String
        
        /// The full name of the provider.
        public let name: String
        
        /// The abbreviation used by the NCBI to reference the provider.
        public let abbreviation: String
        
        /// The provider's homepage URL.
        public let url: URL
        
        
        /// Initializes a new `ExternalLink.Provider` using its defining parameters.
        ///
        /// - Parameters:
        ///   - id: The internal NCBI identifier for the provider.
        ///   - name: The full name of the provider.
        ///   - abbreviation: The abbreviation used by the NCBI to reference the provider.
        ///   - url: The provider's homepage URL.
        public init(id: String, name: String, abbreviation: String, url: URL) {
            self.identifier = id
            self.name = name
            self.abbreviation = abbreviation
            self.url = url
        }
    }
    
    
    /// The external resource URL.
    public let url: URL
    
    /// The external resource title or nil if not set by NCBI.
    public let title: String?
    
    /// The external resource provider.
    public let provider: Provider
    
    
    /// Initializes a new `ExternalLink` using its defining parameters.
    ///
    /// - Parameters:
    ///   - url: The external resource URL.
    ///   - title: The external resource title or nil if unset.
    ///   - provider: The external resource provider.
    public init(url: URL, title: String?, provider: Provider) {
        self.url = url
        self.title = title
        self.provider = provider
    }
}
