/*
 *  DownloadTests.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 24/09/2016.
 *  Copyright:  © 2016-2018 Guillem Servera (https://github.com/gservera)
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

final class DownloadTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        Taxonomy.internalUrlSession = Taxonomy.makeUrlSession()
    }
    
    override func setUp() {
        super.setUp() /// Wait 1 second to avoid NCBI too many requests error (429)
        sleep(1)
    }

    func testDownloadMultipleTaxa() {
        Taxonomy.internalUrlSession = Taxonomy.makeUrlSession()
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [9606, 2]) { result in
            if case .success(let taxa) = result {
                if taxa.count == 2 {
                    condition.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testDownloadUnknownTaxon() {
        Taxonomy.internalUrlSession = Taxonomy.makeUrlSession()
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [561469869]) { result in
            if case .failure(let error) = result, case .unknownError = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testMalformedXML() {
        Taxonomy.internalUrlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "https://any.com")!, statusCode: 200, httpVersion: "1.1",
                            headerFields: [:])
        let data = Data(base64Encoded: "SGVsbG8gd29ybGQ=")
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [-1]) { result in
            if case .failure(let error) = result, case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testUnknownResponse() {
        Taxonomy.internalUrlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "https://github.com")!, statusCode: 500, httpVersion: "1.1",
                            headerFields: [:])!
        let data = Data(base64Encoded: "SGVsbG8gd29ybGQ=")
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [-1]) { result in
            if case .failure(let error) = result, case .unexpectedResponse(500) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testNetworkError() {
        Taxonomy.internalUrlSession = MockSession()
        MockSession.mockResponse = (nil, nil, NSError(domain: "Custom", code: -1, userInfo: nil))
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [-1]) { result in
            if case .failure(let error) = result, case .networkError(let nErr as NSError) = error, nErr.code == -1 {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testOddBehavior() {
        Taxonomy.internalUrlSession = MockSession()
        MockSession.mockResponse = (nil, nil, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [-1]) { result in
            if case .failure(let error) = result, case .unknownError = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testOddBehavior2() {
        Taxonomy.internalUrlSession = MockSession()
        let anyUrl = URL(string: "https://gservera.com")!
        let response = HTTPURLResponse(url: anyUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        let wrongXML = """
                       <?xml version="1.0" encoding="UTF-8"?>
                            <note><to>Tove</to><from>Jani</from><heading>Reminder</heading><body>Don't!</body></note>
                       """
        let data = wrongXML.data(using: .utf8)
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [-1]) { result in
            if case .failure(let error) = result, case .unknownError = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testMock() {
        Taxonomy.internalUrlSession = MockSession()
        let anyUrl = URL(string: "https://gservera.com")!
        let response = HTTPURLResponse(url: anyUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        let xml = """
                  <?xml version="1.0" encoding="UTF-8" ?>
                    <!DOCTYPE eLinkResult PUBLIC "-//NLM//DTD elink 20101123//EN"
                                                 "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20101123/elink.dtd">
                    <TaxaSet>
                        <Taxon>
                            <TaxId>2</TaxId>
                            <ScientificName>Bacteria</ScientificName>
                            <OtherNames>
                                <GenbankCommonName>eubacteria</GenbankCommonName>
                                <Synonym>not Bacteria Haeckel 1894</Synonym>
                            </OtherNames>
                            <GeneticCode><GCId>1</GCId><GCName>Standard</GCName></GeneticCode>
                            <MitoGeneticCode><MGCId>1</MGCId><MGCName>Standard</MGCName></MitoGeneticCode>
                            <Rank>superkingdom</Rank>
                            <LineageEx></LineageEx>
                            <ParentTaxId>0</ParentTaxId>
                        </Taxon>
                    </TaxaSet>
                  """
        MockSession.mockResponse = (xml.data(using: .utf8), response, nil)
        let condition = expectation(description: "Taxon creation from mock XML data")
        Taxonomy.downloadTaxa(identifiers: [-1]) { result in
            if case .success(let taxa) = result {
                XCTAssertTrue(taxa.count == 1)
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testMissingInfoXML() {
        Taxonomy.internalUrlSession = MockSession()
        let anyUrl = URL(string: "https://gservera.com")!
        let response = HTTPURLResponse(url: anyUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        let wrongXML = """
                        <?xml version="1.0" encoding="UTF-8" ?>
                        <!DOCTYPE eLinkResult PUBLIC "-//NLM//DTD elink 20101123//EN"
                                                     "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20101123/elink.dtd">
                        <TaxaSet>
                            <Taxon>
                                <TaxId>58334</TaxId>
                                <LineageEx>
                                    <Taxon><TaxId>3511</TaxId><Rank>genus</Rank></Taxon>
                                </LineageEx>
                            </Taxon>
                        </TaxaSet>
                    """
        let data = wrongXML.data(using: .utf8)
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [-1]) { result in
            if case .failure(let error) = result, case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testMissingInfoXML2() {
        Taxonomy.internalUrlSession = MockSession()
        let anyUrl = URL(string: "https://gservera.com")!
        let response = HTTPURLResponse(url: anyUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        let wrongXML = """
                      <?xml version="1.0" encoding="UTF-8" ?>
                        <!DOCTYPE eLinkResult PUBLIC "-//NLM//DTD elink 20101123//EN"
                                                     "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20101123/elink.dtd">
                        <TaxaSet>
                            <Taxon>
                                <LineageEx>
                                    <Taxon>
                                        <TaxId>3511</TaxId><ScientificName>Quercus</ScientificName><Rank>genus</Rank>
                                    </Taxon>
                                </LineageEx>
                            </Taxon>
                        </TaxaSet>
                      """
        let data = wrongXML.data(using: .utf8)
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [-1]) { result in
            if case .failure(let error) = result, case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testMissingInfoXML3() {
        Taxonomy.internalUrlSession = MockSession()
        let anyUrl = URL(string: "https://gservera.com")!
        let response = HTTPURLResponse(url: anyUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        let wrongXML = """
                        <?xml version="1.0" encoding="UTF-8" ?>
                        <!DOCTYPE eLinkResult PUBLIC "-//NLM//DTD elink 20101123//EN"
                                                     "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20101123/elink.dtd">
                        <TaxaSet>
                            <Taxon>
                                <TaxId>3511</TaxId>
                                <MitoGeneticCode><MGCName>A</MGCName></MitoGeneticCode>
                                <ScientificName>Quercus</ScientificName>
                                <Rank>genus</Rank>
                                <LineageEx>
                                    <Taxon><ScientificName>Quercus</ScientificName><Rank>genus</Rank></Taxon>
                                </LineageEx>
                            </Taxon>
                        </TaxaSet>
                       """
        let data = wrongXML.data(using: .utf8)
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [-1]) { result in
            if case .failure(let error) = result, case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testCancellation() {
        let mockSession = MockSession.shared
        mockSession.wait = 5
        Taxonomy.internalUrlSession = mockSession
        let anyUrl = URL(string: "https://gservera.com")!
        let response = HTTPURLResponse(url: anyUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        do {
            let data = try JSONEncoder().encode(["Any JSON"])
            MockSession.mockResponse = (data, response, nil)
        } catch let error {
            XCTFail("Test implementation fault. \(error)")
        }
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxa(identifiers: [-1]) { _ in
            XCTFail("Should have been canceled")
        }.cancel()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 7.0) {
            condition.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
