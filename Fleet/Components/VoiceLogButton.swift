//
//  VoiceLogButton.swift
//  Fleet
//
//  Floating mic button shown during an active trip.
//  Tapping it starts/stops recording and triggers NLP extraction + review sheet.
//

import SwiftUI

struct VoiceLogButton: View {

    @Bindable var viewModel: VoiceTripLogViewModel
    let tripId: UUID
    let driverId: UUID?
    let routeName: String

    @State private var pulse1: Bool = false
    @State private var pulse2: Bool = false

    var body: some View {
        VStack(spacing: 0) {

            // Live transcript bubble while recording
            if viewModel.voiceService.isRecording && !viewModel.voiceService.liveTranscript.isEmpty {
                transcriptBubble
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Processing state (NLP running)
            if viewModel.isProcessing {
                processingPill
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Just saved confirmation
            if viewModel.justSaved {
                savedPill
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Permission denied warning
            if viewModel.voiceService.permissionDenied {
                permissionPill
                    .transition(.opacity)
            }

            Spacer().frame(height: 12)

            // The mic button
            ZStack {
                // Pulsing rings — only when recording
                if viewModel.voiceService.isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.35), lineWidth: 2)
                        .frame(width: pulse1 ? 90 : 64, height: pulse1 ? 90 : 64)
                        .opacity(pulse1 ? 0 : 0.8)
                        .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulse1)

                    Circle()
                        .stroke(Color.red.opacity(0.2), lineWidth: 2)
                        .frame(width: pulse2 ? 110 : 64, height: pulse2 ? 110 : 64)
                        .opacity(pulse2 ? 0 : 0.6)
                        .animation(.easeOut(duration: 1.2).delay(0.4).repeatForever(autoreverses: false), value: pulse2)
                }

                // Processing spinner ring
                if viewModel.isProcessing {
                    Circle()
                        .stroke(Color.green.opacity(0.4), lineWidth: 3)
                        .frame(width: 72, height: 72)
                }

                // Button fill
                Circle()
                    .fill(buttonColor)
                    .frame(width: 64, height: 64)
                    .shadow(color: buttonColor.opacity(0.45), radius: 12, y: 4)

                // Icon / spinner
                if viewModel.isProcessing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .onTapGesture { handleTap() }
            .disabled(viewModel.isProcessing)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.voiceService.isRecording)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.isProcessing)
        }
        .onChange(of: viewModel.voiceService.isRecording) { _, recording in
            pulse1 = recording
            pulse2 = recording
        }
    }

    // MARK: - Computed

    private var buttonIcon: String {
        viewModel.voiceService.isRecording ? "stop.fill" : "mic.fill"
    }

    private var buttonColor: Color {
        viewModel.isProcessing    ? Color.purple :
        viewModel.voiceService.isRecording ? Color.red    : Color.green
    }

    // MARK: - Subviews

    private var transcriptBubble: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 3, height: CGFloat.random(in: 8...18))
                    .animation(
                        .easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                        value: viewModel.voiceService.isRecording
                    )
            }
            Text(viewModel.voiceService.liveTranscript)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: 220, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.red.opacity(0.25), lineWidth: 1))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        .padding(.bottom, 10)
    }

    private var processingPill: some View {
        HStack(spacing: 6) {
            ProgressView().scaleEffect(0.7).tint(.white)
            Text("Analyzing voice…")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.purple))
        .shadow(color: Color.purple.opacity(0.3), radius: 6, y: 3)
        .padding(.bottom, 10)
    }

    private var savedPill: some View {
        let isIncidentAlert = viewModel.lastSavedWasIncident
        let label = isIncidentAlert ? "Alert sent to fleet!" : "Voice log saved"
        let icon  = isIncidentAlert ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
        let color = isIncidentAlert ? Color.orange : Color.green
        return HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.12)))
        .padding(.bottom, 8)
    }

    private var permissionPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "mic.slash.fill").foregroundStyle(.orange).font(.caption)
            Text("Enable mic & speech in Settings")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.orange.opacity(0.12)))
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    private func handleTap() {
        if viewModel.voiceService.isRecording {
            // Stop → NLP extract → auto-save/report
            viewModel.stopAndExtract(tripId: tripId, driverId: driverId, routeName: routeName)
        } else {
            viewModel.startVoiceCapture()
        }
    }
}
