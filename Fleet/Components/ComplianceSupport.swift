import SwiftUI
import Vision
import PhotosUI
@preconcurrency import UserNotifications

// MARK: - Compliance Status

enum ComplianceStatus: String, Codable {
    case compliant    = "Compliant"
    case expiringSoon = "Expiring Soon"
    case nonCompliant = "Non-Compliant"

    var color: Color {
        switch self {
        case .compliant:    return .green
        case .expiringSoon: return .orange
        case .nonCompliant: return .red
        }
    }
    var icon: String {
        switch self {
        case .compliant:    return "checkmark.shield.fill"
        case .expiringSoon: return "exclamationmark.triangle.fill"
        case .nonCompliant: return "xmark.shield.fill"
        }
    }
}

// MARK: - Compliance Settings

struct ComplianceSettings: Codable, Equatable {
    var vehicleId:       String
    var insuranceExpiry: Date?
    var serviceExpiry:   Date?
}

// MARK: - Store (UserDefaults-backed, app-local)

@MainActor @Observable
final class ComplianceSettingsStore {
    static let shared = ComplianceSettingsStore()
    private static let udKey = "fleet_compliance_settings_v2"

    private(set) var all: [ComplianceSettings] = []
    init() { load() }

    func settings(for vehicleId: String) -> ComplianceSettings {
        all.first { $0.vehicleId == vehicleId } ?? ComplianceSettings(vehicleId: vehicleId)
    }

    func upsert(_ s: ComplianceSettings) {
        if let i = all.firstIndex(where: { $0.vehicleId == s.vehicleId }) {
            all[i] = s
        } else {
            all.append(s)
        }
        save()
        scheduleNotifications(for: s)
    }

    func status(for date: Date?) -> ComplianceStatus {
        guard let date else { return .compliant }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0  { return .nonCompliant }
        if days <= 30 { return .expiringSoon }
        return .compliant
    }

    func daysLeft(for date: Date?) -> Int? {
        guard let date else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.udKey),
              let decoded = try? JSONDecoder().decode([ComplianceSettings].self, from: data)
        else { return }
        all = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: Self.udKey)
        }
    }

    private func scheduleNotifications(for s: ComplianceSettings) {
        let center = UNUserNotificationCenter.current()
        let prefix = "fleet_\(s.vehicleId)_"
        center.getPendingNotificationRequests { pending in
            let toRemove = pending.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
        for days in [30, 15, 7, 1] {
            if let d = s.insuranceExpiry { schedule(id: "\(prefix)ins_\(days)", title: "Insurance Expiry",  body: "Expires in \(days) day\(days == 1 ? "" : "s").", daysBeforeDate: d, advance: days) }
            if let d = s.serviceExpiry   { schedule(id: "\(prefix)svc_\(days)", title: "Service Due",       body: "Service due in \(days) day\(days == 1 ? "" : "s").",   daysBeforeDate: d, advance: days) }
        }
    }

    private func schedule(id: String, title: String, body: String, daysBeforeDate: Date, advance: Int) {
        guard let trigger = Calendar.current.date(byAdding: .day, value: -advance, to: daysBeforeDate),
              trigger > Date() else { return }
        let c = UNMutableNotificationContent()
        c.title = title; c.body = body; c.sound = .default
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: trigger)
        comps.hour = 9; comps.minute = 0
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: c,
                                  trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        )
    }
}

// MARK: - Compliance Badge

struct ComplianceBadge: View {
    let status: ComplianceStatus
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon).font(.system(size: 9, weight: .bold))
            Text(status.rawValue).font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - OCR Date Scanner Sheet
// Unified for both insurance and service — uses Vision + NSDataDetector.
// No external OCR engine dependency.

struct OCRDateScannerSheet: View {

    enum Target: String {
        case insurance = "Insurance Policy"
        case service   = "Service Receipt"
        var accentColor: Color { self == .insurance ? .teal : .orange }
        var icon: String       { self == .insurance ? "shield.lefthalf.filled" : "wrench.and.screwdriver" }
    }

    let target: Target
    let onApply: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var capturedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isScanning     = false
    @State private var scanComplete   = false
    @State private var extractedDate: Date?
    @State private var scanMessage    = ""
    @State private var laserOffset: CGFloat = -100
    @State private var showCameraUnavailable = false
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Document preview ──────────────────────────────
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .frame(height: 220)
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(target.accentColor.opacity(0.25), lineWidth: 1.5))

                            if let img = capturedImage {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .opacity(isScanning ? 0.55 : 1.0)
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: target.icon)
                                        .font(.system(size: 48)).foregroundStyle(target.accentColor.opacity(0.7))
                                    Text(target.rawValue.uppercased())
                                        .font(.caption.bold()).foregroundStyle(Color.primary)
                                    Text("Take a photo or choose from gallery")
                                        .font(.caption2).foregroundStyle(Color.secondary)
                                }
                            }

                            // Scan laser
                            if isScanning {
                                Rectangle()
                                    .fill(LinearGradient(colors: [.clear, target.accentColor.opacity(0.8), .clear],
                                                        startPoint: .top, endPoint: .bottom))
                                    .frame(height: 12)
                                    .offset(y: laserOffset)
                                    .onAppear {
                                        laserOffset = -100
                                        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                                            laserOffset = 100
                                        }
                                    }
                            }

                            // Success overlay
                            if scanComplete && extractedDate != nil {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.green.opacity(0.15)).frame(height: 220)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44)).foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.25), value: scanComplete)

                        // ── Source buttons ────────────────────────────────
                        HStack(spacing: 12) {
                            Button {
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    showCamera = true
                                } else {
                                    showCameraUnavailable = true
                                }
                            } label: {
                                Label("Camera", systemImage: "camera.fill")
                                    .font(.body.bold())
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(target.accentColor).foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Label("Gallery", systemImage: "photo.on.rectangle")
                                    .font(.body.bold())
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(target.accentColor.opacity(0.12))
                                    .foregroundStyle(target.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(target.accentColor.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)

                        // ── Scan status ───────────────────────────────────
                        if isScanning || !scanMessage.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    if isScanning {
                                        ProgressView().tint(target.accentColor).scaleEffect(0.8)
                                    } else {
                                        Image(systemName: extractedDate != nil ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                                            .foregroundStyle(extractedDate != nil ? Color.green : .orange)
                                    }
                                    Text(isScanning ? "Scanning document…" : (extractedDate != nil ? "Date found" : "No date detected"))
                                        .font(.subheadline.bold())
                                }

                                if !scanMessage.isEmpty {
                                    Text(scanMessage)
                                        .font(.caption).foregroundStyle(Color.secondary)
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.tertiarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }

                                if let date = extractedDate {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar.badge.checkmark").foregroundStyle(.green)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Extracted Date").font(.caption).foregroundStyle(.secondary)
                                            Text(date.formatted(date: .long, time: .omitted))
                                                .font(.subheadline.bold())
                                        }
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.green.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .padding(.horizontal)
                        }

                        // ── Use Date button ───────────────────────────────
                        if let date = extractedDate {
                            Button {
                                onApply(date)
                                dismiss()
                            } label: {
                                Label("Use This Date", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                                    .background(Color.green).foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Scan \(target.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Camera Unavailable", isPresented: $showCameraUnavailable) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Camera is not available on this device. Use Gallery instead.")
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(capturedImage: $capturedImage).ignoresSafeArea()
            }
            .onChange(of: selectedItem) { _, item in
                guard let item else { return }
                Task { @MainActor in
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img  = UIImage(data: data) {
                        capturedImage = img
                    }
                }
            }
            .onChange(of: capturedImage) { _, img in
                guard let img else { return }
                Task { await runOCR(on: img) }
            }
        }
    }

    // MARK: - Vision OCR (unified, no external engine)

    private func runOCR(on image: UIImage) async {
        isScanning = true; scanComplete = false; extractedDate = nil
        scanMessage = "Recognising text…"

        guard let cg = image.cgImage else {
            isScanning = false; scanMessage = "Could not read image."; return
        }

        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        let req     = VNRecognizeTextRequest()
        req.recognitionLevel = .accurate
        req.usesLanguageCorrection = false
        req.recognitionLanguages   = ["en-US"]

        do {
            try handler.perform([req])
            let lines = req.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
            scanMessage = "Searching \(lines.count) text segments for dates…"

            let today = Calendar.current.startOfDay(for: Date())
            var candidates: [Date] = []

            // NSDataDetector pass
            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
                for line in lines {
                    let r = NSRange(line.startIndex..., in: line)
                    for m in detector.matches(in: line, options: [], range: r) {
                        if let d = m.date { candidates.append(d) }
                    }
                }
            }

            // Format-based pass
            let formats = [
                "dd/MM/yyyy", "MM/dd/yyyy", "d/M/yyyy", "dd-MM-yyyy",
                "dd.MM.yyyy", "yyyy-MM-dd", "dd MMM yyyy", "d MMM yyyy",
                "MMM dd, yyyy", "MMMM dd, yyyy", "dd MMMM yyyy"
            ]
            let fm = DateFormatter()
            fm.locale = Locale(identifier: "en_US_POSIX")
            fm.isLenient = true
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                for fmt in formats {
                    fm.dateFormat = fmt
                    if let d = fm.date(from: trimmed) { candidates.append(d) }
                }
            }

            isScanning = false
            let midnights = Set(candidates.map { Calendar.current.startOfDay(for: $0) })
            let future = midnights.filter { $0 >= today }.sorted()

            if let best = future.first {
                extractedDate = best
                scanMessage = "Found: \(best.formatted(date: .long, time: .omitted))"
            } else if let past = midnights.filter({ $0 < today }).sorted(by: >).first {
                extractedDate = past
                scanMessage = "⚠ Found expired date: \(past.formatted(date: .long, time: .omitted))"
            } else {
                scanMessage = "No date found. Try a clearer photo or enter manually."
            }
            withAnimation { scanComplete = true }

        } catch {
            isScanning = false
            scanMessage = "OCR error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Vehicle Compliance Section (reusable in any vehicle detail view)

struct VehicleComplianceSection: View {

    let vehicle: Vehicle
    var editable: Bool = false   // fleet manager sees edit buttons; driver sees read-only

    @State private var store         = ComplianceSettingsStore.shared
    @State private var showInsScanner = false
    @State private var showSvcScanner = false

    private var key: String { vehicle.licensePlate ?? vehicle.id.uuidString }
    private var settings: ComplianceSettings { store.settings(for: key) }

    var body: some View {
        VStack(spacing: 0) {

            // Insurance row
            complianceRow(
                icon:   "shield.lefthalf.filled",
                label:  "Insurance Expiry",
                date:   settings.insuranceExpiry,
                status: store.status(for: settings.insuranceExpiry),
                days:   store.daysLeft(for: settings.insuranceExpiry),
                onScan: editable ? { showInsScanner = true } : nil
            )

            Divider().padding(.leading, 52)

            // Service row
            complianceRow(
                icon:   "wrench.and.screwdriver",
                label:  "Next Service Due",
                date:   settings.serviceExpiry,
                status: store.status(for: settings.serviceExpiry),
                days:   store.daysLeft(for: settings.serviceExpiry),
                onScan: editable ? { showSvcScanner = true } : nil
            )
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .sheet(isPresented: $showInsScanner) {
            OCRDateScannerSheet(target: .insurance) { date in
                var s = settings; s.insuranceExpiry = date; store.upsert(s)
            }
        }
        .sheet(isPresented: $showSvcScanner) {
            OCRDateScannerSheet(target: .insurance) { date in
                var s = settings; s.serviceExpiry = date; store.upsert(s)
            }
        }
    }

    private func complianceRow(
        icon: String, label: String, date: Date?,
        status: ComplianceStatus, days: Int?, onScan: (() -> Void)?
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(status.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(status.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                if let date {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption).foregroundStyle(Color.secondary)
                } else {
                    Text("Not set")
                        .font(.caption).foregroundStyle(Color(.tertiaryLabel))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                ComplianceBadge(status: status)
                if let d = days {
                    Text(d >= 0 ? "\(d)d left" : "Expired")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(status.color)
                }
            }

            if let onScan {
                Button(action: onScan) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.teal)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.delegate   = context.coordinator
        return p
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ p: CameraPickerView) { parent = p }
        func imagePickerController(_ p: UIImagePickerController, didFinishPickingMediaWithInfo i: [UIImagePickerController.InfoKey: Any]) {
            parent.capturedImage = i[.originalImage] as? UIImage
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ p: UIImagePickerController) { parent.dismiss() }
    }
}
