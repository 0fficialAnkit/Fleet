import Foundation
import Supabase

enum MessageService {

    static func fetchMessages(userId: UUID) async throws -> [Message] {
        // Fetch all messages where user is sender OR receiver
        let sent: [Message] = try await supabase
            .from("messages")
            .select()
            .eq("sender_id", value: userId)
            .order("sent_at", ascending: false)
            .execute()
            .value

        let received: [Message] = try await supabase
            .from("messages")
            .select()
            .eq("receiver_id", value: userId)
            .order("sent_at", ascending: false)
            .execute()
            .value

        // Merge and sort
        return (sent + received).sorted { ($0.sentAt ?? .distantPast) > ($1.sentAt ?? .distantPast) }
    }

    static func fetchConversation(senderId: UUID, receiverId: UUID) async throws -> [Message] {
        let fromSender: [Message] = try await supabase
            .from("messages")
            .select()
            .eq("sender_id", value: senderId)
            .eq("receiver_id", value: receiverId)
            .execute()
            .value

        let fromReceiver: [Message] = try await supabase
            .from("messages")
            .select()
            .eq("sender_id", value: receiverId)
            .eq("receiver_id", value: senderId)
            .execute()
            .value

        return (fromSender + fromReceiver).sorted { ($0.sentAt ?? .distantPast) < ($1.sentAt ?? .distantPast) }
    }

    static func sendMessage(_ message: Message) async throws {
        try await supabase
            .from("messages")
            .insert(message)
            .execute()
    }
}