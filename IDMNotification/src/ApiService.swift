//
//  ApiService.swift
//  APNSDemoApp
//
//  Created by engineer on 8/25/25.
//

import Foundation
import Cocoa

final class ApiService{
    private struct config  {
        static let tenantUrl = "https://for-bhavik-dev-msp.idemeumlab.com"
        static let clientId = "DESKTOP_LOGIN-7df36f18-cb06-49d4-8dce-953c526c1dda-Tm5RO1-V"
        static let clientSecret = "~^V*Ytaw!qkobIo@jRBHHKeoW-Lam5K^q1~7PRcw6Qprxx5J"
        static let appId = "7df36f18-cb06-49d4-8dce-953c526c1dda"
    }

    
    
    func saveTokenToCloud(fcmRegistrationToken: String) async throws {
            let tokenData = try await getOAuthToken(
                tenantURL: config.tenantUrl,
                clientId: config.clientId,
                clientSecret: config.clientSecret
            )
            
            guard let json = try? JSONSerialization.jsonObject(with: tokenData) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                throw ApiError.invalidTokenResponse
            }
            
            let _ = try await saveFCMToken(
                tenantURL: config.tenantUrl,
                userSessionToken: accessToken,
                fcmRegistrationToken: fcmRegistrationToken,
                appId: config.appId
            )
            
        }
        
        func getOAuthToken(tenantURL: String, clientId: String, clientSecret: String) async throws -> Data {
            let urlString = "\(tenantURL)/api/oauth2/v1/token"
            guard let url = URL(string: urlString) else { throw ApiError.invalidURL }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30.0
            
            let bodyParams = [
                "grant_type": "client_credentials",
                "client_id": clientId,
                "client_secret": clientSecret
            ]
            request.httpBody = bodyParams.map { "\($0.key)=\($0.value)" }
                                         .joined(separator: "&")
                                         .data(using: .utf8)
            
            return try await sendRequestWithRetry(request: request)
        }
        
        func saveFCMToken(tenantURL: String, userSessionToken: String, fcmRegistrationToken: String, appId: String) async throws -> Data {
            let urlString = "\(tenantURL)/api/desktoplogin/apps/\(appId)"
            guard let url = URL(string: urlString) else { throw ApiError.invalidURL }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("*/*", forHTTPHeaderField: "Accept")
            request.setValue("application/vnd.dvmi.desktop.login.app.update.request+json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(userSessionToken)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 30.0
            
            let body = ["fcmRegistrationToken": fcmRegistrationToken]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            
            return try await sendRequestWithRetry(request: request)
        }
        
        private func sendRequestWithRetry(request: URLRequest, retryCount: Int = 0) async throws -> Data {
            let maxRetries = 2
            
            do {
                return try await sendRequest(request: request)
            } catch {
                if retryCount < maxRetries {
                    let delay = min(pow(2.0, Double(retryCount)), 10.0)
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await sendRequestWithRetry(request: request, retryCount: retryCount + 1)
                } else {
                    throw error
                }
            }
        }
        
        private func sendRequest(request: URLRequest) async throws -> Data {
            // Configure URLSession for better connection handling
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            config.waitsForConnectivity = true
            config.allowsCellularAccess = true
            
            let session = URLSession(configuration: config)
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                
                if httpResponse.statusCode >= 400 {
                    throw ApiError.httpError(httpResponse.statusCode)
                }
            }
            
           return data
        }
    
    enum ApiError: Error {
            case invalidURL
            case invalidTokenResponse
            case httpError(Int)
            
            var localizedDescription: String {
                switch self {
                case .invalidURL:
                    return "Invalid URL"
                case .invalidTokenResponse:
                    return "Invalid token response"
                case .httpError(let code):
                    return "HTTP Error: \(code)"
                }
            }
        }
}
