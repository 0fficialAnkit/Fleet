import SwiftUI
import PhotosUI
import Supabase
import Vision

struct DriverFuelView: View {

    @State private var volume: String = ""
    @State private var price: String = ""
    @State private var showSuccess: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    // Photo picker
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var billImage: UIImage?

    // Vision OCR
    @State private var detectedBillAmount: Double?
    @State private var isScanningBill = false

    @State private var viewModel = DriverFuelViewModel()
    @State private var assignedVehicleId: UUID?
    @Environment(AuthViewModel.self) private var authViewModel

    private var isFormValid: Bool {
        !volume.isEmpty && !price.isEmpty && billImage != nil && assignedVehicleId != nil
    }

    private var inputFormSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Log Fuel Expense")
                .font(.title3.bold())
                .foregroundStyle(Color.primary)

            if assignedVehicleId == nil {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.yellow).font(.title3)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("No Assigned Vehicle")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Color.primary)
                        Text("You must have a vehicle assigned by your Fleet Manager to log fuel expenses.")
                            .font(.caption).foregroundStyle(Color.secondary)
                    }
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
            }

            // Volume
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill").foregroundStyle(Color.secondary).font(.subheadline)
                    Text("Fuel Volume (Liters)").font(.subheadline.weight(.medium)).foregroundStyle(Color.secondary)
                }
                TextField("0.0", text: $volume)
                    .keyboardType(.decimalPad).padding(14)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Price
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "indianrupeesign").foregroundStyle(Color.secondary).font(.subheadline)
                    Text("Total Price Paid").font(.subheadline.weight(.medium)).foregroundStyle(Color.secondary)
                }
                TextField("0.00", text: $price)
                    .keyboardType(.decimalPad).padding(14)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Bill Photo
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill").foregroundStyle(Color.secondary).font(.subheadline)
                    Text("Fuel Bill Photo").font(.subheadline.weight(.medium)).foregroundStyle(Color.secondary)
                    Text("(Required)").font(.caption).foregroundStyle(Color.red)
                }

                if let billImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: billImage)
                            .resizable().scaledToFill()
                            .frame(maxWidth: .infinity).frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.5), lineWidth: 1.5))

                        Button {
                            self.billImage = nil
                            selectedPhotoItem = nil
                            detectedBillAmount = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2).symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.red)
                        }
                        .padding(8)
                    }
                } else {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.viewfinder").font(.largeTitle).foregroundStyle(Color.green)
                            Text("Tap to attach bill photo").font(.subheadline.weight(.medium)).foregroundStyle(Color.green)
                            Text("Photo will be sent to Fleet Manager")
                                .font(.caption).foregroundStyle(Color(UIColor.tertiaryLabel))
                        }
                        .frame(maxWidth: .infinity).frame(height: 130)
                        .background(Color.green.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [8])))
                    }
                }
            }

            // OCR scanning indicator
            if isScanningBill {
                HStack(spacing: 10) {
                    ProgressView().scaleEffect(0.85)
                    Text("Scanning bill for amount…").font(.subheadline).foregroundStyle(Color.secondary)
                    Spacer()
                }
                .padding(14)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if let detected = detectedBillAmount {
                Button {
                    price = String(format: "%.0f", detected)
                    detectedBillAmount = nil
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "viewfinder.rectangular").foregroundStyle(Color.blue).font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Amount Detected via OCR")
                                .font(.caption.weight(.semibold)).foregroundStyle(Color.blue)
                            Text("₹\(Int(detected)) — tap to use")
                                .font(.subheadline.weight(.medium)).foregroundStyle(Color.primary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.blue)
                    }
                    .padding(14)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Submit
            Button(action: submitFuelLog) {
                HStack {
                    if isSubmitting {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.up.doc")
                        Text("Submit Fuel Log")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity).padding(16)
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
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green)
                Text("Synced with Fleet Manager").font(.subheadline.weight(.medium)).foregroundStyle(Color.primary)
                Spacer()
            }
            .padding(14)
            .background(Color.green.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recent Logs")

            if viewModel.fuelLogs.isEmpty {
                Text("No fuel logs recorded yet.")
                    .font(.subheadline).foregroundStyle(Color.secondary).padding(.vertical, 8)
            } else {
                ForEach(viewModel.fuelLogs) { log in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "drop.fill").foregroundStyle(Color.green).font(.subheadline)
                                Text("\(String(format: "%.1f", log.litersUsed ?? 0.0)) Liters")
                                    .font(.headline).foregroundStyle(Color.primary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "calendar").foregroundStyle(Color.secondary).font(.caption)
                                Text((log.recordedAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline).foregroundStyle(Color.secondary)
                            }
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "indianrupeesign")
                                .font(.caption.weight(.medium)).foregroundStyle(Color.secondary)
                            Text("\(Int(log.fuelCost ?? 0.0))")
                                .font(.title3.bold()).foregroundStyle(Color.primary)
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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    inputFormSection
                    successBannerSection
                    historySection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Fuel")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DriverFuelAnalyticsView()) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.body.weight(.medium)).foregroundStyle(Color.green)
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        billImage = image
                        detectedBillAmount = nil
                        await scanBillForAmount(image)
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage ?? "Unknown error occurred") }
            .onChange(of: authViewModel.currentUser?.id, initial: true) { _, newUserId in
                guard let userId = newUserId else { return }
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

    // MARK: - Submit

    private func submitFuelLog() {
        let liters = Double(volume) ?? 0.0
        let cost   = Double(price)  ?? 0.0
        let vehicleId = assignedVehicleId ?? UUID()

        isSubmitting = true; showSuccess = false; errorMessage = nil

        Task {
            do {
                var billUrl: String?
                if let billImage, let imageData = billImage.jpegData(compressionQuality: 0.7) {
                    let fileName = "bills/\(UUID().uuidString).jpg"
                    do {
                        try await supabase.storage.from("fuel")
                            .upload(fileName, data: imageData, options: .init(contentType: "image/jpeg"))
                        billUrl = try? supabase.storage.from("fuel").getPublicURL(path: fileName).absoluteString
                    } catch { print("[DriverFuelView] Storage upload failed: \(error)") }
                }

                try await viewModel.addFuelLog(liters: liters, cost: cost, vehicleId: vehicleId, billUrl: billUrl)

                Task {
                    do {
                        if let userId = authViewModel.currentUser?.id {
                            let managers = try await ProfileService.fetchProfilesByRole(role: "fleet_manager")
                            for manager in managers {
                                let notification = Notification(
                                    id: UUID(), userId: manager.id, title: "Fuel Log Submitted",
                                    message: "Driver logged \(String(format: "%.1f", liters))L fuel — ₹\(Int(cost)).",
                                    type: .info, isRead: false, createdAt: Date()
                                )
                                try await NotificationService.createNotification(notification)
                            }
                        }
                    } catch { print("[DriverFuelView] Failed to dispatch notifications: \(error)") }
                }

                await MainActor.run {
                    isSubmitting = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showSuccess = true }
                    volume = ""; price = ""; self.billImage = nil; selectedPhotoItem = nil
                }
            } catch {
                await MainActor.run { isSubmitting = false; errorMessage = error.localizedDescription }
            }
        }
    }

    // MARK: - Vision OCR

    @MainActor
    private func scanBillForAmount(_ image: UIImage) async {
        guard let cgImage = image.cgImage else { return }
        isScanningBill = true; detectedBillAmount = nil

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
                continuation.resume()
            }
        }

        let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let combined = lines.joined(separator: " ")

        let patterns = [
            "₹\\s*(\\d{2,6}(?:[.,]\\d{1,2})?)",
            "[Rr]s\\.?\\s*(\\d{2,6}(?:[.,]\\d{1,2})?)",
            "[Tt]otal[:\\s]+([\\d,]{2,7}(?:\\.\\d{1,2})?)",
            "[Aa]mount[:\\s]+([\\d,]{2,7}(?:\\.\\d{1,2})?)",
            "([\\d,]{3,7}(?:\\.\\d{2})?)"
        ]

        var bestAmount: Double?
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(combined.startIndex..., in: combined)
            let matches = regex.matches(in: combined, range: range)
            let amounts: [Double] = matches.compactMap { match in
                guard let r = Range(match.range(at: 1), in: combined) else { return nil }
                return Double(String(combined[r]).replacingOccurrences(of: ",", with: ""))
            }
            if let amount = amounts.filter({ $0 >= 2 && $0 <= 10_000 }).max() {
                bestAmount = amount; break
            }
        }

        isScanningBill = false
        detectedBillAmount = bestAmount
    }
}

#Preview {
    NavigationStack {
        DriverFuelView()
            .environment(AuthViewModel())
    }
}
