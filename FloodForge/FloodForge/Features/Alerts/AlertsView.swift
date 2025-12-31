//
//  AlertsView.swift
//  FloodForge
//
//  Created by Mark Basaldua on 12/31/25.
//

import SwiftUI

struct AlertsView: View {
    @AppStorage("alertsEnabled") private var alertsEnabled = true

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable alerts", isOn: $alertsEnabled)
            }
            Section("Behavior") {
                Text("Local notifications fire when a site escalates (NORMAL → RISING → CRITICAL).")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Alerts")
    }
}
