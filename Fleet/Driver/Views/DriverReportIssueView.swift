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
        case .engine:     return Color.red
        case .tire:       return Color.yellow
        case .brake:      return Color.orange
        case .electrical: return Color.yellow
        case .fuelLeak:   return Color.blue
        case .bodyDamage: return Color.purple
        case .other:      return Color.secondary
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

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            if isSubmitted {
                successView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        vehicleHeader
                        issueCategorySection
                        severitySection
                        descriptionSection
                        photosSection
                        submitButton
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Report Issue")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
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

    // MARK: - Vehicle Header
    private var vehicleHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: "truck.box.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.green)
                .frame(width: 52, height: 52)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(vehicle.make ?? "Vehicle") \(vehicle.model ?? "")")
                    .font(.system(size: , weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text(vehicle.licensePlate ?? "—")
                    .font(.system(size: , weight: .regular, design: .rounded))
                    .foregroundStyle(Color.green)
            }
            Spacer()
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    // MARK: - Issue Category
    private var issueCategorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Issue Type", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: , weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(IssueCategory.allCases) { category in
                    categoryCard(category)
                }
            }
        }
    }

    private func categoryCard(_ category: IssueCategory) -> some View {
        let isSelected = selectedCategory == category
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? category.color : Color.secondary)
                    .frame(width: 20)
                Text(category.rawValue)
                    .font(.system(size: , weight: .regular, design: .rounded))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? category.color.opacity(0.15) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? category.color.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Severity
    private var severitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Severity", systemImage: "gauge.with.dots.needle.67percent")
                .font(.system(size: , weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary)

            HStack(spacing: 8) {
                ForEach(DefectSeverity.allCases, id: \.self) { severity in
                    severityChip(severity)
                }
            }
        }
    }

    private func severityChip(_ severity: DefectSeverity) -> some View {
        let isSelected = selectedSeverity == severity
        let color = severityColor(severity)
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSeverity = severity
            }
        }) {
            Text(severity.rawValue.capitalized)
                .font(.system(size: , weight: .regular, design: .rounded))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? color : Color.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.18) : Color.white.opacity(0.05))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func severityColor(_ severity: DefectSeverity) -> Color {
        switch severity {
        case .low:      return Color.green
        case .medium:   return Color.yellow
        case .high:     return Color.orange
        case .critical: return Color.red
        }
    }

    // MARK: - Description
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Description", systemImage: "text.alignleft")
                .font(.system(size: , weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                if description.isEmpty {
                    Text("Briefly describe the issue…")
                        .font(.system(size: , weight: .regular, design: .rounded))
                        .foregroundStyle(Color(UIColor.quaternaryLabel))
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                }

                TextEditor(text: $description)
                    .font(.system(size: , weight: .regular, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(10)
                    .onChange(of: description) { _, newValue in
                        if newValue.count > maxDescriptionLength {
                            description = String(newValue.prefix(maxDescriptionLength))
                        }
                    }
            }
            .frame(minHeight: 120)

            HStack {
                Spacer()
                Text("\(description.count)/\(maxDescriptionLength)")
                    .font(.system(size: , weight: .regular, design: .rounded))
                    .foregroundStyle(description.count > maxDescriptionLength - 20 ? Color.yellow : Color(UIColor.quaternaryLabel))
            }
        }
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: handleSubmit) {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Submit Report")
                }
            }
            .font(.system(size: , weight: .medium, design: .rounded))
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.red.opacity(0.35), radius: 12, y: 6)
        }
        .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        .opacity(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(Color.green.opacity(0.08))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.green)
            }

            VStack(spacing: 8) {
                Text("Report Submitted")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text("Your issue has been reported.\nThe maintenance team will be notified.")
                    .font(.system(size: , weight: .regular, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: , weight: .medium, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Photos Section
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Damage Photos", systemImage: "camera.fill")
                .font(.system(size: , weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary)

            Text("Add photos to verify vehicle damage (up to 5)")
                .font(.system(size: , weight: .regular, design: .rounded))
                .foregroundStyle(Color.secondary)

            if !capturedImages.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(capturedImages.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: capturedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button {
                                capturedImages.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.red)
                            }
                            .padding(4)
                        }
                    }
                }
            }

            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 5,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.green)
                    Text(capturedImages.isEmpty ? "Add Photos" : "Add More Photos")
                        .font(.system(size: , weight: .medium, design: .rounded))
                        .foregroundStyle(Color.green)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.green.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                )
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    // MARK: - Submit Action
    private func handleSubmit() {
        withAnimation(.easeInOut) {
            isSubmitting = true
        }
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


