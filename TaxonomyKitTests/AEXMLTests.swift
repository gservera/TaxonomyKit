import Foundation
import XCTest
@testable import TaxonomyKit

final class NCBIXMLTests: XCTestCase {

    var sampleDocument: NCBIXMLDocument = {
        let bundle = Bundle(for: NCBIXMLTests.self)
        let sampleFileUrl = bundle.url(forResource: "DownloadedTaxonSample", withExtension: "xml")!
        do {
            let sampleFileContents = try Data(contentsOf: sampleFileUrl)
            return try NCBIXMLDocument(xml: sampleFileContents)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }()

    // MARK: - XML Read

    func testRootElement() {
        XCTAssertEqual(sampleDocument.root.name, "TaxaSet", "Should be able to find root element.")
    }

    func testParentElement() {
        XCTAssertEqual(sampleDocument.root["Taxon"].parent!.name, "TaxaSet", "Should be able to find parent element.")
    }

    func testChildrenElements() {
        var count = 0
        for _ in sampleDocument.root.children {
            count += 1
        }
        XCTAssertEqual(count, 1, "Should be able to iterate children elements")
    }

    func testName() {
        let secondChildElementName = sampleDocument.root.children[0].children[0].name
        XCTAssertEqual(secondChildElementName, "TaxId", "Should be able to return element name.")
    }

    func testValue() {
        let firstTaxon = sampleDocument.root["Taxon"]

        let firstTaxonId = firstTaxon["TaxId"].value!
        XCTAssertEqual(firstTaxonId, "58334", "Should be able to return element value as optional string.")

        let firstElementWithoutValue = firstTaxon["NOVALUEELELEMENT"].value
        XCTAssertNil(firstElementWithoutValue, "Should be able to have nil value.")

        let firstEmptyElement = firstTaxon["Division"].value
        XCTAssertNil(firstEmptyElement, "Should be able to have nil value.")
    }

    func testNotExistingElement() {
        // non-optional
        XCTAssertNotNil(sampleDocument.root["ducks"]["duck"].error, "Should contain error inside nonexistin element.")
        XCTAssertEqual(sampleDocument.root["ducks"]["duck"].error, .elementNotFound, "Should have ElementNotFound.")
        XCTAssertEqual(sampleDocument.root["ducks"]["duck"].value, nil, "Should have empty value.")

        // optional
        if nil != sampleDocument.root["ducks"]["duck"].all.first {
            XCTFail("Should not be able to find ducks here.")
        } else {
            XCTAssert(true)
        }
    }

    func testAllElements() {
        var count = 0
        let lineageItems = sampleDocument.root["Taxon"]["LineageEx"]["Taxon"].all
        for item in lineageItems {
            XCTAssertNotNil(item.parent, "Each child element should have its parent element.")
            count += 1
        }
        XCTAssertEqual(count, 19, "Should be able to iterate all elements")
    }

    func testFirstElement() {
        let rankElement = sampleDocument.root["Taxon"]["Rank"]
        let firstRankExpectedValue = "species"

        // non-optional
        XCTAssertEqual(rankElement.value, firstRankExpectedValue, "Should be able to find 1st element as non-optional.")

        // optional
        if let rank = rankElement.all.first {
            XCTAssertEqual(rank.value, firstRankExpectedValue, "Should be able to find the first element as optional.")
        } else {
            XCTFail("Should be able to find the first element.")
        }
    }

    func testLastElement() {
        if let item = sampleDocument.root["Taxon"]["LineageEx"]["Taxon"].all.last {
            XCTAssertEqual(item["Rank"].value, "genus", "Should be able to find the last element.")
        } else {
            XCTFail("Should be able to find the last element.")
        }
    }

    func testCountElements() {
        let lineageCount = sampleDocument.root["Taxon"]["LineageEx"]["Taxon"].all.count
        XCTAssertEqual(lineageCount, 19, "Should be able to count elements.")
    }

    // MARK: - XML Write

    func testAddChild() {
        let ducks = sampleDocument.root.addChild(name: "ducks")
        ducks.addChild(name: "duck", value: "Donald")
        ducks.addChild(name: "duck", value: "Daisy")
        ducks.addChild(name: "duck", value: "Scrooge")

        let animalsCount = sampleDocument.root.children.count
        XCTAssertEqual(animalsCount, 2, "Should be able to add child elements to an element.")
        XCTAssertEqual(sampleDocument.root["ducks"]["duck"].all.last!.value!, "Scrooge", "Should be able to iterate.")
    }

    // MARK: - XML Parse Performance

    func testReadXMLPerformance() {
        let bundle = Bundle(for: NCBIXMLTests.self)
        let sampleFileUrl = bundle.url(forResource: "DownloadedTaxonSample", withExtension: "xml")!
        do {
            let sampleFileContents = try Data(contentsOf: sampleFileUrl)
            self.measure {
                _ = try? NCBIXMLDocument(xml: sampleFileContents)
            }
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
}
