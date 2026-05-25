import SwiftUI
import Supabase

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
        case .engine:     return themeModel.danger
        case .tire:       return themeModel.warning
        case .brake:      return Color.orange
        case .electrical: return Color.yellow
        case .fuelLeak:   return themeModel.info
        case .bodyDamage: return themeModel.analyticsPurple
        case .other:      return themeModel.textSecondary
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

    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()

            if isSubmitted {
                successView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: themeModel.spacingLG) {
                        vehicleHeader
                        issueCategorySection
                        severitySection
                        descriptionSection
                        submitButton
                    }
                    .padding(themeModel.spacingMD)
                    .padding(.bottom, themeModel.spacingXXL)
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
    }

    // MARK: - Vehicle Header
    private var vehicleHeader: some View {
        HStack(spacing: themeModel.spacingMD) {
            Image(systemName: "truck.box.fill")
                .font(.system(size: 28))
                .foregroundStyle(themeModel.driverPrimary)
                .frame(width: 52, height: 52)
                .background(themeModel.driverPrimary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(vehicle.make ?? "Vehicle") \(vehicle.model ?? "")")
                    .font(themeModel.headline())
                    .foregroundStyle(themeModel.textPrimary)
                Text(vehicle.licensePlate ?? "—")
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.driverPrimary)
            }
            Spacer()
        }
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    // MARK: - Issue Category
    private var issueCategorySection: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            Label("Issue Type", systemImage: "exclamationmark.triangle.fill")
                .font(themeModel.headline())
                .foregroundStyle(themeModel.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: themeModel.spacingSM) {
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
            HStack(spacing: themeModel.spacingSM) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? category.color : themeModel.textSecondary)
                    .frame(width: 20)
                Text(category.rawValue)
                    .font(themeModel.caption())
                    .foregroundStyle(isSelected ? themeModel.textPrimary : themeModel.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                    .fill(isSelected ? category.color.opacity(0.15) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                    .stroke(isSelected ? category.color.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Severity
    private var severitySection: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            Label("Severity", systemImage: "gauge.with.dots.needle.67percent")
                .font(themeModel.headline())
                .foregroundStyle(themeModel.textPrimary)

            HStack(spacing: themeModel.spacingSM) {
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
                .font(themeModel.caption())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? color : themeModel.textSecondary)
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
        case .low:      return themeModel.success
        case .medium:   return themeModel.warning
        case .high:     return Color.orange
        case .critical: return themeModel.danger
        }
    }

    // MARK: - Description
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            Label("Description", systemImage: "text.alignleft")
                .font(themeModel.headline())
                .foregroundStyle(themeModel.textPrimary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                if description.isEmpty {
                    Text("Briefly describe the issue…")
                        .font(themeModel.body())
                        .foregroundStyle(themeModel.textDisabled)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                }

                TextEditor(text: $description)
                    .font(themeModel.body())
                    .foregroundStyle(themeModel.textPrimary)
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
                    .font(themeModel.caption())
                    .foregroundStyle(description.count > maxDescriptionLength - 20 ? themeModel.warning : themeModel.textDisabled)
            }
        }
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: handleSubmit) {
            HStack(spacing: themeModel.spacingSM) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Submit Report")
                }
            }
            .font(themeModel.bodyMedium())
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [themeModel.danger, themeModel.danger.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
            .shadow(color: themeModel.danger.opacity(0.35), radius: 12, y: 6)
        }
        .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        .opacity(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: themeModel.spacingLG) {
            Spacer()

            ZStack {
                Circle()
                    .fill(themeModel.success.opacity(0.15))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(themeModel.success.opacity(0.08))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(themeModel.success)
            }

            VStack(spacing: themeModel.spacingSM) {
                Text("Report Submitted")
                    .font(themeModel.largeTitle(26))
                    .foregroundStyle(themeModel.textPrimary)
                Text("Your issue has been reported.\nThe maintenance team will be notified.")
                    .font(themeModel.body())
                    .foregroundStyle(themeModel.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(themeModel.bodyMedium())
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(themeModel.driverPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
            }
            .padding(.horizontal, themeModel.spacingMD)
            .padding(.bottom, themeModel.spacingXXL)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                let report = IssueReportRecord(
                    id: UUID(),
                    vehicleId: vehicle.id,
                    reportedBy: userId,
                    category: selectedCategory.rawValue,
                    severity: selectedSeverity.rawValue,
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
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


