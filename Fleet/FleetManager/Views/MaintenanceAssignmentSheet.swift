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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Vehicle summary card
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(severityColor.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(severityColor)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(vehicleName)
                                .font(.title3.bold())
                            Text(licensePlate)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: severityIcon)
                                    .font(.system(size: 11))
                                Text(severityLabel)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(severityColor)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Alert details
                    VStack(alignment: .leading, spacing: 12) {
                        Label(issueTitle, systemImage: "magnifyingglass")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        Text(issueDescription)
                            .font(.body)
                            .foregroundStyle(Color.primary)

                        Divider()

                        Label(recommendationTitle, systemImage: "lightbulb.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        Text(recommendationDescription)
                            .font(.body)
                            .foregroundStyle(Color.primary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Staff picker
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Assign to Maintenance Staff", systemImage: "person.2.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal)

                        if maintenanceStaff.isEmpty {
                            HStack {
                                Image(systemName: "person.fill.xmark")
                                    .foregroundStyle(Color.secondary)
                                Text("No maintenance staff available")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            .padding()
                        } else {
                            ForEach(maintenanceStaff, id: \.id) { person in
                                Button(action: { selectedStaffId = person.id }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.teal.opacity(0.15))
                                                .frame(width: 40, height: 40)
                                            Text(String(person.fullName.prefix(1)).uppercased())
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(Color.teal)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(person.fullName)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(Color.primary)
                                            if let phone = person.phone {
                                                Text(phone)
                                                    .font(.caption)
                                                    .foregroundStyle(Color.secondary)
                                            }
                                        }
                                        Spacer()
                                        if selectedStaffId == person.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.teal)
                                                .font(.system(size: 20))
                                        } else {
                                            Circle()
                                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                    .background(
                                        selectedStaffId == person.id
                                            ? Color.teal.opacity(0.06)
                                            : Color(UIColor.secondarySystemGroupedBackground)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selectedStaffId == person.id ? Color.teal.opacity(0.4) : Color.clear, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (optional)", systemImage: "note.text")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal)

                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(Color.red)
                            .padding(.horizontal)
                    }

                    // Assign button
                    Button(action: assignTask) {
                        HStack {
                            if isAssigning {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 4)
                            } else if assignSuccess {
                                Image(systemName: "checkmark")
                                    .font(.body.bold())
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.body.bold())
                            }
                            Text(assignSuccess ? "Assigned!" : "Assign Task")
                                .font(.body.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selectedStaffId != nil && !assignSuccess
                                ? Color.teal
                                : Color(UIColor.systemFill)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal)
                    }
                    .disabled(selectedStaffId == nil || isAssigning || assignSuccess)
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Assign Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
                await MainActor.run {
                    isAssigning = false
                    errorMessage = "Failed to assign: \(error.localizedDescription)"
                }
            }
        }
    }
}
