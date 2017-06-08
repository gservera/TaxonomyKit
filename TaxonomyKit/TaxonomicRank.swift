/*
 *  TaxonomicRank.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 18/11/2016.
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

/// A set of string-convertible values used to represent the different taxonomic ranks.
public enum TaxonomicRank: String, Comparable, CustomStringConvertible, Codable {
    /// An abstract 'root' taxonomic rank.
    case origin
    //case trunk
    /// The superkingdom/domain taxonomic rank.
    case superkingdom
    /// The kingdom/regnum taxonomic rank.
    case kingdom
    /// The subkingdom taxonomic rank.
    case subkingdom
    /// The infrakingdom taxonomic rank.
    case infrakingdom
    /// The superphylum taxonomic rank.
    case superphylum
    /// The phylum taxonomic rank.
    case phylum
    /// The subphylum taxonomic rank.
    case subphylum
    /// The infraphylum taxonomic rank.
    case infraphylum
    /// The microphylum taxonomic rank.
    case microphylum
    /// The superclass taxonomic rank.
    case superclass
    /// The class taxonomic rank.
    case `class`
    /// The subclass taxonomic rank.
    case subclass
    /// The infraclass taxonomic rank.
    case infraclass
    /// The parvclass taxonomic rank.
    case parvclass
    /// The magnorder taxonomic rank.
    case magnorder
    /// The ssuperorder taxonomic rank.
    case superorder
    /// The order taxonomic rank.
    case order
    /// The suborder taxonomic rank.
    case suborder
    /// The infraorder taxonomic rank.
    case infraorder
    /// The parvorder taxonomic rank.
    case parvorder
    /// The superfamily taxonomic rank.
    case superfamily
    /// The family taxonomic rank.
    case family
    /// The subfamily taxonomic rank.
    case subfamily
    /// The supertribe taxonomic rank.
    case supertribe
    /// The tribe taxonomic rank.
    case tribe
    /// The subtribe taxonomic rank.
    case subtribe
    /// The genus taxonomic rank.
    case genus
    /// The subgenus taxonomic rank.
    case subgenus
    /// The section taxonomic rank.
    case section
    /// The subsection taxonomic rank.
    case subsection
    /// The series taxonomic rank.
    case series
    /// The subseries taxonomic rank.
    case subseries
    /// The species taxonomic rank.
    case species
    /// The subspecies taxonomic rank.
    case subspecies
    /// The varietas taxonomic rank.
    case varietas
    /// The subvarietas taxonomic rank.
    case subvarietas
    /// The form taxonomic rank.
    case form
    /// The subform taxonomic rank.
    case subform
    
    static var hierarchy: [TaxonomicRank] {
        return [
            .origin,//.trunk,
            .superkingdom,.kingdom,.subkingdom,.infrakingdom,
            .superphylum,.phylum,.subphylum,.infraphylum,.microphylum,
            .superclass,.`class`,.subclass,.infraclass,.parvclass,
            .magnorder,.superorder,.order,.suborder,.infraorder,.parvorder,
            .superfamily,.family,.subfamily,
            .supertribe,.tribe,.subtribe,
            .genus,.subgenus,
            .section,.subsection,
            .series,.subseries,
            .species,.subspecies,
            .varietas,.subvarietas,
            .form,.subform
        ]
    }
    
    public static func <(lhs: TaxonomicRank, rhs: TaxonomicRank) -> Bool {
        let hierarchy = TaxonomicRank.hierarchy
        return hierarchy.index(of: lhs)! < hierarchy.index(of: rhs)!
    }
    
    public var description: String {
        return rawValue
    }
    
}
