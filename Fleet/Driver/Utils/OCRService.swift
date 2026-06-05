import Foundation
import UIKit
import Vision

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    func extractFuelData(from image: UIImage) async -> (volume: Double?, price: Double?, date: Date?) {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: (nil, nil, nil))
                    return
                }
                
                let extractedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                print("[OCRService] Extracted lines: \(extractedStrings)")
                
                let (volume, price, date) = self.parseExtractedText(extractedStrings)
                continuation.resume(returning: (volume, price, date))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler: VNImageRequestHandler
            if let cgImage = image.cgImage {
                handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            } else if let ciImage = image.ciImage {
                handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            } else {
                continuation.resume(returning: (nil, nil, nil))
                return
            }
            
            do {
                try handler.perform([request])
            } catch {
                print("[OCRService] Failed to perform OCR: \(error)")
                continuation.resume(returning: (nil, nil, nil))
            }
        }
    }
    
    private func parseExtractedText(_ lines: [String]) -> (Double?, Double?, Date?) {
        var foundVolume: Double?
        var foundPrice: Double?
        var foundDate: Date?
        
        let volumePattern = "(?i)(\\d+(\\.\\d+)?)\\s*(l|ltr|liters|litre|litres|gal|gallons)\\b"
        let pricePattern = "(?i)(rs|inr|total|amount|amt|₹|\\$)\\s*[:\\-]?\\s*(\\d+(\\.\\d+)?)"
        
        // Setup Date detector
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        
        for line in lines {
            // Check for date if not found yet
            if foundDate == nil, let match = detector?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) {
                if let date = match.date {
                    foundDate = date
                }
            }
            
            // Check for volume
            if foundVolume == nil, let volumeMatch = extractNumber(from: line, using: volumePattern, groupIndex: 1) {
                foundVolume = volumeMatch
            }
            
            // Check for price explicitly
            if foundPrice == nil, let priceMatch = extractNumber(from: line, using: pricePattern, groupIndex: 2) {
                foundPrice = priceMatch
            }
        }
        
        // Fallback 1: If price is missing, look for a decimal number at the end of a line containing volume units (e.g. "PETROL 1.00 LTR 87.88")
        if foundPrice == nil {
            let trailingPricePattern = "(?i)(?:l|ltr|liters|litre|litres|gal|gallons)\\b.*?\\s*(\\d+(\\.\\d{1,2})?)\\s*$"
            for line in lines {
                if let priceMatch = extractNumber(from: line, using: trailingPricePattern, groupIndex: 1) {
                    // Make sure the trailing number isn't just the volume again (e.g. if the line is just "1.00 LTR")
                    if priceMatch != foundVolume {
                        foundPrice = priceMatch
                        break
                    }
                }
            }
        }
        
        // Fallback 2: Look for an `@` rate (e.g., "@ ₹ 87.88") which is common on Indian fuel receipts
        if foundPrice == nil {
            let ratePattern = "(?i)@\\s*[^\\d]*?(\\d+(\\.\\d{1,2})?)"
            for line in lines {
                if let priceMatch = extractNumber(from: line, using: ratePattern, groupIndex: 1) {
                    foundPrice = priceMatch
                    break
                }
            }
        }
        
        // Fallback 3: Just find any valid decimal number that looks like a price (has exactly two decimal places)
        if foundPrice == nil {
            var possiblePrices: [Double] = []
            let genericPricePattern = "\\b(\\d+\\.\\d{2})\\b"
            for line in lines {
                if let priceMatch = extractNumber(from: line, using: genericPricePattern, groupIndex: 1) {
                    if priceMatch != foundVolume {
                        possiblePrices.append(priceMatch)
                    }
                }
            }
            // Assume the largest 2-decimal number is the total price
            foundPrice = possiblePrices.max()
        }
        
        return (foundVolume, foundPrice, foundDate)
    }
    
    private func extractNumber(from text: String, using pattern: String, groupIndex: Int) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: nsRange) {
            if let range = Range(match.range(at: groupIndex), in: text) {
                let numberString = String(text[range])
                return Double(numberString)
            }
        }
        return nil
    }
}
