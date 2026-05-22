import SwiftUI

enum UserRole { case driver, fleetManager }

@Observable
final class SupportViewModel {
    private(set) var tickets: [SupportTicket]
    private(set) var messages: [TicketMessage]
    
    init() {
        self.tickets = MockData.supportTickets
        self.messages = MockData.ticketMessages
    }
    
    func tickets(for userId: UUID, role: UserRole) -> [SupportTicket] {
        let filtered: [SupportTicket]
        switch role {
        case .driver: filtered = tickets.filter { $0.driverId == userId }
        case .fleetManager: filtered = tickets
        }
        return filtered.sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
    }
    
    func messages(for ticketId: UUID) -> [TicketMessage] {
        messages.filter { $0.ticketId == ticketId }
            .sorted { ($0.sentAt ?? .distantPast) < ($1.sentAt ?? .distantPast) }
    }
    
    func lastMessage(for ticketId: UUID) -> TicketMessage? { messages(for: ticketId).last }
    
    func createTicket(driverId: UUID, category: TicketCategory, subject: String, initialMessage: String) {
        let now = Date(); let ticketId = UUID()
        let ticket = SupportTicket(id: ticketId, driverId: driverId, managerId: nil, category: category, subject: subject, status: .open, createdAt: now, updatedAt: now)
        let msg = TicketMessage(id: UUID(), ticketId: ticketId, senderId: driverId, message: initialMessage, sentAt: now)
        tickets.insert(ticket, at: 0); messages.append(msg)
    }
    
    func sendMessage(ticketId: UUID, senderId: UUID, text: String) {
        let now = Date()
        messages.append(TicketMessage(id: UUID(), ticketId: ticketId, senderId: senderId, message: text, sentAt: now))
        if let i = tickets.firstIndex(where: { $0.id == ticketId }) { tickets[i].updatedAt = now }
    }
    
    func updateStatus(ticketId: UUID, to status: TicketStatus) {
        if let i = tickets.firstIndex(where: { $0.id == ticketId }) { tickets[i].status = status; tickets[i].updatedAt = Date() }
    }
    
    func openTicketCount(for userId: UUID, role: UserRole) -> Int {
        tickets(for: userId, role: role).filter { $0.status == .open || $0.status == .inProgress }.count
    }
    
    func driverName(for userId: UUID) -> String { MockData.users.first { $0.id == userId }?.fullName ?? "Unknown" }
    func senderName(for userId: UUID) -> String { MockData.users.first { $0.id == userId }?.fullName ?? "Unknown" }
    
    func categoryIcon(_ c: TicketCategory?) -> String {
        switch c {
        case .vehicleIssue: return "wrench.fill"; case .routeProblem: return "map.fill"
        case .tripUpdate: return "shippingbox.fill"; case .documentRequest: return "doc.text.fill"
        case .other: return "questionmark.circle.fill"; case .none: return "circle.fill"
        }
    }
    func categoryColor(_ c: TicketCategory?) -> Color {
        switch c {
        case .vehicleIssue: return themeModel.danger; case .routeProblem: return themeModel.warning
        case .tripUpdate: return themeModel.info; case .documentRequest: return themeModel.analyticsPurple
        case .other: return themeModel.textSecondary; case .none: return themeModel.textTertiary
        }
    }
    func categoryLabel(_ c: TicketCategory?) -> String {
        switch c {
        case .vehicleIssue: return "Vehicle Issue"; case .routeProblem: return "Route Problem"
        case .tripUpdate: return "Trip Update"; case .documentRequest: return "Document Request"
        case .other: return "Other"; case .none: return "Unknown"
        }
    }
    func statusColor(_ s: TicketStatus?) -> Color {
        switch s {
        case .open: return themeModel.info; case .inProgress: return themeModel.warning
        case .resolved: return themeModel.success; case .closed, .none: return themeModel.textTertiary
        }
    }
    func statusLabel(_ s: TicketStatus?) -> String {
        switch s {
        case .open: return "Open"; case .inProgress: return "In Progress"
        case .resolved: return "Resolved"; case .closed: return "Closed"; case .none: return "Unknown"
        }
    }
    func relativeTime(_ date: Date?) -> String {
        guard let date else { return "" }
        let s = Int(Date().timeIntervalSince(date))
        if s < 60 { return "Just now" }; if s < 3600 { return "\(s/60)m ago" }
        if s < 86400 { return "\(s/3600)h ago" }; if s < 604800 { return "\(s/86400)d ago" }
        let f = DateFormatter(); f.dateStyle = .short; return f.string(from: date)
    }
}
