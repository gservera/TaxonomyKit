/*
 *  SpellingTests.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 24/09/2016.
 *  Copyright:  © 2016 Guillem Servera (http://github.com/gservera)
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

final class SpellingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Taxonomy._urlSession = URLSession.shared
    }
    
    //MARK: Find identifiers
    
    func testValidQueryResult() {
        let query = "quercus ilex"
        let condition = expectation(description: "Finished")
        Taxonomy.findSimilarSpelledCandidates(for: query) { (name, error) in
            XCTAssertNil(error)
            XCTAssertNil(name)
            condition.fulfill()
        }
        waitForExpectations(timeout: 1000, handler: nil)
    }
    
    func testMatchingResult() {
        let query = "Quercus iles"
        let condition = expectation(description: "Finished")
        Taxonomy.findSimilarSpelledCandidates(for: query) { (name, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(name)
            XCTAssertEqual(name, "quercus ilex")
            condition.fulfill()
        }
        waitForExpectations(timeout: 1000, handler: nil)
    }
    
    func testUnmatchedQuery() {
        let query = "ngosdkmpdmgpsmsndosdng"
        let condition = expectation(description: "Finished")
        Taxonomy.findSimilarSpelledCandidates(for: query) { (name, error) in
            XCTAssertNil(error)
            XCTAssertNil(name)
            condition.fulfill()
        }
        waitForExpectations(timeout: 1000, handler: nil)
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
        Taxonomy.findSimilarSpelledCandidates(for: "anything") { (name, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(name)
            switch error! {
            case .parseError(_): condition.fulfill()
            default:             break;
            }
        }
        waitForExpectations(timeout: 1000, handler: nil)
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
        Taxonomy.findSimilarSpelledCandidates(for: "anything") { (name, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(name)
            switch error! {
            case .unexpectedResponseError(let code):
                if code == 500 {
                    condition.fulfill()
                }
            default:
                break;
            }
        }
        waitForExpectations(timeout: 1000, handler: nil)
    }
    
    func testNetworkError() {
        Taxonomy._urlSession = MockSession()
        let error = NSError(domain: "Custom", code: -1, userInfo: nil)
        MockSession.mockResponse = (nil, nil, error)
        let condition = expectation(description: "Finished")
        Taxonomy.findSimilarSpelledCandidates(for: "anything") { (name, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(name)
            switch error! {
            case .networkError(let error as NSError):
                if error.code == -1 {
                    condition.fulfill()
                }
            default:
                break;
            }
        }
        waitForExpectations(timeout: 1000, handler: nil)
    }
    
    func testOddBehavior() {
        Taxonomy._urlSession = MockSession()
        MockSession.mockResponse = (nil, nil, nil)
        let condition = expectation(description: "Finished")
        Taxonomy.findSimilarSpelledCandidates(for: "anything") { (name, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(name)
            switch error! {
            case .unknownError(): condition.fulfill()
            default:              break;
            }
        }
        waitForExpectations(timeout: 1000, handler: nil)
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
        Taxonomy.findSimilarSpelledCandidates(for: "anything") { (name, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(name)
            switch error! {
            case .unknownError(): condition.fulfill()
            default:              break;
            }
        }
        waitForExpectations(timeout: 1000, handler: nil)
    }
}
