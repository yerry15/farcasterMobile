//
//  CastManager.swift
//  farcasterFrames
//
//  Created by Jerry Feng on 6/19/24.
//

import Foundation

struct CastId: Codable {
    let fid: Int
    let hash: String
}

struct EmbedCast: Codable {
    let castId: CastId
}

struct EmbedUrl: Codable {
    let url: String
}

struct Cast: Codable {
    let id: String
    let castText: String
    let embedUrl: [EmbedUrl]
    let embedCast: [EmbedCast]
    let username: String
    let pfpUrl: String
    let timestamp: String
    let likes: Int
    let recasts: Int
    
    enum CodingKeys: String, CodingKey {
            case id = "hash"
            case castText = "text"
            case embedUrl = "embed_url"
            case embedCast = "embed_cast"
            case username
            case pfpUrl = "pfp_url"
            case timestamp
            case likes
            case recasts
        }
    }

struct PostBody: Codable {
    let signer: String
    let castMessage: String
    let fid: String
    let parentUrl: String
}

class CastManager {
    static let shared = CastManager()
    
    var casts: [Cast] = []
    
    func postCast(castMessage: String, completion: @escaping (Result<Data, Error>) -> Void) {
            var user_fid: String = ""
            var user_signer: String = ""
            if let fid = UserDefaults.standard.value(forKey: "fid") as? String {
                print("fid: \(fid)")
                user_fid = fid
            } else {
                print("fid not found")
            }
            
            if let signer_private = UserDefaults.standard.value(forKey: "signer_private") as? String {
                print("signer_private: \(signer_private)")
                user_signer = signer_private
            } else {
                print("signer_private not found")
            }
            
            guard let url = URL(string: "http://localhost:3000/message") else {
                completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
                return
            }
            
            let requestBody: [String: Any] = [
                "signer": user_signer,
                "castMessage": castMessage,
                "fid": user_fid
            ]
            
            guard let requestData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                completion(.failure(NSError(domain: "Failed to serialize request body", code: 0, userInfo: nil)))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NSError(domain: "HTTP error", code: httpResponse.statusCode, userInfo: nil)))
                    return
                }
                
                guard let responseData = data else {
                    completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                    return
                }
                
                completion(.success(responseData))
            }
            
            task.resume()
        }
    
    func fetchCasts(completion: @escaping (Result<[Cast], Error>) -> Void) {
        guard let url = URL(string: "http://localhost:3000/feed?pageToken=blank") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 1, userInfo: nil)))
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode([Cast].self, from: data)
                self.casts = decodedData
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
 }
