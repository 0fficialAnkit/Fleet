import SwiftUI
import UIKit

// MARK: - Native Share Sheet Trigger (Direct presentation)
struct ShareSheet {
    static func share(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        
        // Find top-most presented view controller
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // On iPad, activity view controllers must be presented as popovers
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topViewController.view
            popover.sourceRect = CGRect(x: topViewController.view.bounds.midX, y: topViewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topViewController.present(activityVC, animated: true)
    }
}

// MARK: - CSV Generation Utility
struct CSVGenerator {
    static func generateCSV(from reports: [IssueReport]) -> URL? {
        var csvString = "Vehicle,License Plate,Category,Severity,Status,Driver,Submitted At,Description,Assigned To\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        for report in reports {
            let vehicle = report.vehicleName.replacingOccurrences(of: "\"", with: "\"\"")
            let plate = report.licensePlate.replacingOccurrences(of: "\"", with: "\"\"")
            let category = report.issueCategory.replacingOccurrences(of: "\"", with: "\"\"")
            let severity = report.severity.rawValue.capitalized
            let status = report.status.rawValue
            let driver = report.driverName.replacingOccurrences(of: "\"", with: "\"\"")
            let date = formatter.string(from: report.submittedAt)
            let desc = report.description.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: " ")
            let assigned = (report.assignedTo != nil) ? "Assigned" : "Unassigned"
            
            csvString += "\"\(vehicle)\",\"\(plate)\",\"\(category)\",\"\(severity)\",\"\(status)\",\"\(driver)\",\"\(date)\",\"\(desc)\",\"\(assigned)\"\n"
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Issue_Reports_\(Int(Date().timeIntervalSince1970)).csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
    
    static func generateVehicleCSV(vehicle: Vehicle, driverName: String, pastTrips: [Trip], profiles: [Profile]) -> URL? {
        var csvString = "Vehicle Specifications Report\n\n"
        csvString += "Manufacturer,\(vehicle.make ?? "N/A")\n"
        csvString += "Model,\(vehicle.model ?? "N/A")\n"
        csvString += "Year,\(vehicle.year != nil ? String(vehicle.year!) : "N/A")\n"
        csvString += "License Plate,\(vehicle.licensePlate ?? "N/A")\n"
        csvString += "VIN,\(vehicle.vin ?? "N/A")\n"
        csvString += "Tank Capacity,\(vehicle.tankCapacity != nil ? "\(vehicle.tankCapacity!) L" : "N/A")\n"
        csvString += "Mileage,\(vehicle.mileage != nil ? "\(vehicle.mileage!) km/l" : "N/A")\n"
        csvString += "Status,\(vehicle.status?.rawValue ?? "N/A")\n"
        csvString += "Current Driver,\(driverName)\n\n"
        
        csvString += "Completed Trips History\n"
        csvString += "Date,Distance,Driver,Status\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        for trip in pastTrips {
            let date = trip.endTime != nil ? formatter.string(from: trip.endTime!) : "N/A"
            let dist = trip.distance != nil ? "\(trip.distance!) km" : "N/A"
            let tripDriver = profiles.first { $0.id == trip.driverId }?.fullName ?? "Unknown Driver"
            let status = trip.status?.rawValue ?? "Completed"
            
            csvString += "\"\(date)\",\"\(dist)\",\"\(tripDriver)\",\"\(status)\"\n"
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Vehicle_Report_\(vehicle.licensePlate ?? "Vehicle")_\(Int(Date().timeIntervalSince1970)).csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
}

// MARK: - PDF Generation Utility
@MainActor
struct PDFGenerator {
    static func generatePDF(from reports: [IssueReport]) async -> URL? {
        var html = """
        <html>
        <head>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: #1e293b; padding: 20px; }
            h1 { color: #0d9488; border-bottom: 2px solid #0d9488; padding-bottom: 10px; margin-bottom: 20px; font-size: 24px; }
            table { width: 100%; border-collapse: collapse; margin-top: 10px; }
            th { background-color: #f8fafc; color: #475569; font-weight: 600; text-align: left; padding: 10px; border-bottom: 2px solid #e2e8f0; font-size: 11px; text-transform: uppercase; }
            td { padding: 12px 10px; border-bottom: 1px solid #f1f5f9; font-size: 12px; }
            .badge { display: inline-block; padding: 3px 8px; border-radius: 9999px; font-size: 10px; font-weight: 600; text-transform: uppercase; }
            .badge-low { background-color: #dcfce7; color: #15803d; }
            .badge-medium { background-color: #fef9c3; color: #a16207; }
            .badge-high { background-color: #ffedd5; color: #c2410c; }
            .badge-critical { background-color: #fee2e2; color: #b91c1c; }
            .badge-open { background-color: #fee2e2; color: #b91c1c; }
            .badge-assigned { background-color: #ffedd5; color: #c2410c; }
            .badge-in_progress { background-color: #dbeafe; color: #1d4ed8; }
            .badge-resolved { background-color: #dcfce7; color: #15803d; }
            .meta { color: #64748b; font-size: 12px; margin-bottom: 30px; }
            .footer { text-align: center; color: #94a3b8; font-size: 10px; margin-top: 50px; border-top: 1px solid #e2e8f0; padding-top: 10px; }
        </style>
        </head>
        <body>
            <h1>Fleet Operations - Issue Reports Summary</h1>
            <div class="meta">
                Generated on: \(Date().formatted(date: .long, time: .shortened))<br/>
                Total Reports: \(reports.count)
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Vehicle</th>
                        <th>License Plate</th>
                        <th>Category</th>
                        <th>Severity</th>
                        <th>Status</th>
                        <th>Driver</th>
                        <th>Date</th>
                    </tr>
                </thead>
                <tbody>
        """
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        
        for report in reports {
            let severityClass = "badge-\(report.severity.rawValue.lowercased())"
            let statusClass = "badge-\(report.status.dbValue.lowercased())"
            
            html += """
                    <tr>
                        <td><strong>\(report.vehicleName)</strong></td>
                        <td style="font-family: monospace; color: #0d9488;">\(report.licensePlate)</td>
                        <td>\(report.issueCategory)</td>
                        <td><span class="badge \(severityClass)">\(report.severity.rawValue)</span></td>
                        <td><span class="badge \(statusClass)">\(report.status.rawValue)</span></td>
                        <td>\(report.driverName)</td>
                        <td>\(formatter.string(from: report.submittedAt))</td>
                    </tr>
            """
        }
        
        html += """
                </tbody>
            </table>
            <div class="footer">
                Fleet Management System &bull; Confidential &bull; Generated Automatically
            </div>
        </body>
        </html>
        """
        
        return await renderHTMLToPDF(htmlString: html, filename: "Issue_Reports_Summary")
    }
    
    static func generateSingleReportPDF(
        report: IssueReport,
        driverProfile: Profile?,
        vehicle: Vehicle?,
        previousIssues: [IssueReport]
    ) async -> URL? {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        
        let severityClass = "badge-\(report.severity.rawValue.lowercased())"
        let statusClass = "badge-\(report.status.dbValue.lowercased())"
        
        var driverDetails = report.driverName
        if let driver = driverProfile {
            driverDetails = """
            <strong>\(driver.fullName)</strong><br/>
            Email: \(driver.email)<br/>
            \(driver.phone != nil ? "Phone: \(driver.phone!)" : "")
            """
        }
        
        var html = """
        <html>
        <head>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: #1e293b; padding: 30px; }
            h1 { color: #0d9488; margin-bottom: 5px; font-size: 26px; }
            h2 { color: #0f172a; margin-top: 30px; margin-bottom: 10px; font-size: 18px; border-bottom: 1px solid #e2e8f0; padding-bottom: 5px; }
            .subtitle { color: #64748b; font-size: 14px; margin-bottom: 25px; text-transform: uppercase; letter-spacing: 1px; }
            .card { background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 20px; margin-bottom: 25px; }
            .card-title { font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase; margin-bottom: 15px; border-bottom: 1px solid #f1f5f9; padding-bottom: 5px; }
            .grid { display: flex; flex-direction: row; flex-wrap: wrap; margin-bottom: 10px; }
            .grid-col { flex: 1; min-width: 200px; margin-bottom: 15px; }
            .label { font-size: 11px; font-weight: 600; color: #94a3b8; text-transform: uppercase; margin-bottom: 4px; }
            .value { font-size: 14px; color: #0f172a; }
            .value-bold { font-weight: 600; }
            .badge { display: inline-block; padding: 4px 10px; border-radius: 9999px; font-size: 11px; font-weight: 600; text-transform: uppercase; }
            .badge-low { background-color: #dcfce7; color: #15803d; }
            .badge-medium { background-color: #fef9c3; color: #a16207; }
            .badge-high { background-color: #ffedd5; color: #c2410c; }
            .badge-critical { background-color: #fee2e2; color: #b91c1c; }
            .badge-open { background-color: #fee2e2; color: #b91c1c; }
            .badge-assigned { background-color: #ffedd5; color: #c2410c; }
            .badge-in_progress { background-color: #dbeafe; color: #1d4ed8; }
            .badge-resolved { background-color: #dcfce7; color: #15803d; }
            .description { font-size: 14px; color: #334155; line-height: 1.6; background-color: #ffffff; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 15px; margin-top: 10px; }
            table { width: 100%; border-collapse: collapse; margin-top: 10px; }
            th { background-color: #f8fafc; color: #475569; font-weight: 600; text-align: left; padding: 8px; border-bottom: 2px solid #e2e8f0; font-size: 10px; text-transform: uppercase; }
            td { padding: 10px 8px; border-bottom: 1px solid #f1f5f9; font-size: 11px; }
            .footer { text-align: center; color: #94a3b8; font-size: 10px; margin-top: 60px; border-top: 1px solid #e2e8f0; padding-top: 15px; }
        </style>
        </head>
        <body>
            <h1>Full Vehicle & History Report</h1>
            <div class="subtitle">Report ID: \(report.id.uuidString.prefix(8))</div>
            
            <div class="card">
                <div class="card-title">Current Issue Details</div>
                <div class="grid">
                    <div class="grid-col">
                        <div class="label">Issue Category</div>
                        <div class="value value-bold" style="color: #0d9488;">\(report.issueCategory)</div>
                    </div>
                    <div class="grid-col">
                        <div class="label">Reported On</div>
                        <div class="value">\(formatter.string(from: report.submittedAt))</div>
                    </div>
                </div>
                <div class="grid">
                    <div class="grid-col">
                        <div class="label">Severity</div>
                        <div class="value"><span class="badge \(severityClass)">\(report.severity.rawValue)</span></div>
                    </div>
                    <div class="grid-col">
                        <div class="label">Status</div>
                        <div class="value"><span class="badge \(statusClass)">\(report.status.rawValue)</span></div>
                    </div>
                </div>
                <div class="grid">
                    <div class="grid-col">
                        <div class="label">Reported By</div>
                        <div class="value">\(driverDetails)</div>
                    </div>
                    <div class="grid-col">
                        <div class="label">Assigned Status</div>
                        <div class="value">\(report.assignedTo != nil ? "Assigned to Mechanic" : "Unassigned")</div>
                    </div>
                </div>
                <div style="margin-top: 15px;">
                    <div class="label">Detailed Description</div>
                    <div class="description">
                        \(report.description.replacingOccurrences(of: "\n", with: "<br/>"))
                    </div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-title">Vehicle Specifications</div>
                <div class="grid">
                    <div class="grid-col">
                        <div class="label">Make & Model</div>
                        <div class="value value-bold">\(report.vehicleName)</div>
                    </div>
                    <div class="grid-col">
                        <div class="label">License Plate</div>
                        <div class="value" style="font-family: monospace; color: #0d9488; font-weight: 600;">\(report.licensePlate)</div>
                    </div>
                </div>
                <div class="grid">
                    <div class="grid-col">
                        <div class="label">Odometer (Mileage)</div>
                        <div class="value">\(vehicle?.mileage != nil ? "\(Int(vehicle!.mileage!)) km" : "—")</div>
                    </div>
                    <div class="grid-col">
                        <div class="label">VIN</div>
                        <div class="value" style="font-family: monospace;">\(vehicle?.vin ?? "—")</div>
                    </div>
                </div>
                <div class="grid">
                    <div class="grid-col">
                        <div class="label">Year</div>
                        <div class="value">\(vehicle?.year != nil ? "\(vehicle!.year!)" : "—")</div>
                    </div>
                    <div class="grid-col">
                        <div class="label">Current Vehicle Status</div>
                        <div class="value">\(vehicle?.status != nil ? "\(vehicle!.status!.rawValue.capitalized)" : "—")</div>
                    </div>
                </div>
            </div>
            
            <h2>Vehicle History (Other Reported Issues)</h2>
            <table>
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Category</th>
                        <th>Severity</th>
                        <th>Status</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
        """
        
        if previousIssues.isEmpty {
            html += """
                    <tr>
                        <td colspan="5" style="text-align: center; color: #94a3b8; padding: 15px; font-size: 11px;">No other previous issues reported for this vehicle.</td>
                    </tr>
            """
        } else {
            let histFormatter = DateFormatter()
            histFormatter.dateStyle = .short
            histFormatter.timeStyle = .none
            
            for issue in previousIssues {
                let severityBadge = "badge-\(issue.severity.rawValue.lowercased())"
                let statusBadge = "badge-\(issue.status.dbValue.lowercased())"
                
                html += """
                        <tr>
                            <td style="white-space: nowrap; font-size: 11px;">\(histFormatter.string(from: issue.submittedAt))</td>
                            <td style="font-weight: 600; font-size: 11px;">\(issue.issueCategory)</td>
                            <td><span class="badge \(severityBadge)" style="font-size: 9px; padding: 2px 6px;">\(issue.severity.rawValue)</span></td>
                            <td><span class="badge \(statusBadge)" style="font-size: 9px; padding: 2px 6px;">\(issue.status.rawValue)</span></td>
                            <td style="font-size: 11px; color: #475569;">\(issue.description)</td>
                        </tr>
                """
            }
        }
        
        html += """
                </tbody>
            </table>
            
            <div class="footer">
                Fleet Management System &bull; Confidential Document &bull; Generated on \(Date().formatted(date: .long, time: .shortened))
            </div>
        </body>
        </html>
        """
        
        return await renderHTMLToPDF(htmlString: html, filename: "Issue_Report_\(report.id.uuidString.prefix(8))")
    }
    
    static func generateVehicleReportPDF(
        vehicle: Vehicle,
        driver: Profile?,
        pastTrips: [Trip],
        profiles: [Profile]
    ) async -> URL? {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        
        var driverDetails = "Unassigned"
        if let drv = driver {
            driverDetails = """
            <strong>\(drv.fullName)</strong><br/>
            Email: \(drv.email)<br/>
            \(drv.phone != nil ? "Phone: \(drv.phone!)" : "")
            """
        }
        
        var html = """
        <html>
        <head>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: #1e293b; padding: 30px; }
            h1 { color: #0d9488; margin-bottom: 5px; font-size: 26px; }
            h2 { color: #0f172a; margin-top: 30px; margin-bottom: 10px; font-size: 18px; border-bottom: 1px solid #e2e8f0; padding-bottom: 5px; }
            .subtitle { color: #64748b; font-size: 14px; margin-bottom: 25px; text-transform: uppercase; letter-spacing: 1px; }
            .card { background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 20px; margin-bottom: 25px; }
            .card-title { font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase; margin-bottom: 15px; border-bottom: 1px solid #f1f5f9; padding-bottom: 5px; }
            .grid { display: flex; flex-direction: row; flex-wrap: wrap; margin-bottom: 10px; }
            .grid-col { flex: 1; min-width: 200px; margin-bottom: 15px; }
            .label { font-size: 11px; font-weight: 600; color: #94a3b8; text-transform: uppercase; margin-bottom: 4px; }
            .value { font-size: 14px; color: #0f172a; }
            .value-bold { font-weight: 600; }
            table { width: 100%; border-collapse: collapse; margin-top: 10px; }
            th { background-color: #f8fafc; color: #475569; font-weight: 600; text-align: left; padding: 8px; border-bottom: 2px solid #e2e8f0; font-size: 10px; text-transform: uppercase; }
            td { padding: 10px 8px; border-bottom: 1px solid #f1f5f9; font-size: 11px; }
            .footer { text-align: center; color: #94a3b8; font-size: 10px; margin-top: 60px; border-top: 1px solid #e2e8f0; padding-top: 15px; }
        </style>
        </head>
        <body>
            <h1>Vehicle Operations & Specifications Report</h1>
            <div class="subtitle">Vehicle License: \(vehicle.licensePlate ?? "N/A")</div>
            
            <div class="card">
                <div class="card-title">Vehicle Technical Specifications</div>
                <div class="grid">
                    <div class="grid-col">
                        <div class="label">Manufacturer</div>
                        <div class="value value-bold">\(vehicle.make ?? "N/A")</div>
                    </div>
                    <div class="grid-col">
                        <div class="label">Model</div>
                        <div class="value">\(vehicle.model ?? "N/A")</div>
                    </div>
                </div>
                <div class="grid">
                    <div class="grid-col">
                        <div class="label">Manufacture Year</div>
                        <div class="value">\(vehicle.year != nil ? "\(vehicle.year!)" : "N/A")</div>
                    </div>
                    <div class="grid-col">
                        <div class="label">VIN</div>
                        <div class="value" style="font-family: monospace;">\(vehicle.vin ?? "N/A")</div>
                    </div>
                </div>
                <div class="grid">
                    <div class="grid-col">
                        <div class="label">Tank Capacity</div>
                        <div class="value">\(vehicle.tankCapacity != nil ? "\(String(format: "%.1f", vehicle.tankCapacity!)) L" : "N/A")</div>
                    </div>
                    <div class="grid-col">
                        <div class="label">Mileage</div>
                        <div class="value">\(vehicle.mileage != nil ? "\(String(format: "%.1f", vehicle.mileage!)) km/l" : "N/A")</div>
                    </div>
                </div>
                <div class="grid">
                    <div class="grid-col">
                        <div class="label">Purchase Date</div>
                        <div class="value">\(vehicle.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")</div>
                    </div>
                    <div class="grid-col">
                        <div class="label">Status</div>
                        <div class="value" style="font-weight: 600; color: #0d9488;">\(vehicle.status?.rawValue.uppercased() ?? "N/A")</div>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-title">Current Assigned Driver</div>
                <div class="value">\(driverDetails)</div>
            </div>
            
            <h2>Completed Trips History</h2>
            <table>
                <thead>
                    <tr>
                        <th>Date & Time</th>
                        <th>Distance</th>
                        <th>Assigned Driver</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
        """
        
        if pastTrips.isEmpty {
            html += """
                    <tr>
                        <td colspan="4" style="text-align: center; color: #94a3b8; padding: 15px; font-size: 11px;">No completed trips recorded for this vehicle.</td>
                    </tr>
            """
        } else {
            let tripFormatter = DateFormatter()
            tripFormatter.dateStyle = .medium
            tripFormatter.timeStyle = .short
            
            for trip in pastTrips {
                let tripDriver = profiles.first { $0.id == trip.driverId }?.fullName ?? "Unknown Driver"
                let dist = trip.distance != nil ? "\(String(format: "%.1f", trip.distance!)) km" : "—"
                let endTimeStr = trip.endTime != nil ? tripFormatter.string(from: trip.endTime!) : "—"
                
                html += """
                        <tr>
                            <td style="white-space: nowrap; font-size: 11px;">\(endTimeStr)</td>
                            <td style="font-weight: 600; font-size: 11px; color: #0d9488;">\(dist)</td>
                            <td style="font-size: 11px;">\(tripDriver)</td>
                            <td style="font-size: 11px; text-transform: uppercase; color: #15803d; font-weight: 600;">\(trip.status?.rawValue ?? "Completed")</td>
                        </tr>
                """
            }
        }
        
        html += """
                </tbody>
            </table>
            
            <div class="footer">
                Fleet Management System &bull; Confidential Document &bull; Generated on \(Date().formatted(date: .long, time: .shortened))
            </div>
        </body>
        </html>
        """
        
        return await renderHTMLToPDF(htmlString: html, filename: "Vehicle_Report_\(vehicle.licensePlate ?? "Vehicle")")
    }
    
    private static func renderHTMLToPDF(htmlString: String, filename: String) async -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(filename)_\(Int(Date().timeIntervalSince1970)).pdf")
        
        let printPageRenderer = UIPrintPageRenderer()
        
        let printFormatter = UIMarkupTextPrintFormatter(markupText: htmlString)
        printPageRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        
        // Define standard A4 page size
        let paperWidth: Double = 595.2 // 8.27 inches
        let paperHeight: Double = 841.8 // 11.69 inches
        
        let paperRect = CGRect(x: 0, y: 0, width: paperWidth, height: paperHeight)
        // 0.5 inch margins
        let printableRect = CGRect(x: 36, y: 36, width: paperWidth - 72, height: paperHeight - 72)
        
        printPageRenderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        printPageRenderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)
        
        printPageRenderer.prepare(forDrawingPages: NSRange(location: 0, length: 1))
        
        let bounds = UIGraphicsGetPDFContextBounds()
        
        for i in 0..<printPageRenderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            printPageRenderer.drawPage(at: i, in: bounds)
        }
        
        UIGraphicsEndPDFContext()
        
        do {
            try pdfData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
    }
}
