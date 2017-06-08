/*
 *  TaxonTreeTests.swift
 *  TaxonomyKitTests
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

import XCTest
@testable import TaxonomyKit

final class LineageTreeTests: XCTestCase {
    
    var testTaxon1 = Taxon(identifier: 1, name: "Test1", rank: .species, geneticCode: "Unspecified", mitochondrialCode: "Unspecified")
    var testTaxon2 = Taxon(identifier: 2, name: "Test2", rank: .species, geneticCode: "Unspecified", mitochondrialCode: "Unspecified")
    var testTaxon3 = Taxon(identifier: 3, name: "Test3", rank: .species, geneticCode: "Unspecified", mitochondrialCode: "Unspecified")
    
    var lineageTree = LineageTree()

    override func setUp() {
        super.setUp()
        lineageTree = LineageTree()
        testTaxon1.lineageItems = [
            TaxonLineageItem(identifier: 101, name: "Eukaryota", rank: .superkingdom),
            TaxonLineageItem(identifier: 201, name: "Viridiplantae", rank: .kingdom),
            TaxonLineageItem(identifier: 301, name: "Streptophyta", rank: .phylum),
            TaxonLineageItem(identifier: 401, name: "Fagales", rank: .order),
            TaxonLineageItem(identifier: 501, name: "Fagaceae", rank: .family),
            TaxonLineageItem(identifier: 601, name: "Quercus", rank: .genus),
        ]
        testTaxon2.lineageItems = [
            TaxonLineageItem(identifier: 101, name: "Eukaryota", rank: .superkingdom),
            TaxonLineageItem(identifier: 202, name: "Metazoa", rank: .kingdom),
            TaxonLineageItem(identifier: 302, name: "Chordata", rank: .phylum),
            TaxonLineageItem(identifier: 402, name: "Primates", rank: .order),
            TaxonLineageItem(identifier: 502, name: "Hominidae", rank: .family),
            TaxonLineageItem(identifier: 602, name: "Homo", rank: .genus),
        ]
        testTaxon3.lineageItems = [
            TaxonLineageItem(identifier: 101, name: "Eukaryota", rank: .superkingdom),
            TaxonLineageItem(identifier: 202, name: "Metazoa", rank: .kingdom),
            TaxonLineageItem(identifier: 302, name: "Chordata", rank: .phylum),
            TaxonLineageItem(identifier: 403, name: "Cyprinodontiformes", rank: .order),
            TaxonLineageItem(identifier: 503, name: "Poeciliidae", rank: .family),
            TaxonLineageItem(identifier: 603, name: "Xiphophorus", rank: .genus),
        ]
    }
    
    override func tearDown() {
        lineageTree = LineageTree()
        super.tearDown()
    }

    func testTreeInsertion() {
        let node2 = lineageTree.register(testTaxon2)
        XCTAssertNotNil(node2)
        XCTAssertEqual(lineageTree.nodeCount, 8)
        
        let node3 = lineageTree.register(testTaxon3)
        XCTAssertNotNil(node3)
        XCTAssertEqual(lineageTree.nodeCount, 12)
    }
    
    func testClosestCommonAncestor() {
        let node2 = lineageTree.register(testTaxon2)
        let node3 = lineageTree.register(testTaxon3)
        do {
            let commonAncestor = try lineageTree.closestCommonAncestor(for: [node2, node3])
            XCTAssertNotEqual(commonAncestor, lineageTree.rootNode)
            XCTAssertEqual(commonAncestor.identifier, 302)
        } catch let error {
            XCTFail("\(error)")
        }
        
        let node1 = lineageTree.register(testTaxon1)
        do {
            let commonAncestor = try lineageTree.closestCommonAncestor(for: [node1, node2, node3])
            XCTAssertNotEqual(commonAncestor, lineageTree.rootNode)
            XCTAssertEqual(commonAncestor.identifier, 101)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
}
