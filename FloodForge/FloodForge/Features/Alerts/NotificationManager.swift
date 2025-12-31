//
//  NotificationManager.swift
//  FloodForge
//
//  Created by Mark Basaldua on 12/31/25.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuth() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch { return false }
    }

    func notifyEscalation(siteName: String, status: AlertStatus) {
        let content = UNMutableNotificationContent()
        content.title = "FloodForge Alert"
        content.body = "\(siteName) → \(status.rawValue)"
        content.sound = .default

        let req = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req)
    }
}
