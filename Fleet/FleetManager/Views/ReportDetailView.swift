import SwiftUI

// MARK: - Report Detail View
struct ReportDetailView: View {
    let report: IssueReport
    @State var viewModel: ReportsViewModel

    @State private var selectedStaffId: UUID?
    @Environment(\.dismiss) private var dismiss
    
    @State private var isExporting = false

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
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Header: Vehicle & License Plate
                        VStack(alignment: .leading, spacing: 6) {
                            Text(report.vehicleName)
                                .font(.title2.bold())
                                .foregroundStyle(Color.primary)

                            HStack {
                                Text(report.licensePlate)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.teal)

                                Spacer()

                                // Severity Badge
                                StatusBadge(
                                    text: report.severity.rawValue.capitalized,
                                    color: viewModel.severityColor(report.severity)
                                )
                            }
                        }
                        .padding(.top, 8)

                        Divider().background(Color(.separator))

                        // Driver and DateTime Details
                        VStack(alignment: .leading, spacing: 16) {
                            // Driver Details from Database
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Reported By")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .textCase(.uppercase)

                                if let driver = driverProfile {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(driver.fullName)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color.primary)
                                        Text(driver.email)
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.secondary)
                                        if let phone = driver.phone {
                                            Text(phone)
                                                .font(.system(size: 14))
                                                .foregroundStyle(Color.secondary)
                                        }
                                    }
                                } else {
                                    Text(report.driverName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color.primary)
                                }
                            }

                            // Date details
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reported On")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .textCase(.uppercase)
                                Text(report.submittedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.secondary)
                            }
                        }

                        Divider().background(Color(.separator))

                        // Description Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Issue Description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .textCase(.uppercase)

                            Text(report.description)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.secondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider().background(Color(.separator))

                        // Assignment Section (iOS Native Drop Down)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Assign Maintenance Staff")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
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
                                        .foregroundStyle(Color.teal)

                                    if let selectedStaffId = selectedStaffId {
                                        Text(viewModel.staffName(selectedStaffId))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(Color.primary)
                                    } else {
                                        Text("Unassigned")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(Color.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(.tertiaryLabel))
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
            .navigationTitle("Issue Report")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Generating Document...")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Menu {
                            Button {
                                exportCSV()
                            } label: {
                                Label("Export CSV", systemImage: "tablecells.fill")
                            }
                            
                            Button {
                                Task {
                                    await exportPDF()
                                }
                            } label: {
                                Label("Export PDF", systemImage: "doc.text.fill")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.teal)
                        }
                        
                        Button("Save") {
                            handleSave()
                        }
                        .foregroundStyle(Color.teal)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

    private func handleSave() {
        let newStatus: IssueReportStatus = (selectedStaffId == nil) ? .open : .assigned
        viewModel.update(reportId: report.id, assignedTo: selectedStaffId, status: newStatus)
        dismiss()
    }
    
    private func exportCSV() {
        guard let url = CSVGenerator.generateCSV(from: [report]) else { return }
        ShareSheet.share(items: [url])
    }
    
    private func exportPDF() async {
        isExporting = true
        let vehicle = viewModel.allVehicles.first { $0.id == report.vehicleId }
        let previous = viewModel.reports.filter { $0.vehicleId == report.vehicleId && $0.id != report.id }
        
        if let url = await PDFGenerator.generateSingleReportPDF(
            report: report,
            driverProfile: driverProfile,
            vehicle: vehicle,
            previousIssues: previous
        ) {
            ShareSheet.share(items: [url])
        }
        isExporting = false
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