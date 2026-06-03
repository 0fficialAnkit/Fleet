//
//  VoiceLogReviewSheet.swift
//  Fleet
//
//  Presents the NLP-extracted facts to the driver for confirmation
//  before saving to Supabase. Gives the driver full control.
//

import SwiftUI

struct VoiceLogReviewSheet: View {

    @Bindable var viewModel: VoiceTripLogViewModel
    let tripId: UUID
    let driverId: UUID?

    @Environment(\.dismiss) private var dismiss

    private var data: VoiceExtractedData? { viewModel.pendingData }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Transcript Card ────────────────────────────────
                        transcriptCard

                        // ── Extracted Facts ────────────────────────────────
                        if let data, !data.isEmpty {
                            extractedFactsCard(data: data)
                        } else {
                            noFactsCard
                        }

                        // ── Error ──────────────────────────────────────────
                        if let error = viewModel.saveError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                        }

                        // ── Action Buttons ─────────────────────────────────
                        actionButtons

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Review Voice Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        viewModel.discardPending()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .interactiveDismissDisabled(viewModel.isSaving)
        }
    }

    // MARK: - Transcript Card

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Your Recording", systemImage: "waveform")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(data?.rawTranscription ?? "")
                .font(.body)
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
        .padding(.horizontal)
    }

    // MARK: - Extracted Facts Card

    private func extractedFactsCard(data: VoiceExtractedData) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Detected Trip Data", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            // Note about distance update
            if data.mileageKM != nil {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.blue)
                        .font(.caption)
                    Text("Mileage will be recorded on the trip.")
                        .font(.caption)
                        .foregroundStyle(Color.blue)
                }
                .padding(10)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(spacing: 10) {
                if let location = data.location {
                    FactRow(
                        icon: "mappin.circle.fill",
                        label: "Location",
                        value: location,
                        accentColor: .teal
                    )
                }
                if let mileage = data.mileageKM {
                    FactRow(
                        icon: "gauge.with.needle.fill",
                        label: "Mileage Covered",
                        value: String(format: "%.1f km", mileage),
                        accentColor: .green
                    )
                }
                if let eta = data.etaText {
                    FactRow(
                        icon: "clock.fill",
                        label: "ETA",
                        value: eta,
                        accentColor: .orange
                    )
                }
                if let status = data.status {
                    FactRow(
                        icon: status.icon,
                        label: "Status",
                        value: status.displayName,
                        accentColor: statusColor(for: status)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - No Facts Card

    private var noFactsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.orange.opacity(0.7))

            VStack(spacing: 4) {
                Text("No Trip Data Detected")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primary)
                Text("Try saying your location, mileage (e.g. \"done 42 km\"), or status (e.g. \"arrived at destination\").")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Save button
            Button {
                Task { await viewModel.confirmSave(tripId: tripId, driverId: driverId) }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(viewModel.isSaving ? "Saving…" : "Save Log")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .shadow(color: Color.green.opacity(0.35), radius: 8, y: 4)
            .disabled(viewModel.isSaving)

            // Re-record button
            Button {
                viewModel.discardPending()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                    Text("Re-Record")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundStyle(Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
            }
            .disabled(viewModel.isSaving)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func statusColor(for status: VoiceLogStatus) -> Color {
        switch status {
        case .enRoute:   return .green
        case .delayed:   return .orange
        case .arrived:   return .teal
        case .pickedUp:  return .blue
        case .breakdown: return .red
        case .other:     return .gray
        }
    }
}

// MARK: - FactRow

struct FactRow: View {
    let icon: String
    let label: String
    let value: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(accentColor)
        }
        .padding(10)
        .background(accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
