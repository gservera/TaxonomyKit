/*
 *  WikipediaStructs.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 27/02/2017.
 *  Copyright:  © 2017 Guillem Servera (http://github.com/gservera)
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

#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
    public typealias _OSFontType = UIFont
#elseif os(OSX)
    import AppKit
	public typealias _OSFontType = NSFont
#endif


/// A wrapper containing metadata related to a specific taxon. Generated by the
/// `Taxonomy.retrieveWikipediaAbstract` method when a match is found on Wikipedia
/// servers and an extract could be retrieved from the article.
public struct WikipediaResult {
    
    /// The Wikipedia page ID for the query that was sent.
    public let identifier: Int
    
    /// The HTTPS URL pointing to the taxon's Wikipedia page.
    public let url: URL
    
    /// The HTTPS URL pointing to the taxon's Wikipedia mobile page.
    public let mobileUrl: URL
    
    /// The locale used to search Wikipedia.
    public let language: WikipediaLanguage
    
    /// The retrieved extract from the Wikipedia article.
    public let extract: String?
    
    /// The retrieved extract from the Wikipedia article.
    public let attributedExtract: WikipediaAttributedExtract?
    
    /// The title of the Wikipedia article.
    public let title: String
    
    /// The remote HTTPS URL pointing to the Wikipedia page's main image if requested and available.
    public let pageImageUrl: URL?
    
    /// The downloaded Wikipedia page's main image if requested and available.
    public let pageImageData: Data?
    
    init(language: WikipediaLanguage, identifier: Int, extract: String? = nil, title: String, imageUrl: URL? = nil, imageData: Data? = nil) {
        self.language = language
        self.identifier = identifier
        self.extract = extract
        self.attributedExtract = nil
        self.title = title
        self.pageImageUrl = imageUrl
        self.pageImageData = imageData
        self.url = URL(string:"https://\(language.subdomain).wikipedia.org/?curid=\(identifier)")!
        self.mobileUrl = URL(string:"https://\(language.subdomain).m.wikipedia.org/?curid=\(identifier)")!
    }
    
    init(language: WikipediaLanguage, identifier: Int, extract: WikipediaAttributedExtract? = nil, title: String, imageUrl: URL? = nil, imageData: Data? = nil) {
        self.language = language
        self.identifier = identifier
        self.attributedExtract = extract
        self.extract = nil
        self.title = title
        self.pageImageUrl = imageUrl
        self.pageImageData = imageData
        self.url = URL(string:"https://\(language.subdomain).wikipedia.org/?curid=\(identifier)")!
        self.mobileUrl = URL(string:"https://\(language.subdomain).m.wikipedia.org/?curid=\(identifier)")!
    }
}



/// A struct used to transform `Locale` language codes into the different 
/// localized Wikipedia subdomains.
public struct WikipediaLanguage {
    
    /// The subdomain that will be used for the initialization locale.
    let subdomain: String
    
    /// Initializes a new WikipediaLanguage that determines the desired
    /// subdomain using from `Locale` object. Falls back to 'en' when the
    /// language code cannot be determined.
    ///
    /// - Note: The idea of having this type is being able to override any
    ///         non matching code transformations between the iOS locale and the
    ///         Wikipedia subdomain.
    ///
    /// - Parameter locale: The desired language code. Defaults to user's.
    public init(locale: Locale = Locale.current) {
        switch locale.languageCode {
        default:
            subdomain = locale.languageCode ?? "en"
        }
    }
}


public struct WikipediaAttributedExtract {
    public let htmlString: String
    
    #if os(iOS) || os(watchOS) || os(tvOS) || os(OSX)
    public func attributedString(using font: _OSFontType) throws -> NSAttributedString {
        do {
            return try htmlString.parseHTML(setting: font)
        } catch let error {
            throw error
        }
    }
    #endif
    
}

#if os(iOS) || os(watchOS) || os(tvOS) || os(OSX)
public extension String {
    public func parseHTML(setting font: _OSFontType) throws -> NSAttributedString {
        do {
            #if os(iOS) || os(watchOS) || os(tvOS)
                let fontFamily = font.familyName
            #else
                let fontFamily = font.familyName ?? font.fontName
            #endif
            let fontSize = font.pointSize
            let stylePrefix = NSString(format: "<style>body{font-family: '%@';font-size:%fpx;}</style>", fontFamily, fontSize)
            let styledString = (stylePrefix as String) + self
            guard let styledData = styledString.data(using: .utf8) else {
                throw TaxonomyError.unknownError
            }
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
            ]
            let attributed = try NSAttributedString(data: styledData, options: options, documentAttributes: nil)
            return attributed
        } catch let error {
            throw error
        }
    }
}
#endif
