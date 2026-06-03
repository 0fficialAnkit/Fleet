import SwiftUI
import PhotosUI
import Supabase

struct DriverChecklistView: View {

    let checklistType: InspectionType
    let vehicle:       Vehicle?
    let onSubmit:      (String, [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var checkedItems:    Set<String>        = []
    @State private var selectedPhotos:  [PhotosPickerItem] = []
    @State private var capturedImages:  [UIImage]          = []
    @State private var additionalNotes: String             = ""
    @State private var isSubmitting:    Bool               = false

    // MARK: - Checklist data

    let preTripItems: [(name: String, icon: String, mandatory: Bool)] = [
        ("Tire Pressure & Condition",   "tire",                             true),
        ("Brake System Test",           "pedal.brake",                      true),
        ("Engine Oil Level",            "drop.fill",                        true),
        ("Coolant Level",               "thermometer.medium",               true),
        ("Lights & Turn Signals",       "headlight.high.beam",              true),
        ("Mirrors & Windshield",        "mirror.side.right",                true),
        ("Seat Belt Function",          "seatbelt",                         true),
        ("Horn Working",                "speaker.wave.2.fill",              false),
        ("Wiper Blades Condition",      "wiper.washer.fluid",               false),
        ("Dashboard Warning Lights",    "gauge.with.dots.needle.33percent", true),
    ]

    let postTripItems: [(name: String, icon: String, mandatory: Bool)] = [
        ("Vehicle Cleanliness",             "sparkles",                                         false),
        ("Exterior Damage Check",           "car.side.rear.and.collision.and.car.side.front",   true),
        ("Fuel Level Check",                "fuelpump",                                         true),
        ("Cargo Area Secured / Empty",      "shippingbox",                                      true),
        ("Lights & Signals Off",            "headlight.high.beam",                              false),
        ("Parking Brake Engaged",           "pedal.brake",                                      true),
        ("Keys Returned",                   "key.fill",                                         true),
    ]

    var currentItems: [(name: String, icon: String, mandatory: Bool)] {
        checklistType == .preTrip ? preTripItems : postTripItems
    }

    var mandatoryItems:       [String] { currentItems.filter { $0.mandatory }.map { $0.name } }
    var allMandatoryChecked:  Bool     { mandatoryItems.allSatisfy { checkedItems.contains($0) } }
    var checkedCount:         Int      { checkedItems.count }
    var totalCount:           Int      { currentItems.count }

    var swipeLabel: String {
        checklistType == .preTrip ? "Slide to Start Trip" : "Slide to End Trip"
    }

    var swipeTint: Color {
        checklistType == .preTrip ? .green : .red
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {

                        // Progress header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(checklistType == .preTrip
                                     ? "Pre-Trip Safety Check"
                                     : "Post-Trip Safety Check")
                                    .font(.title3.bold())
                                Text("\(checkedCount) of \(totalCount) items checked")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            // Circular progress
                            ZStack {
                                Circle()
                                    .stroke(Color(.systemGray5), lineWidth: 4)
                                Circle()
                                    .trim(from: 0, to: totalCount > 0
                                          ? CGFloat(checkedCount) / CGFloat(totalCount) : 0)
                                    .stroke(swipeTint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .animation(.spring(), value: checkedCount)
                                Text("\(Int(totalCount > 0 ? Double(checkedCount)/Double(totalCount)*100 : 0))%")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(swipeTint)
                            }
                            .frame(width: 48, height: 48)
                        }
                        .padding(.top, 4)

                        // Mandatory legend
                        HStack(spacing: 6) {
                            Circle().fill(.red).frame(width: 7, height: 7)
                            Text("Required to proceed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Checklist grid
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            ForEach(currentItems, id: \.name) { item in
                                checklistCell(item)
                            }
                        }

                        // Photos (optional)
                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            if !capturedImages.isEmpty {
                                LazyVGrid(
                                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                                    spacing: 8
                                ) {
                                    ForEach(capturedImages.indices, id: \.self) { i in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: capturedImages[i])
                                                .resizable().scaledToFill()
                                                .frame(height: 90)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            Button { capturedImages.remove(at: i) } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .symbolRenderingMode(.palette)
                                                    .foregroundStyle(.white, .red)
                                                    .font(.title3)
                                            }.padding(4)
                                        }
                                    }
                                }
                            }

                            PhotosPicker(
                                selection: $selectedPhotos,
                                maxSelectionCount: 5,
                                matching: .images
                            ) {
                                Label(capturedImages.isEmpty ? "Add Photos" : "Add More Photos",
                                      systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.secondary)
                            .controlSize(.regular)
                            .buttonBorderShape(.capsule)
                        }

                        // Additional notes
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            TextField("Add any observations or issues…",
                                      text: $additionalNotes, axis: .vertical)
                                .lineLimit(2...5)
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Report Vehicle Issue
                        if let vehicle {
                            NavigationLink(destination: DriverReportIssueView(vehicle: vehicle)) {
                                Label("Report Vehicle Issue",
                                      systemImage: "exclamationmark.triangle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .controlSize(.large)
                            .buttonBorderShape(.capsule)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }

                // ── Sticky footer — always visible, no scrolling needed ────
                VStack(spacing: 10) {
                    if !allMandatoryChecked {
                        Label("Check all required items (●) to proceed",
                              systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    SwipeToConfirmButton(
                        label:   swipeLabel,
                        tint:    swipeTint,
                        enabled: allMandatoryChecked && !isSubmitting
                    ) {
                        handleSubmit()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
            }
            .navigationTitle(checklistType == .preTrip ? "Pre-Trip Safety" : "Post-Trip Safety")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onChange(of: selectedPhotos) { _, newItems in
                Task {
                    for item in newItems {
                        if let data  = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) { capturedImages.append(image) }
                    }
                    selectedPhotos = []
                }
            }
        }
    }

    // MARK: - Checklist cell

    private func checklistCell(_ item: (name: String, icon: String, mandatory: Bool)) -> some View {
        let isChecked = checkedItems.contains(item.name)
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                if isChecked { checkedItems.remove(item.name) }
                else         { checkedItems.insert(item.name) }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 17))
                    .foregroundStyle(isChecked ? swipeTint : .primary)
                    .frame(width: 22)

                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isChecked ? swipeTint : Color(.systemGray3))
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isChecked ? swipeTint.opacity(0.4) : Color.clear,
                            lineWidth: 1.5)
            )
            // Mandatory dot — top-left corner
            .overlay(alignment: .topLeading) {
                if item.mandatory {
                    Circle().fill(.red)
                        .frame(width: 7, height: 7)
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit (called by swipe)

    private func handleSubmit() {
        isSubmitting = true
        var notes = "Checked: " + checkedItems.joined(separator: ", ")
        if !additionalNotes.isEmpty { notes += "\nNotes: \(additionalNotes)" }
        if !capturedImages.isEmpty  { notes += "\n\(capturedImages.count) photo(s) attached" }

        Task {
            var urls: [String] = []
            for (i, img) in capturedImages.enumerated() {
                if let data = img.jpegData(compressionQuality: 0.7) {
                    let path = "inspections/\(UUID().uuidString)_\(i).jpg"
                    do {
                        try await supabase.storage.from("fleet-uploads")
                            .upload(path, data: data, options: .init(contentType: "image/jpeg"))
                        if let url = try? supabase.storage.from("fleet-uploads")
                            .getPublicURL(path: path).absoluteString { urls.append(url) }
                    } catch { print("Photo upload failed: \(error)") }
                }
            }
            await MainActor.run {
                isSubmitting = false
                onSubmit(notes, urls)
                dismiss()
            }
        }
    }
}

#Preview {
    DriverChecklistView(checklistType: .preTrip, vehicle: nil) { _, _ in }
}
