/*
 *  MockURLSession.swift
 *  TaxonomyKitTests
 *
 *  Created:    Guillem Servera on 27/09/2016.
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

import Foundation

/// A class used to mock URLSession objects for testing purposes.
final class MockSession: URLSession {
    
    var completionHandler:((Data?, URLResponse?, Error?) -> Void)?
    
    static var mockResponse: (data: Data?, urlResponse: URLResponse?, error: Error?)
    
    override class var shared: URLSession {
        return MockSession()
        
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.completionHandler = completionHandler
        return MockTask(response: MockSession.mockResponse, completionHandler: completionHandler)
    }
    
    final class MockTask: URLSessionDataTask {
        
        typealias Response = (data: Data?, urlResponse: URLResponse?, error: Error?)
        var mockResponse: Response
        let completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
        
        init(response: Response, completionHandler:((Data?, URLResponse?, Error?) -> Void)?) {
            self.mockResponse = response
            self.completionHandler = completionHandler
        }
        
        override func resume() {
            completionHandler!(mockResponse.data, mockResponse.urlResponse, mockResponse.error)
        }
        
    }
}
