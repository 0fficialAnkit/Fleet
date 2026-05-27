import SwiftUI
import Vision
import PhotosUI
import UserNotifications

// MARK: - Compliance Status

enum ComplianceStatus: String, Codable {
    case compliant    = "Compliant"
    case expiringSoon = "Expiring Soon"
    case nonCompliant = "Non-Compliant"

    var color: Color {
        switch self {
        case .compliant:    return Color(red: 0.13, green: 0.76, blue: 0.49)
        case .expiringSoon: return Color(red: 1.0,  green: 0.62, blue: 0.04)
        case .nonCompliant: return Color(red: 0.94, green: 0.27, blue: 0.27)
        }
    }
    var icon: String {
        switch self {
        case .compliant:    return "checkmark.shield.fill"
        case .expiringSoon: return "exclamationmark.triangle.fill"
        case .nonCompliant: return "xmark.shield.fill"
        }
    }
    var label: String { rawValue }
}

// MARK: - Models

struct ReminderIntervals: Codable, Equatable {
    var day1:  Bool = true; var day7:  Bool = true
    var day15: Bool = true; var day30: Bool = true
    var activeDays: [Int] { [30, 15, 7, 1] }
}

struct NotificationMethods: Codable, Equatable {
    var pushEnabled: Bool = true; var inAppEnabled: Bool = true; var emailEnabled: Bool = false
}

struct ComplianceSettings: Codable, Equatable {
    var vehicleId:           String
    var insuranceExpiry:     Date?
    var serviceExpiry:       Date?
    var reminderIntervals:   ReminderIntervals   = ReminderIntervals()
    var notificationMethods: NotificationMethods = NotificationMethods()
}

// MARK: - ComplianceSettingsStore

@MainActor @Observable
final class ComplianceSettingsStore {
    private static let udKey = "fleet_compliance_settings"
    private(set) var allSettings: [ComplianceSettings] = []
    init() { load() }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.udKey),
              let decoded = try? JSONDecoder().decode([ComplianceSettings].self, from: data) else { return }
        allSettings = decoded
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(allSettings) else { return }
        UserDefaults.standard.set(data, forKey: Self.udKey)
    }

    func settings(for vehicleId: String) -> ComplianceSettings {
        allSettings.first { $0.vehicleId == vehicleId } ?? ComplianceSettings(vehicleId: vehicleId)
    }
    func upsert(_ settings: ComplianceSettings) {
        if let idx = allSettings.firstIndex(where: { $0.vehicleId == settings.vehicleId }) {
            allSettings[idx] = settings
        } else { allSettings.append(settings) }
        save()
        scheduleLocalNotifications(for: settings)
    }
    func insuranceStatus(for id: String) -> ComplianceStatus { complianceStatus(for: settings(for: id).insuranceExpiry) }
    func serviceStatus(for id: String) -> ComplianceStatus   { complianceStatus(for: settings(for: id).serviceExpiry)   }
    func overallStatus(for id: String) -> ComplianceStatus {
        let ins = insuranceStatus(for: id); let svc = serviceStatus(for: id)
        for s in [ComplianceStatus.nonCompliant, .expiringSoon] { if ins == s || svc == s { return s } }
        return .compliant
    }
    private func complianceStatus(for date: Date?) -> ComplianceStatus {
        guard let date else { return .compliant }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0 { return .nonCompliant }
        if days <= 30 { return .expiringSoon }
        return .compliant
    }
    func daysUntilExpiry(for date: Date?) -> Int? {
        guard let date else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }
    private func scheduleLocalNotifications(for settings: ComplianceSettings) {
        let center = UNUserNotificationCenter.current()
        let prefixIns = "ins_\(settings.vehicleId)_"; let prefixSvc = "svc_\(settings.vehicleId)_"
        center.getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(prefixIns) || $0.identifier.hasPrefix(prefixSvc) }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
        for days in [30, 15, 7, 1] {
            if let date = settings.insuranceExpiry { scheduleNotification(id: "ins_\(settings.vehicleId)_\(days)", title: "Insurance Expiry Reminder", body: "Vehicle insurance expires in \(days) day\(days == 1 ? "" : "s"). Take action now.", triggerDate: Calendar.current.date(byAdding: .day, value: -days, to: date)) }
            if let date = settings.serviceExpiry   { scheduleNotification(id: "svc_\(settings.vehicleId)_\(days)", title: "Service Due Reminder",        body: "Vehicle service is due in \(days) day\(days == 1 ? "" : "s"). Schedule now.",     triggerDate: Calendar.current.date(byAdding: .day, value: -days, to: date)) }
        }
    }
    private func scheduleNotification(id: String, title: String, body: String, triggerDate: Date?) {
        guard let triggerDate, triggerDate > Date() else { return }
        let content = UNMutableNotificationContent(); content.title = title; content.body = body; content.sound = .default; content.badge = 1
        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate); comps.hour = 9; comps.minute = 0
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
    }
    static let shared = ComplianceSettingsStore()
}

// MARK: - Compliance Badge

struct ComplianceBadge: View {
    let status: ComplianceStatus
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon).font(.system(size: 9, weight: .bold))
            Text(status.label).font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Expiry Row

private struct ExpiryRowView: View {
    let icon: String; let label: String; let date: Date?; let status: ComplianceStatus; let daysLeft: Int?
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(status.color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(status.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline.weight(.medium)).foregroundStyle(Color.primary)
                if let date { Text(date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(Color.secondary) }
                else { Text("Not Set").font(.caption).foregroundStyle(Color(.tertiaryLabel)) }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                ComplianceBadge(status: status)
                if let days = daysLeft { Text(days >= 0 ? "\(days)d left" : "Expired").font(.system(size: 10, weight: .medium)).foregroundStyle(status.color) }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: ─────────────────────────────────────────────────────────────────────
// MARK: - Camera Picker (UIViewControllerRepresentable)
// MARK: ─────────────────────────────────────────────────────────────────────

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate   = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.capturedImage = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: ─────────────────────────────────────────────────────────────────────
// MARK: - Compliance Reminder Settings Card
// MARK: ─────────────────────────────────────────────────────────────────────

struct ComplianceReminderCard: View {
    @Binding var settings: ComplianceSettings
    var compact: Bool = false

    enum OCRTarget { case insurance, service
        var displayName: String { self == .insurance ? "Insurance Certificate" : "Service Receipt" }
        var accentColor: Color  { self == .insurance ? .teal : .orange }
        var icon: String        { self == .insurance ? "shield.lefthalf.filled" : "wrench.and.screwdriver" }
    }

    @State private var showingScanner = false
    @State private var scannerTarget: OCRTarget = .insurance

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.teal.opacity(0.12)).frame(width: 40, height: 40)
                    Image(systemName: "bell.badge.shield.half.filled").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.teal)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compliance Dates").font(.headline).foregroundStyle(Color.primary)
                    Text("Set dates to receive automatic alerts").font(.caption).foregroundStyle(Color.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                // Insurance
                ExpiryInputRow(
                    icon: "shield.lefthalf.filled",
                    title: "Insurance Expiry",
                    accentColor: .teal,
                    date: $settings.insuranceExpiry,
                    onScan: { scannerTarget = .insurance; showingScanner = true }
                )

                // Service
                ExpiryInputRow(
                    icon: "wrench.and.screwdriver",
                    title: "Next Service Due",
                    accentColor: .orange,
                    date: $settings.serviceExpiry,
                    onScan: { scannerTarget = .service; showingScanner = true }
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.teal.opacity(0.18), lineWidth: 1))
        .sheet(isPresented: $showingScanner) {
            OCRScannerSheet(target: scannerTarget) { extractedDate in
                if scannerTarget == .insurance {
                    settings.insuranceExpiry = extractedDate
                } else {
                    settings.serviceExpiry = extractedDate
                }
            }
        }
    }
}

// MARK: - Expiry Input Row

private struct ExpiryInputRow: View {
    let icon: String
    let title: String
    let accentColor: Color
    @Binding var date: Date?
    let onScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).font(.system(size: 13)).foregroundStyle(accentColor)
                Text(title).font(.subheadline.bold()).foregroundStyle(Color.primary)
                Spacer()
                if date != nil {
                    Button { date = nil } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundStyle(Color(.tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                // DatePicker
                DatePicker("", selection: Binding(
                    get: { date ?? Date() },
                    set: { date = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .tint(accentColor)

                Spacer()

                // Scan button
                Button(action: onScan) {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.text.viewfinder").font(.system(size: 12, weight: .semibold))
                        Text("Scan").font(.caption.bold())
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Extracted date preview
            if let d = date {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.checkmark").font(.system(size: 11)).foregroundStyle(accentColor)
                    Text(d.formatted(date: .long, time: .omitted)).font(.caption.weight(.medium)).foregroundStyle(accentColor)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(accentColor.opacity(0.08))
                .clipShape(Capsule())
            } else {
                Text("Tap date picker or scan a document to auto-fill").font(.caption2).foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: ─────────────────────────────────────────────────────────────────────
// MARK: - OCR Scanner Sheet (Camera + Gallery + Auto-Apply)
// MARK: ─────────────────────────────────────────────────────────────────────

struct OCRScannerSheet: View {
    let target: ComplianceReminderCard.OCRTarget
    let onApply: (Date) -> Void
    @Environment(\.dismiss) private var dismiss

    enum SourceChoice { case none, camera, gallery }

    @State private var sourceChoice: SourceChoice = .none
    @State private var showingCamera  = false
    @State private var showingGallery = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var capturedImage: UIImage? = nil

    @State private var isScanning      = false
    @State private var scanText        = ""
    @State private var extractedDate: Date? = nil
    @State private var scanComplete    = false
    @State private var laserOffset: CGFloat = -100
    @State private var showingCameraUnavailableAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Document preview frame ────────────────────────────
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .frame(height: 220)
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(target.accentColor.opacity(0.25), lineWidth: 1.5))

                            if let img = capturedImage {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .opacity(isScanning ? 0.6 : 1.0)
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: target == .insurance ? "doc.richtext.fill" : "doc.text.fill")
                                        .font(.system(size: 52)).foregroundStyle(target.accentColor.opacity(0.7))
                                    Text(target.displayName.uppercased())
                                        .font(.caption.bold()).foregroundStyle(Color.primary)
                                    Text("Choose an option below to upload")
                                        .font(.system(size: 10)).foregroundStyle(Color.secondary)
                                }
                            }

                            // Laser scan animation
                            if isScanning {
                                Rectangle()
                                    .fill(LinearGradient(colors: [.clear, target.accentColor, .clear], startPoint: .top, endPoint: .bottom))
                                    .frame(height: 14)
                                    .offset(y: laserOffset)
                                    .onAppear {
                                        laserOffset = -100
                                        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                                            laserOffset = 100
                                        }
                                    }
                            }

                            // Success overlay
                            if scanComplete, extractedDate != nil {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0.13, green: 0.76, blue: 0.49).opacity(0.15))
                                    .frame(height: 220)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44)).foregroundStyle(Color(red: 0.13, green: 0.76, blue: 0.49))
                            }
                        }
                        .padding(.horizontal, 24)
                        .animation(.easeInOut(duration: 0.3), value: scanComplete)

                        // ── Source Picker Buttons ──────────────────────────────
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                // Camera
                                Button {
                                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        showingCamera = true
                                    } else {
                                        showingCameraUnavailableAlert = true
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "camera.fill").font(.system(size: 15))
                                        Text("Camera").font(.body.bold())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(target.accentColor)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)

                                // Gallery
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo.on.rectangle").font(.system(size: 15))
                                        Text("Gallery").font(.body.bold())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(target.accentColor.opacity(0.12))
                                    .foregroundColor(target.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(target.accentColor.opacity(0.3), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 24)
                        }

                        // ── OCR Status Card ───────────────────────────────────
                        if !scanText.isEmpty || isScanning {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    if isScanning {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: target.accentColor)).scaleEffect(0.8)
                                    } else {
                                        Image(systemName: extractedDate != nil ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                                            .foregroundStyle(extractedDate != nil ? Color(red: 0.13, green: 0.76, blue: 0.49) : .orange)
                                    }
                                    Text(isScanning ? "Scanning document..." : (extractedDate != nil ? "Date extracted successfully" : "No date found"))
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color.primary)
                                }

                                if !scanText.isEmpty {
                                    Text(scanText)
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.tertiarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }

                                if let date = extractedDate {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar.badge.checkmark")
                                            .foregroundStyle(Color(red: 0.13, green: 0.76, blue: 0.49))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Extracted Expiry Date")
                                                .font(.caption).foregroundStyle(Color.secondary)
                                            Text(date.formatted(date: .long, time: .omitted))
                                                .font(.subheadline.bold()).foregroundStyle(Color.primary)
                                        }
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(red: 0.13, green: 0.76, blue: 0.49).opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(red: 0.13, green: 0.76, blue: 0.49).opacity(0.25), lineWidth: 1))
                                }
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .padding(.horizontal, 24)
                        }

                        // ── Use Date Button ───────────────────────────────────
                        if let date = extractedDate {
                            Button {
                                onApply(date)
                                dismiss()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill").font(.system(size: 18))
                                    Text("Use This Date").font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.13, green: 0.76, blue: 0.49))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: Color(red: 0.13, green: 0.76, blue: 0.49).opacity(0.35), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Color.clear.frame(height: 24)
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Scan \(target.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.primary)
                }
            }
            .alert("Camera Unavailable", isPresented: $showingCameraUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This device or simulator does not support camera capture. Please use the Gallery option to select a document.")
            }
            // Camera
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPickerView(capturedImage: $capturedImage)
                    .ignoresSafeArea()
            }
            // Gallery onChange
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task { @MainActor in
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let img  = UIImage(data: data) {
                        capturedImage = img
                    }
                }
            }
            // Trigger OCR whenever capturedImage changes
            .onChange(of: capturedImage) { _, img in
                guard let img else { return }
                Task { await runOCR(on: img) }
            }
        }
    }

    // MARK: - Vision OCR

    private func runOCR(on image: UIImage) async {
        isScanning   = true
        scanComplete = false
        extractedDate = nil
        scanText     = "Recognising text in image..."

        guard let cgImage = image.cgImage else {
            isScanning = false; scanText = "Error: could not read image."; return
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        do {
            try handler.perform([request])

            let rawLines = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
            scanText  = "Searching \(rawLines.count) text segments for dates..."

            var found: [Date] = []
            let fm = DateFormatter()
            fm.locale = Locale(identifier: "en_US_POSIX")

            // Regex patterns for date substrings (flexible boundaries to allow trailing dots/brackets)
            let regexPatterns = [
                // numeric: dd/MM/yyyy or MM/dd/yyyy or dd.MM.yyyy
                "\\d{1,2}[/\\-\\.]\\d{1,2}[/\\-\\.]\\d{2,4}",
                // ISO numeric: yyyy-MM-dd
                "\\d{4}[/\\-\\.]\\d{1,2}[/\\-\\.]\\d{1,2}",
                // word dates: dd MMM yyyy or d MMMM yy
                "\\d{1,2}\\s+[A-Za-z]{3,10}\\s+\\d{2,4}",
                // word dates: MMM dd, yyyy
                "[A-Za-z]{3,10}\\s+\\d{1,2}[,\\s]+\\d{2,4}"
            ]

            let formats = [
                "dd/MM/yyyy", "MM/dd/yyyy", "yyyy/MM/dd",
                "dd-MM-yyyy", "MM-dd-yyyy", "yyyy-MM-dd",
                "dd.MM.yyyy", "MM.dd.yyyy", "yyyy.MM.dd",
                "d/M/yy", "M/d/yy",
                "d-M-yy", "M-d-yy",
                "d.M.yy", "M.d.yy",
                "dd MMM yyyy", "d MMM yyyy", "MMM dd yyyy", "dd MMMM yyyy", "MMMM dd yyyy",
                "dd MMM yy", "MMM dd yy",
                "MMM dd, yyyy", "MMMM dd, yyyy",
                "d MMMM yyyy", "MMMM d yyyy"
            ]

            for rawLine in rawLines {
                // ── Normalize the OCR text line ──
                var line = rawLine
                
                // 1. Remove ordinal suffixes like 1st, 2nd, 3rd, 4th (e.g. "27th May" -> "27 May")
                if let ordinalRegex = try? NSRegularExpression(pattern: "(\\b\\d+)(st|nd|rd|th)\\b", options: .caseInsensitive) {
                    line = ordinalRegex.stringByReplacingMatches(in: line, options: [], range: NSRange(location: 0, length: (line as NSString).length), withTemplate: "$1")
                }
                
                // 2. Fix common OCR bar misrecognitions (replacing |, l, I, 1 with / when between digits)
                if let dividerRegex = try? NSRegularExpression(pattern: "(\\d+)\\s*[\\|lI1]\\s*(\\d+)", options: []) {
                    line = dividerRegex.stringByReplacingMatches(in: line, options: [], range: NSRange(location: 0, length: (line as NSString).length), withTemplate: "$1/$2")
                }
                
                // 3. Remove spaces around common date separators
                line = line.replacingOccurrences(of: " / ", with: "/")
                line = line.replacingOccurrences(of: " - ", with: "-")
                line = line.replacingOccurrences(of: " . ", with: ".")
                line = line.replacingOccurrences(of: "/ ", with: "/")
                line = line.replacingOccurrences(of: " /", with: "/")
                line = line.replacingOccurrences(of: "- ", with: "-")
                line = line.replacingOccurrences(of: " -", with: "-")

                // ── 1. NSDataDetector pass on normalized line ──
                if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
                    let range = NSRange(line.startIndex..<line.endIndex, in: line)
                    let matches = detector.matches(in: line, options: [], range: range)
                    for m in matches {
                        if let d = m.date {
                            found.append(d)
                        }
                    }
                }

                // ── 2. Regex Substring Match pass ──
                for pattern in regexPatterns {
                    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
                    let nsString = line as NSString
                    let results = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
                    
                    for result in results {
                        let dateSubstring = nsString.substring(with: result.range)
                        let cleaned = dateSubstring.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        for fmt in formats {
                            fm.dateFormat = fmt
                            if let d = fm.date(from: cleaned) {
                                found.append(d)
                            }
                        }
                    }
                }
                
                // ── 3. Full Line pass as fallback ──
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                for fmt in formats {
                    fm.dateFormat = fmt
                    if let d = fm.date(from: trimmed) {
                        found.append(d)
                    }
                }
            }

            // Brief processing delay for visual effect
            try? await Task.sleep(nanoseconds: 900_000_000)

            isScanning = false
            
            // Normalize current moment to date-only midnight to correctly include "today" as future/expiry
            let calendar = Calendar.current
            let todayMidnight = calendar.startOfDay(for: Date())
            
            // Clean found dates: convert all to midnight for reliable comparison
            let midnightDates = Set(found.map { calendar.startOfDay(for: $0) })
            
            // Sort: prefer future dates (>= todayMidnight), then pick the earliest upcoming expiry.
            // If only past/expired dates remain, pick the latest past date.
            let futureDates = midnightDates.filter { $0 >= todayMidnight }.sorted(by: { $0 < $1 })
            let pastDates   = midnightDates.filter { $0 < todayMidnight }.sorted(by: { $0 > $1 })
            
            if let best = futureDates.first {
                extractedDate = best
                scanText = "✓ Scanned document. Found expiry date: \(best.formatted(date: .long, time: .omitted))"
            } else if let best = pastDates.first {
                extractedDate = best
                scanText = "⚠ Scanned document. Found expired date: \(best.formatted(date: .long, time: .omitted))"
            } else {
                // Do NOT set a silent fallback date. Keep it nil so they know the scanner couldn't locate it.
                extractedDate = nil
                scanText = "Could not extract a valid date from document. Please choose manually."
            }
            withAnimation { scanComplete = true }

        } catch {
            isScanning = false
            scanText   = "OCR error: \(error.localizedDescription)"
        }
    }
}

// MARK: ─────────────────────────────────────────────────────────────────────
// MARK: - Vehicle Compliance Status Card
// MARK: ─────────────────────────────────────────────────────────────────────

struct VehicleComplianceStatusCard: View {
    let vehicleId: String
    @State private var store = ComplianceSettingsStore.shared

    private var s: ComplianceSettings { store.settings(for: vehicleId) }
    private var overall:   ComplianceStatus { store.overallStatus(for: vehicleId)   }
    private var insStatus: ComplianceStatus { store.insuranceStatus(for: vehicleId) }
    private var svcStatus: ComplianceStatus { store.serviceStatus(for: vehicleId)   }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(overall.color.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: overall.icon).font(.system(size: 18, weight: .bold)).foregroundStyle(overall.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compliance Status").font(.headline).foregroundStyle(Color.primary)
                    Text(overall.label).font(.subheadline.weight(.semibold)).foregroundStyle(overall.color)
                }
                Spacer()
                if overall == .nonCompliant {
                    Circle().fill(overall.color).frame(width: 10, height: 10)
                        .overlay(Circle().stroke(overall.color.opacity(0.4), lineWidth: 3).scaleEffect(1.6))
                }
            }
            .padding(16).background(overall.color.opacity(0.06))

            Divider()

            VStack(spacing: 0) {
                ExpiryRowView(icon: "shield.lefthalf.filled",      label: "Insurance", date: s.insuranceExpiry, status: insStatus, daysLeft: store.daysUntilExpiry(for: s.insuranceExpiry))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                Divider().padding(.horizontal, 16)
                ExpiryRowView(icon: "wrench.and.screwdriver.fill", label: "Service",   date: s.serviceExpiry,   status: svcStatus, daysLeft: store.daysUntilExpiry(for: s.serviceExpiry))
                    .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(overall.color.opacity(0.25), lineWidth: 1.2))
        .padding(.horizontal, 16)
    }
}
