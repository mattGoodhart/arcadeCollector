//
//  GenericNetworkingTask.swift
//  arcadeCollector
//
//  Created by TrixxMac on 4/8/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import Foundation

class Networking { 
    
    static let shared = Networking()
    private init() {}
    
    func taskForJSON<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error  in
            if error != nil {
                completion(nil, error)
                print(error!)
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                    print(error!)
                }
                return
            }
            do {
                let responseObject = try JSONDecoder().decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            }
            catch {
                print(error)
            }
        }
        task.resume()
    }
}

