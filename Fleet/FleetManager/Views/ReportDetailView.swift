import SwiftUI

// MARK: - Report Detail View
struct ReportDetailView: View {
    let report: IssueReport
    @State var viewModel: ReportsViewModel

    @State private var selectedStaffId: UUID?
    @Environment(\.dismiss) private var dismiss

    init(report: IssueReport, viewModel: ReportsViewModel) {
        self.report = report
        self.viewModel = viewModel
        _selectedStaffId = State(initialValue: report.assignedTo)
    }

    var driverProfile: Profile? {
        viewModel.profiles.first { $0.id == report.reportedBy }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header: Vehicle & License Plate
                        VStack(alignment: .leading, spacing: 6) {
                            Text(report.vehicleName)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(themeModel.textPrimary)
                            
                            HStack {
                                Text(report.licensePlate)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(themeModel.accent)
                                
                                Spacer()
                                
                                // Severity Badge
                                StatusBadge(
                                    text: report.severity.rawValue.capitalized,
                                    color: viewModel.severityColor(report.severity)
                                )
                            }
                        }
                        .padding(.top, 8)
                        
                        Divider().background(themeModel.divider)
                        
                        // Driver and DateTime Details
                        VStack(alignment: .leading, spacing: 16) {
                            // Driver Details from Database
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Reported By")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(themeModel.textTertiary)
                                    .textCase(.uppercase)
                                
                                if let driver = driverProfile {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(driver.fullName)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(themeModel.textPrimary)
                                        Text(driver.email)
                                            .font(.system(size: 14))
                                            .foregroundStyle(themeModel.textSecondary)
                                        if let phone = driver.phone {
                                            Text(phone)
                                                .font(.system(size: 14))
                                                .foregroundStyle(themeModel.textSecondary)
                                        }
                                    }
                                } else {
                                    Text(report.driverName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(themeModel.textPrimary)
                                }
                            }
                            
                            // Date details
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reported On")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(themeModel.textTertiary)
                                    .textCase(.uppercase)
                                Text(report.submittedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 15))
                                    .foregroundStyle(themeModel.textSecondary)
                            }
                        }
                        
                        Divider().background(themeModel.divider)
                        
                        // Description Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Issue Description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(themeModel.textTertiary)
                                .textCase(.uppercase)
                            
                            Text(report.description)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(themeModel.textSecondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Divider().background(themeModel.divider)
                        
                        // Assignment Section (iOS Native Drop Down)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Assign Maintenance Staff")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(themeModel.textTertiary)
                                .textCase(.uppercase)
                            
                            Menu {
                                Button(action: {
                                    withAnimation {
                                        selectedStaffId = nil
                                    }
                                }) {
                                    HStack {
                                        Text("Unassigned")
                                        if selectedStaffId == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                ForEach(viewModel.maintenanceStaff) { staff in
                                    Button(action: {
                                        withAnimation {
                                            selectedStaffId = staff.id
                                        }
                                    }) {
                                        HStack {
                                            let workload = viewModel.staffWorkloadStatus(staff.id)
                                            Text("\(staff.fullName) — \(workload)")
                                            if selectedStaffId == staff.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(themeModel.accent)
                                    
                                    if let selectedStaffId = selectedStaffId {
                                        Text(viewModel.staffName(selectedStaffId))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(themeModel.textPrimary)
                                    } else {
                                        Text("Unassigned")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(themeModel.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundStyle(themeModel.textTertiary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                        }
                        
                    }
                    .padding(24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Issue Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(themeModel.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        handleSave()
                    }
                    .foregroundStyle(themeModel.accent)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func handleSave() {
        let newStatus: IssueReportStatus = (selectedStaffId == nil) ? .open : .assigned
        viewModel.update(reportId: report.id, assignedTo: selectedStaffId, status: newStatus)
        dismiss()
    }
}

#Preview {
    ReportDetailView(
        report: IssueReport(
            id: UUID(),
            vehicleId: UUID(),
            reportedBy: UUID(),
            vehicleName: "Ford Transit",
            licensePlate: "CA-12345",
            driverName: "John Doe",
            issueCategory: "Brakes",
            severity: .critical,
            description: "Front brake pads are worn down to the metal, causing grinding sound.",
            submittedAt: Date(),
            assignedTo: nil,
            status: .open
        ),
        viewModel: ReportsViewModel()
    )
}
