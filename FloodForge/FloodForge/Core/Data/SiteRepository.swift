//
//  SiteRepository.swift
//  FloodForge
//
//  Created by Mark Basaldua on 12/31/25.
//

import Foundation

protocol SiteRepository {
    func fetchSites() async throws -> [SiteNode]
}

final class MockSiteRepository: SiteRepository {
    func fetchSites() async throws -> [SiteNode] {
        let json = """
        {
          "status": "ok",
          "data": [
            {
              "id": "tx-hc-001",
              "name": "Low Crossing - River Rd",
              "latitude": 29.987,
              "longitude": -98.123,
              "lowTriggered": false,
              "highTriggered": false,
              "status": "NORMAL",
              "updatedAt": "2025-12-31T09:10:00Z"
            },
            {
              "id": "tx-hc-002",
              "name": "Camp Corridor - North Gate",
              "latitude": 30.012,
              "longitude": -98.140,
              "lowTriggered": true,
              "highTriggered": false,
              "status": "RISING",
              "updatedAt": "2025-12-31T09:12:30Z"
            }
          ]
        }
        """
        let data = Data(json.utf8)
        let env = try JSONDecoder.floodforge.decode(APIEnvelope<[SiteNode]>.self, from: data)
        return env.data ?? []
    }
}

final class APISiteRepository: SiteRepository {
    private let api: APIClient
    init(api: APIClient) { self.api = api }

    func fetchSites() async throws -> [SiteNode] {
        let env: APIEnvelope<[SiteNode]> = try await api.get("/api/sites")
        return env.data ?? []
    }
}
