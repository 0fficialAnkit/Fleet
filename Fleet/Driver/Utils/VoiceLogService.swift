//
//  VoiceLogService.swift
//  Fleet
//
//  Wraps SFSpeechRecognizer + AVAudioEngine to provide real-time
//  speech-to-text transcription for hands-free trip logging.
//

import Foundation
import Speech
import AVFoundation

/// Observable service that manages on-device speech recognition.
/// Lifecycle: requestPermissions() → startRecording() → stopRecording() → transcript
@MainActor
@Observable
final class VoiceLogService {

    // MARK: - Published State

    /// Whether the microphone is actively capturing audio.
    var isRecording: Bool = false

    /// Live transcript text updated in real-time while recording.
    var liveTranscript: String = ""

    /// Set to true if mic or speech recognition permission is denied.
    var permissionDenied: Bool = false

    /// Human-readable error message for the UI to display.
    var errorMessage: String? = nil

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer? = {
        // Use device locale, fall back to en-US
        return SFSpeechRecognizer(locale: Locale.current) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }()

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// Timer used to auto-stop after sustained silence.
    private var silenceTimer: Task<Void, Never>?
    /// How long (seconds) of silence before auto-stopping
    private let silenceTimeout: TimeInterval = 10

    // MARK: - Permission

    /// Requests microphone and speech recognition authorization.
    /// Call once during ViewModel init.
    func requestPermissions() async {
        // Speech recognition
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        // Microphone
        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        let allowed = (speechStatus == .authorized) && micGranted
        await MainActor.run {
            self.permissionDenied = !allowed
        }
    }

    // MARK: - Recording Control

    /// Starts live speech recognition. No-op if already recording or permission is denied.
    func startRecording() {
        guard !isRecording else { return }
        guard !permissionDenied else {
            errorMessage = "Microphone or speech recognition permission is not granted. Please enable it in Settings."
            return
        }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition is not available on this device right now."
            return
        }

        do {
            try beginAudioSession()
            try startEngine(recognizer: recognizer)
            isRecording = true
            liveTranscript = ""
            errorMessage = nil
            startSilenceTimer()
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
            cleanUp()
        }
    }

    /// Stops recording and returns the final transcribed string.
    @discardableResult
    func stopRecording() -> String {
        silenceTimer?.cancel()
        silenceTimer = nil

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        isRecording = false
        let finalText = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        return finalText
    }

    // MARK: - Private Helpers

    private func beginAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startEngine(recognizer: SFSpeechRecognizer) throws {
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // Use on-device recognition when available (iOS 13+, no internet needed)
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition

        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    self.liveTranscript = result.bestTranscription.formattedString
                    // Reset silence timer every time we get new speech
                    self.startSilenceTimer()
                }
            }
            if let error {
                // Ignore cancellation errors which happen on normal stop
                let nsError = error as NSError
                if nsError.code != 301 { // 301 = SFSpeechRecognizerErrorCode.canceled
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                        self.cleanUp()
                    }
                }
            }
        }
    }

    /// Resets the auto-stop silence timer. Called on each new speech result.
    private func startSilenceTimer() {
        silenceTimer?.cancel()
        silenceTimer = Task { [weak self] in
            guard let self else { return }
            let nanos = UInt64(self.silenceTimeout * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                // Only auto-stop if we actually captured something
                if self.isRecording {
                    _ = self.stopRecording()
                }
            }
        }
    }

    private func cleanUp() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
    }
}
