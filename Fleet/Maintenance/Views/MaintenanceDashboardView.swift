import SwiftUI
import Supabase

struct MaintenanceDashboardView: View {
    @Binding var selectedTab: Int
    @State private var viewModel = MaintenanceDashboardViewModel()
    @State private var isShowingProfile = false
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: themeModel.spacingLG) {

                        // MARK: - KPI Summary Cards
                        VStack(spacing: themeModel.spacingMD) {
                            HStack(spacing: themeModel.spacingMD) {
                                NavigationLink(value: MaintenanceDestination.workOrderList(filter: nil, assignedTo: viewModel.currentUserId, priority: nil)) {
                                    DashboardCard(
                                        title: "OPEN WORK\nORDERS",
                                        value: "\(viewModel.openWorkOrders)",
                                        icon: "clipboard",
                                        titleColor: Color(red: 59/255, green: 77/255, blue: 140/255),
                                        valueColor: Color(red: 29/255, green: 40/255, blue: 82/255),
                                        backgroundColor: Color(red: 238/255, green: 242/255, blue: 255/255)
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink(value: MaintenanceDestination.workOrderList(filter: nil, assignedTo: viewModel.currentUserId, priority: .critical)) {
                                    DashboardCard(
                                        title: "CRITICAL\nREPAIRS",
                                        value: "\(viewModel.criticalRepairsCount)",
                                        icon: "exclamationmark.triangle",
                                        titleColor: Color(red: 178/255, green: 42/255, blue: 42/255),
                                        valueColor: Color(red: 229/255, green: 62/255, blue: 62/255),
                                        backgroundColor: Color(red: 255/255, green: 237/255, blue: 237/255)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Button {
                                selectedTab = 2 // Switch to Inventory Tab
                            } label: {
                                AvailablePartsCard(percentage: viewModel.availablePartsPercentage)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, themeModel.spacingMD)

                        // MARK: - Upcoming Scheduled Tasks
                        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                            SectionHeader(title: "Upcoming Maintenance")
                                .padding(.horizontal, themeModel.spacingMD)

                            if viewModel.upcomingItems.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: themeModel.spacingSM) {
                                        Image(systemName: "calendar.badge.checkmark")
                                            .font(.system(size: 32))
                                            .foregroundStyle(themeModel.textTertiary)
                                        Text("No upcoming tasks")
                                            .font(themeModel.bodyMedium())
                                            .foregroundStyle(themeModel.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, themeModel.spacingLG)
                            } else {
                                VStack(spacing: themeModel.spacingMD) {
                                    ForEach(viewModel.upcomingItems) { item in
                                        UpcomingMaintenanceCard(item: item)
                                    }
                                }
                                .padding(.horizontal, themeModel.spacingMD)
                            }
                        }

                        // MARK: - Priority Queue
                        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                            SectionHeader(title: "Priority Queue", action: "View All") {
                                // Navigate to all unified items, maybe workOrderList with priority filter
                            }
                            .padding(.horizontal, themeModel.spacingMD)

                            if viewModel.priorityQueueItems.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: themeModel.spacingSM) {
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 32))
                                            .foregroundStyle(themeModel.success)
                                        Text("No priority tasks")
                                            .font(themeModel.bodyMedium())
                                            .foregroundStyle(themeModel.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, themeModel.spacingLG)
                            } else {
                                VStack(spacing: themeModel.spacingMD) {
                                    ForEach(viewModel.priorityQueueItems) { item in
                                        PriorityQueueCard(item: item, viewModel: viewModel)
                                    }
                                }
                                .padding(.horizontal, themeModel.spacingMD)
                            }
                        }

                    }
                    .padding(.vertical, themeModel.spacingMD)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingProfile = true }) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 28, weight: .medium))
//                            .foregroundStyle(themeModel.maintenancePrimary)
                    }
                }
            }
            .navigationDestination(for: MaintenanceDestination.self) { destination in
                switch destination {
                case .workOrderDetail(let order):
                    WorkOrderDetailView(workOrder: order)
                case .issueReportDetail(let report):
                    IssueReportDetailView(report: report)
                case .workOrderList(let filter, let assignedTo, let priority):
                    WorkOrderListView(initialFilter: filter, assignedUserId: assignedTo, priorityFilter: priority)
                }
            }
            .sheet(isPresented: $isShowingProfile) {
                MaintenanceProfileView()
                    .environment(authViewModel)
            }
            .task {
                viewModel.currentUserId = authViewModel.currentUser?.id
                await viewModel.loadData()
                viewModel.setupRealtime()
            }
        }
    }
}

// MARK: - Upcoming Maintenance Card
struct UpcomingMaintenanceCard: View {
    let item: UpcomingDisplayItem

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Image Placeholder & Badge
            ZStack(alignment: .topLeading) {
                // Placeholder Image
                Rectangle()
                    .fill(themeModel.surfaceTertiary)
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: "box.truck.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(themeModel.textTertiary.opacity(0.3))
                    )
                
                // Priority Badge
                if let priorityLabel = item.priorityLabel, let priorityColor = item.priorityColor {
                    Text(priorityLabel.capitalized)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(priorityColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(12)
                }
            }
            
            // MARK: - Content
            VStack(alignment: .leading, spacing: 12) {
                // Tags
                HStack(spacing: 8) {
                    Text(item.referenceId)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(themeModel.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeModel.surfaceTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Text(item.assignmentTag)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(themeModel.maintenancePrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeModel.maintenancePrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Titles
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.vehicleName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(themeModel.textPrimary)
                    
                    Text(item.taskDescription)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(themeModel.textSecondary)
                }
                
                // Meta Info
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                        Text("Est. \(item.estimatedDuration)")
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "wrench.adjustable")
                        Text(item.location)
                    }
                }
                .font(.system(size: 14))
                .foregroundStyle(themeModel.textSecondary)
                .padding(.vertical, 4)
                
                // Action Buttons
                VStack(spacing: 10) {
                    Button {
                        // Handle Start Action
                    } label: {
                        HStack {
                            Image(systemName: item.actionButtonIcon)
                            Text(item.actionButtonTitle)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(themeModel.maintenancePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    if let destination = item.destination {
                        NavigationLink(value: destination) {
                            Text("View Details")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(themeModel.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(themeModel.border, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(themeModel.surfacePrimary)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: themeModel.shadowPrimary, radius: 10, y: 4)
    }
}

// MARK: - Reusable Cards
struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let titleColor: Color
    let valueColor: Color
    let backgroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(titleColor)
                    .lineLimit(2)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(titleColor)
            }
            
            Text(value)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(valueColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

struct AvailablePartsCard: View {
    let percentage: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("AVAILABLE PARTS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(percentage)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    Text("%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 60, height: 60)
                Image(systemName: "shippingbox")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 122/255, green: 140/255, blue: 158/255))
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

// MARK: - Priority Queue Card
struct PriorityQueueCard: View {
    let item: UnifiedMaintenanceItem
    let viewModel: MaintenanceDashboardViewModel
    
    var iconName: String {
        switch item {
        case .issueReport: return "exclamationmark.triangle.fill"
        case .workOrder: return "wrench.and.screwdriver.fill"
        }
    }
    
    var priorityColor: Color {
        switch item.unifiedPriority {
        case .critical, .high: return themeModel.danger
        case .medium: return themeModel.info
        case .low: return themeModel.textSecondary
        case nil: return themeModel.textSecondary
        }
    }
    
    var priorityLabel: String {
        switch item.unifiedPriority {
        case .critical: return "CRITICAL"
        case .high: return "HIGH"
        case .medium: return "MED"
        case .low: return "LOW"
        case nil: return "NONE"
        }
    }
    
    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            ZStack {
                RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                    .fill(priorityColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(priorityColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.vehiclePlate(for: item.vehicleId))
                    .font(themeModel.headline(16))
                    .foregroundStyle(themeModel.textPrimary)
                
                Text(item.subtitle)
                    .font(themeModel.bodyMedium(14))
                    .foregroundStyle(themeModel.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                Text(priorityLabel)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.15))
                    .foregroundColor(priorityColor)
                    .clipShape(Capsule())
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeModel.textTertiary)
            }
        }
        .padding(themeModel.spacingMD)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

#Preview {
    MaintenanceDashboardView(selectedTab: .constant(0))
        .environment(AuthViewModel())
}
