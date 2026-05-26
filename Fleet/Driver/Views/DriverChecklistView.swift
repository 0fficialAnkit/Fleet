import SwiftUI
import PhotosUI
import Supabase

struct DriverChecklistView: View {

    let checklistType: InspectionType
    let onSubmit: (String, [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var checkedItems: Set<String> = []
    @State private var isSubmitted = false
    @State private var isSubmitting = false

    // Photo upload
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var capturedImages: [UIImage] = []
    @State private var additionalNotes: String = ""

    // MARK: - Mandatory Checklist Items

    let preTripItems: [(name: String, icon: String, mandatory: Bool)] = [
        ("Tire Pressure & Condition", "tire", true),
        ("Brake System Test", "pedal.brake", true),
        ("Engine Oil Level", "drop.fill", true),
        ("Coolant Level", "thermometer.medium", true),
        ("Lights & Turn Signals", "headlight.high.beam", true),
        ("Mirrors & Windshield", "mirror.side.right", true),
        ("Seat Belt Function", "seatbelt", true),
        ("Horn Working", "speaker.wave.2.fill", false),
        ("Wiper Blades Condition", "wiper.washer.fluid", false),
        ("Dashboard Warning Lights", "gauge.with.dots.needle.33percent", true),
    ]

    let postTripItems: [(name: String, icon: String, mandatory: Bool)] = [
        ("Vehicle Cleanliness", "sparkles", false),
        ("Exterior Damage Check", "car.side.rear.and.collision.and.car.side.front", true),
        ("Fuel Level Check", "fuelpump", true),
        ("Cargo Area Secured / Empty", "shippingbox", true),
        ("Lights & Signals Off", "headlight.high.beam", false),
        ("Parking Brake Engaged", "pedal.brake", true),
        ("Keys Returned", "key.fill", true),
    ]

    var currentItems: [(name: String, icon: String, mandatory: Bool)] {
        checklistType == .preTrip ? preTripItems : postTripItems
    }

    var mandatoryItems: [String] {
        currentItems.filter { $0.mandatory }.map { $0.name }
    }

    var allMandatoryChecked: Bool {
        mandatoryItems.allSatisfy { checkedItems.contains($0) }
    }

    var checkedCount: Int { checkedItems.count }
    var totalCount: Int { currentItems.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                progressBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: themeModel.spacingMD) {
                        SectionHeader(title: checklistType == .preTrip ? "Pre-Trip Inspection" : "Post-Trip Inspection")
                            .padding(.top)

                        // Mandatory notice
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(themeModel.warning)
                            Text("Items marked with ● are mandatory")
                                .font(themeModel.caption())
                                .foregroundStyle(themeModel.textSecondary)
                        }
                        .padding(.horizontal, 4)

                        // Checklist items
                        ForEach(currentItems, id: \.name) { item in
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    if checkedItems.contains(item.name) {
                                        checkedItems.remove(item.name)
                                    } else {
                                        checkedItems.insert(item.name)
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(themeModel.driverPrimary)
                                        .frame(width: 30)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(item.name)
                                                .font(themeModel.body())
                                                .foregroundColor(themeModel.textPrimary)
                                            if item.mandatory {
                                                Circle()
                                                    .fill(themeModel.danger)
                                                    .frame(width: 6, height: 6)
                                            }
                                        }
                                        if item.mandatory {
                                            Text("Required")
                                                .font(themeModel.small())
                                                .foregroundStyle(themeModel.danger)
                                        }
                                    }
                                    .padding(.leading, 8)

                                    Spacer()

                                    Image(systemName: checkedItems.contains(item.name) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(checkedItems.contains(item.name) ? themeModel.success : themeModel.textTertiary)
                                        .font(.title3)
                                }
                                .padding(themeModel.spacingMD)
                                .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                        .stroke(
                                            checkedItems.contains(item.name)
                                                ? themeModel.success.opacity(0.3)
                                                : Color.white.opacity(0.15),
                                            lineWidth: checkedItems.contains(item.name) ? 1.0 : 0.5
                                        )
                                )
                                .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                            }
                        }

                        // MARK: - Photo Upload Section
                        Divider().background(themeModel.divider).padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(themeModel.driverPrimary)
                                Text("Vehicle Inspection Photos")
                                    .font(themeModel.headline())
                                    .foregroundStyle(themeModel.textPrimary)
                            }

                            Text("Upload photos of any damage or concerns found during inspection")
                                .font(themeModel.caption())
                                .foregroundStyle(themeModel.textSecondary)

                            // Photo grid
                            if !capturedImages.isEmpty {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(capturedImages.indices, id: \.self) { index in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: capturedImages[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))

                                            Button {
                                                capturedImages.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.title3)
                                                    .symbolRenderingMode(.palette)
                                                    .foregroundStyle(.white, themeModel.danger)
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
                                        .foregroundStyle(themeModel.driverPrimary)
                                    Text(capturedImages.isEmpty ? "Add Photos" : "Add More Photos")
                                        .font(themeModel.bodyMedium())
                                        .foregroundStyle(themeModel.driverPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(themeModel.spacingMD)
                                .background(themeModel.driverPrimary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD))
                                .overlay(
                                    RoundedRectangle(cornerRadius: themeModel.radiusMD)
                                        .stroke(themeModel.driverPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                                )
                            }
                        }

                        // MARK: - Additional Notes
                        VStack(alignment: .leading, spacing: themeModel.spacingSM) {
                            Text("Additional Notes")
                                .font(themeModel.headline())
                                .foregroundStyle(themeModel.textPrimary)

                            TextField("Note any issues, damage, or observations...", text: $additionalNotes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(themeModel.body())
                                .padding(themeModel.spacingMD)
                                .background(themeModel.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for button
                }

                // MARK: - Submit Button
                VStack(spacing: 8) {
                    if !allMandatoryChecked {
                        Text("Complete all mandatory items to submit")
                            .font(themeModel.caption())
                            .foregroundStyle(themeModel.danger)
                    }

                    Button(action: handleSubmit) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSubmitted ? "Submitted Successfully" : "Submit Inspection")
                            }
                        }
                        .font(themeModel.headline())
                        .foregroundColor(allMandatoryChecked && !isSubmitted ? themeModel.buttonPrimaryText : themeModel.buttonDisabledText)
                        .frame(maxWidth: .infinity)
                        .padding(themeModel.spacingMD)
                        .background(allMandatoryChecked && !isSubmitted ? themeModel.driverPrimary : themeModel.buttonDisabled)
                        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusSM))
                    }
                    .disabled(!allMandatoryChecked || isSubmitted || isSubmitting)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle(checklistType == .preTrip ? "Pre-Trip Safety" : "Post-Trip Safety")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(themeModel.textSecondary)
                }
            }
            .background(themeModel.backgroundPrimary.ignoresSafeArea())
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
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeModel.surfaceTertiary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(allMandatoryChecked ? themeModel.success : themeModel.driverPrimary)
                        .frame(width: geo.size.width * Double(checkedCount) / Double(max(totalCount, 1)), height: 6)
                        .animation(.spring(response: 0.3), value: checkedCount)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(checkedCount)/\(totalCount) checked")
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.textTertiary)
                Spacer()
                if allMandatoryChecked {
                    Text("All mandatory items ✓")
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.success)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Submit

    private func handleSubmit() {
        isSubmitting = true

        // Build notes string
        var notes = "Checked items: " + checkedItems.joined(separator: ", ")
        if !additionalNotes.isEmpty {
            notes += "\nAdditional notes: \(additionalNotes)"
        }
        if !capturedImages.isEmpty {
            notes += "\n\(capturedImages.count) inspection photo(s) attached"
        }

        Task {
            var imageUrls: [String] = []
            for (index, image) in capturedImages.enumerated() {
                if let data = image.jpegData(compressionQuality: 0.7) {
                    let fileName = "inspections/\(UUID().uuidString)_\(index).jpg"
                    do {
                        try await supabase.storage
                            .from("fleet-uploads")
                            .upload(fileName, data: data, options: .init(contentType: "image/jpeg"))
                        if let publicUrl = try? supabase.storage.from("fleet-uploads").getPublicURL(path: fileName).absoluteString {
                            imageUrls.append(publicUrl)
                        }
                    } catch {
                        print("Failed to upload inspection image: \(error)")
                    }
                }
            }

            await MainActor.run {
                isSubmitting = false
                isSubmitted = true
                onSubmit(notes, imageUrls)
                dismiss()
            }
        }
    }
}

#Preview {
    DriverChecklistView(checklistType: .preTrip, onSubmit: { _, _ in })
}
