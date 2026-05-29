import SwiftUI
import Supabase

// MARK: - Trip Issue Type

enum TripIssueType: String, CaseIterable, Identifiable {
    case delay      = "Trip Delay"
    case traffic    = "Traffic Congestion"
    case route      = "Route Deviation"
    case breakdown  = "Vehicle Breakdown"
    case other      = "Other Issue"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .delay:     return "clock.badge.exclamationmark"
        case .traffic:   return "car.2.fill"
        case .route:     return "road.lanes.curved.right"
        case .breakdown: return "exclamationmark.triangle.fill"
        case .other:     return "ellipsis.circle"
        }
    }

    var color: Color {
        switch self {
        case .delay:     return .orange
        case .traffic:   return .yellow
        case .route:     return .blue
        case .breakdown: return .red
        case .other:     return Color(.secondaryLabel)
        }
    }

    var showsDelayPicker: Bool { self == .delay || self == .traffic }

    var notificationType: NotificationType {
        self == .breakdown ? .maintenance : .warning
    }

    var defaultSeverity: String {
        self == .breakdown ? "high" : "medium"
    }
}

// MARK: - View

struct DriverTripIssueView: View {

    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var selectedType: TripIssueType = .delay
    @State private var estimatedDelayMinutes: Int = 15
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var isSubmitted = false
    @State private var errorMessage: String?

    private let delayOptions = [5, 10, 15, 20, 30, 45, 60]
    private let maxNotes = 300

    var canSubmit: Bool {
        !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isSubmitted {
                    successView
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    formContent
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSubmitted)
            .navigationTitle("Report Trip Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.secondary)
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Submit") { handleSubmit() }
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.orange)
                            .disabled(!canSubmit)
                    }
                }
            }
            .alert("Submission Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }

    // MARK: - Form

    private var formContent: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "road.lanes")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Trip")
                            .font(.body.weight(.semibold))
                        Text("Route #\(trip.id.uuidString.prefix(6).uppercased())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Label("Live", systemImage: "circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            } header: { Text("Trip") }

            Section {
                Picker("Issue Type", selection: $selectedType) {
                    ForEach(TripIssueType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: { Text("Issue Type") } footer: {
                Label(selectedType.rawValue, systemImage: selectedType.icon)
                    .foregroundStyle(selectedType.color)
                    .font(.footnote)
            }

            if selectedType.showsDelayPicker {
                Section {
                    Picker("Estimated Delay", selection: $estimatedDelayMinutes) {
                        ForEach(delayOptions, id: \.self) { minutes in
                            Text(minutes == 60 ? "60+ min" : "\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                } header: { Text("Estimated Delay") } footer: {
                    Text("Lets your fleet manager adjust dispatch timing around this delay.")
                }
            }

            Section {
                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Briefly describe the situation…")
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $notes)
                        .frame(minHeight: 90)
                        .onChange(of: notes) { _, newVal in
                            if newVal.count > maxNotes {
                                notes = String(newVal.prefix(maxNotes))
                            }
                        }
                }
            } header: { Text("Description") } footer: {
                HStack {
                    Text("This is sent directly to your fleet manager.")
                    Spacer()
                    Text("\(notes.count)/\(maxNotes)")
                        .foregroundStyle(notes.count > maxNotes - 40 ? .orange : Color(.tertiaryLabel))
                }
                .font(.caption)
            }
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
                .symbolEffect(.bounce, value: isSubmitted)

            VStack(spacing: 8) {
                Text("Issue Reported")
                    .font(.title2.bold())
                Text("Your fleet manager has been notified and will respond shortly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button { dismiss() } label: {
                Text("Done").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Submit

    private func handleSubmit() {
        isSubmitting = true
        Task {
            do {
                guard let userId = authViewModel.currentUser?.id else {
                    isSubmitting = false
                    return
                }

                var fullDescription = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                if selectedType.showsDelayPicker {
                    let delayStr = estimatedDelayMinutes == 60 ? "60+ minutes" : "\(estimatedDelayMinutes) minutes"
                    fullDescription = "Estimated delay: \(delayStr)\n\n\(fullDescription)"
                }
                fullDescription += "\n\n[Trip ID: \(trip.id.uuidString.prefix(8).uppercased())]"

                let report = IssueReportRecord(
                    id: UUID(),
                    vehicleId: trip.vehicleId,
                    reportedBy: userId,
                    category: selectedType.rawValue,
                    severity: selectedType.defaultSeverity,
                    description: fullDescription,
                    status: "open",
                    assignedTo: nil,
                    createdAt: Date()
                )
                try await IssueReportService.createIssueReport(report)

                let managers = try await ProfileService.fetchProfilesByRole(role: "fleet_manager")
                for manager in managers {
                    let delayNote = selectedType.showsDelayPicker ? " (~\(estimatedDelayMinutes) min delay)" : ""
                    let notification = Notification(
                        id: UUID(),
                        userId: manager.id,
                        title: "Trip Issue: \(selectedType.rawValue)",
                        message: "Driver reported \(selectedType.rawValue.lowercased()) on route #\(trip.id.uuidString.prefix(6).uppercased())\(delayNote).",
                        type: selectedType.notificationType,
                        isRead: false,
                        createdAt: Date()
                    )
                    try? await NotificationService.createNotification(notification)
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        isSubmitting = false
                        isSubmitted = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    DriverTripIssueView(
        trip: Trip(
            id: UUID(), vehicleId: UUID(), driverId: UUID(), routeId: UUID(),
            startTime: Date(), endTime: nil, distance: nil, status: .active, orderType: .pickUpAndDrop
        )
    )
    .environment(AuthViewModel())
}
