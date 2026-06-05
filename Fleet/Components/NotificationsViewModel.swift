import SwiftUI

@MainActor
@Observable
final class NotificationsViewModel {
    private(set) var notifications: [Notification] = []
    var isLoading = false
    var errorMessage: String?
    var currentUserId: UUID?

    func loadData() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await NotificationService.fetchNotifications(userId: userId)
            let excludedTitles = [
                "driver entered pickup zone",
                "driver picked up",
                "driver entered drop-off zone",
                "drop-off completed",
                "driver dropped off"
            ]
            
            // Show both read and unread notifications
            notifications = fetched.filter { notification in
                let title = (notification.title ?? "").lowercased()
                let notExcluded = !excludedTitles.contains(where: { title.contains($0) })
                return notExcluded
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        RealtimeManager.shared.addNotificationsChangeHandler { [weak self] in
            Task { @MainActor [weak self] in
                await self?.loadData()
            }
        }
    }

    func markAsRead(_ notification: Notification) {
        Task {
            do {
                try await NotificationService.markAsRead(id: notification.id)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func markAllAsRead() {
        let unread = notifications.filter { $0.isRead == false }
        for notification in unread {
            markAsRead(notification)
        }
    }

    func deleteNotification(_ notification: Notification) {
        Task {
            do {
                try await NotificationService.deleteNotification(id: notification.id)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
