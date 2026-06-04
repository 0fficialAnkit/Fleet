// ESGComplianceDashboardView.swift
// Fleet
//
// ESG Compliance Dashboard for Fleet Managers.

import SwiftUI
import Charts

struct ESGComplianceDashboardView: View {
    let trips: [Trip]
    let vehicles: [Vehicle]
    let fuelLogs: [FuelLog]
    
    @State private var esgMetrics: FleetESGMetrics?
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let metrics = esgMetrics {
                    // Total Emissions Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "leaf.arrow.circlepath")
                                .font(.title2)
                                .foregroundStyle(.green)
                            Text("Total Fleet CO2 Emissions")
                                .font(.headline)
                            Spacer()
                            let isOverLimit = metrics.totalCO2EmissionsKg > metrics.recommendedCO2LimitKg
                            Text(isOverLimit ? "Over Target" : "Within Target")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isOverLimit ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                                .foregroundStyle(isOverLimit ? Color.red : Color.green)
                                .clipShape(Capsule())
                        }
                        
                        HStack(alignment: .firstTextBaseline) {
                            Text(String(format: "%.1f kg", metrics.totalCO2EmissionsKg))
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "Limit: %.1f kg", metrics.recommendedCO2LimitKg))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                                Text("Recommended Max")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Progress bar for the limit
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(metrics.totalCO2EmissionsKg > metrics.recommendedCO2LimitKg ? Color.red : Color.green)
                                    .frame(width: min(geo.size.width, geo.size.width * CGFloat(metrics.totalCO2EmissionsKg / max(1.0, metrics.recommendedCO2LimitKg))), height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        HStack {
                            Text("YTD 2026")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if metrics.totalCO2EmissionsKg > metrics.recommendedCO2LimitKg {
                                Text(String(format: "Exceeded by %.1f%%", (metrics.totalCO2EmissionsKg - metrics.recommendedCO2LimitKg) / max(1.0, metrics.recommendedCO2LimitKg) * 100.0))
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                            } else {
                                Text(String(format: "Remaining capacity: %.1f kg", metrics.recommendedCO2LimitKg - metrics.totalCO2EmissionsKg))
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Emissions by Vehicle Type Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Emissions by Vehicle Type")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(metrics.emissionsByVehicleType.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                                if let val = metrics.emissionsByVehicleType[type] {
                                    SectorMark(
                                        angle: .value("CO2", val),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(by: .value("Type", type.displayName))
                                    .annotation(position: .overlay) {
                                        Text(String(format: "%.0f", val))
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                        .chartForegroundStyleScale([
                            "Two Wheeler": Color.cyan,
                            "Three Wheeler": Color.teal,
                            "Four Wheeler": Color.orange,
                            "Truck": Color.indigo
                        ])
                        .frame(height: 250)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Export Button
                    Button(action: {
                        isExporting = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            let fileName = "ESG_Compliance_Report"
                            let tmpDir   = FileManager.default.temporaryDirectory
                            let url      = tmpDir.appendingPathComponent("\(fileName).pdf")
                            buildPDF(to: url, metrics: metrics)
                            exportURL = url
                            isExporting = false
                            showingShareSheet = true
                        }
                    }) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(isExporting ? "Generating Report..." : "Export ESG Report (CSRD Format)")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isExporting)
                    .padding(.horizontal)
                    
                } else {
                    ProgressView("Calculating ESG Metrics...")
                        .padding(.top, 50)
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("ESG Compliance")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Calculate metrics off the main thread
            let metrics = ESGService.generateFleetMetrics(trips: trips, vehicles: vehicles, fuelLogs: fuelLogs)
            self.esgMetrics = metrics
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    // MARK: - PDF Builder
    private func buildPDF(to url: URL, metrics: FleetESGMetrics) {
        let pageW: CGFloat = 595   // A4 width points
        let pageH: CGFloat = 842   // A4 height points
        let margin: CGFloat = 48
        let renderer  = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            func drawText(_ text: String, x: CGFloat = margin, font: UIFont, color: UIColor = .label, maxWidth: CGFloat? = nil) -> CGFloat {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let w    = maxWidth ?? (pageW - margin * 2)
                let rect = CGRect(x: x, y: y, width: w, height: 2000)
                let str  = NSString(string: text)
                let used = str.boundingRect(with: rect.size, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                str.draw(in: CGRect(x: x, y: y, width: w, height: used.height), withAttributes: attrs)
                return used.height + 4
            }

            func section(_ title: String) {
                y += 14
                let sepPath = UIBezierPath()
                sepPath.move(to: CGPoint(x: margin, y: y))
                sepPath.addLine(to: CGPoint(x: pageW - margin, y: y))
                UIColor.separator.setStroke(); sepPath.lineWidth = 0.5; sepPath.stroke()
                y += 6
                y += drawText(title.uppercased(), font: .systemFont(ofSize: 10, weight: .semibold), color: .secondaryLabel)
                y += 2
            }

            func row(_ label: String, _ value: String, isValueBold: Bool = false) {
                if y > pageH - margin * 2 { ctx.beginPage(); y = margin }
                let labelFont = UIFont.systemFont(ofSize: 12, weight: .regular)
                let valueFont = UIFont.systemFont(ofSize: 12, weight: isValueBold ? .bold : .medium)
                let lW: CGFloat = 200
                let labelH = drawText(label, font: labelFont, color: .secondaryLabel, maxWidth: lW)
                let valueX = margin + lW + 8
                let valueH = drawText(value, x: valueX, font: valueFont, maxWidth: pageW - margin - valueX)
                y += max(labelH, valueH)
            }

            // Title
            y += drawText("Fleet ESG Compliance & Carbon Report", font: .systemFont(ofSize: 22, weight: .bold))
            y += drawText("Generated on \(Date().formatted(date: .long, time: .shortened))",
                          font: .systemFont(ofSize: 11), color: .secondaryLabel)
            y += 8

            // Fleet Summary
            section("Fleet Overview")
            row("Total Vehicles Evaluated", "\(vehicles.count)")
            row("Total Trips Evaluated", "\(trips.count)")

            // Carbon Emissions Summary
            section("Emissions Summary")
            row("Total Fleet CO2 Emissions", String(format: "%.1f kg", metrics.totalCO2EmissionsKg), isValueBold: true)
            row("Recommended Limit (Compliance target)", String(format: "%.1f kg", metrics.recommendedCO2LimitKg))
            
            let isOverLimit = metrics.totalCO2EmissionsKg > metrics.recommendedCO2LimitKg
            let statusText: String
            if isOverLimit {
                let pct = (metrics.totalCO2EmissionsKg - metrics.recommendedCO2LimitKg) / max(1.0, metrics.recommendedCO2LimitKg) * 100
                statusText = String(format: "EXCEEDED by %.1f%%", pct)
            } else {
                let remaining = metrics.recommendedCO2LimitKg - metrics.totalCO2EmissionsKg
                statusText = String(format: "COMPLIANT (Remaining capacity: %.1f kg)", remaining)
            }
            row("Compliance Status", statusText, isValueBold: true)

            // Emissions by Vehicle Type
            section("Emissions by Vehicle Type")
            for type in metrics.emissionsByVehicleType.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
                if let val = metrics.emissionsByVehicleType[type] {
                    row(type.displayName, String(format: "%.1f kg (%.1f%% of total)", val, (val / max(1.0, metrics.totalCO2EmissionsKg)) * 100))
                }
            }

            // Recommendations
            section("Recommendations & Action Items")
            let recommendation: String
            if isOverLimit {
                recommendation = "Action Required: The fleet's carbon footprint exceeds the recommended sustainability target of \(String(format: "%.1f kg", metrics.recommendedCO2LimitKg)). It is highly recommended to transition high-emission vehicles (especially heavy trucks) to electric/low-emission alternatives, optimize route planning to reduce total trip distance, and implement eco-driving guidelines for drivers."
            } else {
                recommendation = "Sustainability Maintained: The fleet is currently operating within the target carbon limit of \(String(format: "%.1f kg", metrics.recommendedCO2LimitKg)). To maintain compliance, continue active route optimization, schedule periodic preventative maintenance to optimize fuel efficiency, and monitor new vehicle acquisitions for low-emission ratings."
            }
            y += drawText(recommendation, font: .systemFont(ofSize: 11), color: .label)
        }

        try? data.write(to: url)
    }
}
