import SwiftUI
internal import Auth

struct NotificationsView: View {
    @State private var viewModel = NotificationsViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.secondary)
                        Text("No notifications")
                            .font(.body)
                            .foregroundStyle(Color.secondary)
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
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                            } else {
                                Button {
                                    viewModel.markAsRead(notification)
                                } label: {
                                    NotificationRowContent(notification: notification)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                    .refreshable { await viewModel.loadData() }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.notifications.filter({ !$0.isRead }).isEmpty {
                        Button("Mark All Read") {
                            viewModel.markAllAsRead()
                        }
                        .foregroundStyle(Color.teal)
                        .font(.footnote)
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
                    onEnd: { id, vId, notes, urls in
                        Task { try? await TripService.endTrip(id: id) }
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
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title ?? "Notification")
                        .font(.body.bold())
                        .foregroundStyle(notification.isRead ? Color.secondary : Color.primary)
                    Spacer()
                    if let date = notification.createdAt {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }

                Text(notification.message ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(notification.isRead ? Color.white.opacity(0.02) : Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(notification.isRead ? Color.clear : iconColor.opacity(0.3), lineWidth: 1)
        )
    }
}
