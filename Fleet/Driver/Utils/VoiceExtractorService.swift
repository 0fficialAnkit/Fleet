//
//  VoiceExtractorService.swift
//  Fleet
//
//  On-device NLP engine that extracts structured trip facts from a
//  raw speech transcript. No network calls — runs entirely locally.
//
//  Extracts:
//    • Location  — via NaturalLanguage Named Entity Recognition (.placeName)
//    • Mileage   — via regex (km / kilometers / miles)
//    • ETA       — via regex (N minutes/hours away / ETA N min)
//    • Status    — via keyword matching (delayed, arrived, picked up, …)
//

import Foundation
import NaturalLanguage

enum VoiceExtractorService {

    // MARK: - Public API

    /// Parse a transcript and return all detected trip facts.
    /// Runs synchronously; typical duration < 80 ms on modern iPhones.
    static func extract(from transcript: String) -> VoiceExtractedData {
        let lower = transcript.lowercased()
        return VoiceExtractedData(
            location:         extractLocation(from: transcript),
            mileageKM:        extractMileage(from: lower),
            etaText:          extractETA(from: lower),
            status:           extractStatus(from: lower),
            rawTranscription: transcript
        )
    }

    // MARK: - Location (Named Entity Recognition)

    private static func extractLocation(from text: String) -> String? {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        var locations: [String] = []
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation, .joinNames]
        ) { tag, tokenRange in
            if tag == .placeName {
                locations.append(String(text[tokenRange]))
            }
            return true
        }

        // Return the first detected place name
        return locations.first
    }

    // MARK: - Mileage (Regex)

    private static func extractMileage(from lower: String) -> Double? {
        // Match patterns like: "42 km", "42.5 km", "120 kilometers", "35 miles"
        // Optionally preceded by verbs: "done 42 km", "covered 120 km", "completed 35 km"
        let kmPattern  = #"(?:done|covered|completed|travelled|traveled|at)?\s*(\d+(?:\.\d+)?)\s*(?:km|kilometer(?:s)?)"#
        let miPattern  = #"(\d+(?:\.\d+)?)\s*(?:mile(?:s)?)"#

        if let value = firstCapture(pattern: kmPattern, in: lower).flatMap(Double.init) {
            return value
        }
        if let value = firstCapture(pattern: miPattern, in: lower).flatMap(Double.init) {
            return value * 1.60934   // convert miles → km
        }
        return nil
    }

    // MARK: - ETA (Regex)

    private static func extractETA(from lower: String) -> String? {
        // Patterns: "20 minutes away", "ETA 30 min", "arriving in 1 hour", "in 20 minutes"
        let minutePatterns = [
            #"eta\s*(?:is\s*)?(\d+)\s*(?:minutes?|mins?)"#,
            #"arriving\s+in\s+(\d+)\s*(?:minutes?|mins?)"#,
            #"(\d+)\s*(?:minutes?|mins?)\s*(?:away|left|more|to\s+go)"#,
            #"in\s+(\d+)\s*(?:minutes?|mins?)"#,
        ]
        let hourPatterns = [
            #"(\d+)\s*(?:hours?|hrs?)\s*(?:away|left|more|to\s+go)"#,
            #"arriving\s+in\s+(\d+)\s*(?:hours?|hrs?)"#,
        ]

        for pattern in minutePatterns {
            if let n = firstCapture(pattern: pattern, in: lower).flatMap(Int.init) {
                return "\(n) min\(n == 1 ? "" : "s")"
            }
        }
        for pattern in hourPatterns {
            if let n = firstCapture(pattern: pattern, in: lower).flatMap(Int.init) {
                return "\(n) hr\(n == 1 ? "" : "s")"
            }
        }
        return nil
    }

    // MARK: - Status (Keyword Matching)

    private static func extractStatus(from lower: String) -> VoiceLogStatus? {
        // Ordered from most specific to least specific
        let rules: [(keywords: [String], status: VoiceLogStatus)] = [
            (["breakdown", "broke down", "puncture", "flat tyre", "flat tire",
              "engine failure", "engine fail", "accident", "crash"], .breakdown),
            (["delay", "delayed", "stuck in traffic", "heavy traffic", "traffic jam",
              "slow traffic", "behind schedule", "running late"], .delayed),
            (["arrived", "reached destination", "reached the destination", "delivered",
              "delivery done", "delivery complete", "dropped off", "reached"], .arrived),
            (["picked up", "pickup done", "pickup complete", "collected",
              "loaded the goods", "package collected", "parcel collected"], .pickedUp),
            (["en route", "on the way", "heading to", "heading towards",
              "driving to", "in transit", "on my way", "moving"], .enRoute),
        ]

        for rule in rules {
            for keyword in rule.keywords where lower.contains(keyword) {
                return rule.status
            }
        }
        return nil
    }

    // MARK: - Regex Helper

    private static func firstCapture(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text)
        else { return nil }
        return String(text[range])
    }
}
