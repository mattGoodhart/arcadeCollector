//
//  GenericNetworkingTask.swift
//  arcadeCollector
//
//  Created by TrixxMac on 4/8/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import Foundation

class Networking { // Make this a Singleton?
    
    func taskForJSON<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) { // TODO - error handling based on server response. Maybe show a notification
        
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
                   // print(responseObject)
                }
            }
            catch {
                print(error)
            }
        }
        task.resume()
    }
 /*
    enum Endpoints {
        
        static let base = "https://onthemap-api.udacity.com/v1"
        
        case studentLocations
        case session // for logging in/out
        case user // logged-in user
        case updatePin
        case newPin
        case signUp
        
        var stringValue: String {
            switch self {
            case .studentLocations: return Endpoints.base + "/StudentLocation?limit=100&order=-updatedAt"
            case .session: return Endpoints.base + "/session"
            case .user: return Endpoints.base + "/users/" + uniqueKey
            case .updatePin: return Endpoints.base + "/StudentLocation/" + objectID
            case .newPin: return Endpoints.base + "/StudentLocation"
            case .signUp: return "https://auth.udacity.com/sign-up"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
     
     
     
     "https://www.youtube.com/embed/\(videoID)"
     
     "http://adb.arcadeitalia.net/service_scraper.php?ajax=query_mame&game_name=" + viewedGame.romSetName! + "&use_parent=1"
     
     
     "http://adb.arcadeitalia.net/media/mame.current/pcbs/" + inputString + ".png"
     
     "https://raw.githubusercontent.com/mamedev/mame/master/src/mame/drivers/" + viewedGame.driver
     
     http://adb.arcadeitalia.net/download_file.php?tipo=xml&codice=" + viewedGame.romSetName
     
     http://adb.arcadeitalia.net/download_file.php?tipo=mame_current&codice=" + self.viewedGame.romSetName! + "&entity=manual")
     
 */
    
    
    // add other networking refactored functions here
}

