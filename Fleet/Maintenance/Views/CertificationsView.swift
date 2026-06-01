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
    @State private var selectedCertificate: Certificate? = nil

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Summary Strip
                    HStack(spacing: 12) {
                        CertStatPill(
                            value: "\(certificates.count)",
                            label: "Total",
                            color: Color.brown
                        )
                        CertStatPill(
                            value: "\(certificates.filter { !$0.isExpired }.count)",
                            label: "Active",
                            color: Color.green
                        )
                        CertStatPill(
                            value: "\(certificates.filter { $0.isExpired }.count)",
                            label: "Expired",
                            color: Color.red
                        )
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Certificates List
                    if certificates.isEmpty {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.brown.opacity(0.06))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "rosette")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundStyle(Color.brown.opacity(0.5))
                                    .symbolEffect(.pulse)
                            }
                            VStack(spacing: 6) {
                                Text("No certificates yet")
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                                Text("Tap + to add your professional certifications.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(certificates) { cert in
                                CertificateCard(certificate: cert)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation(.spring(response: 0.35)) {
                                                certificates.removeAll { $0.id == cert.id }
                                                saveCertificates()
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Certifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isShowingAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddCertificateSheet { newCert in
                withAnimation(.spring(response: 0.35)) {
                    certificates.append(newCert)
                    saveCertificates()
                }
            }
        }
        .onAppear {
            loadCertificates()
        }
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

// MARK: - Certificate Card
private struct CertificateCard: View {
    let certificate: Certificate

    var statusColor: Color {
        if certificate.isExpired { return .red }
        if certificate.isExpiringSoon { return .orange }
        return .green
    }

    var statusLabel: String {
        if certificate.isExpired { return "Expired" }
        if certificate.isExpiringSoon { return "Expiring Soon" }
        return "Active"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(statusColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: "rosette")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(statusColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(certificate.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    Text(certificate.issuingBody)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                Spacer(minLength: 0)

                Text(statusLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor, in: Capsule())
            }

            Divider().background(Color(.separator))

            HStack(spacing: 16) {
                CertInfoPill(icon: "number", text: certificate.certificateNumber)
                CertInfoPill(icon: "calendar", text: certificate.dateIssued.formatted(date: .abbreviated, time: .omitted))
                if let expiry = certificate.expiryDate {
                    CertInfoPill(icon: "clock.badge.exclamationmark", text: expiry.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    certificate.isExpired ? Color.red.opacity(0.25) : Color(.separator).opacity(0.2),
                    lineWidth: certificate.isExpired ? 1.0 : 0.5
                )
        )
    }
}

// MARK: - Cert Info Pill
private struct CertInfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(Color.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemFill))
        .clipShape(Capsule())
    }
}

// MARK: - Cert Stat Pill
private struct CertStatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 0.8)
        )
    }
}

// MARK: - Add Certificate Sheet
private struct AddCertificateSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var issuingBody = ""
    @State private var certificateNumber = ""
    @State private var dateIssued = Date()
    @State private var hasExpiry = false
    @State private var expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()

    let onSave: (Certificate) -> Void

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !issuingBody.trimmingCharacters(in: .whitespaces).isEmpty &&
        !certificateNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Header Icon
                        ZStack {
                            Circle()
                                .fill(Color.brown.opacity(0.08))
                                .frame(width: 80, height: 80)
                            Image(systemName: "rosette")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(Color.brown)
                        }
                        .padding(.top, 8)

                        // Form Fields
                        VStack(spacing: 16) {
                            CertTextField(label: "Certificate Name", placeholder: "e.g. ASE Certification", text: $name)
                            CertTextField(label: "Issuing Body", placeholder: "e.g. National Institute", text: $issuingBody)
                            CertTextField(label: "Certificate Number", placeholder: "e.g. ASE-2024-1234", text: $certificateNumber)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date Issued")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.secondary)
                                DatePicker("", selection: $dateIssued, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .tint(Color.brown)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Toggle(isOn: $hasExpiry) {
                                Text("Has Expiry Date")
                                    .font(.subheadline.weight(.medium))
                            }
                            .tint(Color.brown)

                            if hasExpiry {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Expiry Date")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.secondary)
                                    DatePicker("", selection: $expiryDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .tint(Color.brown)
                                        .labelsHidden()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 16)

                        // Save Button
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
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Certificate")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                isValid ? Color.brown : Color.brown.opacity(0.4),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                        }
                        .disabled(!isValid)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Add Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.brown)
                }
            }
        }
    }
}

// MARK: - CertTextField
private struct CertTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            TextField(placeholder, text: $text)
                .font(.body)
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
