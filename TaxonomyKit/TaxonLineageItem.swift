/*
 *  TaxonLineageItem.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 24/09/2016.
 *  Copyright:  © 2016 Guillem Servera (http://github.com/gservera)
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


/// The `TaxonLineageItem` is a value that describes an element from a retrieved
/// taxon's lineage.
public struct TaxonLineageItem {
    
    /// The internal NCBI identifier for the record.
    public let identifier: TaxonID
    
    /// The scientific name of the record.
    public let name: String
    
    /// The rank of the record or `nil` if the record has no rank.
    public let rank: String?
    
    
    /// Initializes a new `TaxonLineageItem` using its three defining parameters.
    ///
    /// - parameter identifier: The internal NCBI identifier for the record.
    /// - parameter name:       The scientific name of the record.
    /// - parameter rank:       The rank of the record. If you pass a 'no rank' string, the 
    ///                         `rank` property will be set to `nil`.
    ///
    /// - returns: The initialized `TaxonLineageItem` struct.
    public init(identifier: TaxonID, name: String, rank: String) {
        self.identifier = identifier
        self.name = name
        self.rank = (rank == "no rank") ? nil : rank
    }
    
    
    /// Returns `true` if the `rank` property is set. If `rank` is `nil`, this will return
    /// `false` instead.
    public var hasRank: Bool {
        return rank != nil
    }
}


extension TaxonLineageItem: Equatable, Hashable,
                            CustomStringConvertible, CustomDebugStringConvertible {
    
    // TaxonLineageItem structs are considered equal when they have the same NCBI record ID.
    public static func ==(lhs: TaxonLineageItem, rhs: TaxonLineageItem) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public var hashValue: Int {
        return identifier.hashValue
    }
    
    public var description: String {
        return "\(rank ?? "no rank"): \(name)"
    }
    
    public var debugDescription: String {
        return "Taxon Lineage Item ID: \(identifier), name: \(name), rank: \(rank ?? "nil")"
    }
}
