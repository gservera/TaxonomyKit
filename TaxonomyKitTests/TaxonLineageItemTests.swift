/*
 *  TaxonLineageItemTests.swift
 *  TaxonomyKitTests
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

import XCTest
@testable import TaxonomyKit

final class TaxonLineageItemTests: XCTestCase {
    
    let testItem1 = TaxonLineageItem(identifier: "1234", name: "Quercus", rank: "genus")
    let testItem2 = TaxonLineageItem(identifier: "5678", name: "No rank", rank: "no rank")
    let testItem3 = TaxonLineageItem(identifier: "1234", name: "foofoof", rank: "foofoof")
    
    func testInitialization() {
        
        XCTAssertEqual(testItem1.identifier, "1234", "TaxonLineageItem init failed")
        XCTAssertEqual(testItem1.name, "Quercus", "TaxonLineageItem init failed")
        XCTAssertNotNil(testItem1.rank, "TaxonLineageItem init failed")
        XCTAssertEqual(testItem1.rank!, "genus", "TaxonLineageItem init failed")
        XCTAssertNil(testItem2.rank, "TaxonLineageItem rank should be nil")
        XCTAssertTrue(testItem1.hasRank, "TaxonLineageItem hasRank failed")
        XCTAssertFalse(testItem2.hasRank, "TaxonLineageItem hasRank failed")
    }
    
    func testEqualty() {
        XCTAssertEqual(testItem1, testItem3, "TaxonLineageItem equalty failed")
        XCTAssertNotEqual(testItem1, testItem2, "TaxonLineageItem equalty failed")
        XCTAssertEqual(testItem1.hashValue, testItem3.hashValue)
        XCTAssertNotEqual(testItem1.hashValue, testItem2.hashValue)
    }
    
    func testDescription() {
        XCTAssertEqual(testItem1.description, "genus: Quercus")
        XCTAssertEqual(testItem2.description, "no rank: No rank")
    }
    
    func testDebugDescription() {
        XCTAssertEqual(testItem1.debugDescription, "Taxon Lineage Item ID: 1234, name: Quercus, rank: genus")
        XCTAssertEqual(testItem2.debugDescription, "Taxon Lineage Item ID: 5678, name: No rank, rank: nil")
    }
    
}
