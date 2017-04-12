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
        Taxonomy.findPossibleScientificNames(matching: "Melicotoner", language: lang) { result in
            if case .success(let wrapper) = result {
                XCTAssertNotNil(wrapper)
                condition.fulfill()
            } else {
                XCTFail("Wikipedia test should not have failed")
            }
        }
        waitForExpectations(timeout: 1000)
    }
}
