/*
 *  WikipediaTests.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 27/02/2017.
 *  Copyright:  © 2017 Guillem Servera (http://github.com/gservera)
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

final class WikipediaAbstractTests: XCTestCase {

    let existingTaxon = Taxon(identifier: -1, name: "Quercus ilex", rank: nil, geneticCode: "", mitochondrialCode: "")
    let nonExisting = Taxon(identifier: -1, name: "angpadgnpdajfgn", rank: nil, geneticCode: "", mitochondrialCode: "")

    func testValidTaxon() {
        Taxonomy.internalUrlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        let wikipedia = Wikipedia(language: WikipediaLanguage(locale: Locale(identifier: "en-US")))
        wikipedia.retrieveAbstract(for: existingTaxon) { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testValidPageID() {
        Taxonomy.internalUrlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        let wikipedia = Wikipedia(language: WikipediaLanguage(locale: Locale(identifier: "en-US")))
        wikipedia.retrieveAbstract(for: "344877") { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testValidTaxonWithCustomLocale() {
        Taxonomy.internalUrlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        let customLocale = WikipediaLanguage(locale: Locale(identifier: "ca-ES"))
        let wikipedia = Wikipedia(language: customLocale)
        wikipedia.retrieveAbstract(for: existingTaxon) { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                XCTAssertEqual(wrapper!.language.subdomain, "ca")
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testValidTaxonWithFakeCustomLocale() {
        Taxonomy.internalUrlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        let customLocale = WikipediaLanguage(locale: Locale(identifier: "."))
        let wikipedia = Wikipedia(language: customLocale)
        wikipedia.retrieveAbstract(for: existingTaxon) { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                XCTAssertEqual(wrapper!.language.subdomain, "en")
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testInvalidTaxon() {
        Taxonomy.internalUrlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        let wikipedia = Wikipedia(language: WikipediaLanguage(locale: Locale(identifier: "en-US")))
        wikipedia.retrieveAbstract(for: nonExisting) { result in
            if case .success(let wrapper) = result {
                XCTAssertNil(wrapper)
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testFakeMalformedJSON() {
        Taxonomy.internalUrlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "https://gservera.com")!,
                            statusCode: 200, httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let data = Data(base64Encoded: "SGVsbG8gd29ybGQ=")
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        let wikipedia = Wikipedia(language: WikipediaLanguage(locale: Locale(identifier: "en-US")))
        wikipedia.retrieveAbstract(for: existingTaxon) { result in
            if case .failure(let error) = result, case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testUnknownResponse() {
        Taxonomy.internalUrlSession = MockSession()
        let response =
            HTTPURLResponse(url: URL(string: "https://gservera.com")!,
                            statusCode: 500, httpVersion: "1.1",
                            headerFields: [:])! as URLResponse
        let data = Data(base64Encoded: "SGVsbG8gd29ybGQ=")
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        let wikipedia = Wikipedia(language: WikipediaLanguage(locale: Locale(identifier: "en-US")))
        wikipedia.retrieveAbstract(for: existingTaxon) { result in
            if case .failure(let error) = result, case .unexpectedResponse(500) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testNetworkError() {
        Taxonomy.internalUrlSession = MockSession()
        let error = NSError(domain: "Custom", code: -1, userInfo: nil)
        MockSession.mockResponse = (nil, nil, error)
        let condition = expectation(description: "Finished")
        let wikipedia = Wikipedia(language: WikipediaLanguage(locale: Locale(identifier: "en-US")))
        wikipedia.retrieveAbstract(for: existingTaxon) { result in
            if case .failure(let error) = result, case .networkError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testOddBehavior() {
        Taxonomy.internalUrlSession = MockSession()
        MockSession.mockResponse = (nil, nil, nil)
        let condition = expectation(description: "Finished")
        let wikipedia = Wikipedia(language: WikipediaLanguage(locale: Locale(identifier: "en-US")))
        wikipedia.retrieveAbstract(for: existingTaxon) { result in
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
        do {
            let data = try JSONEncoder().encode(["Any JSON"])
            MockSession.mockResponse = (data, response, nil)
        } catch let error {
            XCTFail("Test implementation fault. \(error)")
        }
        let condition = expectation(description: "Finished")
        let wikipedia = Wikipedia(language: WikipediaLanguage(locale: Locale(identifier: "en-US")))
        wikipedia.retrieveAbstract(for: existingTaxon) { result in
            if case .failure(let error) = result, case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testOddBehavior3() {
        Taxonomy.internalUrlSession = MockSession()
        let anyUrl = URL(string: "https://gservera.com")!
        let response = HTTPURLResponse(url: anyUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        do {
            let data = try JSONEncoder().encode(["query": ["pages": ([:] as [String: String])]])
            MockSession.mockResponse = (data, response, nil)
        } catch let error {
            XCTFail("Test implementation fault. \(error)")
        }
        let condition = expectation(description: "Finished")
        let wikipedia = Wikipedia(language: WikipediaLanguage(locale: Locale(identifier: "en-US")))
        wikipedia.retrieveAbstract(for: existingTaxon) { result in
            if case .failure(let error) = result, case .unknownError = error {
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
        let wikipedia = Wikipedia(language: WikipediaLanguage(locale: Locale(identifier: "en-US")))
        let dataTask = wikipedia.retrieveAbstract(for: existingTaxon) { _ in
            XCTFail("Should have been canceled")
        }
        dataTask.cancel()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 7.0) {
            condition.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    // MARK: - Attributed extracts

    #if os(iOS) || os(watchOS) || os(tvOS) || os(OSX)

    func testWikipediaAttributedExtract() {
        let extract = WikipediaAttributedExtract(htmlString: "T<i>Homo sapiens</i> is a <b>species</b>.")
        guard let attributedString = try? extract.attributedString(using: TXKFont(name: "Palatino", size: 12.0)!) else {
            XCTFail("Could not generate attributed string")
            return
        }
        XCTAssertEqual(attributedString.string, "THomo sapiens is a species.")
        XCTAssertEqual(attributedString.attribute(.font, at: 0, effectiveRange: nil) as? TXKFont,
                       TXKFont(name: "Palatino", size: 12.0), "Wrong font in attributed extract")
        XCTAssertNotEqual(attributedString.attribute(.font, at: 1, effectiveRange: nil) as? TXKFont,
                          TXKFont(name: "Palatino", size: 12.0), "Wrong font in attributed extract")
    }

    func testWikipediaAttributedExtractPerformance() {
        let extract = WikipediaAttributedExtract(htmlString: "T<i>Homo sapiens</i> is a <b>species</b>.")
        measure {
            _ = try? extract.attributedString(using: TXKFont(name: "Palatino", size: 12.0)!)
        }
    }

    #endif

}
