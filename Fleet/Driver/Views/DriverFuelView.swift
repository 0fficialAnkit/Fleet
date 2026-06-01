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
        !volume.isEmpty && !price.isEmpty && billImage != nil && assignedVehicleId != nil
    }

    private var inputFormSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Log Fuel Expense")
                .font(.title3.bold())
                .foregroundStyle(Color.primary)

            if assignedVehicleId == nil {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Assigned Vehicle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("You must have a vehicle assigned by your Fleet Manager to log fuel expenses.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
            }

            // Volume
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(Color.secondary)
                    Text("Fuel Volume (Liters)")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.secondary)
                }
                TextField("0.0", text: $volume)
                    .keyboardType(.decimalPad)
                    .padding(16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Price
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "indianrupeesign")
                        .foregroundStyle(Color.secondary)
                    Text("Total Price Paid")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.secondary)
                }
                TextField("0.00", text: $price)
                    .keyboardType(.decimalPad)
                    .padding(16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // MARK: - Bill Photo (mandatory)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundStyle(Color.secondary)
                    Text("Fuel Bill Photo")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.secondary)
                    Text("(Required)")
                        .font(.body)
                        .foregroundStyle(Color.red)
                }

                if let billImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: billImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.5), lineWidth: 1.5)
                            )

                        Button {
                            self.billImage = nil
                            selectedPhotoItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.red)
                        }
                        .padding(8)
                    }
                } else {
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.viewfinder")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.green)
                            Text("Tap to attach bill photo")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.green)
                            Text("Photo will be sent to Fleet Manager")
                                .font(.body)
                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .background(Color.green.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                        )
                    }
                }
            }

            // Submit
            Button(action: submitFuelLog) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up.doc")
                        Text("Submit Fuel Log")
                    }
                }
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(!isFormValid || isSubmitting ? Color(UIColor.tertiarySystemFill) : Color.green)
                .foregroundStyle(!isFormValid || isSubmitting ? Color(UIColor.tertiaryLabel) : Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isFormValid || isSubmitting)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var successBannerSection: some View {
        if showSuccess {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                Text("Synced with Fleet Manager")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary)
                Spacer()
            }
            .padding(14)
            .background(Color.green.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Logs")

            if viewModel.fuelLogs.isEmpty {
                Text("No fuel logs recorded yet.")
                    .font(.body)
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(viewModel.fuelLogs) { log in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundStyle(Color.green)
                                Text("\(String(format: "%.1f", log.litersUsed ?? 0.0)) Liters")
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                            }
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(Color.secondary)
                                Text((log.recordedAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                    .font(.body)
                                    .foregroundStyle(Color.secondary)
                            }
                        }

                        Spacer()

                        HStack(spacing: 2) {
                            Image(systemName: "indianrupeesign")
                                .foregroundStyle(Color.secondary)
                            Text("\(Int(log.fuelCost ?? 0.0))")
                                .font(.title3.bold())
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    inputFormSection
                    successBannerSection
                    historySection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Fuel")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { }
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
            .onChange(of: authViewModel.currentUser?.id, initial: true) { _, newUserId in
                guard let userId = newUserId else { return }
                viewModel.currentUserId = userId
                Task {
                    await viewModel.loadData()
                    viewModel.setupRealtime()
                    // Fetch assigned vehicle
                    let vehicle = try? await VehicleService.fetchVehicleForDriver(driverId: userId)
                    assignedVehicleId = vehicle?.id
                }
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
                // Upload bill photo to the `fuel` storage bucket with local error handling
                var billUrl: String?
                if let billImage, let imageData = billImage.jpegData(compressionQuality: 0.7) {
                    let fileName = "bills/\(UUID().uuidString).jpg"
                    do {
                        try await supabase.storage
                            .from("fuel")
                            .upload(fileName, data: imageData, options: .init(contentType: "image/jpeg"))
                        billUrl = try? supabase.storage
                            .from("fuel")
                            .getPublicURL(path: fileName)
                            .absoluteString
                    } catch {
                        print("[DriverFuelView] Storage upload failed: \(error)")
                    }
                }

                // Save fuel log (with receipt URL if uploaded) to fuel_logs table
                try await viewModel.addFuelLog(
                    liters: liters,
                    cost: cost,
                    vehicleId: vehicleId,
                    billUrl: billUrl
                )

                // Dispatch notifications to managers in the background to prevent UI blocking
                Task {
                    do {
                        if let userId = authViewModel.currentUser?.id {
                            let managers = try await ProfileService.fetchProfilesByRole(role: "fleet_manager")
                            for manager in managers {
                                let notification = Notification(
                                    id: UUID(),
                                    userId: manager.id,
                                    title: "Fuel Log Submitted",
                                    message: "Driver logged \(String(format: "%.1f", liters))L fuel — ₹\(Int(cost)).",
                                    type: .info,
                                    isRead: false,
                                    createdAt: Date()
                                )
                                try await NotificationService.createNotification(notification)
                            }
                        }
                    } catch {
                        print("[DriverFuelView] Failed to dispatch notifications: \(error)")
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
