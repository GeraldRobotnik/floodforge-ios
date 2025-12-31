import Foundation
import SwiftUI
import Combine

@MainActor
final class SitesViewModel: ObservableObject {
    @Published var sites: [SiteNode] = []
    @Published var isLoading = false
    @Published var error: String?

    // UI state
    @Published var query: String = ""
    @Published var filter: SiteFilter = .all
    @Published var favoritesOnly: Bool = false
    @Published private(set) var lastRefreshedAt: Date? = nil

    @AppStorage("alertsEnabled") private var alertsEnabled = true

    // Persist favorites as a comma-separated string (simple + reliable)
    @AppStorage("favoriteSiteIDs") private var favoriteIDsStorage: String = ""

    private let repo: SiteRepository
    private var lastStatusById: [String: AlertStatus] = [:]

    init(repo: SiteRepository) {
        self.repo = repo
    }

    func onAppear() async {
        await refresh()
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

            // Sort by status severity then name (feels intentional)
            self.sites = newSites.sorted { a, b in
                let ra = rank(a.status)
                let rb = rank(b.status)
                if ra != rb { return ra > rb } // critical/rising bubble up
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }

            lastRefreshedAt = Date()
        } catch {
            self.error = "Failed to load sites: \(error)"
        }
    }

    // MARK: - Derived collections used by the View

    var filteredSites: [SiteNode] {
        var out = sites

        // Filter by status
        switch filter {
        case .all: break
        case .normal: out = out.filter { $0.status == .normal }
        case .rising: out = out.filter { $0.status == .rising }
        case .critical: out = out.filter { $0.status == .critical }
        }

        // Search
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            out = out.filter {
                $0.name.localizedCaseInsensitiveContains(q) ||
                $0.id.localizedCaseInsensitiveContains(q)
            }
        }

        // Favorites only
        if favoritesOnly {
            let fav = favoriteIDs
            out = out.filter { fav.contains($0.id) }
        }

        return out
    }

    var favoriteSites: [SiteNode] {
        let fav = favoriteIDs
        return filteredSites.filter { fav.contains($0.id) }
    }

    var nonFavoriteSites: [SiteNode] {
        let fav = favoriteIDs
        return filteredSites.filter { !fav.contains($0.id) }
    }

    var refreshSummary: String {
        guard let t = lastRefreshedAt else { return "Not refreshed yet" }
        return "Refreshed \(t.formatted(.relative(presentation: .named)))"
    }

    var emptyStateMessage: String {
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "No matches for your search." }
        if favoritesOnly { return "No favorites match this filter." }
        if filter != .all { return "No sites match this filter." }
        return "No data returned."
    }

    // MARK: - Favorites

    private var favoriteIDs: Set<String> {
        let items = favoriteIDsStorage
            .split(separator: ",")
            .map { String($0) }
            .filter { !$0.isEmpty }
        return Set(items)
    }

    func isFavorite(_ id: String) -> Bool {
        favoriteIDs.contains(id)
    }

    func toggleFavorite(_ id: String) {
        var s = favoriteIDs
        if s.contains(id) { s.remove(id) } else { s.insert(id) }
        favoriteIDsStorage = s.sorted().joined(separator: ",")
        objectWillChange.send()
    }

    // MARK: - Escalation logic

    private func isEscalation(from: AlertStatus, to: AlertStatus) -> Bool {
        rank(to) > rank(from)
    }

    private func rank(_ s: AlertStatus) -> Int {
        switch s {
        case .normal: return 0
        case .rising: return 1
        case .critical: return 2
        case .degraded: return 0
        }
    }
}
