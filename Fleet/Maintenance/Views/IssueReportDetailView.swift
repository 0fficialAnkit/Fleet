import SwiftUI

struct IssueReportDetailView: View {
    let report: IssueReportRecord
    @State private var currentStatus: String
    @State private var notes: String = ""

    init(report: IssueReportRecord) {
        self.report = report
        _currentStatus = State(initialValue: report.status)
    }

    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: themeModel.spacingLG) {

                    // MARK: - Status Banner
                    HStack(spacing: themeModel.spacingSM) {
                        Image(systemName: statusIcon(currentStatus))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(statusColor(currentStatus))
                        Text(statusLabel(currentStatus))
                            .font(themeModel.headline())
                            .foregroundStyle(statusColor(currentStatus))
                        Spacer()
                        StatusBadge(
                            text: severityLabel(report.severity),
                            color: severityColor(report.severity),
                            icon: severityIcon(report.severity)
                        )
                    }
                    .padding(themeModel.spacingMD)
                    .background(statusColor(currentStatus).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                            .stroke(statusColor(currentStatus).opacity(0.25), lineWidth: 1)
                    )

                    // MARK: - Details Section
                    GlassSection(title: "Report Details") {
                        InfoRow(icon: "number", label: "Report ID", value: "REP-\(report.id.uuidString.prefix(8).uppercased())")
                        divider
                        InfoRow(icon: "car.fill", label: "Vehicle", value: "VH-\(report.vehicleId.uuidString.prefix(8).uppercased())")
                        divider
                        InfoRow(icon: "tag.fill", label: "Category", value: report.category)
                        divider
                        InfoRow(icon: "flag.fill", label: "Severity", value: severityLabel(report.severity), valueColor: severityColor(report.severity))
                        divider
                        InfoRow(icon: "calendar", label: "Created", value: report.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "N/A")
                    }

                    // MARK: - Description
                    if let desc = report.description, !desc.isEmpty {
                        GlassSection(title: "Description") {
                            Text(desc)
                                .font(themeModel.body())
                                .foregroundStyle(themeModel.textPrimary)
                        }
                    }

                    // MARK: - Action Buttons
                    VStack(spacing: themeModel.spacingMD) {
                        if currentStatus.lowercased() == "open" || currentStatus.lowercased() == "assigned" {
                            ActionButton(title: "Start Work", icon: "play.circle.fill", color: themeModel.maintenancePrimary) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = "in_progress" }
                            }
                        }
                        if currentStatus.lowercased() == "in_progress" {
                            ActionButton(title: "Mark as Resolved", icon: "checkmark.circle.fill", color: themeModel.success) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = "resolved" }
                            }
                        }
                        if currentStatus.lowercased() == "resolved" || currentStatus.lowercased() == "closed" {
                            ActionButton(title: "Reopen Issue", icon: "arrow.counterclockwise.circle.fill", color: themeModel.warning) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentStatus = "in_progress" }
                            }
                        }
                    }
                    .padding(.bottom, themeModel.spacingLG)
                }
                .padding(themeModel.spacingMD)
            }
        }
        .navigationTitle("Issue Report")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var divider: some View { Divider().background(themeModel.divider) }

    // MARK: - Helpers
    func statusIcon(_ s: String) -> String {
        switch s.lowercased() {
        case "open", "assigned": return "tray.circle"
        case "in_progress": return "wrench.adjustable"
        case "resolved", "closed": return "checkmark.circle.fill"
        default: return "tray.circle"
        }
    }
    
    func statusLabel(_ s: String) -> String {
        switch s.lowercased() {
        case "open": return "Open"
        case "assigned": return "Assigned"
        case "in_progress": return "In Progress"
        case "resolved": return "Resolved"
        case "closed": return "Closed"
        default: return "Unknown"
        }
    }
    
    func statusColor(_ s: String) -> Color {
        switch s.lowercased() {
        case "open", "assigned": return themeModel.info
        case "in_progress": return themeModel.warning
        case "resolved", "closed": return themeModel.success
        default: return themeModel.textSecondary
        }
    }
    
    func severityLabel(_ p: String) -> String {
        switch p.lowercased() {
        case "low": return "Low"
        case "medium": return "Medium"
        case "high": return "High"
        case "critical": return "Critical"
        default: return "N/A"
        }
    }
    
    func severityIcon(_ p: String) -> String {
        switch p.lowercased() {
        case "low": return "arrow.down.circle"
        case "medium": return "minus.circle"
        case "high": return "arrow.up.circle"
        case "critical": return "exclamationmark.2"
        default: return "minus.circle"
        }
    }
    
    func severityColor(_ p: String) -> Color {
        switch p.lowercased() {
        case "critical": return themeModel.danger
        case "high": return themeModel.warning
        case "medium": return themeModel.info
        case "low": return themeModel.success
        default: return themeModel.textSecondary
        }
    }
}

// MARK: - GlassSection
private struct GlassSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            SectionHeader(title: title)
            VStack(spacing: themeModel.spacingMD) {
                content()
            }
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
        }
    }
}

// MARK: - Action Button
private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: themeModel.spacingSM) {
                Image(systemName: icon)
                Text(title)
            }
            .font(themeModel.headline())
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.15), radius: 8, y: 4)
        }
    }
}
