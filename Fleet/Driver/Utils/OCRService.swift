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
        
        let volumePattern = "(?i)(\\d+(\\.\\d+)?)\\s*(l|ltr|liters|litre|litres)\\b"
        let pricePattern = "(?i)(rs|inr|total|₹)\\s*[:\\-]?\\s*(\\d+(\\.\\d+)?)"
        
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
        
        // If price wasn't found, try matching 'amount' or 'amt'
        if foundPrice == nil {
            let amountPattern = "(?i)(amount|amt)\\s*[:\\-]?\\s*(\\d+(\\.\\d+)?)"
            for line in lines {
                if let priceMatch = extractNumber(from: line, using: amountPattern, groupIndex: 2) {
                    foundPrice = priceMatch
                    break
                }
            }
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
