import SwiftUI

struct SitesView: View {
    @StateObject var vm: SitesViewModel

    var body: some View {
        NavigationStack {
            Group {
                if let error = vm.error {
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                    .padding(.top, 16)
                } else if vm.sites.isEmpty && vm.isLoading {
                    ProgressView("Loading…")
                        .padding(.top, 24)
                } else if vm.filteredSites.isEmpty {
                    ContentUnavailableView(
                        "No sites",
                        systemImage: "drop",
                        description: Text(vm.emptyStateMessage)
                    )
                    .padding(.top, 16)
                } else {
                    List {
                        // Top status bar (last refresh + count)
                        Section {
                            HStack(spacing: 10) {
                                Label(vm.refreshSummary, systemImage: "arrow.clockwise")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(vm.filteredSites.count) shown")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.footnote)
                        }

                        // Favorites section
                        if !vm.favoriteSites.isEmpty {
                            Section("Favorites") {
                                ForEach(vm.favoriteSites) { s in
                                    siteRow(s)
                                }
                            }
                        }

                        // All / filtered section
                        Section(vm.favoriteSites.isEmpty ? "Sites" : "All Sites") {
                            ForEach(vm.nonFavoriteSites) { s in
                                siteRow(s)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await vm.refresh() }
                }
            }
            .navigationTitle("Sites")
            .navigationDestination(for: SiteNode.self) { s in
                SiteDetailView(site: s, isFavorite: vm.isFavorite(s.id)) {
                    vm.toggleFavorite(s.id)
                }
            }
            .searchable(text: $vm.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search sites")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $vm.filter) {
                            ForEach(SiteFilter.allCases) { f in
                                Text(f.title).tag(f)
                            }
                        }
                        Toggle("Favorites only", isOn: $vm.favoritesOnly)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(vm.isLoading)
                }
            }
            .task { await vm.onAppear() }
        }
    }

    @ViewBuilder
    private func siteRow(_ s: SiteNode) -> some View {
        NavigationLink(value: s) {
            SiteCardRow(
                site: s,
                isFavorite: vm.isFavorite(s.id),
                onToggleFavorite: { vm.toggleFavorite(s.id) }
            )
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                vm.toggleFavorite(s.id)
            } label: {
                Label(vm.isFavorite(s.id) ? "Unfavorite" : "Favorite",
                      systemImage: vm.isFavorite(s.id) ? "star.slash" : "star")
            }
            .tint(.yellow)
        }
    }
}

// MARK: - Row UI (status-forward)

private struct SiteCardRow: View {
    let site: SiteNode
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Left status rail
            RoundedRectangle(cornerRadius: 3)
                .fill(site.status.color)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: site.status.icon)
                        .foregroundStyle(site.status.color)

                    Text(site.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(isFavorite ? Color.yellow : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFavorite ? "Unfavorite" : "Favorite")
                }

                HStack(spacing: 8) {
                    StatusPill(text: site.status.rawValue, tint: site.status.color)

                    StatusPill(
                        text: "LOW \(site.lowTriggered ? "TRIPPED" : "OK")",
                        tint: site.lowTriggered ? .orange : .secondary
                    )

                    StatusPill(
                        text: "HIGH \(site.highTriggered ? "TRIPPED" : "OK")",
                        tint: site.highTriggered ? .red : .secondary
                    )

                    Spacer()

                    // Relative timestamp reads better than absolute in a list
                    Text(site.updatedAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct StatusPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15))
            .foregroundStyle(tint)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Detail View (small polish)

struct SiteDetailView: View {
    let site: SiteNode
    let isFavorite: Bool
    let toggleFavorite: () -> Void

    var body: some View {
        Form {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: site.status.icon)
                        .foregroundStyle(site.status.color)
                    Text(site.status.rawValue)
                        .font(.headline)
                    Spacer()
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                    }
                    .buttonStyle(.plain)
                }

                LabeledContent("Updated") {
                    Text(site.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Status")
            }

            Section("Sensors") {
                LabeledContent("Low float") { Text(site.lowTriggered ? "TRIPPED" : "OK").foregroundStyle(.secondary) }
                LabeledContent("High float") { Text(site.highTriggered ? "TRIPPED" : "OK").foregroundStyle(.secondary) }
            }

            Section("Location") {
                if let lat = site.latitude, let lon = site.longitude {
                    LabeledContent("Coordinates") {
                        Text(String(format: "%.5f, %.5f", lat, lon)).foregroundStyle(.secondary)
                    }

                    // Quick “real app” feature: jump to Apple Maps
                    Link("Open in Maps", destination: URL(string: "http://maps.apple.com/?ll=\(lat),\(lon)&q=\(site.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Site")")!)
                } else {
                    Text("No coordinates set yet.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Filter types + status mapping

enum SiteFilter: String, CaseIterable, Identifiable {
    case all, normal, rising, critical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .normal: return "Normal"
        case .rising: return "Rising"
        case .critical: return "Critical"
        }
    }
}

private extension AlertStatus {
    var color: Color {
        switch self {
        case .normal: return .green
        case .rising: return .orange
        case .critical: return .red
        case .degraded: return .gray
        }
    }

    var icon: String {
        switch self {
        case .normal: return "checkmark.circle"
        case .rising: return "exclamationmark.triangle"
        case .critical: return "xmark.octagon"
        case .degraded: return "wifi.slash"
        }
    }
}
