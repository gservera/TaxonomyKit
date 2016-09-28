//
//  MockURLSession.swift
//  Taxonomy
//
//  Created by Guillem Servera Negre on 27/9/16.
//  Copyright © 2016 Guillem Servera. All rights reserved.
//

import Foundation

class MockSession: URLSession {
    
    var completionHandler:((Data?, URLResponse?, Error?) -> Void)?
    
    static var mockResponse: (data: Data?, urlResponse: URLResponse?, error: Error?)
    
    override class var shared: URLSession {
        return MockSession()
        
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.completionHandler = completionHandler
        return MockTask(response: MockSession.mockResponse, completionHandler: completionHandler)
    }
    
    class MockTask: URLSessionDataTask {
        
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
