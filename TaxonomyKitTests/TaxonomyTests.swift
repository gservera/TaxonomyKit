/*
 *  TaxonomyTests.swift
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

final class TaxonomyTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Taxonomy._urlSession = URLSession.shared
    }
    
    func testInit() {
        XCTAssertNotNil(Taxonomy())
    }

    
    //MARK: Spelling
    
    func testSpelling() {
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
    
    //MARK: Download
    
    func testDownloadTaxon() {
        let query = "58334"
        let condition = expectation(description: "Finished")
        
        Taxonomy.downloadTaxon(withIdentifier: query) { (taxon, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(taxon)
            condition.fulfill()
        }
        
        waitForExpectations(timeout: 1000, handler: nil)
    }
    
    func testDownloadUnknownTaxon() {
        let query = "anpafnpanpifadn"
        let condition = expectation(description: "Finished")
        
        Taxonomy.downloadTaxon(withIdentifier: query) { (taxon, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(taxon)
            switch error! {
            case .badRequest(_):
                condition.fulfill()
            default:
                break;
            }
            
        }
        
        waitForExpectations(timeout: 1000, handler: nil)
    }
    
}
