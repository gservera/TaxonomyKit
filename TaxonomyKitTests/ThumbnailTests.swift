/*
 *  ThumbnailTests.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 09/04/2017.
 *  Copyright:  © 2017 Guillem Servera (https://github.com/gservera)
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

final class ThumbnailTests: XCTestCase {
    
    let existingTaxon = Taxon(identifier: "", name: "Quercus ilex", rank: nil, geneticCode: "", mitochondrialCode: "")
    let nonExistingTaxon = Taxon(identifier: "", name: "angpadgnpdajfgn", rank: nil, geneticCode: "", mitochondrialCode: "")
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testValidTaxon() {
        Taxonomy._urlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        Taxonomy.retrieveWikipediaThumbnail(for: existingTaxon, width: 500, language: WikipediaLanguage(locale: Locale(identifier: "en-US"))) { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testValidPageID() {
        Taxonomy._urlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        Taxonomy.retrieveWikipediaThumbnail(for: "344877", width: 500, language: WikipediaLanguage(locale: Locale(identifier: "en-US"))) { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testValidTaxonWithFakeCustomLocale() {
        Taxonomy._urlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        let customLocale = WikipediaLanguage(locale: Locale(identifier: "."))
        Taxonomy.retrieveWikipediaAbstract(for: existingTaxon, language: customLocale) { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                XCTAssertEqual(wrapper!.language.subdomain, "en")
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testInvalidTaxon() {
        Taxonomy._urlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        Taxonomy.retrieveWikipediaThumbnail(for: nonExistingTaxon, width: 500) { result in
            if case .success(let wrapper) = result {
                XCTAssertNil(wrapper)
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testFakeMalformedJSON() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "https://gservera.com")!,
                            statusCode: 200, httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let data = Data(base64Encoded: "SGVsbG8gd29ybGQ=")
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.retrieveWikipediaThumbnail(for: existingTaxon, width: 500) { result in
            if case .failure(let error) = result, case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testUnknownResponse() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "https://gservera.com")!,
                            statusCode: 500, httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let data = Data(base64Encoded: "SGVsbG8gd29ybGQ=")
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.retrieveWikipediaThumbnail(for: existingTaxon, width: 500) { result in
            if case .failure(let error) = result,
                case .unexpectedResponseError(500) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testNetworkError() {
        Taxonomy._urlSession = MockSession()
        let error = NSError(domain: "Custom", code: -1, userInfo: nil)
        MockSession.mockResponse = (nil, nil, error)
        let condition = expectation(description: "Finished")
        Taxonomy.retrieveWikipediaThumbnail(for: existingTaxon, width: 500) { result in
            if case .failure(let error) = result,
                case .networkError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testOddBehavior() {
        Taxonomy._urlSession = MockSession()
        MockSession.mockResponse = (nil, nil, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.retrieveWikipediaThumbnail(for: existingTaxon, width: 500) { result in
            if case .failure(let error) = result,
                case .unknownError() = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testOddBehavior2() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "https://gservera.com")!,
                            statusCode: 200,
                            httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let data = try! JSONSerialization.data(withJSONObject: ["Any JSON"])
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.retrieveWikipediaThumbnail(for: existingTaxon, width: 500) { result in
            if case .failure(let error) = result,
                case .unknownError() = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testOddBehavior3() {
        Taxonomy._urlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "https://gservera.com")!,
                            statusCode: 200,
                            httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let data = try! JSONSerialization.data(withJSONObject: ["query":["pages":[:]]])
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.retrieveWikipediaThumbnail(for: existingTaxon, width: 500) { result in
            if case .failure(let error) = result,
                case .unknownError() = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 1000)
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
        let dataTask = Taxonomy.retrieveWikipediaThumbnail(for: existingTaxon, width: 500) { result in
            XCTFail("Should have been canceled")
            
            } as! MockSession.MockTask
        dataTask.cancel()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 7.0) {
            condition.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    

}
