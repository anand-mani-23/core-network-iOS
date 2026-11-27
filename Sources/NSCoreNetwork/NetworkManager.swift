//
//  ApiClient.swift
//  NSCoreNetwork
//
//  Created by apple on 27/11/26.
//

import Foundation

// MARK: - Shared Response & Error Contracts

public struct APIResponseWrapper<T: Decodable & Sendable>: Decodable, Sendable {
    public let success: Bool
    public let message: String
    public let data: T?

    enum CodingKeys: String, CodingKey {
        case success, message, data
    }

    public init(success: Bool, message: String, data: T? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

public enum APIError: Error, Sendable {
    case invalidURL(path: String)
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case noData
    case decodingFailed(Error)
    case unauthorized
}

// MARK: - Networking Protocols

public protocol APIClientProtocol: Sendable {
    func execute(path: String) async throws -> Data
    func execute<T: Decodable & Sendable>(path: String, as type: T.Type) async throws -> T
}

public protocol NetworkManaging: Sendable {
    func fetchData(path: String) async throws -> Data
    func fetch<T: Decodable & Sendable>(path: String, as type: T.Type) async throws -> T
}

// MARK: - Concrete Transport Client

public final class APIClient: APIClientProtocol, Sendable {
    private let baseURL: URL
    private let session: URLSession

    public init(
        baseURL: URL = URL(string: "https://simplexmobapps.com/api/v1")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    private func performRequest(
        _ request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data, let response else {
                    continuation.resume(throwing: APIError.invalidResponse)
                    return
                }

                continuation.resume(returning: (data, response))
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

// MARK: - Decoupled Network Manager

public final class NetworkManager: NetworkManaging, Sendable {
    private let apiClient: any APIClientProtocol

    public init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func fetchData(path: String) async throws -> Data {
        try await apiClient.execute(path: path)
    }

    public func fetch<T: Decodable & Sendable>(path: String, as type: T.Type) async throws -> T {
        do {
            return try await apiClient.execute(path: path, as: type)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
