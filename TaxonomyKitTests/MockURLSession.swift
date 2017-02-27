/*
 *  MockURLSession.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 27/09/2016.
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

import Foundation
import XCTest

/// A class used to mock URLSession objects for testing purposes.
@objc public class MockSession: URLSession {
    
    var wait: UInt32 = 0
    
    var completionHandler:((Data?, URLResponse?, Error?) -> Void)?
    
    static var mockResponse: (data: Data?, urlResponse: URLResponse?, error: Error?)
    
    override public class var shared: URLSession {
        return MockSession()
        
    }
    
    override public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.completionHandler = completionHandler
        let task = MockTask(response: MockSession.mockResponse, completionHandler: completionHandler)
        task.wait = wait
        return task
    }
    
    @objc public class MockTask: URLSessionDataTask {
        
        var wait: UInt32 = 0
        var canceled = false
        
        typealias Response = (data: Data?, urlResponse: URLResponse?, error: Error?)
        var mockResponse: Response
        let completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
        
        init(response: Response, completionHandler:((Data?, URLResponse?, Error?) -> Void)?) {
            self.mockResponse = response
            self.completionHandler = completionHandler
        }
        
        override public func resume() {
            DispatchQueue.global(qos: .background).async {
                let wait = self.wait 
                if wait > 0 {
                    sleep(wait)
                }
                DispatchQueue.main.async {
                    if self.canceled {
                        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
                        self.completionHandler!(nil, nil, error)
                    } else {
                        self.completionHandler!(self.mockResponse.data, self.mockResponse.urlResponse, self.mockResponse.error)
                    }
                    
                }
            }
            
        }

        public override func cancel() {
            canceled = true
        }
        
    }
}

final class MockSessionTests: XCTestCase {
    
    func testMockSessionCreation() {
        let mockSession = MockSession.shared
        (mockSession as! MockSession).wait = 0
        XCTAssertTrue(mockSession is MockSession, "Failed")
    }
    
}
