//
//  InsuranceOCREngine.swift
//  Fleet
//
//  A robust, keyword-based parser that processes raw text blocks extracted by Vision OCR
//  to extract insurance provider, policy number, vehicle registration, policy holder,
//  issue date, and expiry date.
//
//  Improvements over v1:
//  - Extended look-ahead window (1 → 5 lines) so table cell pairs are found even when
//    Vision OCR emits label and value as separate, non-adjacent observations.
//  - Global fallback: if no keyword-proximate date is found, picks the latest future date
//    present anywhere in the document (almost always the expiry date).
//  - OCR-corruption pre-processing: strips leading ■/▪/• characters, replaces pipe `|`
//    with `/`, normalises multi-space gaps, etc.
//  - Proximity scoring: awards more points the closer (in terms of lines) a date is to
//    an expiry keyword line.
//

import Foundation

struct InsuranceOCREngine {

    private struct DateMatch {
        let date: Date
        let text: String
        let range: NSRange
        let lineIndex: Int
    }

    private struct ScoredDate {
        let match: DateMatch
        let score: Int
    }

    // MARK: - Public API

    static func parse(lines: [String]) -> InsuranceOCRResult {

        // 1. Pre-process: clean OCR artefacts from every line
        let cleaned = lines.map { cleanOCRLine($0) }.filter { !$0.isEmpty }

        // 2. Extract named fields
        var provider: String?
        var policyNo: String?
        var holder:   String?
        var regNo:    String?

        let providerKeywords = ["insured by", "insurer", "company", "insurance co",
                                "underwriter", "insurance provider", "insurance company",
                                "issued by", "policy issued by"]
        let policyKeywords   = ["policy no", "policy number", "policy#", "certificate no",
                                "cert no", "policy code", "policy id"]
        let regKeywords      = ["vehicle no", "registration number", "registration no",
                                "reg. no", "vehicle reg", "regn", "plate number", "plate",
                                "reg no", "vehicle registration"]
        let holderKeywords   = ["insured:", "policy holder", "name of insured", "holder",
                                "insured name", "client name", "customer name", "name"]

        for (index, line) in cleaned.enumerated() {
            let lower = line.lowercased()
            if lower.isEmpty { continue }

            // Policy Number
            if policyNo == nil {
                for kw in policyKeywords where lower.contains(kw) {
                    policyNo = valueAfterKeyword(kw, in: line) ?? nextNonEmpty(after: index, in: cleaned)
                    break
                }
            }

            // Vehicle Registration
            if regNo == nil {
                for kw in regKeywords where lower.contains(kw) {
                    regNo = valueAfterKeyword(kw, in: line) ?? nextNonEmpty(after: index, in: cleaned)
                    break
                }
            }

            // Policy Holder
            if holder == nil {
                for kw in holderKeywords where lower.contains(kw) {
                    holder = valueAfterKeyword(kw, in: line) ?? nextNonEmpty(after: index, in: cleaned)
                    break
                }
            }

            // Provider
            if provider == nil {
                for kw in providerKeywords where lower.contains(kw) {
                    provider = valueAfterKeyword(kw, in: line) ?? nextNonEmpty(after: index, in: cleaned)
                    break
                }
                // Direct name match fallback
                let commonProviders = ["geico", "progressive", "state farm", "allstate",
                                       "liberty mutual", "nationwide", "axa", "allianz",
                                       "zurich", "chubb", "hdfc ergo", "icici lombard",
                                       "tata aig", "bajaj allianz", "new india", "oriental"]
                if provider == nil {
                    for comp in commonProviders where lower.contains(comp) {
                        if let r = lower.range(of: comp) {
                            let start = line.index(line.startIndex, offsetBy: lower.distance(from: lower.startIndex, to: r.lowerBound))
                            let end   = line.index(line.startIndex, offsetBy: lower.distance(from: lower.startIndex, to: r.upperBound))
                            provider = String(line[start..<end])
                        }
                        break
                    }
                }
            }
        }

        // 3. Date extraction
        let issueCandidate  = bestDate(
            near: ["issue date", "date of issue", "effective from", "commencement",
                   "start date", "from date", "effective date", "valid from",
                   "issue", "inception date"],
            in: cleaned, preferRangeEnd: false
        )
        let expiryCandidate = bestExpiryDate(in: cleaned)

        let issueDate      = issueCandidate?.date
        let expiryDate     = expiryCandidate?.date
        let expiryDateText = expiryCandidate?.text

        // 4. OCR status
        let status: InsuranceOCRStatus
        if provider != nil && policyNo != nil && expiryDate != nil {
            status = .success
        } else if expiryDate != nil {
            status = .partial
        } else {
            status = .notDetected
        }

        return InsuranceOCRResult(
            insuranceProvider:  provider,
            policyNumber:       policyNo,
            policyHolderName:   holder,
            vehicleRegistration: regNo,
            issueDate:          issueDate,
            expiryDate:         expiryDate,
            expiryDateText:     expiryDateText,
            ocrStatus:          status
        )
    }

    // MARK: - Expiry date selection

    private static func bestExpiryDate(in lines: [String]) -> DateMatch? {
        let expiryKeywords = [
            "expiry date", "expiration date", "date of expiry", "policy expiry",
            "exp date", "exp. date", "expires", "expires on", "valid until",
            "valid upto", "validity upto", "valid up to", "validity up to",
            "valid through", "valid till", "valid to", "to date", "end date",
            "policy end date", "coverage end date", "expiry", "expiration"
        ]

        // Primary: keyword-proximity search with extended look-ahead
        if let explicit = bestDate(near: expiryKeywords, in: lines, preferRangeEnd: true) {
            return explicit
        }

        // Secondary: policy-period range (two dates on same line with a connector)
        if let rangeDate = bestDateFromPolicyRange(in: lines) {
            return rangeDate
        }

        // Tertiary: global fallback — return the latest future date anywhere in the doc
        return globalLatestFutureDate(in: lines)
    }

    // MARK: - Keyword-proximity search
    //
    // Searches all lines for a matching keyword, then looks at:
    //   • dates on the same line (inline values)
    //   • dates on the next 5 lines (table cells read row-by-row by Vision)
    // Each candidate is scored; the highest-scoring date is returned.

    private static func bestDate(near keywords: [String],
                                 in lines: [String],
                                 preferRangeEnd: Bool) -> DateMatch? {
        var scored: [ScoredDate] = []

        for (lineIndex, line) in lines.enumerated() {
            let lowerLine = line.lowercased()
            let matchingKeywordRanges = keywords.flatMap { keywordRanges(for: $0, in: lowerLine) }
            guard !matchingKeywordRanges.isEmpty else { continue }

            let sameLineDates = dateMatches(in: line, lineIndex: lineIndex)

            for keywordRange in matchingKeywordRanges {
                let keywordEnd = keywordRange.location + keywordRange.length

                // Same-line dates — highest confidence
                if !sameLineDates.isEmpty {
                    for match in sameLineDates {
                        let afterKeyword = match.range.location >= keywordEnd
                        let distance = afterKeyword
                            ? match.range.location - keywordEnd
                            : keywordRange.location - (match.range.location + match.range.length)
                        var score = 1_000 - min(abs(distance), 500)
                        score += afterKeyword ? 350 : -250
                        if preferRangeEnd {
                            score += rangeEndScore(for: match, in: line,
                                                   keywordEnd: keywordEnd,
                                                   sameLineDates: sameLineDates)
                        }
                        scored.append(ScoredDate(match: match, score: score))
                    }
                }

                // Look-ahead: next 1…5 lines — handles table-format docs where label
                // and value are in separate Vision text observations.
                let lookAheadMax = min(lineIndex + 6, lines.count)
                for offset in 1..<(lookAheadMax - lineIndex) {
                    let nextIndex = lineIndex + offset
                    guard nextIndex < lines.count else { break }
                    let nextDates = dateMatches(in: lines[nextIndex], lineIndex: nextIndex)
                    guard !nextDates.isEmpty else { continue }
                    // Penalise dates further away (each extra line costs 80 pts)
                    let distancePenalty = offset * 80
                    for match in nextDates {
                        var score = 650 - distancePenalty - min(match.range.location, 200)
                        if preferRangeEnd { score += match.range.location }
                        scored.append(ScoredDate(match: match, score: score))
                    }
                }
            }
        }

        return scored
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                if preferRangeEnd && $0.match.date != $1.match.date {
                    return $0.match.date > $1.match.date
                }
                return $0.match.range.location < $1.match.range.location
            }
            .first?.match
    }

    // MARK: - Policy range parser

    private static func bestDateFromPolicyRange(in lines: [String]) -> DateMatch? {
        var scored: [ScoredDate] = []
        for line in lines {
            let lower = line.lowercased()
            let matches = dateMatches(in: line, lineIndex: 0).sorted { $0.range.location < $1.range.location }
            guard matches.count >= 2 else { continue }

            let between = textBetween(matches.first!, matches.last!, in: lower)
            let hasConnector = ["to", "upto", "up to", "until", "through", "till", "-", "–", "—"]
                .contains { between.contains($0) }
            let hasContext = ["valid", "period", "policy", "insurance", "coverage", "from"]
                .contains { lower.contains($0) }
            guard hasConnector && hasContext else { continue }

            for (i, match) in matches.enumerated() {
                let beforeDate = (lower as NSString).substring(
                    with: NSRange(location: 0, length: min(match.range.location, (lower as NSString).length))
                )
                var score = 700 + match.range.location
                if i == matches.count - 1 { score += 350 }
                if ["to", "upto", "up to", "until", "through", "till"]
                    .contains(where: { beforeDate.contains(" \($0) ") }) { score += 500 }
                if let first = matches.first?.date, match.date >= first { score += 100 }
                scored.append(ScoredDate(match: match, score: score))
            }
        }
        return scored
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.match.date > $1.match.date
            }
            .first?.match
    }

    // MARK: - Global fallback: latest future date in entire document

    private static func globalLatestFutureDate(in lines: [String]) -> DateMatch? {
        let today = Calendar.current.startOfDay(for: Date())
        var allFutureDates: [DateMatch] = []

        for (idx, line) in lines.enumerated() {
            for match in dateMatches(in: line, lineIndex: idx) {
                if match.date >= today {
                    allFutureDates.append(match)
                }
            }
        }

        // Return the latest future date (most likely to be an expiry date)
        return allFutureDates.max(by: { $0.date < $1.date })
    }

    // MARK: - Helpers

    private static func textBetween(_ first: DateMatch, _ second: DateMatch, in lower: String) -> String {
        let ns  = lower as NSString
        let s   = min(first.range.location + first.range.length, ns.length)
        let e   = min(second.range.location, ns.length)
        guard e > s else { return "" }
        return ns.substring(with: NSRange(location: s, length: e - s))
    }

    private static func rangeEndScore(for match: DateMatch, in line: String,
                                      keywordEnd: Int, sameLineDates: [DateMatch]) -> Int {
        let lower = line.lowercased() as NSString
        let s = min(keywordEnd, lower.length)
        let e = min(match.range.location, lower.length)
        let between = e > s ? lower.substring(with: NSRange(location: s, length: e - s)) : ""
        var score = 0
        if sameLineDates.count > 1 { score += match.range.location }
        if ["to", "until", "through", "upto", "up to", "end"]
            .contains(where: { between.contains($0) }) { score += 450 }
        return score
    }

    private static func keywordRanges(for keyword: String, in lowerLine: String) -> [NSRange] {
        // Use a loose match (no mandatory word boundary) so "expiry date" is found even
        // when adjacent to colons, tabs, or OCR artefacts.
        let escaped = NSRegularExpression.escapedPattern(for: keyword)
        guard let regex = try? NSRegularExpression(
            pattern: escaped, options: [.caseInsensitive]) else { return [] }
        return regex.matches(
            in: lowerLine,
            range: NSRange(location: 0, length: (lowerLine as NSString).length)
        ).map(\.range)
    }

    // Next non-empty line that doesn't look like a date or single word (i.e. a value)
    private static func nextNonEmpty(after index: Int, in lines: [String]) -> String? {
        for i in (index + 1)..<min(index + 4, lines.count) {
            let val = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if val.count > 2 { return val }
        }
        return nil
    }

    private static func valueAfterKeyword(_ keyword: String, in line: String) -> String? {
        let lower = line.lowercased()
        guard let range = lower.range(of: keyword) else { return nil }
        let start = line.index(line.startIndex,
                               offsetBy: lower.distance(from: lower.startIndex, to: range.upperBound))
        var remainder = String(line[start...])
            .trimmingCharacters(in: CharacterSet(charactersIn: " :-=,;|\t"))
        // Strip leading OCR noise characters
        remainder = remainder.trimmingCharacters(in: CharacterSet(charactersIn: "■▪•·"))
        return remainder.count >= 3 ? remainder : nil
    }

    // MARK: - Date matching & parsing

    private static func dateMatches(in text: String, lineIndex: Int) -> [DateMatch] {
        let sep = "\\s*[./\\-|]\\s*"
        let pattern = """
        \\b(?:\
        \\d{1,2}(?:st|nd|rd|th)?\\s+[A-Za-z]{3,10},?\\s+\\d{2,4}|\
        [A-Za-z]{3,10}\\s+\\d{1,2}(?:st|nd|rd|th)?,?\\s+\\d{2,4}|\
        \\d{1,2}(?:st|nd|rd|th)?\(sep)\\d{1,2}\(sep)\\d{2,4}|\
        \\d{4}\(sep)\\d{1,2}\(sep)\\d{1,2}\
        )\\b
        """
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .allowCommentsAndWhitespace]) else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { m in
            let raw = ns.substring(with: m.range).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let date = parseDate(raw) else { return nil }
            return DateMatch(date: date, text: raw, range: m.range, lineIndex: lineIndex)
        }
    }

    private static func parseDate(_ raw: String) -> Date? {
        let cleaned = cleanDateText(raw)
        let formats = [
            "dd/MM/yyyy", "d/M/yyyy", "dd/MM/yy", "d/M/yy",
            "MM/dd/yyyy", "M/d/yyyy", "MM/dd/yy", "M/d/yy",
            "yyyy/MM/dd", "yyyy-MM-dd", "yyyy.M.d", "yyyy.MM.dd",
            "dd-MM-yyyy", "d-M-yyyy", "dd-MM-yy", "d-M-yy",
            "dd.MM.yyyy", "d.M.yyyy", "dd.MM.yy", "d.M.yy",
            "dd MMM, yyyy", "d MMM, yyyy", "dd MMMM, yyyy", "d MMMM, yyyy",
            "dd MMM yyyy",  "d MMM yyyy",  "dd MMMM yyyy",  "d MMMM yyyy",
            "MMMM dd, yyyy","MMMM d, yyyy","MMM dd, yyyy",  "MMM d, yyyy",
            "MMMM dd yyyy", "MMMM d yyyy", "MMM dd yyyy",   "MMM d yyyy",
            "dd-MMM-yyyy",  "d-MMM-yyyy",  "dd-MMM-yy",     "d-MMM-yy"
        ]
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.isLenient = true          // more forgiving than v1
        for f in formats {
            fmt.dateFormat = f
            if let d = fmt.date(from: cleaned) { return d }
        }
        return nil
    }

    private static func cleanDateText(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove ordinal suffixes (1st → 1, 27th → 27)
        if let r = try? NSRegularExpression(pattern: "(\\b\\d{1,2})(st|nd|rd|th)\\b", options: .caseInsensitive) {
            s = r.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "$1")
        }
        s = s.replacingOccurrences(of: " / ", with: "/")
        s = s.replacingOccurrences(of: " - ", with: "-")
        s = s.replacingOccurrences(of: " . ", with: ".")
        s = s.replacingOccurrences(of: "|", with: "/")
        // Collapse any remaining separator whitespace
        if let r = try? NSRegularExpression(pattern: "\\s*([./\\-|])\\s*") {
            s = r.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "$1")
        }
        return s
    }

    /// Cleans a raw OCR line before field/date extraction.
    private static func cleanOCRLine(_ line: String) -> String {
        var s = line.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip leading bullet / black-square OCR artefacts (e.g. ■10,00,000)
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "■▪•·\u{25A0}\u{25AA}"))
        // Pipe → slash (common in table-formatted OCR output)
        s = s.replacingOccurrences(of: "|", with: "/")
        // Collapse multiple spaces
        while s.contains("  ") { s = s.replacingOccurrences(of: "  ", with: " ") }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
