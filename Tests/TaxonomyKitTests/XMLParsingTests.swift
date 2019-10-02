import Foundation
import XCTest
@testable import TaxonomyKit

// swiftlint:disable line_length

final class NCBIXMLTests: XCTestCase {

    private static var sampleDocumentContents = """
<?xml version="1.0" ?>
<!DOCTYPE TaxaSet PUBLIC "-//NLM//DTD Taxon, 14th January 2002//EN" "https://www.ncbi.nlm.nih.gov/entrez/query/DTD/taxon.dtd">
<TaxaSet><Taxon>
    <TaxId>58334</TaxId>
    <ScientificName>Quercus ilex</ScientificName>
    <OtherNames>
        <CommonName>holly oak</CommonName>
        <Name>
            <ClassCDE>authority</ClassCDE>
            <DispName>Quercus ilex L.</DispName>
        </Name>
    </OtherNames>
    <ParentTaxId>3511</ParentTaxId>
    <Rank>species</Rank>
    <Division></Division>
    <GeneticCode>
        <GCId>1</GCId>
        <GCName>Standard</GCName>
    </GeneticCode>
    <MitoGeneticCode>
        <MGCId>1</MGCId>
        <MGCName>Standard</MGCName>
    </MitoGeneticCode>
    <Lineage>cellular organisms; Eukaryota; Viridiplantae; Streptophyta; Streptophytina; Embryophyta; Tracheophyta; Euphyllophyta; Spermatophyta; Magnoliophyta; Mesangiospermae; eudicotyledons; Gunneridae; Pentapetalae; rosids; fabids; Fagales; Fagaceae; Quercus</Lineage>
    <LineageEx>
        <Taxon>
            <TaxId>131567</TaxId>
            <ScientificName>cellular organisms</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>2759</TaxId>
            <ScientificName>Eukaryota</ScientificName>
            <Rank>superkingdom</Rank>
        </Taxon>
        <Taxon>
            <TaxId>33090</TaxId>
            <ScientificName>Viridiplantae</ScientificName>
            <Rank>kingdom</Rank>
        </Taxon>
        <Taxon>
            <TaxId>35493</TaxId>
            <ScientificName>Streptophyta</ScientificName>
            <Rank>phylum</Rank>
        </Taxon>
        <Taxon>
            <TaxId>131221</TaxId>
            <ScientificName>Streptophytina</ScientificName>
            <Rank>subphylum</Rank>
        </Taxon>
        <Taxon>
            <TaxId>3193</TaxId>
            <ScientificName>Embryophyta</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>58023</TaxId>
            <ScientificName>Tracheophyta</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>78536</TaxId>
            <ScientificName>Euphyllophyta</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>58024</TaxId>
            <ScientificName>Spermatophyta</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>3398</TaxId>
            <ScientificName>Magnoliophyta</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>1437183</TaxId>
            <ScientificName>Mesangiospermae</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>71240</TaxId>
            <ScientificName>eudicotyledons</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>91827</TaxId>
            <ScientificName>Gunneridae</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>1437201</TaxId>
            <ScientificName>Pentapetalae</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>71275</TaxId>
            <ScientificName>rosids</ScientificName>
            <Rank>subclass</Rank>
        </Taxon>
        <Taxon>
            <TaxId>91835</TaxId>
            <ScientificName>fabids</ScientificName>
            <Rank>no rank</Rank>
        </Taxon>
        <Taxon>
            <TaxId>3502</TaxId>
            <ScientificName>Fagales</ScientificName>
            <Rank>order</Rank>
        </Taxon>
        <Taxon>
            <TaxId>3503</TaxId>
            <ScientificName>Fagaceae</ScientificName>
            <Rank>family</Rank>
        </Taxon>
        <Taxon>
            <TaxId>3511</TaxId>
            <ScientificName>Quercus</ScientificName>
            <Rank>genus</Rank>
        </Taxon>
    </LineageEx>
    <Properties>
        <Property>
            <PropName>pgcode</PropName>
            <PropValueInt>11</PropValueInt>
        </Property>
    </Properties>
    <CreateDate>1997/04/02 16:21:00</CreateDate>
    <UpdateDate>2017/06/14 10:56:24</UpdateDate>
    <PubDate>1997/04/10 01:00:00</PubDate>
</Taxon>
</TaxaSet>
"""

    var sampleDocument: NCBIXMLDocument = {
        do {
            let sampleFileContents = NCBIXMLTests.sampleDocumentContents.data(using: .utf8)!
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
        if sampleDocument.root["ducks"]["duck"].all.first != nil {
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
        let sampleFileContents = NCBIXMLTests.sampleDocumentContents.data(using: .utf8)!
        self.measure {
            _ = try? NCBIXMLDocument(xml: sampleFileContents)
        }
    }
}
