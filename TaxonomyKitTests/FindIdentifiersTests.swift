/*
 *  FindIdentifiersTests.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 24/09/2016.
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

final class FindIdentifiersTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Taxonomy._urlSession = URLSession.shared
    }
    
    func testQueryWithSingleResult() {
        Taxonomy._urlSession = URLSession.shared
        let condition = expectation(description: "Should have succeeded")
        Taxonomy.findIdentifiers(for: "Quercus ilex") { result in
            if case .success(let identifiers) = result {
                XCTAssertEqual(identifiers.count, 1)
                XCTAssertEqual(identifiers[0], 58334)
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testUnmatchedQuery() {
        Taxonomy._urlSession = URLSession.shared
        let condition = expectation(description: "Unmatched query")
        Taxonomy.findIdentifiers(for: "invalid-invalid") { result in
            if case .success(let identifiers) = result {
                XCTAssertEqual(identifiers.count, 0)
                condition.fulfill()
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
        Taxonomy.findIdentifiers(for: "anything") { result in
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
        Taxonomy.findIdentifiers(for: "anything") { result in
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
        Taxonomy.findIdentifiers(for: "anything") { result in
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
        Taxonomy.findIdentifiers(for: "anything") { result in
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
        Taxonomy.findIdentifiers(for: "anything") { result in
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
        let dataTask = Taxonomy.findIdentifiers(for: "anything") { result in
            XCTFail("Should have been canceled")
            
        } as! MockSession.MockTask
        dataTask.cancel()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 7.0) {
            condition.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
