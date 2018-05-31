/*
 *  LineageAlignmentTests.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 19/11/2016.
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

import XCTest
@testable import TaxonomyKit

final class LineageAlignmentTests: XCTestCase {

    var homoSapiens = Taxon(identifier: 9606, name: "Homo sapiens", rank: .species,
                            geneticCode: "Unspecified", mitochondrialCode: "Unspecified")
    var quercusIlex = Taxon(identifier: 58334, name: "Quercus ilex", rank: .species,
                            geneticCode: "Unspecified", mitochondrialCode: "Unspecified")
    var hiv1 = Taxon(identifier: 11676, name: "Human immunodeficiency virus 1", rank: .species,
                     geneticCode: "Unspecified", mitochondrialCode: "Unspecified")

    var lineageTree = LineageTree()

    override func setUp() {
        super.setUp()
        lineageTree = LineageTree()
        homoSapiens.lineageItems = [
            TaxonLineageItem(identifier: 131567, name: "cellular organisms", rank: nil),
            TaxonLineageItem(identifier: 2579, name: "Eukaryota", rank: .superkingdom),
            TaxonLineageItem(identifier: 33154, name: "Opisthokonta", rank: nil),
            TaxonLineageItem(identifier: 33208, name: "Metazoa", rank: .kingdom),
            TaxonLineageItem(identifier: 6072, name: "Eumetazoa", rank: nil),
            TaxonLineageItem(identifier: 33213, name: "Bilateria", rank: nil),
            TaxonLineageItem(identifier: 33511, name: "Deuterostomia", rank: nil),
            TaxonLineageItem(identifier: 7711, name: "Chordata", rank: .phylum),
            TaxonLineageItem(identifier: 89593, name: "Craniata", rank: .subphylum),
            TaxonLineageItem(identifier: 7742, name: "Vertebrata", rank: nil),
            TaxonLineageItem(identifier: 7776, name: "Gnathostomata", rank: nil),
            TaxonLineageItem(identifier: 117570, name: "Teleostomi", rank: nil),
            TaxonLineageItem(identifier: 117571, name: "Euteleostomi", rank: nil),
            TaxonLineageItem(identifier: 8287, name: "Sarcopterygii", rank: nil),
            TaxonLineageItem(identifier: 1338369, name: "Dipnotetrapodomorpha", rank: nil),
            TaxonLineageItem(identifier: 32523, name: "Tetrapoda", rank: nil),
            TaxonLineageItem(identifier: 32524, name: "Amniota", rank: nil),
            TaxonLineageItem(identifier: 40674, name: "Mammalia", rank: .class),
            TaxonLineageItem(identifier: 32525, name: "Theria", rank: nil),
            TaxonLineageItem(identifier: 9347, name: "Eutheria", rank: nil),
            TaxonLineageItem(identifier: 1437010, name: "Boreoeutheria", rank: nil),
            TaxonLineageItem(identifier: 314146, name: "Euarchontoglires", rank: .superorder),
            TaxonLineageItem(identifier: 9443, name: "Primates", rank: .order),
            TaxonLineageItem(identifier: 376913, name: "Haplorrhini", rank: .suborder),
            TaxonLineageItem(identifier: 314293, name: "Simiiformes", rank: .infraorder),
            TaxonLineageItem(identifier: 9526, name: "Catarrhini", rank: .parvorder),
            TaxonLineageItem(identifier: 314295, name: "Hominoidea", rank: .superfamily),
            TaxonLineageItem(identifier: 9604, name: "Hominidae", rank: .family),
            TaxonLineageItem(identifier: 207598, name: "Homininae", rank: .subfamily),
            TaxonLineageItem(identifier: 9605, name: "Homo", rank: .genus)
        ]
        quercusIlex.lineageItems = [
            TaxonLineageItem(identifier: 131567, name: "cellular organisms", rank: nil),
            TaxonLineageItem(identifier: 2579, name: "Eukaryota", rank: .superkingdom),
            TaxonLineageItem(identifier: 33090, name: "Viridiplantae", rank: .kingdom),
            TaxonLineageItem(identifier: 35493, name: "Streptophyta", rank: .phylum),
            TaxonLineageItem(identifier: 131221, name: "Streptophytina", rank: .subphylum),
            TaxonLineageItem(identifier: 3193, name: "Embryophyta", rank: nil),
            TaxonLineageItem(identifier: 58023, name: "Tracheophyta", rank: nil),
            TaxonLineageItem(identifier: 78536, name: "Euphyllophyta", rank: nil),
            TaxonLineageItem(identifier: 58024, name: "Spermatophyta", rank: nil),
            TaxonLineageItem(identifier: 3398, name: "Magnoliophyta", rank: nil),
            TaxonLineageItem(identifier: 1437183, name: "Mesangiospermae", rank: nil),
            TaxonLineageItem(identifier: 71240, name: "eudicotyledons", rank: nil),
            TaxonLineageItem(identifier: 91827, name: "Gunneridae", rank: nil),
            TaxonLineageItem(identifier: 1437201, name: "Pentapetaleae", rank: nil),
            TaxonLineageItem(identifier: 71275, name: "rosids", rank: .subclass),
            TaxonLineageItem(identifier: 91835, name: "fabids", rank: nil),
            TaxonLineageItem(identifier: 3502, name: "Fagales", rank: .order),
            TaxonLineageItem(identifier: 3503, name: "Fagaceae", rank: .family),
            TaxonLineageItem(identifier: 3511, name: "Quercus", rank: .genus)
        ]
        hiv1.lineageItems = [
            TaxonLineageItem(identifier: 10239, name: "Viruses", rank: .superkingdom),
            TaxonLineageItem(identifier: 35268, name: "Retro-transcribing viruses", rank: nil),
            TaxonLineageItem(identifier: 11632, name: "Retroviridae", rank: .family),
            TaxonLineageItem(identifier: 327045, name: "Orthoretrovirinae", rank: .subfamily),
            TaxonLineageItem(identifier: 11646, name: "Lentivirus", rank: .genus),
            TaxonLineageItem(identifier: 11652, name: "Primate lentivirus group", rank: nil)
        ]
    }

    override func tearDown() {
        lineageTree = LineageTree()
        super.tearDown()
    }

    func testCleanedUpAlignment() {
        _ = lineageTree.register(homoSapiens)
        _ = lineageTree.register(quercusIlex)
        _ = lineageTree.register(hiv1)
        let alignment = LineageAlignment(lineageTree: lineageTree)
        let cleanedUp = alignment.cleanedUp
        var expectedCleanedUpAlignment: [[String]] = [
            ["origin"],
            ["cellular organisms"],
            ["Viruses", "Eukaryota"],
            ["Retro-transcribing viruses", "Opisthokonta"],
            ["Metazoa", "Viridiplantae"],
            ["Eumetazoa"],
            ["Bilateria"],
            ["Deuterostomia"],
            ["Chordata", "Streptophyta"],
            ["Craniata", "Streptophytina"],
            ["Vertebrata", "Embryophyta"],
            ["Gnathostomata", "Tracheophyta"],
            ["Teleostomi", "Euphyllophyta"],
            ["Euteleostomi", "Spermatophyta"],
            ["Sarcopterygii", "Magnoliophyta"],
            ["Dipnotetrapodomorpha", "Mesangiospermae"],
            ["Tetrapoda", "eudicotyledons"],
            ["Amniota", "Gunneridae"],
            ["Pentapetaleae"],
            ["Mammalia"],
            ["Theria"],
            ["Eutheria"],
            ["Boreoeutheria"],
            ["rosids"],
            ["fabids"],
            ["Euarchontoglires"],
            ["Primates", "Fagales"],
            ["Haplorrhini"],
            ["Simiiformes"],
            ["Catarrhini"],
            ["Hominoidea"],
            ["Retroviridae", "Hominidae", "Fagaceae"],
            ["Orthoretrovirinae", "Homininae"],
            ["Lentivirus", "Homo", "Quercus"],
            ["Primate lentivirus group"],
            ["Human immunodeficiency virus 1", "Homo sapiens", "Quercus ilex"]
        ]
        XCTAssertEqual(cleanedUp.count, expectedCleanedUpAlignment.count,
                       "Expected \(expectedCleanedUpAlignment.count) columns in alignment, found \(cleanedUp.count)")
        for (idx, column) in expectedCleanedUpAlignment.enumerated() {
            XCTAssertEqual(cleanedUp[i].count, column.count, """
                                                             Expected \(expectedCleanedUpAlignment[i].count) rows in
                                                             alignment column \(i), found \(cleanedUp[i].count)
                                                             """)
            for (row, name) in column.enumerated() {
                let foundName = cleanedUp[i].cells[r].node.name
                XCTAssertEqual(foundName, name, "Expected \(name) at alignment \(idx):\(row). Found \(foundName) instead.")
            }
        }
    }

    func testColumnAndCellSpan() {
        _ = lineageTree.register(homoSapiens)
        _ = lineageTree.register(quercusIlex)
        _ = lineageTree.register(hiv1)
        let alignment = LineageAlignment(lineageTree: lineageTree)
        let cleanedUp = alignment.cleanedUp
        XCTAssertEqual(cleanedUp[0].cells[0].span, 3)
        XCTAssertEqual(cleanedUp[35].cells[0].span, 1)
        XCTAssertEqual(cleanedUp[35].cells[1].span, 1)
        XCTAssertEqual(cleanedUp[35].cells[2].span, 1)
        XCTAssertEqual(cleanedUp[2].cells[0].span, 1)
        XCTAssertEqual(cleanedUp[2].cells[1].span, 2)
        XCTAssertEqual(cleanedUp[0].span, 3)
        XCTAssertEqual(cleanedUp[35].span, 3)
    }

    func testDescription() {
        _ = lineageTree.register(homoSapiens)
        _ = lineageTree.register(quercusIlex)
        _ = lineageTree.register(hiv1)
        let alignment = LineageAlignment(lineageTree: lineageTree)
        let cleanedUp = alignment.cleanedUp
        XCTAssertEqual(cleanedUp[35].cells[1].debugDescription, "<9606:Homo sapiens@1(1)>")
        XCTAssertEqual(cleanedUp[35].debugDescription,
                       "[3:species]: Human immunodeficiency virus 1, Homo sapiens, Quercus ilex")
        XCTAssertEqual(cleanedUp[1].debugDescription, "[1:no rank]: cellular organisms")
    }
}
