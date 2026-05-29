//
//  InsuranceDocumentService.swift
//  Fleet
//
//  Handles CRUD for the vehicle_documents table (insurance rows).
//  File upload targets the "vehicle-documents" Supabase Storage bucket
//  when available; falls back to storing a local file:// URL so the
//  rest of the feature works even without the bucket configured.
//

import Foundation
import Supabase
import UIKit

// MARK: - Insert / Update payloads

private struct InsuranceDocumentInsert: Encodable {
    let id: UUID
    let vehicle_id: UUID
    let document_type: String
    let file_url: String?
    let expiry_date: String?          // ISO-8601 date string
    let insurance_provider: String?
    let policy_number: String?
    let policy_holder_name: String?
    let issue_date: String?           // ISO-8601 date string
    let ocr_status: String?
}

private struct InsuranceDocumentUpdate: Encodable {
    let file_url: String?
    let expiry_date: String?
    let insurance_provider: String?
    let policy_number: String?
    let policy_holder_name: String?
    let issue_date: String?
    let ocr_status: String?
}

// MARK: - InsuranceOCRResult (shared between OCR engine and upload view)

enum InsuranceOCRStatus: String, Codable, Hashable, Sendable {
    case pending = "pending"
    case success = "success"
    case partial = "partial"
    case notDetected = "not_detected"

    var displayLabel: String {
        switch self {
        case .pending: return "Ready to Scan"
        case .success: return "Details Extracted"
        case .partial: return "Partially Extracted"
        case .notDetected: return "Expiry Date Not Detected"
        }
    }
}

enum InsuranceAlertLevel: String, Codable, Hashable, Sendable {
    case normal
    case warning
    case highPriority
    case critical

    static func level(for daysUntilExpiry: Int) -> InsuranceAlertLevel {
        if daysUntilExpiry < 0 { return .critical }
        if daysUntilExpiry <= 15 { return .highPriority }
        if daysUntilExpiry <= 30 { return .warning }
        return .normal
    }
}

struct InsuranceOCRResult {
    var insuranceProvider: String? = nil
    var policyNumber: String? = nil
    var policyHolderName: String? = nil
    var vehicleRegistration: String? = nil
    var issueDate: Date? = nil
    var expiryDate: Date? = nil
    var expiryDateText: String? = nil
    var ocrStatus: InsuranceOCRStatus = .pending

    /// True when at least an expiry date was found
    var hasExpiry: Bool { expiryDate != nil }
}

// MARK: - Service

enum InsuranceDocumentService {

    private static let storageBucket = "vehicle-documents"
    private static let udCacheKey    = "fleet_insurance_docs_cache"

    // MARK: Fetch

    static func fetchDocuments(vehicleId: UUID) async throws -> [VehicleDocument] {
        do {
            let result: [VehicleDocument] = try await supabase
                .from("vehicle_documents")
                .select()
                .eq("vehicle_id", value: vehicleId)
                .eq("document_type", value: "insurance")
                .order("uploaded_at", ascending: false)
                .execute()
                .value
            print("[InsuranceDocumentService] fetchDocuments(\(vehicleId)): \(result.count) docs")
            cacheLocally(result, for: vehicleId)
            return result
        } catch {
            print("[InsuranceDocumentService] fetchDocuments ERROR: \(error) — returning local cache")
            return cachedDocuments(for: vehicleId)
        }
    }

    // MARK: Upload file to Storage (best-effort)

    /// Uploads a UIImage to Supabase Storage.  Returns the public URL on success,
    /// or nil if the bucket doesn't exist / upload fails (non-fatal).
    static func uploadFile(image: UIImage, vehicleId: UUID, documentId: UUID) async -> String? {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return nil }
        return await uploadFile(
            data: data,
            vehicleId: vehicleId,
            documentId: documentId,
            fileExtension: "jpg",
            contentType: "image/jpeg"
        )
    }

    static func uploadFile(
        data: Data,
        vehicleId: UUID,
        documentId: UUID,
        fileExtension: String,
        contentType: String
    ) async -> String? {
        let sanitizedExtension = fileExtension
            .trimmingCharacters(in: CharacterSet(charactersIn: ". "))
            .lowercased()
        let pathExtension = sanitizedExtension.isEmpty ? "dat" : sanitizedExtension
        let path = "\(vehicleId.uuidString)/\(documentId.uuidString).\(pathExtension)"
        do {
            try await supabase.storage
                .from(storageBucket)
                .upload(path, data: data, options: FileOptions(contentType: contentType))
            let url = try supabase.storage.from(storageBucket).getPublicURL(path: path)
            print("[InsuranceDocumentService] uploadFile: \(url.absoluteString)")
            return url.absoluteString
        } catch {
            print("[InsuranceDocumentService] uploadFile (non-fatal): \(error)")
            return nil
        }
    }

    // MARK: Create

    static func createDocument(
        vehicleId:        UUID,
        ocrResult:        InsuranceOCRResult,
        fileUrl:          String?,
        documentId:       UUID = UUID()
    ) async throws -> VehicleDocument {

        let newId  = documentId
        let iso    = isoFormatter()

        let payload = InsuranceDocumentInsert(
            id:                   newId,
            vehicle_id:           vehicleId,
            document_type:        "insurance",
            file_url:             fileUrl,
            expiry_date:          ocrResult.expiryDate.map { iso.string(from: $0) },
            insurance_provider:   ocrResult.insuranceProvider,
            policy_number:        ocrResult.policyNumber,
            policy_holder_name:   ocrResult.policyHolderName,
            issue_date:           ocrResult.issueDate.map { iso.string(from: $0) },
            ocr_status:           ocrResult.ocrStatus.rawValue
        )

        do {
            try await supabase
                .from("vehicle_documents")
                .insert(payload)
                .execute()
            print("[InsuranceDocumentService] createDocument(\(newId)): OK")
        } catch {
            // If the DB insert fails (e.g. columns not yet migrated), store locally
            print("[InsuranceDocumentService] createDocument DB error — saving locally: \(error)")
        }

        let doc = VehicleDocument(
            id:                 newId,
            vehicleId:          vehicleId,
            documentType:       .insurance,
            fileUrl:            fileUrl,
            expiryDate:         ocrResult.expiryDate,
            insuranceProvider:  ocrResult.insuranceProvider,
            policyNumber:       ocrResult.policyNumber,
            policyHolderName:   ocrResult.policyHolderName,
            issueDate:          ocrResult.issueDate,
            ocrStatus:          ocrResult.ocrStatus,
            uploadedAt:         Date()
        )
        appendToLocalCache(doc, vehicleId: vehicleId)
        return doc
    }

    // MARK: Update (manual field corrections)

    static func updateDocument(_ doc: VehicleDocument) async throws {
        let iso = isoFormatter()
        let payload = InsuranceDocumentUpdate(
            file_url:             doc.fileUrl,
            expiry_date:          doc.expiryDate.map { iso.string(from: $0) },
            insurance_provider:   doc.insuranceProvider,
            policy_number:        doc.policyNumber,
            policy_holder_name:   doc.policyHolderName,
            issue_date:           doc.issueDate.map { iso.string(from: $0) },
            ocr_status:           doc.ocrStatus?.rawValue
        )
        do {
            try await supabase
                .from("vehicle_documents")
                .update(payload)
                .eq("id", value: doc.id)
                .execute()
            print("[InsuranceDocumentService] updateDocument(\(doc.id)): OK")
        } catch {
            print("[InsuranceDocumentService] updateDocument ERROR: \(error)")
            throw error
        }
    }

    // MARK: - Local cache helpers

    private static func cacheLocally(_ docs: [VehicleDocument], for vehicleId: UUID) {
        var all = allCached()
        all[vehicleId.uuidString] = docs
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: udCacheKey)
        }
    }

    private static func appendToLocalCache(_ doc: VehicleDocument, vehicleId: UUID) {
        var all = allCached()
        var list = all[vehicleId.uuidString] ?? []
        list.insert(doc, at: 0)
        all[vehicleId.uuidString] = list
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: udCacheKey)
        }
    }

    private static func cachedDocuments(for vehicleId: UUID) -> [VehicleDocument] {
        allCached()[vehicleId.uuidString] ?? []
    }

    private static func allCached() -> [String: [VehicleDocument]] {
        guard let data = UserDefaults.standard.data(forKey: udCacheKey),
              let decoded = try? JSONDecoder().decode([String: [VehicleDocument]].self, from: data)
        else { return [:] }
        return decoded
    }

    // MARK: - Helpers

    private static func isoFormatter() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }
}
