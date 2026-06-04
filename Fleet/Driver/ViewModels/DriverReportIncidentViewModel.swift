import SwiftUI
import CoreLocation
import Supabase

@MainActor
@Observable
final class DriverReportIncidentViewModel {
    var isSubmitting = false
    var isSubmitted = false
    var errorMessage: String?
    
    private let locationManager = LocationManager()
    
    init() {
        locationManager.requestPermission()
    }
    
    func submitIncident(tripId: UUID, driverId: UUID?, incidentType: String, description: String, images: [UIImage]) {
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                var uploadedUrls: [String] = []
                for (index, image) in images.enumerated() {
                    if let data = image.jpegData(compressionQuality: 0.7) {
                        let fileName = "incidents/\(UUID().uuidString)_\(index).jpg"
                        do {
                            try await supabase.storage
                                .from("fleet-uploads")
                                .upload(fileName, data: data, options: .init(contentType: "image/jpeg"))
                            if let publicUrl = try? supabase.storage.from("fleet-uploads").getPublicURL(path: fileName).absoluteString {
                                uploadedUrls.append(publicUrl)
                            }
                        } catch {
                            print("Image upload failed, continuing without image: \(error)")
                        }
                    }
                }
                
                let photoUrl = uploadedUrls.first
                
                var locationString = "Unknown Location"
                if let coord = locationManager.coordinate {
                    locationString = "\(String(format: "%.5f", coord.latitude)), \(String(format: "%.5f", coord.longitude))"
                }
                
                let incident = TripIncident(
                    id: UUID(),
                    tripId: tripId,
                    driverId: driverId,
                    incidentType: incidentType,
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    location: locationString,
                    photoUrl: photoUrl,
                    createdAt: Date()
                )
                
                try await TripIncidentService.createIncident(incident)
                
                // Notify fleet manager
                try? await NotificationService.notifyManager(
                    forTrip: tripId,
                    title: "Trip Incident Reported",
                    message: "A \(incidentType) incident was reported by the driver.",
                    type: .alert
                )
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        self.isSubmitting = false
                        self.isSubmitted = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = error.localizedDescription
                }
                print("Error submitting incident: \(error)")
            }
        }
    }
}
