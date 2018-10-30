/*
 *  TaxonRepresenting.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 19/11/2016.
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

import Foundation

/// Any type that encapsulates the minimum data required to identify a record 
/// from the NCBI's Taxonomy database (this is the record ID), plus some basic
/// properties (name and rank) that describe the record.
public protocol TaxonRepresenting: Hashable, CustomStringConvertible {

    /// The internal NCBI identifier for the record.
    var identifier: TaxonID { get }

    /// The scientific name of the record.
    var name: String { get }

    /// The rank of the record or `nil` if the record has no rank.
    var rank: TaxonomicRank? { get }

}

extension TaxonRepresenting {

    /// Returns a Boolean value indicating whether two values are equal. Two
    /// `TaxonRepresenting` values are equal when they have the same identifier.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    /// The hash value. Depends on the identifier.
    public var hashValue: Int {
        return identifier.hashValue
    }

    /// A textual representation of this instance.
    public var description: String {
        return "\(rank?.rawValue ?? "no rank"): \(name)::\(type(of: self))"
    }

}
