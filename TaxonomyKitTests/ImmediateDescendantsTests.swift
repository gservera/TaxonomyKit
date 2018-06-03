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
    
    override func setUp() {
        super.setUp()
        Taxonomy.internalUrlSession = URLSession.shared
    }
    
    func testQueryWithSingleResult() {
        let item = TaxonLineageItem(identifier: 0, name: "Panthera", rank: .genus)
        Taxonomy.internalUrlSession = URLSession.shared
        let condition = expectation(description: "Should have succeeded")
        Taxonomy.downloadImmediateDescendants(for: item) { result in
            if case .success(let descendants) = result {
                XCTAssertEqual(descendants.count, 6)
                condition.fulfill()
            }
        }
        waitForExpectations(timeout: 100)
    }
    
}
