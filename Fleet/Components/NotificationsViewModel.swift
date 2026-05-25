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
            notifications = try await NotificationService.fetchNotifications(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func setupRealtime() {
        RealtimeManager.shared.addNotificationsChangeHandler { [weak self] in
            Task { await self?.loadData() }
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
}
