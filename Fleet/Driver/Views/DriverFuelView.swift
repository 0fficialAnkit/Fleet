import SwiftUI
import PhotosUI
import Supabase

struct DriverFuelView: View {

    @State private var volume: String = ""
    @State private var price: String = ""
    @State private var showSuccess: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    // Photo picker
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var billImage: UIImage?

    @State private var viewModel = DriverFuelViewModel()
    @State private var assignedVehicleId: UUID?
    @Environment(AuthViewModel.self) private var authViewModel

    private var isFormValid: Bool {
        !volume.isEmpty && !price.isEmpty && billImage != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Input Form
                VStack(alignment: .leading, spacing: themeModel.spacingLG) {
                    Text("Log Fuel Expense")
                        .font(themeModel.title(22))
                        .foregroundStyle(themeModel.textPrimary)

                    // Volume
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(themeModel.textSecondary)
                            Text("Fuel Volume (Liters)")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.textSecondary)
                        }
                        TextField("0.0", text: $volume)
                            .keyboardType(.decimalPad)
                            .padding(themeModel.spacingMD)
                            .background(themeModel.inputBackground)
                            .cornerRadius(themeModel.radiusSM)
                    }

                    // Price
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        HStack {
                            Image(systemName: "indianrupeesign")
                                .foregroundStyle(themeModel.textSecondary)
                            Text("Total Price Paid")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.textSecondary)
                        }
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                            .padding(themeModel.spacingMD)
                            .background(themeModel.inputBackground)
                            .cornerRadius(themeModel.radiusSM)
                    }

                    // MARK: - Bill Photo (mandatory)
                    VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(themeModel.textSecondary)
                            Text("Fuel Bill Photo")
                                .font(themeModel.bodyMedium())
                                .foregroundStyle(themeModel.textSecondary)
                            Text("(Required)")
                                .font(themeModel.caption())
                                .foregroundStyle(themeModel.danger)
                        }

                        if let billImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: billImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: themeModel.radiusMD)
                                            .stroke(themeModel.success.opacity(0.5), lineWidth: 1.5)
                                    )

                                Button {
                                    self.billImage = nil
                                    selectedPhotoItem = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, themeModel.danger)
                                }
                                .padding(8)
                            }
                        } else {
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                VStack(spacing: themeModel.spacingSM) {
                                    Image(systemName: "doc.viewfinder")
                                        .font(.system(size: 32))
                                        .foregroundStyle(themeModel.driverPrimary)
                                    Text("Tap to attach bill photo")
                                        .font(themeModel.bodyMedium())
                                        .foregroundStyle(themeModel.driverPrimary)
                                    Text("Photo will be sent to Fleet Manager")
                                        .font(themeModel.caption())
                                        .foregroundStyle(themeModel.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .background(themeModel.driverPrimary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD))
                                .overlay(
                                    RoundedRectangle(cornerRadius: themeModel.radiusMD)
                                        .stroke(themeModel.driverPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                                )
                            }
                        }
                    }



                    // Submit
                    Button(action: submitFuelLog) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.up.doc")
                                Text("Submit Fuel Log")
                            }
                        }
                        .font(themeModel.bodyMedium())
                        .frame(maxWidth: .infinity)
                        .padding(themeModel.spacingMD)
                        .background(!isFormValid || isSubmitting ? themeModel.buttonDisabled : themeModel.driverPrimary)
                        .foregroundColor(!isFormValid || isSubmitting ? themeModel.buttonDisabledText : themeModel.buttonPrimaryText)
                        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
                .padding(themeModel.spacingMD)
                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)

                // MARK: - Success Banner
                if showSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(themeModel.success)
                        Text("Synced with Fleet Manager")
                            .font(themeModel.bodyMedium())
                            .foregroundStyle(themeModel.textPrimary)
                        Spacer()
                    }
                    .padding(themeModel.spacingMD)
                    .background(themeModel.success.opacity(0.15))
                    .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // MARK: - History
                VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                    SectionHeader(title: "Recent Logs")

                    if viewModel.fuelLogs.isEmpty {
                        Text("No fuel logs recorded yet.")
                            .font(themeModel.body())
                            .foregroundStyle(themeModel.textSecondary)
                    } else {
                        ForEach(viewModel.fuelLogs) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: themeModel.spacingXS) {
                                    HStack {
                                        Image(systemName: "drop.fill")
                                            .foregroundColor(themeModel.success)
                                        Text("\(String(format: "%.1f", log.litersUsed ?? 0.0)) Liters")
                                            .font(themeModel.headline())
                                            .foregroundColor(themeModel.textPrimary)
                                    }
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(themeModel.textSecondary)
                                        Text((log.recordedAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                            .font(themeModel.caption())
                                            .foregroundColor(themeModel.textSecondary)
                                    }
                                }

                                Spacer()

                                HStack(spacing: 2) {
                                    Image(systemName: "indianrupeesign")
                                        .foregroundColor(themeModel.textSecondary)
                                    Text("\(Int(log.fuelCost ?? 0.0))")
                                        .font(themeModel.title(22))
                                        .foregroundColor(themeModel.textPrimary)
                                }
                            }
                            .padding(themeModel.spacingMD)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                        }
                    }
                }
            }
            .padding()
        }
        .background(themeModel.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Fuel")
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    billImage = image
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
        .task {
            viewModel.currentUserId = authViewModel.currentUser?.id
            await viewModel.loadData()
            viewModel.setupRealtime()
            // Fetch assigned vehicle
            if let userId = authViewModel.currentUser?.id {
                let vehicle = try? await VehicleService.fetchVehicleForDriver(driverId: userId)
                assignedVehicleId = vehicle?.id
            }
        }
    }

    // MARK: - Submit

    private func submitFuelLog() {
        let liters = Double(volume) ?? 0.0
        let cost = Double(price) ?? 0.0
        let vehicleId = assignedVehicleId ?? UUID()

        isSubmitting = true
        showSuccess = false
        errorMessage = nil

        Task {
            do {
                // Upload bill photo to Supabase Storage
                var billUrl: String?
                if let billImage, let imageData = billImage.jpegData(compressionQuality: 0.7) {
                    let fileName = "fuel_bills/\(UUID().uuidString).jpg"
                    try await supabase.storage
                        .from("fleet-uploads")
                        .upload(fileName, data: imageData, options: .init(contentType: "image/jpeg"))
                    billUrl = try supabase.storage.from("fleet-uploads").getPublicURL(path: fileName).absoluteString
                }

                try await viewModel.addFuelLog(liters: liters, cost: cost, vehicleId: vehicleId)

                // Notify fleet managers about fuel log with bill
                if let userId = authViewModel.currentUser?.id {
                    let managers = try await ProfileService.fetchProfilesByRole(role: "fleet_manager")
                    for manager in managers {
                        let notification = Notification(
                            id: UUID(),
                            userId: manager.id,
                            title: "Fuel Log Submitted",
                            message: "Driver logged \(String(format: "%.1f", liters))L fuel — ₹\(Int(cost)). Bill photo attached.",
                            type: .info,
                            isRead: false,
                            createdAt: Date()
                        )
                        try? await NotificationService.createNotification(notification)
                    }
                }

                await MainActor.run {
                    isSubmitting = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSuccess = true
                    }
                    volume = ""
                    price = ""
                    self.billImage = nil
                    selectedPhotoItem = nil
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
    NavigationStack {
        DriverFuelView()
            .environment(AuthViewModel())
    }
}
