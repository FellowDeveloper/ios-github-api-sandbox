//
//  URLRequestHandler.swift
//  GithubFetch
//
//  Created by Anton Tugolukov on 4/5/23.
//

import Foundation

class URLRequestHandler {
    static func handle(_ request:URLRequest, completion : @escaping(Data?, URLResponse?, Error?)->Void) {
        URLSession.shared.dataTask(with: request, completionHandler: completion).resume()
    }
}
