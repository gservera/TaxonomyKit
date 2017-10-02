/*
 *  DownloadTests.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 24/09/2016.
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

final class DownloadTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Taxonomy._urlSession = URLSession.shared
    }
    
    
    func testDownloadTaxon() {
        Taxonomy._urlSession = URLSession.shared
        let query = 9606
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: query) { result in
            if case .success(_) = result {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testDownloadUnknownTaxon() {
        Taxonomy._urlSession = URLSession.shared
        let query = 561469854169419684
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: query) { result in
            if case .failure(let error) = result, case .unknownError = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testMalformedXML() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "http://github.com")!,
                            statusCode: 200, httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let data = Data(base64Encoded: "SGVsbG8gd29ybGQ=")
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: -1) { result in
            if case .failure(let error) = result, case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testUnknownResponse() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "http://github.com")!,
                            statusCode: 500, httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let data = Data(base64Encoded: "SGVsbG8gd29ybGQ=")
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: -1) { result in
            if case .failure(let error) = result,
                case .unexpectedResponse(500) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testNetworkError() {
        Taxonomy._urlSession = MockSession()
        let error = NSError(domain: "Custom", code: -1, userInfo: nil)
        MockSession.mockResponse = (nil, nil, error)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: -1) { result in
            if case .failure(let error) = result,
                case .networkError(let nErr as NSError) = error, nErr.code == -1 {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testOddBehavior() {
        Taxonomy._urlSession = MockSession()
        MockSession.mockResponse = (nil, nil, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: -1) { result in
            if case .failure(let error) = result,
                case .unknownError = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testOddBehavior2() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "http://github.com")!,
                            statusCode: 200,
                            httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let wrongXML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><note><to>Tove</to><from>Jani</from><heading>Reminder</heading><body>Don't forget me this weekend!</body></note>"
        let data = wrongXML.data(using: .utf8)
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: -1) { result in
            if case .failure(let error) = result,
                case .unknownError = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testMock() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "http://github.com")!,
                            statusCode: 200,
                            httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><!DOCTYPE eLinkResult PUBLIC \"-//NLM//DTD elink 20101123//EN\" \"https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20101123/elink.dtd\"><TaxaSet><Taxon><TaxId>2</TaxId><ScientificName>Bacteria</ScientificName><OtherNames><GenbankCommonName>eubacteria</GenbankCommonName><BlastName>bacteria; bacteria</BlastName><Synonym>not Bacteria Haeckel 1894</Synonym><Inpart>Monera</Inpart></OtherNames><ParentTaxId>131567</ParentTaxId><Rank>superkingdom</Rank><Division>Bacteria</Division><GeneticCode><GCId>11</GCId><GCName>Bacterial, Archaeal and Plant Plastid</GCName></GeneticCode><MitoGeneticCode><MGCId>0</MGCId><MGCName>Unspecified</MGCName></MitoGeneticCode><Lineage>cellular organisms</Lineage><LineageEx><Taxon><TaxId>131567</TaxId><ScientificName>cellular organisms</ScientificName><Rank>no rank</Rank></Taxon></LineageEx><CreateDate>1995/02/27 09:24:00</CreateDate><UpdateDate>2017/02/16 16:52:33</UpdateDate><PubDate>1993/04/20 01:00:00</PubDate></Taxon></TaxaSet>"
        let data = xml.data(using: .utf8)
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: -1) { result in
            if case .success(let taxon) = result {
                XCTAssertNotNil(taxon)
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testMissingInfoXML() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "http://github.com")!,
                            statusCode: 200,
                            httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let wrongXML = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><!DOCTYPE eLinkResult PUBLIC \"-//NLM//DTD elink 20101123//EN\" \"https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20101123/elink.dtd\"><TaxaSet><Taxon><TaxId>58334</TaxId><LineageEx><Taxon><TaxId>3511</TaxId><ScientificName>Quercus</ScientificName><Rank>genus</Rank></Taxon></LineageEx></Taxon></TaxaSet>"
        let data = wrongXML.data(using: .utf8)
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: -1) { result in
            if case .failure(let error) = result,
                case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testMissingInfoXML2() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "https://gservera.com")!,
                            statusCode: 200,
                            httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let wrongXML = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><!DOCTYPE eLinkResult PUBLIC \"-//NLM//DTD elink 20101123//EN\" \"https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20101123/elink.dtd\"><TaxaSet><Taxon><LineageEx><Taxon><TaxId>3511</TaxId><ScientificName>Quercus</ScientificName><Rank>genus</Rank></Taxon></LineageEx></Taxon></TaxaSet>"
        let data = wrongXML.data(using: .utf8)
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: -1) { result in
            if case .failure(let error) = result,
                case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testMissingInfoXML3() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "https://gservera.com")!,
                            statusCode: 200,
                            httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let wrongXML = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><!DOCTYPE eLinkResult PUBLIC \"-//NLM//DTD elink 20101123//EN\" \"https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20101123/elink.dtd\"><TaxaSet><Taxon><TaxId>3511</TaxId><GeneticCode><GCName>A</GCName></GeneticCode><MitoGeneticCode><MGCName>A</MGCName></MitoGeneticCode><ScientificName>Quercus</ScientificName><Rank>genus</Rank><LineageEx><Taxon><ScientificName>Quercus</ScientificName><Rank>genus</Rank></Taxon></LineageEx></Taxon></TaxaSet>"
        let data = wrongXML.data(using: .utf8)
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadTaxon(withIdentifier: -1) { result in
            if case .failure(let error) = result,
                case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testCancellation() {
        Taxonomy._urlSession = MockSession()
        (Taxonomy._urlSession as! MockSession).wait = 5
        let response =
            HTTPURLResponse(url: URL(string: "https://gservera.com")!,
                            statusCode: 200,
                            httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let data = try! JSONSerialization.data(withJSONObject: ["Any JSON"])
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        let dataTask = Taxonomy.downloadTaxon(withIdentifier: -1) { result in
            XCTFail("Should have been canceled")
            
            } as! MockSession.MockTask
        dataTask.cancel()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 7.0) {
            condition.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
