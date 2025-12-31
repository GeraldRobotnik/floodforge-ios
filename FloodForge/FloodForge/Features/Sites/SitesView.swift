//
//  SitesView.swift
//  FloodForge
//
//  Created by Mark Basaldua on 12/31/25.
//

import SwiftUI

struct SitesView: View {
    @StateObject var vm: SitesViewModel

    var body: some View {
        NavigationStack {
            Group {
                if let error = vm.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if vm.sites.isEmpty && vm.isLoading {
                    ProgressView("Loading…")
                } else if vm.sites.isEmpty {
                    ContentUnavailableView("No sites", systemImage: "drop", description: Text("No data returned."))
                } else {
                    List(vm.sites) { s in
                        NavigationLink(value: s) {
                            HStack(spacing: 12) {
                                StatusBadge(status: s.status)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(s.name).font(.headline)
                                    Text("LOW: \(s.lowTriggered ? "TRIPPED" : "OK") • HIGH: \(s.highTriggered ? "TRIPPED" : "OK")")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(s.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .refreshable { await vm.refresh() }
                }
            }
            .navigationTitle("Sites")
            .navigationDestination(for: SiteNode.self) { s in
                SiteDetailView(site: s)
            }
            .task { await vm.refresh() }
        }
    }
}

struct StatusBadge: View {
    let status: AlertStatus
    var body: some View {
        Text(status.rawValue)
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SiteDetailView: View {
    let site: SiteNode

    var body: some View {
        Form {
            Section("Status") {
                row("State", site.status.rawValue)
                row("Low float", site.lowTriggered ? "TRIPPED" : "OK")
                row("High float", site.highTriggered ? "TRIPPED" : "OK")
                row("Updated", site.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
            Section("Location") {
                if let lat = site.latitude, let lon = site.longitude {
                    Text("Lat \(lat), Lon \(lon)")
                } else {
                    Text("No coordinates set").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Detail")
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k); Spacer(); Text(v).foregroundStyle(.secondary) }
    }
}
