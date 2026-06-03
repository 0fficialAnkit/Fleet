//
//  VoiceTripLogViewModel.swift
//  Fleet
//
//  Orchestrates the full voice → extract → review → save flow.
//  After extraction, routes to either:
//    • VoiceIncidentReviewSheet  — when NLP detects a delay / breakdown / other
//    • VoiceLogReviewSheet       — for factual updates (en route, arrived, mileage, ETA)
//

import SwiftUI
import CoreLocation
import UserNotifications

@MainActor
@Observable
final class VoiceTripLogViewModel {

    // MARK: - Persisted State

    /// Voice logs for the current trip (newest first).
    var voiceLogs: [VoiceTripLog] = []

    // MARK: - Recording / Extraction State

    var pendingData: VoiceExtractedData? = nil
    var isProcessing: Bool = false

    /// Shows the factual log review sheet (en route, mileage, ETA, arrived…).
    var showReviewSheet: Bool = false

    /// Shows the incident alert sheet (delayed, breakdown, other).
    var showIncidentSheet: Bool = false

    // MARK: - Save State

    var isSaving: Bool = false
    var saveError: String? = nil
    var justSaved: Bool = false

    // MARK: - Dependencies

    let voiceService = VoiceLogService()
    private let locationManager = LocationManager()

    // MARK: - Init

    init() {
        Task { await voiceService.requestPermissions() }
        locationManager.requestPermission()
    }

    // MARK: - Recording Control

    func startVoiceCapture() {
        voiceService.startRecording()
    }

    /// Stops recording, runs NLP extraction, then routes to the correct sheet.
    func stopAndExtract() {
        let transcript = voiceService.stopRecording()
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isProcessing = true

        Task.detached(priority: .userInitiated) {
            let extracted = VoiceExtractorService.extract(from: transcript)
            await MainActor.run {
                self.pendingData = extracted
                self.isProcessing = false

                // Route: incident types → incident sheet; factual updates → log sheet
                if let status = extracted.status, status.isIncident {
                    self.showIncidentSheet = true
                } else {
                    self.showReviewSheet = true
                }
            }
        }
    }

    // MARK: - Incident Confirmation

    /// Driver taps "Send Alert" in VoiceIncidentReviewSheet.
    /// Saves to trip_incidents (source='voice') + notifies fleet managers.
    func confirmIncident(tripId: UUID, driverId: UUID?, routeName: String) async {
        guard let data = pendingData else { return }

        isSaving = true
        saveError = nil

        // Resolve GPS location string
        var locationString = "Unknown Location"
        if let coord = locationManager.coordinate {
            locationString = "\(String(format: "%.5f", coord.latitude)), \(String(format: "%.5f", coord.longitude))"
        }
        if let place = data.location { locationString = place }

        let incidentTypeName = data.status?.incidentType?.rawValue ?? TripIncidentType.other.rawValue

        let incident = TripIncident(
            id: UUID(),
            tripId: tripId,
            driverId: driverId,
            incidentType: incidentTypeName,
            description: data.rawTranscription,
            location: locationString,
            photoUrl: nil,
            source: "voice",
            createdAt: Date()
        )

        do {
            // 1. Persist incident
            try await TripIncidentService.createIncident(incident)

            // 2. Send in-app notification to all fleet managers
            if let managers = try? await ProfileService.fetchProfilesByRole(role: "fleet_manager") {
                for manager in managers {
                    let notification = Notification(
                        id: UUID(),
                        userId: manager.id,
                        title: "🚨 Driver Alert — \(incidentTypeName)",
                        message: "\(routeName): \"\(data.rawTranscription)\"",
                        type: .alert,
                        isRead: false,
                        referenceId: tripId,
                        createdAt: Date()
                    )
                    try? await NotificationService.createNotification(notification)
                }
            }

            // 3. Local push notification (visible even if app is backgrounded)
            scheduleLocalPush(incidentType: incidentTypeName, transcript: data.rawTranscription)

            withAnimation {
                justSaved = true
            }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation { self.justSaved = false }
            }

        } catch {
            saveError = "Failed to send alert: \(error.localizedDescription)"
        }

        isSaving = false
        pendingData = nil
        showIncidentSheet = false
    }

    // MARK: - Voice Log Confirmation (factual update flow)

    func confirmSave(tripId: UUID, driverId: UUID?) async {
        guard let data = pendingData else { return }

        isSaving = true
        saveError = nil

        let log = VoiceTripLog(
            id: UUID(),
            tripId: tripId,
            driverId: driverId,
            transcription: data.rawTranscription,
            extractedLocation: data.location,
            extractedMileage: data.mileageKM,
            extractedETA: data.etaText,
            extractedStatus: data.status?.rawValue,
            createdAt: Date()
        )

        do {
            try await VoiceTripLogService.saveLog(log)
            if let mileage = data.mileageKM {
                try? await TripService.updateTripDistance(id: tripId, distance: mileage)
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                voiceLogs.insert(log, at: 0)
                justSaved = true
            }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation { self.justSaved = false }
            }
        } catch {
            saveError = "Failed to save: \(error.localizedDescription)"
        }

        isSaving = false
        pendingData = nil
        showReviewSheet = false
    }

    // MARK: - Discard

    func discardPending() {
        pendingData = nil
        showReviewSheet = false
        showIncidentSheet = false
    }

    // MARK: - Data Loading

    func loadLogs(tripId: UUID) async {
        do {
            voiceLogs = try await VoiceTripLogService.fetchLogs(forTripId: tripId)
        } catch {
            print("[VoiceTripLogViewModel] loadLogs ERROR: \(error)")
        }
    }

    // MARK: - Local Push Notification

    private func scheduleLocalPush(incidentType: String, transcript: String) {
        let content = UNMutableNotificationContent()
        content.title = "Driver Alert — \(incidentType)"
        content.body = transcript
        content.sound = .defaultCritical
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
