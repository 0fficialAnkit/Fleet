import SwiftUI

// MARK: - Generic Maintenance Assignment Sheet

struct MaintenanceAssignmentSheet: View {
    let vehicleName: String
    let licensePlate: String
    let severityLabel: String
    let severityColor: Color
    let severityIcon: String
    
    let issueTitle: String
    let issueDescription: String
    let recommendationTitle: String
    let recommendationDescription: String
    
    let maintenanceStaff: [Profile]
    let onAssign: (_ staffId: UUID, _ notes: String) async throws -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStaffId: UUID?
    @State private var notes: String = ""
    @State private var isAssigning = false
    @State private var assignSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                // ── Vehicle Details ──────────────────────────────────
                Section("Vehicle Details") {
                    LabeledContent("Vehicle", value: vehicleName)
                    LabeledContent("Licence Plate", value: licensePlate)
                    HStack {
                        Text("Severity")
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: severityIcon)
                                .font(.system(size: 11))
                            Text(severityLabel)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(severityColor)
                    }
                }
                
                // ── Alert Details ────────────────────────────────────
                Section("Alert Details") {
                    LabeledContent("Category", value: issueTitle)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(issueDescription)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recommendation")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(recommendationDescription)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
                
                // ── Assign to Maintenance ────────────────────────────
                Section("Assign to Maintenance") {
                    if maintenanceStaff.isEmpty {
                        Text("No maintenance staff available")
                            .foregroundStyle(Color.secondary)
                    } else {
                        Picker("Assign To", selection: $selectedStaffId) {
                            Text("Not Assigned").tag(nil as UUID?)
                            ForEach(maintenanceStaff, id: \.id) { staff in
                                Text(staff.fullName).tag(staff.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.primary)
                    }
                }
                
                // ── Notes ────────────────────────────────────────────
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(Color.red)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Assign Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isAssigning {
                        ProgressView()
                    } else {
                        Button(assignSuccess ? "Assigned" : "Assign") {
                            assignTask()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedStaffId != nil && !assignSuccess ? Color.teal : Color.secondary)
                        .disabled(selectedStaffId == nil || assignSuccess)
                    }
                }
            }
        }
    }

    private func assignTask() {
        guard let staffId = selectedStaffId else { return }
        isAssigning = true
        errorMessage = nil
        Task {
            do {
                try await onAssign(staffId, notes)
                await MainActor.run {
                    isAssigning = false
                    assignSuccess = true
                }
                try? await Task.sleep(for: .seconds(1.2))
                await MainActor.run { dismiss() }
            } catch {
                print("[MaintenanceAssignmentSheet] assignTask error: \(error)")
                await MainActor.run {
                    isAssigning = false
                    errorMessage = "Failed to assign: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    MaintenanceAssignmentSheet(
        vehicleName: "Tesla Model 3",
        licensePlate: "CA-9988",
        severityLabel: "Critical",
        severityColor: .red,
        severityIcon: "exclamationmark.triangle.fill",
        issueTitle: "Brake System Malfunction",
        issueDescription: "The driver reported that the brake pedal feels soft and the vehicle takes longer to stop than expected. Warning light on dashboard is active.",
        recommendationTitle: "Immediate Service",
        recommendationDescription: "Tow vehicle to maintenance depot. Inspect master cylinder, check brake fluid levels, and scan for OBD codes.",
        maintenanceStaff: [
            Profile(
                id: UUID(uuidString: "e1aa00aa-bbbb-cccc-dddd-eeeeeeffffff") ?? UUID(),
                fullName: "Alex Rivera",
                email: "alex@fleet.com",
                phone: "+1 (555) 019-2834",
                licenseNumber: nil,
                role: "maintenance",
                status: "active",
                createdAt: Date()
            ),
            Profile(
                id: UUID(uuidString: "e2bb11bb-cccc-dddd-eeee-ffffff000000") ?? UUID(),
                fullName: "Jordan Lee",
                email: "jordan@fleet.com",
                phone: "+1 (555) 019-5821",
                licenseNumber: nil,
                role: "maintenance",
                status: "active",
                createdAt: Date()
            )
        ],
        onAssign: { staffId, notes in
            print("Assigned to \(staffId) with notes: \(notes)")
        }
    )
}
