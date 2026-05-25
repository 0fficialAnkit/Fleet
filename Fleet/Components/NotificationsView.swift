import SwiftUI
internal import Auth

struct NotificationsView: View {
    @State private var viewModel = NotificationsViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(themeModel.textSecondary)
                        Text("No notifications")
                            .font(themeModel.body())
                            .foregroundColor(themeModel.textSecondary)
                    }
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRow(notification: notification) {
                                if !notification.isRead {
                                    viewModel.markAsRead(notification)
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
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
                    .foregroundColor(themeModel.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.notifications.filter({ !$0.isRead }).isEmpty {
                        Button("Mark All Read") {
                            viewModel.markAllAsRead()
                        }
                        .foregroundColor(themeModel.accent)
                        .font(themeModel.caption())
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

struct NotificationRow: View {
    let notification: Notification
    let onTap: () -> Void
    
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
        case .info: return themeModel.info
        case .warning: return themeModel.warning
        case .alert: return themeModel.danger
        case .maintenance: return themeModel.analyticsPurple
        case .none: return themeModel.textSecondary
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title ?? "Notification")
                            .font(themeModel.headline(16))
                            .foregroundColor(notification.isRead ? themeModel.textSecondary : themeModel.textPrimary)
                        Spacer()
                        if let date = notification.createdAt {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(themeModel.caption(12))
                                .foregroundColor(themeModel.textTertiary)
                        }
                    }
                    
                    Text(notification.message ?? "")
                        .font(themeModel.body(14))
                        .foregroundColor(themeModel.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .fill(notification.isRead ? Color.white.opacity(0.02) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(notification.isRead ? Color.clear : iconColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
