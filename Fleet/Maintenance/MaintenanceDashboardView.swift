import SwiftUI

struct MaintenanceDashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    HStack {
                        SummaryCard(title: "Pending Tasks", count: "12", icon: "exclamationmark.circle.fill", color: .orange)
                        SummaryCard(title: "In Progress", count: "5", icon: "arrow.triangle.2.circlepath", color: .blue)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        SummaryCard(title: "Completed Today", count: "8", icon: "checkmark.circle.fill", color: .green)
                        SummaryCard(title: "Low Stock Items", count: "3", icon: "exclamationmark.triangle.fill", color: .red)
                    }
                    .padding(.horizontal)
                    
                    // AI Predictive Maintenance Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AI Insights")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        GroupBox {
                            HStack(alignment: .top) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.yellow)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Vehicle V-102 likely needs brake pad replacement in the next 3 days.")
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("Confidence: 92%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Upcoming Scheduled Tasks
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Upcoming Scheduled Maintenance")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TaskRow(vehicleId: "V-204", taskType: "Oil Change", date: "Today, 2:00 PM")
                            TaskRow(vehicleId: "V-118", taskType: "Tire Rotation", date: "Tomorrow, 9:00 AM")
                            TaskRow(vehicleId: "V-305", taskType: "Annual Inspection", date: "Oct 25, 10:00 AM")
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct SummaryCard: View {
    let title: String
    let count: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
                Text(count)
                    .font(.title)
                    .bold()
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct TaskRow: View {
    let vehicleId: String
    let taskType: String
    let date: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vehicleId)
                    .font(.headline)
                Text(taskType)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(date)
                    .font(.caption)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    MaintenanceDashboardView()
}
