//
//  APIClient.swift
//  FloodForge
//
//  Created by Mark Basaldua on 12/31/25.
//

import Foundation

enum APIError: Error {
    case badURL
    case badResponse(Int)
    case decoding(Error)
    case transport(Error)
}

final class APIClient {
    let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw APIError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 15

        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw APIError.badResponse(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badResponse(http.statusCode) }

            do {
                return try JSONDecoder.floodforge.decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch {
            throw APIError.transport(error)
        }
    }
}

extension JSONDecoder {
    static var floodforge: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
