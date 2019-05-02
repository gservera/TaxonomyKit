/*
 *  TaxonTests.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 24/09/2016.
 *  Copyright:  © 2016-2019 Guillem Servera (https://github.com/gservera)
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

final class TaxonTests: XCTestCase {

    var test1 = Taxon(identifier: 1234, name: "Quercus", rank: .genus,
                      geneticCode: "Standard", mitochondrialCode: "Standard")
    var test2 = Taxon(identifier: 5678, name: "No rank", rank: nil,
                      geneticCode: "Standard", mitochondrialCode: "Unspecified")
    var test3 = Taxon(identifier: 1234, name: "foofoof", rank: nil,
                      geneticCode: "Standard", mitochondrialCode: "Standard")

    override func setUp() {
        super.setUp()
        test3.commonNames = ["holly oak"]
        test3.genbankCommonName = "holly oak"
        test3.synonyms = ["cool oak"]
        test3.lineageItems = [TaxonLineageItem(identifier: 111, name: "any", rank: nil)]
        test3.parentIdentifier = 2
    }

    func testInitialization() {
        XCTAssertEqual(test1.identifier, 1234, "Taxon init failed")
        XCTAssertEqual(test1.name, "Quercus", "Taxon init failed")
        XCTAssertNotNil(test1.rank, "Taxon init failed")
        XCTAssertEqual(test1.rank!, .genus, "Taxon init failed")
        XCTAssertNil(test2.rank, "Taxon rank should be nil")

        XCTAssertEqual(test1.geneticCode, "Standard", "Taxon init failed")

        XCTAssertNotNil(test1.mitochondrialCode, "Taxon init failed")
        XCTAssertEqual(test1.mitochondrialCode!, "Standard", "Taxon init failed")
        XCTAssertNil(test2.mitochondrialCode, "Taxon mitochondrialCode should be nil")

        XCTAssertTrue(test1.hasRank, "Taxon hasRank failed")
        XCTAssertFalse(test2.hasRank, "Taxon hasRank failed")

        XCTAssertTrue(test1.lineageItems.isEmpty, "Taxon init failed")
        XCTAssertTrue(test3.lineageItems.count == 1, "Taxon init failed")

        XCTAssertEqual(test3.commonNames, ["holly oak"], "Taxon init failed")
        XCTAssertEqual(test3.genbankCommonName!, "holly oak", "Taxon init failed")
        XCTAssertEqual(test3.synonyms.count, 1, "Taxon init failed")
        XCTAssertEqual(test3.parentIdentifier, 2, "Taxon parent identifier not set")
    }

    func testEqualty() {
        XCTAssertEqual(test1, test3, "Taxon equalty failed")
        XCTAssertNotEqual(test1, test2, "Taxon equalty failed")
        XCTAssertEqual(test1.hashValue, test3.hashValue)
        XCTAssertNotEqual(test1.hashValue, test2.hashValue)
    }

    func testDescription() {
        XCTAssertEqual(test1.description, "genus: Quercus::Taxon")
        XCTAssertEqual(test2.description, "no rank: No rank::Taxon")
    }

    func testURLGeneration() {
        let url = URL(string: "https://ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=1234")!
        XCTAssertEqual(test1.url, url, "Taxon URL Generation failed")
    }

}
