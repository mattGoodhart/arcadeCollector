//
//  GenericNetworkingTask.swift
//  arcadeCollector
//
//  Created by TrixxMac on 4/8/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import Foundation
import UIKit

class Networking { 
    
    static let shared = Networking()
    private init() {}
    
    func taskForJSON<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error  in
            guard error == nil, let data = data else {
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
                DispatchQueue.main.async {
                    completion(nil, error)
                    print(error)
                }
            }
        }
        task.resume()
    }
    
    func fetchText(at url: URL, with completion: @escaping ((String) -> Void)) {
        DispatchQueue.global().async {
            guard let textData = try? String(contentsOf: url) else {
                print("Text download failed for URL: \(url)")
                return
            }
            DispatchQueue.main.async {
                completion(textData)
            }
        }
    }
    
    func fetchData(at url: URL, with completion: @escaping ((Data?) -> Void)) {
        DispatchQueue.global().async {
            guard let data = try? Data(contentsOf: url) else {
                DispatchQueue.main.async {
                    print("Download failed for URL: \(url)")
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
}
