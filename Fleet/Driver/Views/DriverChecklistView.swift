import SwiftUI
import PhotosUI
import Supabase

struct DriverChecklistView: View {

    let checklistType: InspectionType
    let vehicle: Vehicle?
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
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: checklistType == .preTrip ? "Pre-Trip Inspection" : "Post-Trip Inspection")
                            .padding(.top)

                        // Mandatory notice
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.yellow)
                            Text("Items marked with ● are mandatory")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.secondary)
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
                                        .foregroundColor(Color.green)
                                        .frame(width: 30)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(item.name)
                                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.primary)
                                            if item.mandatory {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 6, height: 6)
                                            }
                                        }
                                        if item.mandatory {
                                            Text("Required")
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundStyle(Color.red)
                                        }
                                    }
                                    .padding(.leading, 8)

                                    Spacer()

                                    Image(systemName: checkedItems.contains(item.name) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(checkedItems.contains(item.name) ? Color.green : Color(UIColor.tertiaryLabel))
                                        .font(.title3)
                                }
                                .padding(16)
                                .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(
                                            checkedItems.contains(item.name)
                                                ? Color.green.opacity(0.3)
                                                : Color.white.opacity(0.15),
                                            lineWidth: checkedItems.contains(item.name) ? 1.0 : 0.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                            }
                        }

                        // MARK: - Photo Upload Section
                        Divider().background(Color(UIColor.separator)).padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(Color.green)
                                Text("Vehicle Inspection Photos")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.primary)
                            }

                            Text("Upload photos of any damage or concerns found during inspection")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.secondary)

                            // Photo grid
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
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
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

                        // MARK: - Additional Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Notes")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.primary)

                            TextField("Note any issues, damage, or observations...", text: $additionalNotes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .padding(16)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for button
                }

                // MARK: - Submit Button
                VStack(spacing: 8) {
                    if let vehicle = vehicle {
                        NavigationLink(destination: DriverReportIssueView(vehicle: vehicle)) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Report an Issue")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.red.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.bottom, 8)
                    }

                    if !allMandatoryChecked {
                        Text("Complete all mandatory items to submit")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.red)
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
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(allMandatoryChecked && !isSubmitted ? Color(UIColor.systemBackground) : Color(UIColor.tertiaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(allMandatoryChecked && !isSubmitted ? Color.green : Color(UIColor.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .foregroundStyle(Color.secondary)
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
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
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(allMandatoryChecked ? Color.green : Color.green)
                        .frame(width: geo.size.width * Double(checkedCount) / Double(max(totalCount, 1)), height: 6)
                        .animation(.spring(response: 0.3), value: checkedCount)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(checkedCount)/\(totalCount) checked")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                Spacer()
                if allMandatoryChecked {
                    Text("All mandatory items ✓")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.green)
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
    DriverChecklistView(checklistType: .preTrip, vehicle: nil, onSubmit: { _, _ in })
}
