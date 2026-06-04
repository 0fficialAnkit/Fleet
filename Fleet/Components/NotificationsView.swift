import SwiftUI
internal import Auth

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
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView(
                            "No Notifications",
                            systemImage: "bell.slash",
                            description: Text("You're all caught up.")
                        )
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No Notifications")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            if notification.referenceId != nil {
                                NavigationLink {
                                    NotificationDetailDestination(notification: notification)
                                        .onAppear {
                                            viewModel.markAsRead(notification)
                                        }
                                } label: {
                                    NotificationRowContent(notification: notification)
                                }
                            } else {
                                Button {
                                    viewModel.markAsRead(notification)
                                } label: {
                                    NotificationRowContent(notification: notification)
                                }
                                .tint(.primary)
                            }
                        }
                    }
                    .refreshable { await viewModel.loadData() }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.notifications.filter({ !$0.isRead }).isEmpty {
                        Button("Mark All Read") {
                            viewModel.markAllAsRead()
                        }
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

struct NotificationDetailDestination: View {
    let notification: Notification
    @State private var trip: Trip?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let trip = trip {
                TripDetailView(
                    trip: trip,
                    onStart: { id, vId, notes, urls in
                        Task { try? await TripService.startTrip(id: id) }
                    },
                    onEnd: { id, vId, distance, notes, urls in
                        Task { try? await TripService.endTrip(id: id, distance: distance) }
                    }
                )
            } else {
                Text("Details not found")
            }
        }
        .task {
            if let tripId = notification.referenceId {
                trip = try? await TripService.fetchTrip(id: tripId)
            }
            isLoading = false
        }
    }
}

struct NotificationRowContent: View {
    let notification: Notification

    var iconName: String {
        switch notification.type {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .alert: return "exclamationmark.triangle.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .none: return "bell.fill"
        }
    }

    var iconColor: Color {
        switch notification.type {
        case .info: return Color.blue
        case .warning: return Color.yellow
        case .alert: return Color.red
        case .maintenance: return Color.purple
        case .none: return Color.secondary
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Unread indicator
            Circle()
                .fill(notification.isRead ? Color.clear : Color.blue)
                .frame(width: 10, height: 10)
                .padding(.top, 10)
                .padding(.trailing, -4)

            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
                .padding(.top, 0)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title ?? "Notification")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(notification.isRead ? .secondary : .primary)
                        .lineLimit(2)
                    
                    Spacer(minLength: 8)
                    
                    if let date = notification.createdAt {
                        Text(date.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .layoutPriority(1)
                    }
                }

                Text(notification.message ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 8)
    }
}
