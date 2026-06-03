//
//  VoiceIncidentReviewSheet.swift
//  Fleet
//
//  Shown when NLP detects a delay / breakdown / other from the driver's voice.
//  Driver reviews what was understood, then taps "Send Alert" to notify fleet.
//  Uses native iOS sheet styling — no custom backgrounds or glassmorphism.
//

import SwiftUI

struct VoiceIncidentReviewSheet: View {

    @Bindable var viewModel: VoiceTripLogViewModel
    let tripId: UUID
    let driverId: UUID?
    let routeName: String

    @Environment(\.dismiss) private var dismiss

    private var data: VoiceExtractedData? { viewModel.pendingData }
    private var incidentType: TripIncidentType {
        data?.status?.incidentType ?? .other
    }

    var body: some View {
        NavigationStack {
            Form {
                // ── What we heard ──────────────────────────────────
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("What you said", systemImage: "mic.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text("\"\(data?.rawTranscription ?? "")\"")
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }

                // ── Detected Details ───────────────────────────────
                Section(header: Text("Detected Details")) {
                    Label(incidentType.rawValue, systemImage: incidentType.icon)
                        .font(.body)
                        .foregroundStyle(incidentColor)

                    if let location = data?.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.body)
                    }

                    if let eta = data?.etaText {
                        Label("Delay: \(eta)", systemImage: "clock")
                            .font(.body)
                    }
                }

                // ── Alert info ─────────────────────────────────────
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.orange)
                        Text("This will alert the fleet manager immediately and appear on their dashboard.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // ── Error ──────────────────────────────────────────
                if let error = viewModel.saveError {
                    Section {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                // ── Actions ────────────────────────────────────────
                Section {
                    Button {
                        Task { await viewModel.confirmIncident(tripId: tripId, driverId: driverId, routeName: routeName) }
                    } label: {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.85)
                                    .padding(.trailing, 4)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                            }
                            Text(viewModel.isSaving ? "Sending Alert…" : "Send Alert to Fleet Manager")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(incidentColor)
                    .disabled(viewModel.isSaving)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Button(role: .cancel) {
                        viewModel.discardPending()
                        dismiss()
                    } label: {
                        Text("Re-Record")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isSaving)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                .listSectionSpacing(0)
            }
            .navigationTitle("Voice Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        viewModel.discardPending()
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .interactiveDismissDisabled(viewModel.isSaving)
            .onChange(of: viewModel.showIncidentSheet) { _, isShown in
                if !isShown { dismiss() }
            }
        }
    }

    private var incidentColor: Color {
        switch incidentType {
        case .breakdown: return .red
        case .traffic:   return .orange
        default:         return .orange
        }
    }
}
