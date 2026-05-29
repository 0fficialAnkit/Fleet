//
//  InsuranceDocumentDetailSheet.swift
//  Fleet
//
//  Created by Antigravity on 29/05/26.
//

import SwiftUI

struct InsuranceDocumentDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let document: VehicleDocument
    let vehicle: Vehicle
    var onSave: () -> Void
    
    @State private var provider: String = ""
    @State private var policyNumber: String = ""
    @State private var holder: String = ""
    @State private var vehicleReg: String = ""
    @State private var issueDate: Date = Date()
    @State private var hasIssueDate: Bool = false
    @State private var expiryDate: Date?
    
    @State private var isSaving = false
    @State private var saveError: String? = nil
    
    init(document: VehicleDocument, vehicle: Vehicle, onSave: @escaping () -> Void) {
        self.document = document
        self.vehicle = vehicle
        self.onSave = onSave
        
        _provider = State(initialValue: document.insuranceProvider ?? "")
        _policyNumber = State(initialValue: document.policyNumber ?? "")
        _holder = State(initialValue: document.policyHolderName ?? "")
        _vehicleReg = State(initialValue: vehicle.licensePlate ?? "")
        
        if let issue = document.issueDate {
            _issueDate = State(initialValue: issue)
            _hasIssueDate = State(initialValue: true)
        } else {
            _hasIssueDate = State(initialValue: false)
        }
        
        _expiryDate = State(initialValue: document.expiryDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Document Preview") {
                    if let fileUrl = document.fileUrl, let url = URL(string: fileUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .frame(height: 150)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity)
                                    .shadow(radius: 2)
                            case .failure:
                                Link(destination: url) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(.blue)
                                        Text("Open Policy Attachment")
                                            .underline()
                                        Spacer()
                                        Image(systemName: "arrow.up.forward.app")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.secondary)
                            Text("No attachment file (offline/local only)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Policy Information") {
                    HStack {
                        Text("Provider")
                            .frame(width: 100, alignment: .leading)
                        TextField("e.g. Progressive", text: $provider)
                    }
                    HStack {
                        Text("Policy No")
                            .frame(width: 100, alignment: .leading)
                        TextField("e.g. POL-12345", text: $policyNumber)
                    }
                    HStack {
                        Text("Insured")
                            .frame(width: 100, alignment: .leading)
                        TextField("e.g. John Doe", text: $holder)
                    }
                    HStack {
                        Text("Reg No")
                            .frame(width: 100, alignment: .leading)
                        TextField("e.g. ABC-123", text: $vehicleReg)
                    }
                }
                
                Section("Dates") {
                    Toggle("Has Issue Date", isOn: $hasIssueDate)
                    if hasIssueDate {
                        DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                    }
                    if let expiryDate {
                        DatePicker("Expiry Date", selection: expiryDateBinding(defaultDate: expiryDate), displayedComponents: .date)
                    } else {
                        HStack {
                            Text("Expiry Date")
                            Spacer()
                            Text("Not Set")
                                .foregroundColor(.red)
                        }
                        Button {
                            expiryDate = Date()
                        } label: {
                            Label("Set Expiry Date", systemImage: "calendar.badge.plus")
                        }
                    }
                }
                
                if let saveError {
                    Section {
                        Text(saveError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Policy Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func expiryDateBinding(defaultDate: Date) -> Binding<Date> {
        Binding(
            get: { expiryDate ?? defaultDate },
            set: { expiryDate = $0 }
        )
    }
    
    private func saveChanges() {
        guard let expiryDate else {
            saveError = "Please set the policy expiry date before saving."
            return
        }

        isSaving = true
        saveError = nil
        
        Task {
            do {
                var updatedDoc = document
                updatedDoc.insuranceProvider = provider.isEmpty ? nil : provider
                updatedDoc.policyNumber = policyNumber.isEmpty ? nil : policyNumber
                updatedDoc.policyHolderName = holder.isEmpty ? nil : holder
                updatedDoc.issueDate = hasIssueDate ? issueDate : nil
                updatedDoc.expiryDate = expiryDate
                
                try await InsuranceDocumentService.updateDocument(updatedDoc)
                
                // Update local settings store
                let plateOrUuid = vehicle.licensePlate ?? vehicle.id.uuidString
                var settings = ComplianceSettingsStore.shared.settings(for: plateOrUuid)
                settings.insuranceExpiry = expiryDate
                ComplianceSettingsStore.shared.upsert(settings)
                
                // Refresh compliance notifications
                let defaultUserId = vehicle.adminId ?? UUID()
                await InsuranceMonitorService.shared.forceCheck(vehicles: [vehicle], userId: defaultUserId)
                
                onSave()
                dismiss()
            } catch {
                saveError = error.localizedDescription
                isSaving = false
            }
        }
    }
}
