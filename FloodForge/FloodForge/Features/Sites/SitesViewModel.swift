import Foundation
import SwiftUI
import Combine

@MainActor
final class SitesViewModel: ObservableObject {
    @Published var sites: [SiteNode] = []
    @Published var isLoading = false
    @Published var error: String?

    @AppStorage("alertsEnabled") private var alertsEnabled = true

    private let repo: SiteRepository
    private var lastStatusById: [String: AlertStatus] = [:]

    init(repo: SiteRepository) {
        self.repo = repo
    }

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let newSites = try await repo.fetchSites()

            if alertsEnabled {
                for s in newSites {
                    let prev = lastStatusById[s.id]
                    if let prev, isEscalation(from: prev, to: s.status) {
                        NotificationManager.shared.notifyEscalation(siteName: s.name, status: s.status)
                    }
                    lastStatusById[s.id] = s.status
                }
            } else {
                for s in newSites { lastStatusById[s.id] = s.status }
            }

            sites = newSites
        } catch {
            self.error = "Failed to load sites: \(error)"
        }
    }

    private func isEscalation(from: AlertStatus, to: AlertStatus) -> Bool {
        func rank(_ s: AlertStatus) -> Int {
            switch s {
            case .normal: return 0
            case .rising: return 1
            case .critical: return 2
            case .degraded: return 0
            }
        }
        return rank(to) > rank(from)
    }
}
