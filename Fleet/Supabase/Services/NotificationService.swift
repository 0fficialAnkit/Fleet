import Foundation
import Supabase

enum NotificationService {

    static func fetchNotifications(userId: UUID) async throws -> [Notification] {
        try await supabase
            .from("notifications")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    static func createNotification(_ notification: Notification) async throws {
        try await supabase
            .from("notifications")
            .insert(notification)
            .execute()
    }

    static func markAsRead(id: UUID) async throws {
        struct ReadUpdate: Encodable {
            let is_read: Bool
        }
        try await supabase
            .from("notifications")
            .update(ReadUpdate(is_read: true))
            .eq("id", value: id)
            .execute()
    }
}
