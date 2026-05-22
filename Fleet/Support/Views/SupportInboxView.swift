import SwiftUI

struct SupportInboxView: View {
    let userRole: UserRole
    let userId: UUID
    @State private var viewModel = SupportViewModel()
    @State private var showingCreateTicket = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: themeModel.spacingSM) {
                ForEach(viewModel.tickets(for: userId, role: userRole)) { ticket in
                    NavigationLink(destination: TicketDetailView(ticket: ticket, userRole: userRole, userId: userId, viewModel: viewModel)) {
                        TicketRowView(ticket: ticket, viewModel: viewModel, userRole: userRole)
                    }.buttonStyle(.plain)
                }
                if viewModel.tickets(for: userId, role: userRole).isEmpty { emptyState }
            }
            .padding(.horizontal).padding(.top, themeModel.spacingSM)
        }
        .background(themeModel.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(userRole == .driver ? "My Tickets" : "Support Tickets")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .toolbar {
            if userRole == .driver {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingCreateTicket = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(themeModel.accent).font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateTicket) {
            CreateTicketView(viewModel: viewModel, driverId: userId)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: themeModel.spacingMD) {
            Image(systemName: "ticket").font(.system(size: 48)).foregroundColor(themeModel.textTertiary)
            Text("No tickets yet").font(themeModel.headline()).foregroundStyle(themeModel.textSecondary)
            if userRole == .driver {
                Text("Tap + to raise a new support ticket").font(themeModel.caption()).foregroundStyle(themeModel.textTertiary)
            }
        }.padding(.top, 60)
    }
}

struct TicketRowView: View {
    let ticket: SupportTicket; let viewModel: SupportViewModel; let userRole: UserRole
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            Image(systemName: viewModel.categoryIcon(ticket.category))
                .font(.system(size: 20)).foregroundColor(viewModel.categoryColor(ticket.category))
                .frame(width: 42, height: 42)
                .background(viewModel.categoryColor(ticket.category).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
            VStack(alignment: .leading, spacing: themeModel.spacingXS) {
                HStack {
                    Text(ticket.subject ?? "No Subject").font(themeModel.headline(15)).foregroundStyle(themeModel.textPrimary).lineLimit(1)
                    Spacer()
                    Text(viewModel.relativeTime(ticket.updatedAt)).font(themeModel.small()).foregroundColor(themeModel.textTertiary)
                }
                if let lastMsg = viewModel.lastMessage(for: ticket.id) {
                    Text(lastMsg.message ?? "").font(themeModel.caption()).foregroundColor(themeModel.textSecondary).lineLimit(1)
                }
                HStack(spacing: themeModel.spacingSM) {
                    Text(viewModel.statusLabel(ticket.status)).font(themeModel.small())
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(viewModel.statusColor(ticket.status).opacity(0.15))
                        .foregroundColor(viewModel.statusColor(ticket.status))
                        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusXS))
                    Text(viewModel.categoryLabel(ticket.category)).font(themeModel.small()).foregroundColor(themeModel.textTertiary)
                    if userRole == .fleetManager {
                        Spacer()
                        Text(viewModel.driverName(for: ticket.driverId)).font(themeModel.small()).foregroundColor(themeModel.textSecondary)
                    }
                }
            }
            Image(systemName: "chevron.right").font(.caption).foregroundColor(themeModel.textTertiary)
        }
        .padding(themeModel.spacingMD).background(themeModel.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
        .shadow(color: themeModel.shadowSoft, radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        SupportInboxView(userRole: .driver, userId: UUID(uuidString: "22000000-0000-0000-0000-000000000002")!)
    }.preferredColorScheme(.dark)
}
