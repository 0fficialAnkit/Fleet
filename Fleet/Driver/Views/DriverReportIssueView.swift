import SwiftUI
import Supabase
import PhotosUI

// MARK: - Issue Category

enum IssueCategory: String, CaseIterable, Identifiable {
    case engine      = "Engine Problem"
    case tire        = "Tyre Issue"
    case brake       = "Brake Issue"
    case electrical  = "Electrical Fault"
    case fuelLeak    = "Fuel Leak"
    case bodyDamage  = "Body Damage"
    case suspension  = "Suspension Issue"
    case cooling     = "Cooling System"
    case transmission = "Transmission Issue"
    case other       = "Other"

    var id: String { rawValue }

    // kept for compatibility with PredictiveMaintenanceService keyword matching
    var icon: String {
        switch self {
        case .engine:       return "engine.combustion"
        case .tire:         return "circle.circle"
        case .brake:        return "exclamationmark.brake.warning"
        case .electrical:   return "bolt.fill"
        case .fuelLeak:     return "fuelpump.exclamationmark"
        case .bodyDamage:   return "car.side.rear.and.collision.and.car.side.front"
        case .suspension:   return "arrow.up.and.down"
        case .cooling:      return "thermometer.medium"
        case .transmission: return "gearshape"
        case .other:        return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .engine, .fuelLeak, .brake: return .red
        case .tire, .electrical:         return .orange
        case .bodyDamage, .suspension:   return .purple
        case .cooling, .transmission:    return .blue
        case .other:                     return .secondary
        }
    }
}

// MARK: - Where Noticed

enum IssueLocation: String, CaseIterable, Identifiable {
    case highway    = "On Highway"
    case city       = "In City Traffic"
    case parking    = "At Parking / Stop"
    case loading    = "During Loading / Unloading"
    case workshop   = "At Workshop"
    case other      = "Other"
    var id: String { rawValue }
}

// MARK: - View

struct DriverReportIssueView: View {

    let vehicle: Vehicle

    @State private var selectedCategory: IssueCategory = .engine
    @State private var selectedSeverity: DefectSeverity = .medium
    @State private var selectedLocation: IssueLocation = .highway
    @State private var issueDate: Date = Date()
    @State private var isDriveable: Bool = true
    @State private var descriptionText: String = ""
    @State private var isSubmitted  = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var capturedImages: [UIImage] = []

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    private let maxLength = 400

    // MARK: - Body

    var body: some View {
        ZStack {
            if isSubmitted {
                successView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                formView
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isSubmitted)
        .navigationTitle("Report Issue")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSubmitting {
                    ProgressView()
                } else {
                    Button("Submit") { handleSubmit() }
                        .fontWeight(.semibold)
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
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        capturedImages.append(image)
                    }
                }
                selectedPhotos = []
            }
        }
    }

    private var canSubmit: Bool {
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Form

    private var formView: some View {
        Form {

            // ── Vehicle ───────────────────────────────────────────
            Section("Vehicle") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vehicle.make ?? "Vehicle") \(vehicle.model ?? "")")
                        .font(.body.weight(.semibold))
                    Text(vehicle.licensePlate ?? "—")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let type = vehicle.vehicleType {
                        Text(type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }

            // ── Issue Details ─────────────────────────────────────
            Section {
                Picker("Issue Type", selection: $selectedCategory) {
                    ForEach(IssueCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.primary)

                Picker("Severity", selection: $selectedSeverity) {
                    ForEach(DefectSeverity.allCases, id: \.self) { s in
                        Text(s.rawValue.capitalized).tag(s)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.primary)
            } header: {
                Text("Issue Details")
            } footer: {
                Text(severityFooter)
                    .foregroundStyle(severityColor(selectedSeverity))
            }

            // ── When & Where ──────────────────────────────────────
            Section {
                DatePicker("Date & Time", selection: $issueDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])

                Picker("Where Noticed", selection: $selectedLocation) {
                    ForEach(IssueLocation.allCases) { loc in
                        Text(loc.rawValue).tag(loc)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.primary)

                Toggle("Vehicle Still Driveable", isOn: $isDriveable)
            } header: {
                Text("When & Where")
            } footer: {
                if !isDriveable {
                    Text("⚠️ Vehicle marked as not driveable. Fleet manager will be alerted immediately.")
                        .foregroundStyle(.red)
                }
            }

            // ── Description ───────────────────────────────────────
            Section {
                ZStack(alignment: .topLeading) {
                    if descriptionText.isEmpty {
                        Text("Describe the issue in detail — what you heard, saw, or felt…")
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 110)
                        .onChange(of: descriptionText) { _, new in
                            if new.count > maxLength { descriptionText = String(new.prefix(maxLength)) }
                        }
                }
            } header: {
                Text("Description")
            } footer: {
                HStack {
                    Text("Be specific — this helps the technician diagnose faster.")
                    Spacer()
                    Text("\(descriptionText.count)/\(maxLength)")
                        .foregroundStyle(descriptionText.count > maxLength - 40 ? .orange : Color(.tertiaryLabel))
                }
                .font(.caption)
            }

            // ── Damage Photos ─────────────────────────────────────
            Section {
                if !capturedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(capturedImages.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: capturedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    Button {
                                        capturedImages.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, .red)
                                            .font(.title3)
                                    }
                                    .padding(2)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                if capturedImages.count < 6 {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 6 - capturedImages.count,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            capturedImages.isEmpty ? "Attach Photos" : "Add More (\(capturedImages.count)/6)",
                            systemImage: "photo.badge.plus"
                        )
                    }
                }
            } header: {
                Text("Damage Photos")
            } footer: {
                Text("Up to 6 photos. Attached to the report sent to the maintenance team.")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: isSubmitted)

            VStack(spacing: 8) {
                Text("Report Submitted")
                    .font(.title2.bold())
                Text("Your issue has been reported.\nThe fleet manager and maintenance team will be notified.")
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
            .tint(Color(.label))
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func severityColor(_ s: DefectSeverity) -> Color {
        switch s {
        case .low:      return .green
        case .medium:   return .orange
        case .high:     return .red
        case .critical: return .red
        }
    }

    private var severityFooter: String {
        switch selectedSeverity {
        case .low:      return "Low — Minor issue, no immediate action needed."
        case .medium:   return "Medium — Should be addressed within 48 hours."
        case .high:     return "High — Needs prompt attention, may affect safety."
        case .critical: return "Critical — Stop driving. Vehicle must be taken out of service now."
        }
    }

    // MARK: - Submit

    private func handleSubmit() {
        isSubmitting = true

        Task {
            do {
                guard let userId = authViewModel.currentUser?.id else {
                    isSubmitting = false; return
                }

                // Upload photos — best-effort, never blocks submission if bucket missing
                var uploadedUrls: [String] = []
                for (index, image) in capturedImages.enumerated() {
                    if let data = image.jpegData(compressionQuality: 0.75) {
                        let fileName = "defects/\(UUID().uuidString)_\(index).jpg"
                        do {
                            try await supabase.storage
                                .from("fleet-uploads")
                                .upload(fileName, data: data, options: .init(contentType: "image/jpeg"))
                            if let url = try? supabase.storage.from("fleet-uploads").getPublicURL(path: fileName).absoluteString {
                                uploadedUrls.append(url)
                            }
                        } catch {
                            print("[DriverReportIssue] Photo upload skipped: \(error.localizedDescription)")
                        }
                    }
                }

                // Build full description
                var full = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                full += "\n\nLocation: \(selectedLocation.rawValue)"
                full += "\nDriveable: \(isDriveable ? "Yes" : "No ⚠️")"
                full += "\nReported at: \(issueDate.formatted(date: .abbreviated, time: .shortened))"
                if !uploadedUrls.isEmpty {
                    full += "\n\n[Photos]\n" + uploadedUrls.map { "- \($0)" }.joined(separator: "\n")
                }

                // Save report
                let report = IssueReportRecord(
                    id: UUID(),
                    vehicleId: vehicle.id,
                    reportedBy: userId,
                    category: selectedCategory.rawValue,
                    severity: selectedSeverity.rawValue,
                    description: full,
                    status: "open",
                    assignedTo: nil,
                    createdAt: issueDate
                )
                try await IssueReportService.createIssueReport(report)

                // Notify fleet manager — critical/non-driveable triggers urgent title
                let isUrgent = selectedSeverity == .critical || !isDriveable
                try? await NotificationService.notifyManager(
                    forVehicle: vehicle.id,
                    title: isUrgent ? "🚨 Urgent: \(selectedCategory.rawValue)" : "New Issue Report",
                    message: "\(selectedCategory.rawValue) on \(vehicle.make ?? "") \(vehicle.model ?? "") (\(vehicle.licensePlate ?? "")). Severity: \(selectedSeverity.rawValue.capitalized).",
                    type: .maintenance
                )

                await MainActor.run {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isSubmitting = false
                        isSubmitted  = true
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
