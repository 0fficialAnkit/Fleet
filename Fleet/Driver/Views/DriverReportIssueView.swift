import SwiftUI
import Supabase
import PhotosUI

// MARK: - Issue Category
enum IssueCategory: String, CaseIterable, Identifiable {
    case engine      = "Engine Problem"
    case tire        = "Tire Issue"
    case brake       = "Brake Issue"
    case electrical  = "Electrical Fault"
    case fuelLeak    = "Fuel Leak"
    case bodyDamage  = "Body Damage"
    case other       = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .engine:     return "engine.combustion"
        case .tire:       return "circle.circle"
        case .brake:      return "exclamationmark.brake.warning"
        case .electrical: return "bolt.fill"
        case .fuelLeak:   return "fuelpump.exclamationmark"
        case .bodyDamage: return "car.side.rear.and.collision.and.car.side.front"
        case .other:      return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .engine:     return .red
        case .tire:       return .yellow
        case .brake:      return .orange
        case .electrical: return .yellow
        case .fuelLeak:   return .blue
        case .bodyDamage: return .purple
        case .other:      return .secondary
        }
    }
}

// MARK: - DriverReportIssueView
struct DriverReportIssueView: View {
    let vehicle: Vehicle

    @State private var selectedCategory: IssueCategory = .engine
    @State private var selectedSeverity: DefectSeverity = .medium
    @State private var description: String = ""
    @State private var isSubmitted = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    private let maxDescriptionLength = 200

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var capturedImages: [UIImage] = []

    // MARK: - Body
    var body: some View {
        ZStack {
            if isSubmitted {
                successView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                formContent
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
                        .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .alert("Submission Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
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

    // MARK: - Form Content
    private var formContent: some View {
        Form {
            // ── Vehicle ──────────────────────────────────────────
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(vehicle.make ?? "Vehicle") \(vehicle.model ?? "")")
                            .font(.body.weight(.semibold))
                        Text(vehicle.licensePlate ?? "—")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Label("Active", systemImage: "circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            } header: {
                Text("Vehicle")
            }

            // ── Issue Type ────────────────────────────────────────
            Section {
                Picker("Issue Type", selection: $selectedCategory) {
                    ForEach(IssueCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(category)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Issue Type")
            } footer: {
                Label(selectedCategory.rawValue, systemImage: selectedCategory.icon)
                    .foregroundStyle(selectedCategory.color)
                    .font(.footnote)
            }

            // ── Severity ──────────────────────────────────────────
            Section {
                Picker("Severity", selection: $selectedSeverity) {
                    ForEach(DefectSeverity.allCases, id: \.self) { severity in
                        Text(severity.rawValue.capitalized).tag(severity)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            } header: {
                Text("Severity")
            } footer: {
                Text(severityFooter)
                    .foregroundStyle(severityColor(selectedSeverity))
            }

            // ── Description ───────────────────────────────────────
            Section {
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Briefly describe the issue…")
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .onChange(of: description) { _, newValue in
                            if newValue.count > maxDescriptionLength {
                                description = String(newValue.prefix(maxDescriptionLength))
                            }
                        }
                }
            } header: {
                Text("Description")
            } footer: {
                HStack {
                    if !description.isEmpty {
                        Text("Be specific — this helps the technician diagnose faster.")
                    }
                    Spacer()
                    Text("\(description.count)/\(maxDescriptionLength)")
                        .foregroundStyle(description.count > maxDescriptionLength - 20 ? .orange : Color(.tertiaryLabel))
                }
            }

            // ── Damage Photos ─────────────────────────────────────
            Section {
                if capturedImages.isEmpty {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Add Photos", systemImage: "photo.badge.plus")
                    }
                } else {
                    // Thumbnail strip
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

                    if capturedImages.count < 5 {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 5 - capturedImages.count,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Add More Photos", systemImage: "photo.badge.plus")
                        }
                    }
                }
            } header: {
                Text("Damage Photos")
            } footer: {
                Text("Up to 5 photos. These are attached to the report sent to maintenance.")
            }
        }
    }

    // MARK: - Success View
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
                Text("Your issue has been reported.\nThe maintenance team will be notified shortly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.green)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers
    private func severityColor(_ severity: DefectSeverity) -> Color {
        switch severity {
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
        case .critical: return "Critical — Vehicle should be taken out of service immediately."
        }
    }

    // MARK: - Submit Action
    private func handleSubmit() {
        isSubmitting = true
        Task {
            do {
                guard let userId = authViewModel.currentUser?.id else {
                    isSubmitting = false
                    return
                }

                // Upload photos to Supabase Storage
                var uploadedUrls: [String] = []
                for (index, image) in capturedImages.enumerated() {
                    if let data = image.jpegData(compressionQuality: 0.7) {
                        let fileName = "defects/\(UUID().uuidString)_\(index).jpg"
                        try await supabase.storage
                            .from("fleet-uploads")
                            .upload(fileName, data: data, options: .init(contentType: "image/jpeg"))
                        if let publicUrl = try? supabase.storage.from("fleet-uploads").getPublicURL(path: fileName).absoluteString {
                            uploadedUrls.append(publicUrl)
                        }
                    }
                }

                var finalDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
                if !uploadedUrls.isEmpty {
                    finalDescription += "\n\n[Damage Photos]"
                    for url in uploadedUrls {
                        finalDescription += "\n- \(url)"
                    }
                }

                let report = IssueReportRecord(
                    id: UUID(),
                    vehicleId: vehicle.id,
                    reportedBy: userId,
                    category: selectedCategory.rawValue,
                    severity: selectedSeverity.rawValue,
                    description: finalDescription,
                    status: "open",
                    assignedTo: nil,
                    createdAt: Date()
                )
                try await IssueReportService.createIssueReport(report)

                // Notify all fleet managers
                let managers = try await ProfileService.fetchProfilesByRole(role: "fleet_manager")
                for manager in managers {
                    let notification = Notification(
                        id: UUID(),
                        userId: manager.id,
                        title: "New Issue Report",
                        message: "\(selectedCategory.rawValue) reported on \(vehicle.make ?? "") \(vehicle.model ?? "")",
                        type: .maintenance,
                        isRead: false,
                        createdAt: Date()
                    )
                    try? await NotificationService.createNotification(notification)
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isSubmitting = false
                        isSubmitted = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
                print("Error submitting report: \(error)")
            }
        }
    }
}
