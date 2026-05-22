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
  case active = "active"
  case inactive = "inactive"
  case maintenance = "maintenance"
}

enum MaintenanceTaskStatus: String, Codable, CaseIterable, Sendable {
  case pending = "pending"
  case inProgress = "in_progress"
  case completed = "completed"
  case cancelled = "cancelled"
}

enum WorkOrderStatus: String, Codable, CaseIterable, Sendable {
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

enum InspectionType: String, Codable, CaseIterable, Sendable {
  case preTrip = "pre_trip"
  case postTrip = "post_trip"
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
  var passwordHash: String
  var phone: String?
  var licenseNumber: String?
  var roleId: UUID //FK
  var status: UserStatus?
  var createdAt: Date?

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
  var status: VehicleStatus?

  enum CodingKeys: String, CodingKey {
      case id, make, model, year, vin
      case licensePlate = "license_plate"
      case tankCapacity = "tank_capacity"
      case mileage
      case purchaseDate = "purchase_date"
      case assignedDriverId = "assigned_driver_id"
      case status
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
struct MaintenanceTask: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var vehicleId: UUID // FK
  var scheduledBy: UUID? // FK
  var assignedTo: UUID? // FK
  var taskType: MaintenanceTaskType?
  var description: String?
  var scheduledDate: Date?
  var status: MaintenanceTaskStatus?

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case scheduledBy = "scheduled_by"
      case assignedTo = "assigned_to"
      case taskType = "task_type"
      case description
      case scheduledDate = "scheduled_date"
      case status
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

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case createdBy = "created_by"
      case assignedTo = "assigned_to"
      case priority, status
      case createdAt = "created_at"
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

  enum CodingKeys: String, CodingKey {
      case id
      case routeName = "route_name"
      case startLocation = "start_location"
      case endLocation = "end_location"
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

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case driverId = "driver_id"
      case routeId = "route_id"
      case startTime = "start_time"
      case endTime = "end_time"
      case distance, status
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
  var inspectionId: UUID // FK
  var reportedBy: UUID? // FK
  var description: String?
  var severity: DefectSeverity?
  var status: DefectStatus?

  enum CodingKeys: String, CodingKey {
      case id
      case inspectionId = "inspection_id"
      case reportedBy = "reported_by"
      case description, severity, status
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
  var createdAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case userId = "user_id"
      case title, message, type
      case isRead = "is_read"
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

  enum CodingKeys: String, CodingKey {
      case id
      case vehicleId = "vehicle_id"
      case driverId = "driver_id"
      case litersUsed = "liters_used"
      case fuelCost = "fuel_cost"
      case recordedAt = "recorded_at"
  }
}

// MARK: - Support Ticket System

enum TicketCategory: String, Codable, CaseIterable, Sendable {
  case vehicleIssue = "vehicle_issue"
  case routeProblem = "route_problem"
  case tripUpdate = "trip_update"
  case documentRequest = "document_request"
  case other = "other"
}

enum TicketStatus: String, Codable, CaseIterable, Sendable {
  case open = "open"
  case inProgress = "in_progress"
  case resolved = "resolved"
  case closed = "closed"
}

struct SupportTicket: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var driverId: UUID
  var managerId: UUID?
  var category: TicketCategory?
  var subject: String?
  var status: TicketStatus?
  var createdAt: Date?
  var updatedAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case driverId = "driver_id"
      case managerId = "manager_id"
      case category, subject, status
      case createdAt = "created_at"
      case updatedAt = "updated_at"
  }
}

struct TicketMessage: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  var ticketId: UUID
  var senderId: UUID
  var message: String?
  var sentAt: Date?

  enum CodingKeys: String, CodingKey {
      case id
      case ticketId = "ticket_id"
      case senderId = "sender_id"
      case message
      case sentAt = "sent_at"
  }
}

