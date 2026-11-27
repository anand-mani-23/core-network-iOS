//
//  ApiClient.swift
//  NSCoreNetwork
//
//  Created by apple on 27/11/26.
//

import Foundation

import Foundation

// MARK: - Errors
public enum APIError: Error, Sendable {
    case invalidURL(path: String)
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case noData
    case decodingFailed(Error)
    case unauthorized
}

public final class APIClient: Sendable {
    private let baseURL: URL
    private let session: URLSession
   
    public init(
        baseURL: URL = URL(string: "https://simplexmobapps.com/api/v1")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func performRequest(
        _ request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) {
                data,
                response,
                error in

                if let error {
                    continuation.resume(
                        throwing: error
                    )
                    return
                }

                guard let data,
                      let response else {
                    continuation.resume(
                        throwing: APIError.invalidResponse
                    )
                    return
                }

                continuation.resume(
                    returning: (data, response)
                )
            }
            task.resume()
        }
    }

    public func execute(path: String) async throws -> Data {
        let url: URL
        if path.hasPrefix("http") {
            guard let fullURL = URL(string: path) else {
                throw APIError.invalidURL(path: path)
            }
            url = fullURL
        } else {
            let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
            url = baseURL.appendingPathComponent(cleanPath)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("iOS-1.0.0", forHTTPHeaderField: "X-App-Version")

        let (data, response) = try await performRequest(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw APIError.unauthorized
        case 400...499, 500...599:
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        default:
            throw APIError.invalidResponse
        }
    }
    
    public func execute<T: Decodable & Sendable>(path: String, as type: T.Type) async throws -> T {
        let data = try await execute(path: path)
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}

final class NetworkManager {
    private let apiClient = APIClient()

    func fetch<T: Decodable>(path: String, as type: T.Type) async throws -> T {
        let data = try await apiClient.execute(path: path)
        return try JSONDecoder().decode(type, from: data)
    }
}
