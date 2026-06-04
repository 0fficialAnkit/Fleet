import SwiftUI
import PhotosUI
import Supabase

struct DriverFuelView: View {

    var isReadOnly: Bool = false

    // MARK: - State

    @State private var volume: String = ""
    @State private var price: String = ""
    @State private var showSuccess = false
    @State private var isSubmitting = false
    @State private var isExtractingOCR = false

    // Photo — uses modern PhotosUI. Camera still needs UIImagePickerController.
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var billImage: UIImage?
    @State private var showCamera = false

    @State private var viewModel = DriverFuelViewModel()
    @State private var assignedVehicleId: UUID?
    @State private var submitError: LocalizedErrorWrapper?

    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @FocusState private var activeField: InputField?
    private enum InputField: Hashable { case volume, price }

    // MARK: - Computed

    private var isFormValid: Bool {
        guard !volume.trimmingCharacters(in: .whitespaces).isEmpty,
              !price.trimmingCharacters(in: .whitespaces).isEmpty,
              billImage != nil,
              assignedVehicleId != nil
        else { return false }
        return true
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {

                // ── Trip-ended notice ─────────────────────────────────
                if isReadOnly {
                    Section {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Trip Has Ended")
                                    .font(.subheadline.weight(.semibold))
                                Text("Fuel logging is only available during an active trip.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // ── No-vehicle notice ─────────────────────────────────
                if assignedVehicleId == nil {
                    Section {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("No Vehicle Assigned")
                                    .font(.subheadline.weight(.semibold))
                                Text("Contact your Fleet Manager to get a vehicle assigned.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }

                // ── Entry ─────────────────────────────────────────────
                Section("Log Fuel Expense") {
                    LabeledContent {
                        TextField("0.0", text: $volume)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($activeField, equals: .volume)
                    } label: {
                        Label("Volume (L)", systemImage: "drop.fill")
                    }

                    LabeledContent {
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($activeField, equals: .price)
                    } label: {
                        Label("Amount (₹)", systemImage: "indianrupeesign")
                    }
                }
                .disabled(assignedVehicleId == nil || isReadOnly)
                .opacity(isReadOnly ? 0.4 : 1.0)

                // ── Bill Photo ────────────────────────────────────────
                Section {
                    if let billImage {
                        // Preview + remove
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: billImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay {
                                    if isExtractingOCR {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                        VStack(spacing: 8) {
                                            ProgressView()
                                            Text("Reading Bill…")
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    self.billImage = nil
                                    self.selectedPhotoItem = nil
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .red)
                            }
                            .padding(8)
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    } else {
                        // Camera / Gallery tiles
                        HStack(spacing: 12) {
                            Button {
                                activeField = nil
                                showCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label("Gallery", systemImage: "photo.on.rectangle")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                } header: {
                    HStack {
                        Text("Bill Photo")
                        Spacer()
                        if billImage == nil {
                            Text("Required")
                                .foregroundStyle(.red)
                                .textCase(.none)
                        } else {
                            Label("Captured", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .textCase(.none)
                        }
                    }
                }
                .disabled(assignedVehicleId == nil || isReadOnly)
                .opacity(isReadOnly ? 0.4 : 1.0)

                // ── Success row ───────────────────────────────────────
                if showSuccess {
                    Section {
                        Label("Synced with Fleet Manager", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // ── Submit ────────────────────────────────────────────
                Section {
                    Button(action: submitFuelLog) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Label("Submit Fuel Log", systemImage: "arrow.up.doc.fill")
                                    .font(.body.weight(.semibold))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(!isFormValid || isSubmitting)
                    .tint(.green)
                }

                // ── Recent Logs ───────────────────────────────────────
                Section("Recent Logs") {
                    if viewModel.fuelLogs.isEmpty {
                        ContentUnavailableView(
                            "No Logs Yet",
                            systemImage: "fuelpump",
                            description: Text("Submit your first fuel log above.")
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    } else {
                        ForEach(viewModel.fuelLogs) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(String(format: "%.1f L", log.litersUsed ?? 0))
                                        .font(.body.weight(.semibold))
                                    Text((log.recordedAt ?? .now).formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("₹\(Int(log.fuelCost ?? 0))")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Fuel")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { activeField = nil }
                }
            }
            // ── Gallery selection ─────────────────────────────────────
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    withAnimation { billImage = image }
                    await extractOCR(from: image)
                }
            }
            // ── Camera result ─────────────────────────────────────────
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $billImage, sourceType: .camera)
                    .ignoresSafeArea()
            }
            // Run OCR when camera sets billImage (selectedPhotoItem stays nil)
            .onChange(of: billImage) { old, new in
                guard old == nil, let new, selectedPhotoItem == nil else { return }
                Task { await extractOCR(from: new) }
            }
            // ── Error alert ───────────────────────────────────────────
            .alert(
                "Submission Failed",
                isPresented: Binding(
                    get: { submitError != nil },
                    set: { if !$0 { submitError = nil } }
                ),
                presenting: submitError
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.message)
            }
            // ── Load data on user change ──────────────────────────────
            .onChange(of: authViewModel.currentUser?.id, initial: true) { _, userId in
                guard let userId else { return }
                viewModel.currentUserId = userId
                Task {
                    await viewModel.loadData()
                    viewModel.setupRealtime()
                    let vehicle = try? await VehicleService.fetchVehicleForDriver(driverId: userId)
                    assignedVehicleId = vehicle?.id
                }
            }
        }
    }

    // MARK: - OCR

    @MainActor
    private func extractOCR(from image: UIImage) async {
        isExtractingOCR = true
        let (vol, cost, _) = await OCRService.shared.extractFuelData(from: image)
        if let vol  { volume = String(format: "%.1f", vol) }
        if let cost { price  = String(format: "%.2f", cost) }
        isExtractingOCR = false
    }

    // MARK: - Submit

    private func submitFuelLog() {
        let liters    = Double(volume) ?? 0
        let cost      = Double(price)  ?? 0
        let vehicleId = assignedVehicleId ?? UUID()

        isSubmitting = true
        showSuccess  = false
        submitError  = nil

        Task {
            do {
                // Upload bill image to storage
                var billUrl: String?
                if let billImage, let data = billImage.jpegData(compressionQuality: 0.7) {
                    let path = "bills/\(UUID().uuidString).jpg"
                    do {
                        try await supabase.storage
                            .from("fuel")
                            .upload(path, data: data, options: .init(contentType: "image/jpeg"))
                        billUrl = try? supabase.storage
                            .from("fuel")
                            .getPublicURL(path: path)
                            .absoluteString
                    } catch {
                        print("[DriverFuelView] Upload failed: \(error)")
                    }
                }

                // Persist fuel log
                try await viewModel.addFuelLog(
                    liters: liters,
                    cost: cost,
                    vehicleId: vehicleId,
                    recordedAt: .now,
                    billUrl: billUrl
                )

                // Notify manager (fire-and-forget)
                Task.detached(priority: .background) {
                    try? await NotificationService.notifyManager(
                        forVehicle: vehicleId,
                        title: "Fuel Log Submitted",
                        message: "Driver logged \(String(format: "%.1f", liters))L — ₹\(Int(cost)).",
                        type: .info
                    )
                }

                // Reset form
                isSubmitting = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showSuccess = true
                }
                volume = ""
                price  = ""
                billImage     = nil
                selectedPhotoItem = nil

            } catch {
                isSubmitting = false
                submitError  = LocalizedErrorWrapper(error)
            }
        }
    }
}

// MARK: - Error wrapper

private struct LocalizedErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
    init(_ error: Error) { self.message = error.localizedDescription }
}

// MARK: - Preview

#Preview {
    DriverFuelView()
        .environment(AuthViewModel())
}
