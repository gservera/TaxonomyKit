//
//  NameGuessingTests.swift
//  TaxonomyKit
//
//  Created by Guillem Servera Negre on 12/4/17.
//  Copyright © 2017 Guillem Servera. All rights reserved.
//

import XCTest
@testable import TaxonomyKit

final class NameGuessingTests: XCTestCase {

    
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
        let locale = Locale(identifier: "ca-ES")
        let lang = WikipediaLanguage(locale: locale)
        let wikipedia = Wikipedia(language: lang)
        wikipedia.findPossibleScientificNames(matching: "Melicotoner") { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                XCTAssertEqual("Prunus persica", wrapper.first)
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testValidTaxon2() {
        Taxonomy._urlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        let locale = Locale(identifier: "en-US")
        let lang = WikipediaLanguage(locale: locale)
        let wikipedia = Wikipedia(language: lang)
        wikipedia.findPossibleScientificNames(matching: "pork tapeworm") { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                XCTAssertEqual("Taenia solium", wrapper.first)
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
        let wikipedia = Wikipedia(language: customLocale)
        wikipedia.findPossibleScientificNames(matching: "Eurasian otter") { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                XCTAssertEqual("Lutra lutra", wrapper.first)
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 1000)
    }
    
    func testUnmatchedQuery() {
        Taxonomy._urlSession = URLSession.shared
        let condition = expectation(description: "Finished")
        let wikipedia = Wikipedia()
        wikipedia.findPossibleScientificNames(matching: "ijgadngadngadfgnadfgnadlfgnaildfg") { result in
            if case .success(let wrapper) = result {
                XCTAssertTrue(wrapper.count == 0)
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
        let wikipedia = Wikipedia()
        wikipedia.findPossibleScientificNames(matching: "Eurasian otter") { result in
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
        let wikipedia = Wikipedia()
        wikipedia.findPossibleScientificNames(matching: "Eurasian otter") { result in
            if case .failure(let error) = result,
                case .unexpectedResponse(500) = error {
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
        let wikipedia = Wikipedia()
        wikipedia.findPossibleScientificNames(matching: "Eurasian otter") { result in
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
        let wikipedia = Wikipedia()
        wikipedia.findPossibleScientificNames(matching: "Eurasian otter") { result in
            if case .failure(let error) = result,
                case .unknownError = error {
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
        let wikipedia = Wikipedia()
        wikipedia.findPossibleScientificNames(matching: "Eurasian otter") { result in
            if case .failure(let error) = result,
                case .parseError(message: "Could not parse JSON data") = error {
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
        let wikipedia = Wikipedia()
        wikipedia.findPossibleScientificNames(matching: "Eurasian otter") { result in
            if case .failure(let error) = result,
                case .unknownError = error {
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
        let wikipedia = Wikipedia()
        let dataTask = wikipedia.findPossibleScientificNames(matching: "Eurasian otter") { result in
            XCTFail("Should have been canceled")
            
            } as! MockSession.MockTask
        dataTask.cancel()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 7.0) {
            condition.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
