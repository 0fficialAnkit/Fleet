//
//  DataModel.swift
//  Fleet
//
//  Created by Vaibhav Singh on 19/05/26.
//

import Foundation

enum UserStatus: String, Codable, CaseIterable, Sendable {
  case active = "active"
  case inactive = "inactive"
  case suspended = "suspended"
}

enum VehicleStatus: String, Codable, CaseIterable, Sendable {
  case active = "available"
  case inactive = "unavailable"
  case maintenance = "maintenance"
}

enum MaintenanceTaskStatus: String, Codable, CaseIterable, Sendable {
  case pending = "pending"
  case inProgress = "in_progress"
  case completed = "completed"
  case cancelled = "cancelled"
}

enum WorkOrderStatus: String, Codable, CaseIterable, Sendable {
  case pending = "pending" // Add this case
  case open = "open"
  case inProgress = "in_progress"
  case completed = "completed"
  case cancelled = "cancelled"
}

enum WorkOrderPriority: String, Codable, CaseIterable, Sendable {
  case low = "low"
  case medium = "medium"
  case high = "high"
  case critical = "critical"
}

enum TripStatus: String, Codable, CaseIterable, Sendable {
  case scheduled = "scheduled"
  case active = "active"
  case completed = "completed"
  case cancelled = "cancelled"
}

enum OrderType: String, Codable, CaseIterable, Sendable, Identifiable {
  case pickUpAndDrop = "pick_up_and_drop"
  case bulkOrderShip = "bulk_order_ship"
  case travel = "travel"

  var id: String { rawValue }

  var displayName: String {
      switch self {
      case .pickUpAndDrop: return "Pick Up & Drop"
      case .bulkOrderShip: return "Bulk Order Ship"
      case .travel: return "Travel"
      }
  }
}

enum InspectionType: String, Codable, CaseIterable, Sendable, Identifiable {
  case preTrip = "pre_trip"
  case postTrip = "post_trip"
  var id: String { rawValue }
}

enum DefectSeverity: String, Codable, CaseIterable, Sendable {
  case low = "low"
  case medium = "medium"
  case high = "high"
  case critical = "critical"
}

enum DefectStatus: String, Codable, CaseIterable, Sendable {
  case open = "open"
  case resolved = "resolved"
  case closed = "closed"
}

enum GeofenceZoneType: String, Codable, CaseIterable, Sendable {
  case restricted = "restricted"
  case allowed = "allowed"
  case custom = "custom"
}

enum GeofenceEventType: String, Codable, CaseIterable, Sendable {
  case enter = "enter"
  case exit = "exit"
}

enum NotificationType: String, Codable, CaseIterable, Sendable {
  case alert = "alert"
  case info = "info"
  case warning = "warning"
  case maintenance = "maintenance"
}

enum ReportType: String, Codable, CaseIterable, Sendable {
  case trip = "trip"
  case fuel = "fuel"
  case maintenance = "maintenance"
  case inspection = "inspection"
  case defect = "defect"
}

enum DocumentType: String, Codable, CaseIterable, Sendable {
  case insurance = "insurance"
  case registration = "registration"
  case permit = "permit"
  case other = "other"
}

enum TripUpdateType: String, Codable, CaseIterable, Sendable {
  case started = "started"
  case enRoute = "en_route"
  case delayed = "delayed"
  case completed = "completed"
  case cancelled = "cancelled"
  case voiceLog = "voice_log"
}

enum MaintenanceTaskType: String, Codable, CaseIterable, Sendable {
  case oilChange = "oil_change"
  case tireRotation = "tire_rotation"
  case inspection = "inspection"
  case repair = "repair"
  case other = "other"
}

// MARK: - Role
struct Role: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var roleName: String

  enum CodingKeys: String, CodingKey {
      case id
      case roleName = "role_name"
  }
}

// MARK: - User
struct User: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var fullName: String
  var email: String
  var passwordHash: String?   // Optional — DB may not return this column
  var phone: String?
  var licenseNumber: String?
  var roleId: UUID //FK
  var status: UserStatus?
  var createdAt: Date?
  var createdByManagerId: UUID? // FK — which fleet manager created this user

  enum CodingKeys: String, CodingKey {
      case id
      case fullName = "full_name"
      case email
      case passwordHash = "password_hash"
      case phone
      case licenseNumber = "license_number"
      case roleId = "role_id"
      case status
      case createdAt = "created_at"
      case createdByManagerId = "created_by_manager_id"
  }
}

enum VehicleType: String, Codable, CaseIterable, Sendable, Identifiable {
  case twoWheeler = "two_wheeler"
  case threeWheeler = "three_wheeler"
  case car = "car"
  case truck = "truck"
  
  var id: String { rawValue }
  
  var maintenanceThresholdKM: Double {
      switch self {
      case .twoWheeler: return 3000
      case .threeWheeler: return 5000
      case .car: return 10000
      case .truck: return 20000
      }
  }
  
  var displayName: String {
      switch self {
      case .twoWheeler: return "Two Wheeler"
      case .threeWheeler: return "Three Wheeler"
      case .car: return "Four Wheeler"
      case .truck: return "Truck"
      }
  }
}

// MARK: - Vehicle
struct Vehicle: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var make: String?
  var model: String?
  var year: Int?
  var vin: String?
  var licensePlate: String?
  var tankCapacity: Double?
  var mileage: Double?
  var purchaseDate: Date?
  var assignedDriverId: UUID? //FK
  var adminId: UUID? //FK
  var status: VehicleStatus?
  var vehicleType: VehicleType?

  enum CodingKeys: String, CodingKey {
      case id, make, model, year, vin
      case licensePlate = "license_plate"
      case tankCapacity = "tank_capacity"
      case mileage
      case purchaseDate = "purchase_date"
      case assignedDriverId = "assigned_driver_id"
      case adminId = "admin_id"
      case status
      case vehicleType = "vehicle_type"
  }
}

//  MARK: - VehicleDocument
struct VehicleDocument: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var vehicleId: UUID //FK
  var documentType: DocumentType?
  var fileUrl: String?
  var expiryDate: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case documentType = "document_type"
      case fileUrl = "file_url"
      case expiryDate = "expiry_date"
  }
}

//  MARK: - VehicleLocation
struct VehicleLocation: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var vehicleId: UUID //FK
  var latitude: Double?
  var longitude: Double?
  var speed: Double?
  var recordedAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case latitude, longitude, speed
      case recordedAt = "recorded_at"
  }
}
//  MARK: - MaintenanceTask
enum MaintenanceScheduleType: String, Codable, CaseIterable, Sendable, Identifiable {
    case date = "date"
    case mileage = "mileage"
    case interval = "interval"
    
    var id: String { rawValue }
}

struct MaintenanceTask: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var workOrderId: UUID? // FK — optional, tasks can exist without a work order
  var vehicleId: UUID // FK
  var scheduledBy: UUID? // FK
  var assignedTo: UUID? // FK
  var taskType: MaintenanceTaskType?
  var description: String?
  var scheduledDate: Date?
  var targetMileage: Double?
  var serviceIntervalMonths: Int?
  var scheduleType: MaintenanceScheduleType?
  var status: MaintenanceTaskStatus?
  var completedAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case workOrderId = "work_order_id"
      case vehicleId = "vehicle_id"
      case scheduledBy = "scheduled_by"
      case assignedTo = "assigned_to"
      case taskType = "task_type"
      case description
      case scheduledDate = "scheduled_date"
      case targetMileage = "target_mileage"
      case serviceIntervalMonths = "service_internal"
      case scheduleType = "schedule_type"
      case status
      case completedAt = "completed_at"
  }
}

//  MARK: - WorkOrder
struct WorkOrder: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var vehicleId: UUID // FK
  var createdBy: UUID? // FK
  var assignedTo: UUID? // FK
  var priority: WorkOrderPriority?
  var status: WorkOrderStatus?
  var createdAt: Date?
  var completedAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case createdBy = "created_by"
      case assignedTo = "assigned_to"
      case priority
      case status = "lifecycle_status"
      case createdAt = "created_at"
      case completedAt = "completed_at"
  }
}

//  MARK: - MaintenanceHistory
struct MaintenanceHistory: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var vehicleId: UUID // FK
  var workOrderId: UUID? // FK
  var serviceDetails: String?
  var cost: Double?
  var completedAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case workOrderId = "work_order_id"
      case serviceDetails = "service_details"
      case cost
      case completedAt = "completed_at"
  }
}

//MARK: - Inventory
struct Inventory: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var partName: String?
  var stockQuantity: Int?
  var reorderLevel: Int?
  var unitCost: Double?

  enum CodingKeys: String, CodingKey {
      case id
      case partName = "part_name"
      case stockQuantity = "stock_quantity"
      case reorderLevel = "reorder_level"
      case unitCost = "unit_cost"
  }
}

//MARK: - WorkOrderPart
struct WorkOrderPart: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var workOrderId: UUID // FK
  var inventoryItemId: UUID // FK
  var quantityUsed: Int?
  var hoursSpent: Double?

  enum CodingKeys: String, CodingKey {
      case id
      case workOrderId = "work_order_id"
      case inventoryItemId = "inventory_item_id"
      case quantityUsed = "quantity_used"
      case hoursSpent = "hours_spent"
  }
}

//  MARK: - Route
struct Route: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var routeName: String?
  var startLocation: String?
  var endLocation: String?
  var createdByManagerId: UUID? // FK — which fleet manager created this route

  enum CodingKeys: String, CodingKey {
      case id
      case routeName = "route_name"
      case startLocation = "start_location"
      case endLocation = "end_location"
      case createdByManagerId = "created_by_manager_id"
  }
}

//MARK: - Trip
struct Trip: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var vehicleId: UUID // FK
  var driverId: UUID? // FK
  var routeId: UUID? // FK
  var startTime: Date?
  var endTime: Date?
  var distance: Double?
  var status: TripStatus?
  var orderType: OrderType?
  var createdAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case driverId = "driver_id"
      case routeId = "route_id"
      case startTime = "start_time"
      case endTime = "end_time"
      case distance, status
      case orderType = "order_type"
      case createdAt = "created_at"
  }
}

//  MARK: - TripUpdate
struct TripUpdate: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var tripId: UUID // FK
  var updateType: TripUpdateType?
  var message: String?
  var createdAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case tripId = "trip_id"
      case updateType = "update_type"
      case message
      case createdAt = "created_at"
  }
}

//  MARK: - TripIncident
enum TripIncidentType: String, Codable, CaseIterable, Sendable {
    case traffic = "Traffic"
    case accident = "Accident"
    case breakdown = "Breakdown"
    case weather = "Weather"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .traffic: return "car.2.fill"
        case .accident: return "car.burst.fill"
        case .breakdown: return "wrench.and.screwdriver.fill"
        case .weather: return "cloud.heavyrain.fill"
        case .other: return "exclamationmark.triangle.fill"
        }
    }
}

struct TripIncident: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var tripId: UUID
    var driverId: UUID?
    var incidentType: String
    var description: String
    var location: String
    var photoUrl: String?
    var source: String?         // "voice" | "manual"
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case tripId       = "trip_id"
        case driverId     = "driver_id"
        case incidentType = "incident_type"
        case description
        case location
        case photoUrl     = "photo_url"
        case source
        case createdAt    = "created_at"
    }

    /// True when this incident was reported via voice (not the manual form).
    var isVoiceReported: Bool { source == "voice" }
}

// MARK: - VoiceLogStatus

/// Structured trip status extracted from a driver's voice recording.
enum VoiceLogStatus: String, Codable, CaseIterable, Sendable {
    case enRoute   = "en_route"
    case delayed   = "delayed"
    case arrived   = "arrived"
    case pickedUp  = "picked_up"
    case breakdown = "breakdown"
    case other     = "other"

    var displayName: String {
        switch self {
        case .enRoute:   return "En Route"
        case .delayed:   return "Delayed"
        case .arrived:   return "Arrived"
        case .pickedUp:  return "Picked Up"
        case .breakdown: return "Breakdown"
        case .other:     return "Update"
        }
    }

    var icon: String {
        switch self {
        case .enRoute:   return "arrow.triangle.turn.up.right.road.fill"
        case .delayed:   return "clock.badge.exclamationmark.fill"
        case .arrived:   return "checkmark.circle.fill"
        case .pickedUp:  return "shippingbox.fill"
        case .breakdown: return "wrench.and.screwdriver.fill"
        case .other:     return "mic.fill"
        }
    }

    /// Maps voice status to the closest TripIncidentType for saving to trip_incidents.
    var incidentType: TripIncidentType? {
        switch self {
        case .delayed:   return .traffic
        case .breakdown: return .breakdown
        case .other:     return .other
        case .enRoute, .arrived, .pickedUp: return nil   // factual updates, not incidents
        }
    }

    /// True when this status represents an alert-worthy incident.
    var isIncident: Bool { incidentType != nil }
}

// MARK: - VoiceExtractedData

/// In-memory structured result from VoiceExtractorService.
/// Not persisted — only lives during the driver review flow.
struct VoiceExtractedData {
    var location: String?
    var mileageKM: Double?
    var etaText: String?
    var status: VoiceLogStatus?
    var rawTranscription: String

    /// True when NLP found no structured facts in the transcript.
    var isEmpty: Bool {
        location == nil && mileageKM == nil && etaText == nil && status == nil
    }
}

// MARK: - VoiceTripLog

/// Persisted record in the `voice_trip_logs` Supabase table.
struct VoiceTripLog: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var tripId: UUID
    var driverId: UUID?
    var transcription: String
    var extractedLocation: String?
    var extractedMileage: Double?
    var extractedETA: String?
    var extractedStatus: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case tripId           = "trip_id"
        case driverId         = "driver_id"
        case transcription
        case extractedLocation = "extracted_location"
        case extractedMileage  = "extracted_mileage"
        case extractedETA      = "extracted_eta"
        case extractedStatus   = "extracted_status"
        case createdAt         = "created_at"
    }

    /// Typed status parsed from the stored raw string.
    var voiceLogStatus: VoiceLogStatus? {
        guard let raw = extractedStatus else { return nil }
        return VoiceLogStatus(rawValue: raw)
    }
}

//  MARK: - VehicleInspection
struct VehicleInspection: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var vehicleId: UUID // FK
  var driverId: UUID? // FK
  var tripId: UUID? // FK
  var inspectionType: InspectionType?
  var notes: String?
  var createdAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case driverId = "driver_id"
      case tripId = "trip_id"
      case inspectionType = "inspection_type"
      case notes
      case createdAt = "created_at"
  }
}

//  MARK: - InspectionPhoto
struct InspectionPhoto: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var inspectionId: UUID // FK
  var imageUrl: String?

  enum CodingKeys: String, CodingKey {
      case id
      case inspectionId = "inspection_id"
      case imageUrl = "image_url"
  }
}

//  MARK: - DefectReport
struct DefectReport: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var inspectionId: UUID // FK - required
  var reportedBy: UUID? // FK
  var description: String // required
  var severity: DefectSeverity?
  var status: DefectStatus?
  var createdAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case inspectionId = "inspection_id"
      case reportedBy = "reported_by"
      case description, severity, status
      case createdAt = "created_at"
  }
}

//  MARK: - Geofence
struct Geofence: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var zoneName: String?
  var zoneType: GeofenceZoneType?
  var coordinates: String?

  enum CodingKeys: String, CodingKey {
      case id
      case zoneName = "zone_name"
      case zoneType = "zone_type"
      case coordinates
  }
}

//  MARK: - GeofenceEvent
struct GeofenceEvent: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var geofenceId: UUID //FK
  var vehicleId: UUID //FK
  var eventType: GeofenceEventType?
  var triggeredAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case geofenceId = "geofence_id"
      case vehicleId = "vehicle_id"
      case eventType = "event_type"
      case triggeredAt = "triggered_at"
  }
}

//  MARK: - Notification
struct Notification: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var userId: UUID // FK
  var title: String?
  var message: String?
  var type: NotificationType?
  var isRead: Bool
  var referenceId: UUID?
  var createdAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case userId = "user_id"
      case title, message, type
      case isRead = "is_read"
      case referenceId = "reference_id"
      case createdAt = "created_at"
  }
}

//  MARK: - Message
struct Message: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var senderId: UUID // FK
  var receiverId: UUID // FK
  var message: String?
  var sentAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case senderId = "sender_id"
      case receiverId = "receiver_id"
      case message
      case sentAt = "sent_at"
  }
}

//  MARK: - Report
struct Report: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var generatedBy: UUID // FK
  var reportType: ReportType?
  var fileUrl: String?
  var createdAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case generatedBy = "generated_by"
      case reportType = "report_type"
      case fileUrl = "file_url"
      case createdAt = "created_at"
  }
}

//  MARK: - FuelLog
struct FuelLog: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var vehicleId: UUID // FK
  var driverId: UUID? // FK
  var litersUsed: Double?
  var fuelCost: Double?
  var recordedAt: Date?
  var billUrl: String? // URL of receipt photo in `fuel` storage bucket

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case driverId = "driver_id"
      case litersUsed = "liters_used"
      case fuelCost = "fuel_cost"
      case recordedAt = "recorded_at"
      case billUrl = "bill_url"
  }
}

// MARK: - Profile (linked to auth.users via Supabase Auth)
struct Profile: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var fullName: String
    var email: String
    var phone: String?
    var licenseNumber: String?
    var role: String // "fleet_manager", "driver", "maintenance"
    var status: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case phone
        case licenseNumber = "license_number"
        case role
        case status
        case createdAt = "created_at"
    }

    var userStatus: UserStatus? {
        guard let status else { return nil }
        return UserStatus(rawValue: status)
    }
}

// MARK: - IssueReportRecord (maps to issue_reports table)
struct IssueReportRecord: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var vehicleId: UUID
    var reportedBy: UUID
    var category: String
    var severity: String
    var description: String?
    var status: String
    var assignedTo: UUID?
    var createdAt: Date?
    var issuePhoto: String?   // comma-separated public URLs

    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId  = "vehicle_id"
        case reportedBy = "reported_by"
        case category
        case severity
        case description
        case status
        case assignedTo = "assigned_to"
        case createdAt  = "created_at"
        case issuePhoto = "issue_photo"
    }
}

// MARK: - DriverRecord (maps to drivers table)
struct DriverRecord: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var profileId: UUID
    var licenseNumber: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case licenseNumber = "license_number"
        case createdAt = "created_at"
    }
}

// MARK: - MaintenanceStaffRecord (maps to maintenance_staff table)
struct MaintenanceStaffRecord: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var profileId: UUID
    var specialization: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case specialization
        case createdAt = "created_at"
    }
}

// MARK: - Geofence models

/// A circular zone around a pickup or dropoff location.
/// Radius is stored so it can be changed per-trip in future.
struct TripGeofence: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var tripId: UUID
    var vehicleId: UUID
    var driverId: UUID?
    var name: String            // human-readable address
    var latitude: Double
    var longitude: Double
    var radiusMeters: Double    // default 5000 = 5 km
    var zoneType: String        // "pickup" | "dropoff"
    var isActive: Bool
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude
        case tripId       = "trip_id"
        case vehicleId    = "vehicle_id"
        case driverId     = "driver_id"
        case radiusMeters = "radius_meters"
        case zoneType     = "zone_type"
        case isActive     = "is_active"
        case createdAt    = "created_at"
    }
}

/// Logged when the driver crosses a zone boundary or completes a stage.
struct TripGeofenceEvent: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var geofenceId: UUID
    var vehicleId: UUID
    var driverId: UUID?
    var eventType: String       // "enter" | "exit" | "pickup_done"
    var occurredAt: Date?
    var latitude: Double?       // driver's location when event fired
    var longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude
        case geofenceId = "geofence_id"
        case vehicleId  = "vehicle_id"
        case driverId   = "driver_id"
        case eventType  = "event_type"
        case occurredAt = "occurred_at"
    }
}
