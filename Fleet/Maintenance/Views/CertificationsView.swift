import SwiftUI

// MARK: - Certificate Model
struct Certificate: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var issuingBody: String
    var dateIssued: Date
    var expiryDate: Date?
    var certificateNumber: String

    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return expiry < Date()
    }

    var isExpiringSoon: Bool {
        guard let expiry = expiryDate else { return false }
        let thirtyDays = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expiry <= thirtyDays && expiry >= Date()
    }
}

// MARK: - Certifications View
struct CertificationsView: View {
    @State private var certificates: [Certificate] = []
    @State private var isShowingAddSheet = false

    var activeCount:  Int { certificates.filter { !$0.isExpired }.count }
    var expiredCount: Int { certificates.filter  {  $0.isExpired }.count }

    var body: some View {
        List {
            // ── KPI summary ──────────────────────────────────────────────
            Section {
                HStack(spacing: 0) {
                    certKpi("\(certificates.count)", "Total",   .brown)
                    Divider().frame(height: 36)
                    certKpi("\(activeCount)",         "Active",  .green)
                    Divider().frame(height: 36)
                    certKpi("\(expiredCount)",         "Expired", .red)
                }
                .padding(.vertical, 4)
            }

            // ── Certificate rows ─────────────────────────────────────────
            if certificates.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Certifications",
                        systemImage: "rosette",
                        description: Text("Tap + to add your professional certifications.")
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(certificates) { cert in
                        CertificateRow(certificate: cert)
                    }
                    .onDelete { indices in
                        certificates.remove(atOffsets: indices)
                        saveCertificates()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Certifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingAddSheet = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddCertificateSheet { newCert in
                certificates.append(newCert)
                saveCertificates()
            }
        }
        .onAppear { loadCertificates() }
    }

    // MARK: - KPI cell
    private func certKpi(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Persistence
    private func saveCertificates() {
        if let data = try? JSONEncoder().encode(certificates) {
            UserDefaults.standard.set(data, forKey: "maintenance_certificates")
        }
    }

    private func loadCertificates() {
        if let data = UserDefaults.standard.data(forKey: "maintenance_certificates"),
           let decoded = try? JSONDecoder().decode([Certificate].self, from: data) {
            certificates = decoded
        }
    }
}

// MARK: - Certificate Row (native list style)
private struct CertificateRow: View {
    let certificate: Certificate

    var statusColor: Color {
        if certificate.isExpired    { return .red }
        if certificate.isExpiringSoon { return .orange }
        return .green
    }

    var statusLabel: String {
        if certificate.isExpired      { return "Expired" }
        if certificate.isExpiringSoon { return "Expiring Soon" }
        return "Active"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "rosette")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(certificate.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(certificate.issuingBody)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label(certificate.dateIssued.formatted(date: .abbreviated, time: .omitted),
                          systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(Color(.tertiaryLabel))
                    if let expiry = certificate.expiryDate {
                        Label(expiry.formatted(date: .abbreviated, time: .omitted),
                              systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(statusColor)
                    }
                }
            }

            Spacer()

            StatusBadge(text: statusLabel, color: statusColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Certificate Sheet
private struct AddCertificateSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name              = ""
    @State private var issuingBody       = ""
    @State private var certificateNumber = ""
    @State private var dateIssued        = Date()
    @State private var hasExpiry         = false
    @State private var expiryDate        = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()

    let onSave: (Certificate) -> Void

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !issuingBody.trimmingCharacters(in: .whitespaces).isEmpty &&
        !certificateNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Certificate Details") {
                    TextField("Certificate Name", text: $name)
                    TextField("Issuing Body",     text: $issuingBody)
                    TextField("Certificate #",    text: $certificateNumber)
                }

                Section("Dates") {
                    DatePicker("Date Issued", selection: $dateIssued, displayedComponents: .date)
                        .tint(.brown)
                    Toggle("Has Expiry Date", isOn: $hasExpiry)
                        .tint(.brown)
                    if hasExpiry {
                        DatePicker("Expiry Date", selection: $expiryDate,
                                   in: dateIssued..., displayedComponents: .date)
                            .tint(.brown)
                            .transition(.opacity)
                    }
                }

                Section {
                    Button {
                        let cert = Certificate(
                            id: UUID(),
                            name: name.trimmingCharacters(in: .whitespaces),
                            issuingBody: issuingBody.trimmingCharacters(in: .whitespaces),
                            dateIssued: dateIssued,
                            expiryDate: hasExpiry ? expiryDate : nil,
                            certificateNumber: certificateNumber.trimmingCharacters(in: .whitespaces)
                        )
                        onSave(cert)
                        dismiss()
                    } label: {
                        Text("Save Certificate")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(.label))
                    .disabled(!isValid)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Add Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: hasExpiry)
        }
    }
}
