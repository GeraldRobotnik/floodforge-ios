//
//  SitesMapView.swift
//  FloodForge
//
//  Created by Mark Basaldua on 12/31/25.
//

import SwiftUI
import MapKit

struct SitesMapView: View {
    let sites: [SiteNode]
    @State private var position: MapCameraPosition = .automatic
    @State private var selected: SiteNode?

    private var mappable: [SiteNode] { sites.filter { $0.coordinate != nil } }

    var body: some View {
        NavigationStack {
            Map(position: $position, selection: $selected) {
                ForEach(mappable) { s in
                    Marker(s.name, coordinate: s.coordinate!)
                        .tag(s)
                }
            }
            .overlay(alignment: .bottom) {
                if let s = selected {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(s.name).font(.headline)
                        Text("Status: \(s.status.rawValue)").foregroundStyle(.secondary)
                        Text("LOW \(s.lowTriggered ? "TRIPPED" : "OK") • HIGH \(s.highTriggered ? "TRIPPED" : "OK")")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding()
                }
            }
            .navigationTitle("Map")
        }
    }
}
