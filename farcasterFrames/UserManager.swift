//
//  UserManager.swift
//  farcasterFrames
//
//  Created by Jerry Feng on 6/24/24.
//

import Foundation


struct SignerPayload: Codable {
    let token: String
    let privateKey: String
    let publicKey: String
    let deepLinkUrl: String
}

struct PollingStatus: Codable {
    let state: String
    let userFid: Int?
}

struct User: Codable {
    let fid: Int
    let signerKey: String
}

class UserManager {
    static let shared = UserManager()
    func signInWithWarpcast(completion: @escaping (Result<SignerPayload, Error>) -> Void) {
            let url = URL(string: "http://localhost:3000/sign-in")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let session = URLSession.shared
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Check for HTTP response status code indicating success
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    completion(.failure(NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])))
                    return
                }
                
                // Ensure data is present
                guard let responseData = data else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                do {
                    // Decode the JSON response into a SignerPayload object
                    let decoder = JSONDecoder()
                    print(responseData)
                    let signerPayload = try decoder.decode(SignerPayload.self, from: responseData)
                    UserDefaults.standard.set(signerPayload.privateKey, forKey: "signer_private")
                    UserDefaults.standard.set("false", forKey: "signer_approved")
                    UserDefaults.standard.set(signerPayload.token, forKey: "token")
                    completion(.success(signerPayload))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    func pollForApproval(token: String, completion: @escaping (Result<String, Error>) -> Void) {
            let url = URL(string: "http://localhost:3000/sign-in/poll?pollingToken=\(token)")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let session = URLSession.shared
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Check for HTTP response status code indicating success
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    completion(.failure(NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])))
                    return
                }
                
                // Ensure data is present
                guard let responseData = data else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                do {
                    // Decode the JSON response into a SignerPayload object
                    let decoder = JSONDecoder()
                    let pollingStatus = try decoder.decode(PollingStatus.self, from: responseData)
                    if pollingStatus.state == "completed", pollingStatus.userFid != nil {
                        UserDefaults.standard.set("true", forKey: "signer_approved")
                        UserDefaults.standard.set(String(pollingStatus.userFid ?? 0), forKey: "fid")
                    }
                    completion(.success(pollingStatus.state))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    func getUserData() -> User {
        var user_signer: String = ""
        var user_fid: Int = 0
        if let fid = UserDefaults.standard.value(forKey: "fid") as? String {
            user_fid = Int(fid) ?? 0
        } else {
            return User(fid: 0, signerKey: "")
        }
        
        if let signer_key = UserDefaults.standard.value(forKey: "signer_key") as? String {
            user_signer = signer_key
        } else {
            return User(fid: 0, signerKey: "")
        }
        
        return User(fid: user_fid, signerKey: user_signer)
    }
}
