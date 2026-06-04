import SwiftUI
internal import Auth

// MARK: - Notifications View

struct NotificationsView: View {
    @State private var viewModel = NotificationsViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                } else if viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("You're all caught up.")
                    )
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationCard(
                                notification: notification,
                                onMarkRead: { viewModel.markAsRead(notification) }
                            )
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if !notification.isRead {
                                    Button {
                                        viewModel.markAsRead(notification)
                                    } label: {
                                        Label("Read", systemImage: "envelope.open")
                                    }
                                    .tint(.blue)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteNotification(notification)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel.loadData() }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Removed explicit Close button to rely on native swipe-to-dismiss
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.notifications.contains(where: { !$0.isRead }) {
                        Button {
                            viewModel.markAllAsRead()
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 22))
                                .foregroundStyle(.tint)
                        }
                        .accessibilityLabel("Mark all as read")
                    }
                }
            }
        }
        .task {
            viewModel.currentUserId = authViewModel.currentUser?.id
            await viewModel.loadData()
            viewModel.setupRealtime()
        }
    }
}

// MARK: - Notification Card

private struct NotificationCard: View {
    let notification: Notification
    let onMarkRead: () -> Void

    private var cleanTitle: String {
        let raw = notification.title ?? "Notification"
        return raw.replacingOccurrences(
            of: "[^a-zA-Z0-9 :\\-.,!?'\"]",
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var iconConfig: (name: String, color: Color) {
        switch notification.type {
        case .info:        return ("info.circle.fill", .blue)
        case .warning:     return ("exclamationmark.triangle.fill", .orange)
        case .alert:       return ("exclamationmark.triangle.fill", .red)
        case .maintenance: return ("wrench.and.screwdriver.fill", .purple)
        case .none:        return ("bell.fill", .secondary)
        }
    }

    var body: some View {
        Group {
            if let referenceId = notification.referenceId {
                NavigationLink {
                    NotificationDetailDestination(notification: notification)
                        .onAppear { onMarkRead() }
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)

                // Silence unused referenceId warning
                .id(referenceId)
            } else {
                cardContent
                    .contentShape(Rectangle())
                    .onTapGesture { onMarkRead() }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var cardContent: some View {
        HStack(alignment: .center, spacing: 12) {

            // Unread dot
            if !notification.isRead {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
            } else {
                Spacer()
                    .frame(width: 8, height: 8)
            }

            // Icon
            Image(systemName: iconConfig.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(iconConfig.color)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Text
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(cleanTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(notification.isRead ? .secondary : .primary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if let date = notification.createdAt {
                        Text(date.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .layoutPriority(1)
                    }
                }

                Text(notification.message ?? "")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            // Extra trailing space so text doesn't collide with the chevron overlay
            .padding(.trailing, notification.referenceId != nil ? 16 : 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Notification Detail Destination

struct NotificationDetailDestination: View {
    let notification: Notification
    @State private var trip: Trip?
    @State private var isLoading = true
    @State private var ordersViewModel = OrdersViewModel()
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let trip {
                OrderDetailView(trip: trip, viewModel: ordersViewModel)
            } else {
                ContentUnavailableView(
                    "Trip Not Found",
                    systemImage: "questionmark.circle",
                    description: Text("This trip may have been deleted.")
                )
            }
        }
        .task {
            ordersViewModel.adminId = authViewModel.currentUserId
            await ordersViewModel.loadData()
            if let tripId = notification.referenceId {
                trip = try? await TripService.fetchTrip(id: tripId)
            }
            isLoading = false
        }
    }
}
