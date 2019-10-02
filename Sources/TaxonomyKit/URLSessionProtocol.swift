//
//  File.swift
//  
//
//  Created by Guillem Servera Negre on 02/10/2019.
//

import Foundation

protocol URLSessionProtocol {
    
    func dataTask(with url: URL,
                  completionHandler: @escaping(Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
    
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping(Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol { }
