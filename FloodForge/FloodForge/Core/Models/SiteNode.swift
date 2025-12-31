//
//  SiteNode.swift
//  FloodForge
//
//  Created by Mark Basaldua on 12/31/25.
//

import Foundation
import CoreLocation

enum AlertStatus: String, Codable, CaseIterable {
    case normal = "NORMAL"
    case rising = "RISING"
    case critical = "CRITICAL"
    case degraded = "DEGRADED"
}

struct SiteNode: Identifiable, Codable, Hashable {
    let id: String
    let name: String

    let latitude: Double?
    let longitude: Double?

    let lowTriggered: Bool
    let highTriggered: Bool

    let status: AlertStatus
    let updatedAt: Date

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct APIEnvelope<T: Codable>: Codable {
    let status: String
    let data: T?
}
