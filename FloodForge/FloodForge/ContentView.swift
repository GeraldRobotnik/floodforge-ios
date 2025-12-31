//
//  ContentView.swift
//  FloodForge
//
//  Created by Mark Basaldua on 12/31/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = SitesViewModel(repo: MockSiteRepository())

    var body: some View {
        TabView {
            SitesView(vm: vm)
                .tabItem { Label("Sites", systemImage: "list.bullet.rectangle") }

            SitesMapView(sites: vm.sites)
                .tabItem { Label("Map", systemImage: "map") }

            NavigationStack { AlertsView() }
                .tabItem { Label("Alerts", systemImage: "bell") }
        }
        .task { _ = await NotificationManager.shared.requestAuth() }
    }
}

#Preview { ContentView() }
