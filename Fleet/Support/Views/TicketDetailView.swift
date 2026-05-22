import SwiftUI

struct TicketDetailView: View {
    let ticket: SupportTicket; let userRole: UserRole; let userId: UUID; var viewModel: SupportViewModel
    @State private var newMessage = ""
    
    private var current: SupportTicket { viewModel.tickets.first { $0.id == ticket.id } ?? ticket }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: themeModel.spacingMD) {
                        ticketHeader
                        ForEach(viewModel.messages(for: ticket.id)) { msg in
                            MessageBubble(message: msg, isCurrentUser: msg.senderId == userId, senderName: viewModel.senderName(for: msg.senderId)).id(msg.id)
                        }
                    }.padding(themeModel.spacingMD)
                }
                .onChange(of: viewModel.messages(for: ticket.id).count) {
                    if let last = viewModel.messages(for: ticket.id).last?.id { withAnimation { proxy.scrollTo(last, anchor: .bottom) } }
                }
            }
            if current.status != .closed && current.status != .resolved { composeBar } else { closedBanner }
        }
        .background(themeModel.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(current.subject ?? "Ticket").navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .toolbar {
            if userRole == .fleetManager {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if current.status != .resolved { Button { viewModel.updateStatus(ticketId: ticket.id, to: .resolved) } label: { Label("Mark Resolved", systemImage: "checkmark.circle") } }
                        if current.status != .closed { Button { viewModel.updateStatus(ticketId: ticket.id, to: .closed) } label: { Label("Close Ticket", systemImage: "xmark.circle") } }
                        if current.status == .open { Button { viewModel.updateStatus(ticketId: ticket.id, to: .inProgress) } label: { Label("Mark In Progress", systemImage: "arrow.triangle.2.circlepath") } }
                    } label: { Image(systemName: "ellipsis.circle").foregroundColor(themeModel.accent) }
                }
            }
        }
    }
    
    private var ticketHeader: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.categoryIcon(current.category)).foregroundColor(viewModel.categoryColor(current.category))
                    Text(viewModel.categoryLabel(current.category)).font(themeModel.bodyMedium()).foregroundStyle(themeModel.textPrimary)
                }
                Spacer()
                Text(viewModel.statusLabel(current.status)).font(themeModel.small()).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(viewModel.statusColor(current.status).opacity(0.15))
                    .foregroundColor(viewModel.statusColor(current.status))
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXS))
            }
            if userRole == .fleetManager {
                Text("Driver: \(viewModel.driverName(for: current.driverId))").font(themeModel.caption()).foregroundColor(themeModel.textSecondary)
            }
            Text("Created \(viewModel.relativeTime(current.createdAt))").font(themeModel.small()).foregroundColor(themeModel.textTertiary)
        }
        .padding(themeModel.spacingMD).background(themeModel.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
        .shadow(color: themeModel.shadowSoft, radius: 5, x: 0, y: 2)
    }
    
    private var composeBar: some View {
        HStack(spacing: themeModel.spacingSM) {
            TextField("Type a message...", text: $newMessage, axis: .vertical).lineLimit(1...4)
                .font(themeModel.body()).foregroundStyle(themeModel.textPrimary)
                .padding(.horizontal, 12).padding(.vertical, 10).background(themeModel.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD))
                .overlay(RoundedRectangle(cornerRadius: themeModel.radiusMD).stroke(themeModel.inputBorder, lineWidth: 1))
            Button(action: sendMsg) {
                Image(systemName: "paperplane.fill").font(.system(size: 18))
                    .foregroundColor(newMessage.trimmingCharacters(in: .whitespaces).isEmpty ? themeModel.textDisabled : themeModel.accent)
                    .frame(width: 42, height: 42)
                    .background(newMessage.trimmingCharacters(in: .whitespaces).isEmpty ? themeModel.surfaceTertiary : themeModel.accent.opacity(0.15))
                    .clipShape(Circle())
            }.disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
        }.padding(.horizontal, themeModel.spacingMD).padding(.vertical, themeModel.spacingSM).background(themeModel.backgroundSecondary)
    }
    
    private var closedBanner: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill").foregroundColor(themeModel.success)
            Text("This ticket has been \(viewModel.statusLabel(current.status).lowercased())").font(themeModel.caption()).foregroundStyle(themeModel.textSecondary)
        }.padding(themeModel.spacingMD).frame(maxWidth: .infinity).background(themeModel.backgroundSecondary)
    }
    
    private func sendMsg() {
        let text = newMessage.trimmingCharacters(in: .whitespaces); guard !text.isEmpty else { return }
        viewModel.sendMessage(ticketId: ticket.id, senderId: userId, text: text); newMessage = ""
    }
}

struct MessageBubble: View {
    let message: TicketMessage; let isCurrentUser: Bool; let senderName: String
    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: themeModel.spacingXS) {
                Text(senderName).font(themeModel.small()).foregroundColor(themeModel.textTertiary)
                Text(message.message ?? "").font(themeModel.body())
                    .foregroundStyle(isCurrentUser ? themeModel.accentForeground : themeModel.textPrimary)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(isCurrentUser ? themeModel.accent : themeModel.backgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD))
                if let t = message.sentAt { Text(t, style: .time).font(themeModel.small()).foregroundColor(themeModel.textTertiary) }
            }
            if !isCurrentUser { Spacer(minLength: 60) }
        }
    }
}
