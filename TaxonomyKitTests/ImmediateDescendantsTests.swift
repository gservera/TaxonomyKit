/*
 *  ImmediateDescendantsTests.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 24/09/2018.
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

final class ImmediateDescendantsTests: XCTestCase {

    let item = TaxonLineageItem(identifier: 9688, name: "Panthera", rank: .genus)

    override func setUp() {
        super.setUp()
        Taxonomy.internalUrlSession = Taxonomy.makeUrlSession()
    }

    func testQueryWithSingleResult() {
        Taxonomy.internalUrlSession = Taxonomy.makeUrlSession()
        let condition = expectation(description: "Should have succeeded")
        Taxonomy.downloadImmediateDescendants(for: item) { result in
            if case .success(let descendants) = result {
                XCTAssertEqual(descendants.count, 6)
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 100)
    }

    func testUnmatchedQuery() {
        Taxonomy.internalUrlSession = Taxonomy.makeUrlSession()
        let condition = expectation(description: "Unmatched query")
        let unmatched = TaxonLineageItem(identifier: 0, name: "angaiuognbaoudfoabngud", rank: .genus)
        Taxonomy.downloadImmediateDescendants(for: unmatched) { result in
            if case .success(let identifiers) = result {
                XCTAssertEqual(identifiers.count, 0)
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testFakeMalformedJSON() {
        Taxonomy.internalUrlSession = MockSession()
        let anyUrl = URL(string: "https://gservera.com")!
        let response = HTTPURLResponse(url: anyUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        let data = Data(base64Encoded: "SGVsbG8gd29ybGQ=")
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadImmediateDescendants(for: item) { result in
            if case .failure(let error) = result, case .parseError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testUnknownResponse() {
        Taxonomy.internalUrlSession = MockSession()
        let anyUrl = URL(string: "https://gservera.com")!
        let response = HTTPURLResponse(url: anyUrl, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: [:])!
        let data = Data(base64Encoded: "SGVsbG8gd29ybGQ=")
        MockSession.mockResponse = (data, response, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadImmediateDescendants(for: item) { result in
            if case .failure(let error) = result,
                case .unexpectedResponse(500) = error {
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
        Taxonomy.downloadImmediateDescendants(for: item) { result in
            if case .failure(let error) = result,
                case .networkError(_) = error {
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testOddBehavior() {
        Taxonomy.internalUrlSession = MockSession()
        MockSession.mockResponse = (nil, nil, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.downloadImmediateDescendants(for: item) { result in
            if case .failure(let error) = result,
                case .unknownError = error {
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
        Taxonomy.downloadImmediateDescendants(for: item) { result in
            if case .failure(let error) = result,
                case .unknownError = error {
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
        let dataTask = Taxonomy.findIdentifiers(for: "anything") { _ in
            XCTFail("Should have been canceled")
        }
        dataTask.cancel()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 7.0) {
            condition.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

}
