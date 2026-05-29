//
//  InsuranceUploadView.swift
//  Fleet
//
//  Created by Antigravity on 29/05/26.
//

import SwiftUI
import PhotosUI
import PDFKit
import UniformTypeIdentifiers
import Vision

struct InsuranceUploadView: View {
    @Environment(\.dismiss) private var dismiss
    
    let vehicle: Vehicle
    var onSaveSuccess: (() -> Void)? = nil
    
    // Step state
    @State private var currentStep: UploadStep = .chooseSource
    enum UploadStep: Int, Comparable {
        case chooseSource = 1
        case scanning = 2
        case review = 3
        case saving = 4
        
        static func < (lhs: UploadStep, rhs: UploadStep) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    // Selected File / Image
    @State private var selectedImage: UIImage?
    @State private var selectedFileName: String = ""
    @State private var selectedDocumentImages: [UIImage] = []
    @State private var selectedDocumentTextLines: [String] = []
    @State private var selectedUploadData: Data?
    @State private var selectedUploadFileExtension = "jpg"
    @State private var selectedUploadContentType = "image/jpeg"
    
    // OCR results and editing fields
    @State private var provider: String = ""
    @State private var policyNumber: String = ""
    @State private var policyHolder: String = ""
    @State private var vehicleReg: String = ""
    @State private var issueDate: Date = Date()
    @State private var hasIssueDate: Bool = false
    @State private var expiryDate: Date?
    @State private var expiryDateText: String?
    @State private var manualExpiryDateText = ""
    @State private var isManualExpiryEntry = false
    @State private var hasExpiryDate: Bool = false
    @State private var ocrStatus: InsuranceOCRStatus = .pending
    
    // UI states
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var isPhotosPickerPresented = false
    @State private var isFileImporterPresented = false
    @State private var isCameraPresented = false
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""
    @State private var laserOffset: CGFloat = -150
    @State private var saveProgress: Double = 0.0
    @State private var saveError: String? = nil
    @State private var scanStatusText = "Extracting text and searching for expiry date..."
    
    // Compliance Stores
    @State private var store = ComplianceSettingsStore.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Sleek dark-mode inspired gradient background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Step timeline indicator
                    stepTimelineView
                        .padding(.top, 10)
                    
                    // Main Step Content
                    VStack {
                        switch currentStep {
                        case .chooseSource:
                            chooseSourceView
                        case .scanning:
                            scanningView
                        case .review:
                            reviewFieldsView
                        case .saving:
                            savingView
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Upload Insurance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Group {
                        if currentStep == .chooseSource {
                            Button("Cancel") { dismiss() }
                        } else if currentStep == .review {
                            Button("Back") {
                                withAnimation { currentStep = .chooseSource }
                            }
                        }
                    }
                }
            }
            // Sheet presentations
            .sheet(isPresented: $isCameraPresented) {
                CameraPickerView(capturedImage: $selectedImage)
            }
            .photosPicker(isPresented: $isPhotosPickerPresented, selection: $photosPickerItem, matching: .images)
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            // Watch for photosPickerItem changes
            .onChange(of: photosPickerItem) { _, item in
                if let item {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            let contentType = item.supportedContentTypes.first
                            self.selectedUploadData = data
                            self.selectedUploadFileExtension = contentType?.preferredFilenameExtension ?? "jpg"
                            self.selectedUploadContentType = contentType?.preferredMIMEType ?? "image/jpeg"
                            self.selectedDocumentImages = [image]
                            self.selectedDocumentTextLines = []
                            withAnimation { self.currentStep = .scanning }
                            self.selectedImage = image
                            self.selectedFileName = "Photo Library Image"
                            startScanning()
                        }
                        photosPickerItem = nil
                    }
                }
            }
            // Watch for camera image capture
            .onChange(of: selectedImage) { _, image in
                if image != nil && currentStep == .chooseSource {
                    selectedDocumentImages = image.map { [$0] } ?? []
                    selectedDocumentTextLines = []
                    selectedUploadData = nil
                    selectedUploadFileExtension = "jpg"
                    selectedUploadContentType = "image/jpeg"
                    selectedFileName = "Captured Photo"
                    startScanning()
                }
            }
        }
    }
    
    // MARK: - Step Timeline View
    private var stepTimelineView: some View {
        HStack(spacing: 8) {
            ForEach(1...4, id: \.self) { step in
                let stepType = UploadStep(rawValue: step)!
                let isActive = currentStep == stepType
                let isCompleted = currentStep > stepType
                
                HStack(spacing: 8) {
                    // Circle indicator
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.green : (isActive ? Color.blue : Color.gray.opacity(0.3)))
                            .frame(width: 28, height: 28)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isActive || isCompleted ? .white : .secondary)
                        }
                    }
                    
                    if step < 4 {
                        // Connecting line
                        RoundedRectangle(cornerRadius: 1)
                            .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Step 1: Choose Source
    private var chooseSourceView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Large visual icon/graphic
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .padding(.bottom, 10)
            
            VStack(spacing: 8) {
                Text("Scan Insurance Policy")
                    .font(.title2.weight(.bold))
                Text("Select a document to automatically extract dates, policy numbers, and provider details.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                // Camera Button
                Button {
                    isCameraPresented = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take a Photo")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // Photo Library Button
                Button {
                    photosPickerItem = nil
                    isPhotosPickerPresented = true
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Choose from Photos")
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(uiColor: .separator), lineWidth: 1)
                    )
                }
                
                // PDF / File Button
                Button {
                    isFileImporterPresented = true
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("Upload PDF, JPG, PNG, or HEIC")
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(uiColor: .separator), lineWidth: 1)
                    )
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Step 2: Scanning View
    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if let image = selectedImage {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                        )
                        .clipped()
                    
                    // Laser scanner animation
                    Rectangle()
                        .fill(LinearGradient(colors: [Color.blue.opacity(0), Color.blue.opacity(0.8), Color.blue.opacity(0)], startPoint: .top, endPoint: .bottom))
                        .frame(height: 30)
                        .offset(y: laserOffset)
                        .blendMode(.screen)
                        .onAppear {
                            withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                                laserOffset = 150
                            }
                        }
                }
                .frame(height: 300)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
            }
            
            VStack(spacing: 8) {
                Text("Analyzing Policy Document...")
                    .font(.headline)
                Text(selectedFileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(scanStatusText)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Step 3: Review Fields View
    private var reviewFieldsView: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Status Info
                    HStack {
                        Image(systemName: ocrStatus == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(ocrStatus == .success ? .green : .orange)
                        VStack(alignment: .leading) {
                            Text(ocrStatus.displayLabel)
                                .font(.subheadline.weight(.bold))
                            Text(ocrStatus == .success ? "Review and adjust any fields before saving." : "Some fields could not be parsed automatically. Please fill them in.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(ocrStatus == .success ? Color.green.opacity(0.08) : Color.orange.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(ocrStatus == .success ? Color.green.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Warnings for undetected values
                    if expiryDate == nil {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Expiry Date Not Found. Enter it manually from the uploaded document before saving.")
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Field Card Section
                    VStack(spacing: 14) {
                        // Provider
                        fieldInputRow(
                            label: "Insurance Provider",
                            icon: "building.2.fill",
                            placeholder: "e.g. Progressive",
                            text: $provider,
                            isValid: !provider.isEmpty
                        )
                        
                        // Policy Number
                        fieldInputRow(
                            label: "Policy Number",
                            icon: "number",
                            placeholder: "e.g. POL-123456",
                            text: $policyNumber,
                            isValid: !policyNumber.isEmpty
                        )
                        
                        // Policy Holder
                        fieldInputRow(
                            label: "Policy Holder Name",
                            icon: "person.fill",
                            placeholder: "e.g. John Doe",
                            text: $policyHolder,
                            isValid: !policyHolder.isEmpty
                        )
                        
                        // Vehicle Reg
                        fieldInputRow(
                            label: "Vehicle Registration",
                            icon: "car.fill",
                            placeholder: "e.g. ABC 123",
                            text: $vehicleReg,
                            isValid: !vehicleReg.isEmpty
                        )
                        
                        Divider()
                        
                        // Issue Date (with optional toggle)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Issue Date", systemImage: "calendar")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Toggle("", isOn: $hasIssueDate)
                                    .labelsHidden()
                            }
                            if hasIssueDate {
                                DatePicker("", selection: $issueDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("Not Detected / Set")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        
                        // Expiry Date (REQUIRED)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Expiry Date", systemImage: "calendar.badge.exclamationmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(expiryDate == nil ? .red : .secondary)
                                Spacer()
                                if expiryDate == nil {
                                    Text("Not Found")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red)
                                        .cornerRadius(4)
                                }
                            }
                            if let expiryDate {
                                VStack(alignment: .leading, spacing: 6) {
                                    if let expiryDateText, !isManualExpiryEntry {
                                        Text(expiryDateText)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.primary)
                                    }
                                    DatePicker("", selection: expiryDateBinding(defaultDate: expiryDate), displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Expiry Date Not Found")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    TextField("Enter expiry date (DD/MM/YYYY)", text: $manualExpiryDateText)
                                        .keyboardType(.numbersAndPunctuation)
                                        .textFieldStyle(.roundedBorder)

                                    Button {
                                        applyManualExpiryDate()
                                    } label: {
                                        Label("Use Entered Date", systemImage: "calendar.badge.plus")
                                            .font(.caption.weight(.bold))
                                    }
                                    .disabled(manualExpiryDateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(expiryDate != nil ? Color(uiColor: .secondarySystemGroupedBackground) : Color.red.opacity(0.05))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(expiryDate == nil ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                }
                .padding(.vertical)
            }
            
            // Bottom Action buttons
            VStack(spacing: 10) {
                if showValidationError {
                    Text(validationErrorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
                
                Button {
                    saveDocument()
                } label: {
                    Text("Save & Upload Policy")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Step 4: Saving View
    private var savingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if let error = saveError {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Save Failed")
                    .font(.title3.weight(.bold))
                
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Button("Try Again") {
                    withAnimation { currentStep = .review }
                }
                .padding(.top)
            } else if saveProgress >= 1.0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, value: saveProgress)
                
                Text("Upload Successful!")
                    .font(.title2.weight(.bold))
                Text("Policy details stored and notification alerts scheduled.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            } else {
                VStack(spacing: 16) {
                    ProgressView(value: saveProgress)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                        .frame(width: 200)
                    
                    Text("Uploading document...")
                        .font(.headline)
                    
                    Text(saveProgress < 0.5 ? "Uploading file to storage..." : "Saving database records...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper field view
    private func fieldInputRow(label: String, icon: String, placeholder: String, text: Binding<String>, isValid: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                Spacer()
                if !isValid {
                    Text("Missing")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(.vertical, 6)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    // MARK: - Logic

    private func resetExtractedPolicyFieldsForNewScan() {
        provider = ""
        policyNumber = ""
        policyHolder = ""
        vehicleReg = ""
        issueDate = Date()
        hasIssueDate = false
        expiryDate = nil
        expiryDateText = nil
        manualExpiryDateText = ""
        isManualExpiryEntry = false
        hasExpiryDate = false
        ocrStatus = .pending
        showValidationError = false
        validationErrorMessage = ""
        scanStatusText = "Extracting text and searching for expiry date..."
    }

    private func expiryDateBinding(defaultDate: Date) -> Binding<Date> {
        Binding(
            get: { expiryDate ?? defaultDate },
            set: { newValue in
                expiryDate = newValue
                expiryDateText = nil
                hasExpiryDate = true
                isManualExpiryEntry = true
            }
        )
    }

    private func applyManualExpiryDate() {
        guard let date = parseManualExpiryDate(manualExpiryDateText) else {
            withAnimation {
                showValidationError = true
                validationErrorMessage = "Enter the expiry date as DD/MM/YYYY, DD-MM-YYYY, or YYYY-MM-DD."
            }
            return
        }

        expiryDate = date
        expiryDateText = manualExpiryDateText.trimmingCharacters(in: .whitespacesAndNewlines)
        hasExpiryDate = true
        isManualExpiryEntry = true
        showValidationError = false
    }

    private func parseManualExpiryDate(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let formats = [
            "dd/MM/yyyy", "d/M/yyyy", "dd-MM-yyyy", "d-M-yyyy",
            "dd.MM.yyyy", "d.M.yyyy", "yyyy-MM-dd", "yyyy/MM/dd"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.isLenient = false

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            self.selectedFileName = url.lastPathComponent

            guard url.startAccessingSecurityScopedResource() else {
                alert(errorMsg: "Could not access selected file.")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url) else {
                alert(errorMsg: "Could not read selected file.")
                return
            }

            let ext = url.pathExtension.lowercased()
            selectedUploadData = data
            selectedUploadFileExtension = ext.isEmpty ? "dat" : ext
            selectedUploadContentType = mimeType(forFileExtension: selectedUploadFileExtension)

            if ext == "pdf" {
                guard let document = PDFDocument(data: data) else {
                    alert(errorMsg: "Could not read PDF file.")
                    return
                }

                let images = rasterizePDFPages(from: document)
                let textLines = extractTextLines(from: document)
                guard !images.isEmpty || !textLines.isEmpty else {
                    alert(errorMsg: "Could not read text or pages from the selected PDF.")
                    return
                }

                selectedDocumentImages = images
                selectedDocumentTextLines = textLines
                withAnimation { currentStep = .scanning }
                selectedImage = images.first
                startScanning()
            } else if let image = UIImage(data: data) {
                selectedDocumentImages = [image]
                selectedDocumentTextLines = []
                withAnimation { currentStep = .scanning }
                selectedImage = image
                startScanning()
            } else {
                alert(errorMsg: "Could not load selected image.")
            }
        case .failure(let error):
            alert(errorMsg: error.localizedDescription)
        }
    }

    private func extractTextLines(from document: PDFDocument) -> [String] {
        document.string?
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []
    }

    private func rasterizePDFPages(from document: PDFDocument) -> [UIImage] {
        var images: [UIImage] = []
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            images.append(image)
        }
        return images
    }

    private func mimeType(forFileExtension fileExtension: String) -> String {
        UTType(filenameExtension: fileExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
    
    private func alert(errorMsg: String) {
        validationErrorMessage = errorMsg
        showValidationError = true
    }
    
    private func startScanning() {
        resetExtractedPolicyFieldsForNewScan()
        withAnimation { currentStep = .scanning }
        
        Task {
            let images = selectedDocumentImages
            let seedLines = selectedDocumentTextLines
            guard !images.isEmpty || !seedLines.isEmpty else {
                withAnimation { currentStep = .chooseSource }
                return
            }
            
            let result = await runOCR(on: images, seedLines: seedLines)
            
            // Populate fields
            self.provider = result.insuranceProvider ?? ""
            self.policyNumber = result.policyNumber ?? ""
            self.policyHolder = result.policyHolderName ?? ""
            self.vehicleReg = result.vehicleRegistration ?? ""
            
            if let issue = result.issueDate {
                self.issueDate = issue
                self.hasIssueDate = true
            } else {
                self.hasIssueDate = false
            }
            
            self.expiryDate = result.expiryDate
            self.expiryDateText = result.expiryDateText
            self.hasExpiryDate = result.expiryDate != nil
            self.isManualExpiryEntry = false
            
            self.ocrStatus = result.ocrStatus
            self.scanStatusText = result.expiryDateText.map { "Expiry date found: \($0)" }
                ?? "Expiry date not found. Review the document and enter it manually."
            
            withAnimation { currentStep = .review }
        }
    }
    
    private func runOCR(on images: [UIImage], seedLines: [String] = []) async -> InsuranceOCRResult {
        var rawLines = seedLines
        if !seedLines.isEmpty {
            await updateScanStatus("Reading embedded document text...")
            let seededResult = InsuranceOCREngine.parse(lines: rawLines)
            if let expiryDateText = seededResult.expiryDateText {
                await updateScanStatus("Expiry date found: \(expiryDateText)")
            }
        }

        for (index, image) in images.enumerated() {
            await updateScanStatus("Scanning page \(index + 1) of \(max(images.count, 1))...")
            rawLines.append(contentsOf: await recognizedTextLines(on: image))

            let partialResult = InsuranceOCREngine.parse(lines: rawLines)
            if let expiryDateText = partialResult.expiryDateText {
                await updateScanStatus("Expiry date found: \(expiryDateText)")
            } else {
                await updateScanStatus("Searching page \(index + 1) for expiry date...")
            }
        }

        await updateScanStatus("Preparing detected policy details...")
        return InsuranceOCREngine.parse(lines: rawLines)
    }

    private func updateScanStatus(_ message: String) async {
        await MainActor.run {
            scanStatusText = message
        }
    }

    private func recognizedTextLines(on image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                let req     = VNRecognizeTextRequest()
                req.recognitionLevel       = .accurate
                req.usesLanguageCorrection = false
                req.recognitionLanguages   = ["en-US"]
                do {
                    try handler.perform([req])
                    let lines = req.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
                    cont.resume(returning: lines)
                } catch {
                    cont.resume(returning: [])
                }
            }
        }
    }
    
    private func saveDocument() {
        // Validation
        if expiryDate == nil {
            withAnimation {
                showValidationError = true
                validationErrorMessage = "Please enter a valid expiry date."
            }
            return
        }
        
        showValidationError = false
        withAnimation {
            currentStep = .saving
            saveProgress = 0.1
        }
        
        Task {
            do {
                // Step A: Upload file to storage (if available)
                var fileUrl: String? = nil
                let documentId = UUID()
                withAnimation { saveProgress = 0.3 }
                if let data = selectedUploadData {
                    fileUrl = await InsuranceDocumentService.uploadFile(
                        data: data,
                        vehicleId: vehicle.id,
                        documentId: documentId,
                        fileExtension: selectedUploadFileExtension,
                        contentType: selectedUploadContentType
                    )
                } else if let img = selectedImage {
                    fileUrl = await InsuranceDocumentService.uploadFile(
                        image: img,
                        vehicleId: vehicle.id,
                        documentId: documentId
                    )
                }
                
                withAnimation { saveProgress = 0.6 }
                
                // Step B: Save document details
                let ocrResult = InsuranceOCRResult(
                    insuranceProvider: provider.isEmpty ? nil : provider,
                    policyNumber: policyNumber.isEmpty ? nil : policyNumber,
                    policyHolderName: policyHolder.isEmpty ? nil : policyHolder,
                    vehicleRegistration: vehicleReg.isEmpty ? nil : vehicleReg,
                    issueDate: hasIssueDate ? issueDate : nil,
                    expiryDate: expiryDate,
                    ocrStatus: provider.isEmpty || policyNumber.isEmpty ? .partial : .success
                )
                
                _ = try await InsuranceDocumentService.createDocument(
                    vehicleId: vehicle.id,
                    ocrResult: ocrResult,
                    fileUrl: fileUrl,
                    documentId: documentId
                )
                
                withAnimation { saveProgress = 0.8 }
                
                // Step C: Update local compliance settings
                let plateOrUuid = vehicle.licensePlate ?? vehicle.id.uuidString
                var currentSettings = store.settings(for: plateOrUuid)
                currentSettings.insuranceExpiry = expiryDate
                store.upsert(currentSettings)
                
                // Step D: Trigger notifications and monitors
                // Admin ID / current user ID fallback
                let defaultUserId = vehicle.adminId ?? UUID()
                await InsuranceMonitorService.shared.forceCheck(vehicles: [vehicle], userId: defaultUserId)
                
                withAnimation {
                    saveProgress = 1.0
                }
                
                // Dimiss view after successful presentation
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                onSaveSuccess?()
                dismiss()
                
            } catch {
                withAnimation {
                    saveError = error.localizedDescription
                }
            }
        }
    }
}
