/*
 *  TaxonLineageItem.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 24/09/2016.
 *  Copyright:  © 2016-2017 Guillem Servera (http://github.com/gservera)
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
public struct TaxonLineageItem: TaxonRepresenting {

    public let identifier: TaxonID

    public let name: String

    public let rank: TaxonomicRank?

    
    /// Initializes a new instance using its three defining parameters.
    ///
    /// - Parameters:
    ///   - identifier: The internal NCBI identifier for the record.
    ///   - name: The scientific name of the record.
    ///   - rank: The rank of the record or `nil` if not set.
    internal init(identifier: TaxonID, name: String, rank: TaxonomicRank?) {
        self.identifier = identifier
        self.name = name
        self.rank = rank
    }
    
    
    /// Returns `true` if the `rank` property is set. If `rank` is `nil`, this will return
    /// `false` instead.
    public var hasRank: Bool {
        return rank != nil
    }
}
