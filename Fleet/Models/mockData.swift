//
//  mockData.swift
//  Fleet
//
//  Created by Ankit Kumar on 19/05/26.
//

import Foundation

// MARK: - Shared date helpers

private let cal = Calendar.current
private func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: Date())! }
private func daysAhead(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: Date())! }
private func hoursAgo(_ n: Int) -> Date { cal.date(byAdding: .hour, value: -n, to: Date())! }
private func minutesAgo(_ n: Int) -> Date { cal.date(byAdding: .minute, value: -n, to: Date())! }

// Roles
private let roleFleetManager  = UUID(uuidString: "11000000-0000-0000-0000-000000000001")!
private let roleDriver         = UUID(uuidString: "11000000-0000-0000-0000-000000000002")!
private let roleMaintenance    = UUID(uuidString: "11000000-0000-0000-0000-000000000003")!

// Users
private let uManager           = UUID(uuidString: "22000000-0000-0000-0000-000000000001")! // fleet manager
private let uDriver1           = UUID(uuidString: "22000000-0000-0000-0000-000000000002")!
private let uDriver2           = UUID(uuidString: "22000000-0000-0000-0000-000000000003")!
private let uDriver3           = UUID(uuidString: "22000000-0000-0000-0000-000000000004")!
private let uMech1             = UUID(uuidString: "22000000-0000-0000-0000-000000000005")! // maintenance
private let uMech2             = UUID(uuidString: "22000000-0000-0000-0000-000000000006")!

// Vehicles
private let vTruck1            = UUID(uuidString: "33000000-0000-0000-0000-000000000001")!
private let vTruck2            = UUID(uuidString: "33000000-0000-0000-0000-000000000002")!
private let vTruck3            = UUID(uuidString: "33000000-0000-0000-0000-000000000003")!
private let vVan1              = UUID(uuidString: "33000000-0000-0000-0000-000000000004")!
private let vEV1               = UUID(uuidString: "33000000-0000-0000-0000-000000000005")!

// Routes
private let rDelhibMumbai      = UUID(uuidString: "44000000-0000-0000-0000-000000000001")!
private let rPuneNagpur        = UUID(uuidString: "44000000-0000-0000-0000-000000000002")!
private let rBengaluruChennai  = UUID(uuidString: "44000000-0000-0000-0000-000000000003")!

// Trips
private let trip1              = UUID(uuidString: "55000000-0000-0000-0000-000000000001")!
private let trip2              = UUID(uuidString: "55000000-0000-0000-0000-000000000002")!
private let trip3              = UUID(uuidString: "55000000-0000-0000-0000-000000000003")!
private let trip4              = UUID(uuidString: "55000000-0000-0000-0000-000000000004")!

// Work Orders
private let wo1                = UUID(uuidString: "66000000-0000-0000-0000-000000000001")!
private let wo2                = UUID(uuidString: "66000000-0000-0000-0000-000000000002")!
private let wo3                = UUID(uuidString: "66000000-0000-0000-0000-000000000003")!
private let wo4                = UUID(uuidString: "66000000-0000-0000-0000-000000000004")!
private let wo5                = UUID(uuidString: "66000000-0000-0000-0000-000000000005")!

// Maintenance Tasks
private let mt1                = UUID(uuidString: "77000000-0000-0000-0000-000000000001")!
private let mt2                = UUID(uuidString: "77000000-0000-0000-0000-000000000002")!
private let mt3                = UUID(uuidString: "77000000-0000-0000-0000-000000000003")!

// Inspections
private let insp1              = UUID(uuidString: "88000000-0000-0000-0000-000000000001")!
private let insp2              = UUID(uuidString: "88000000-0000-0000-0000-000000000002")!
private let insp3              = UUID(uuidString: "88000000-0000-0000-0000-000000000003")!

// Inventory
private let inv1               = UUID(uuidString: "99000000-0000-0000-0000-000000000001")!
private let inv2               = UUID(uuidString: "99000000-0000-0000-0000-000000000002")!
private let inv3               = UUID(uuidString: "99000000-0000-0000-0000-000000000003")!
private let inv4               = UUID(uuidString: "99000000-0000-0000-0000-000000000004")!
private let inv5               = UUID(uuidString: "99000000-0000-0000-0000-000000000005")!

// Geofences
private let gf1                = UUID(uuidString: "AA000000-0000-0000-0000-000000000001")!
private let gf2                = UUID(uuidString: "AA000000-0000-0000-0000-000000000002")!

// Maintenance History
private let mh1                = UUID(uuidString: "BB000000-0000-0000-0000-000000000001")!
private let mh2                = UUID(uuidString: "BB000000-0000-0000-0000-000000000002")!
private let mh3                = UUID(uuidString: "BB000000-0000-0000-0000-000000000003")!

// Defect Reports
private let dr1                = UUID(uuidString: "CC000000-0000-0000-0000-000000000001")!
private let dr2                = UUID(uuidString: "CC000000-0000-0000-0000-000000000002")!
private let dr3                = UUID(uuidString: "CC000000-0000-0000-0000-000000000003")!


enum MockData {

    // MARK: - Roles
    static let roles: [Role] = [
        Role(id: roleFleetManager, roleName: "Fleet Manager"),
        Role(id: roleDriver,       roleName: "Driver"),
        Role(id: roleMaintenance,  roleName: "Maintenance"),
    ]

    // MARK: - Users
    static let users: [User] = [
        User(
            id: uManager,
            fullName: "Ankit Kumar",
            email: "ankit@gmail.com",
            passwordHash: "$2b$12$hashedpassword001",
            phone: "+91-98765-43210",
            roleId: roleFleetManager,
            status: .active,
            createdAt: daysAgo(120)
        ),
        User(
            id: uDriver1,
            fullName: "Ravi Kumar",
            email: "ravi.kumar@fleetpro.in",
            passwordHash: "$2b$12$hashedpassword002",
            phone: "+91-91234-56789",
            roleId: roleDriver,
            status: .active,
            createdAt: daysAgo(90)
        ),
        User(
            id: uDriver2,
            fullName: "Suresh Patil",
            email: "suresh.patil@fleetpro.in",
            passwordHash: "$2b$12$hashedpassword003",
            phone: "+91-97890-12345",
            roleId: roleDriver,
            status: .active,
            createdAt: daysAgo(75)
        ),
        User(
            id: uDriver3,
            fullName: "Deepak Sharma",
            email: "deepak.sharma@fleetpro.in",
            passwordHash: "$2b$12$hashedpassword004",
            phone: "+91-93456-78901",
            roleId: roleDriver,
            status: .inactive,
            createdAt: daysAgo(60)
        ),
        User(
            id: uMech1,
            fullName: "Pradeep Nair",
            email: "pradeep.nair@fleetpro.in",
            passwordHash: "$2b$12$hashedpassword005",
            phone: "+91-94567-89012",
            roleId: roleMaintenance,
            status: .active,
            createdAt: daysAgo(110)
        ),
        User(
            id: uMech2,
            fullName: "Kiran Joshi",
            email: "kiran.joshi@fleetpro.in",
            passwordHash: "$2b$12$hashedpassword006",
            phone: "+91-95678-90123",
            roleId: roleMaintenance,
            status: .active,
            createdAt: daysAgo(85)
        ),
    ]

    // MARK: - Vehicles
    static var vehicles: [Vehicle] = [
        Vehicle(
            id: vTruck1,
            make: "Tata",
            model: "Prima 4028.S",
            year: 2021,
            vin: "MAT445130M8K00001",
            licensePlate: "MH-04-BT-7821",
            assignedDriverId: uDriver1,
            status: .active
        ),
        Vehicle(
            id: vTruck2,
            make: "Ashok Leyland",
            model: "Boss 2518",
            year: 2020,
            vin: "MB1AT5140LBC02234",
            licensePlate: "MH-12-CX-4490",
            assignedDriverId: uDriver2,
            status: .maintenance
        ),
        Vehicle(
            id: vTruck3,
            make: "Mahindra",
            model: "Blazo X 40",
            year: 2022,
            vin: "MA1TC2GX8NM03311",
            licensePlate: "KA-01-PR-9902",
            assignedDriverId: nil,
            status: .active
        ),
        Vehicle(
            id: vVan1,
            make: "Force",
            model: "Traveller 3350",
            year: 2023,
            vin: "MCA6KT1B4PE00891",
            licensePlate: "DL-08-SA-2217",
            assignedDriverId: uDriver3,
            status: .inactive
        ),
        Vehicle(
            id: vEV1,
            make: "Tata",
            model: "Ace EV",
            year: 2024,
            vin: "MAT445EV0P8B00052",
            licensePlate: "MH-14-EV-0033",
            assignedDriverId: uDriver1,
            status: .active
        ),
    ]

    // MARK: - Vehicle Documents
    static let vehicleDocuments: [VehicleDocument] = [
        VehicleDocument(
            id: UUID(),
            vehicleId: vTruck1,
            documentType: .insurance,
            fileUrl: "https://storage.fleetpro.in/docs/insurance_MH04BT7821.pdf",
            expiryDate: daysAhead(180)
        ),
        VehicleDocument(
            id: UUID(),
            vehicleId: vTruck1,
            documentType: .registration,
            fileUrl: "https://storage.fleetpro.in/docs/rc_MH04BT7821.pdf",
            expiryDate: daysAhead(730)
        ),
        VehicleDocument(
            id: UUID(),
            vehicleId: vTruck2,
            documentType: .permit,
            fileUrl: "https://storage.fleetpro.in/docs/permit_MH12CX4490.pdf",
            expiryDate: daysAhead(30)     // expiring soon — triggers alert
        ),
        VehicleDocument(
            id: UUID(),
            vehicleId: vTruck3,
            documentType: .insurance,
            fileUrl: "https://storage.fleetpro.in/docs/insurance_KA01PR9902.pdf",
            expiryDate: daysAgo(5)        // already expired
        ),
        VehicleDocument(
            id: UUID(),
            vehicleId: vEV1,
            documentType: .registration,
            fileUrl: "https://storage.fleetpro.in/docs/rc_MH14EV0033.pdf",
            expiryDate: daysAhead(1095)
        ),
    ]

    // MARK: - Vehicle Locations
    static let vehicleLocations: [VehicleLocation] = [
        VehicleLocation(
            id: UUID(),
            vehicleId: vTruck1,
            latitude: 19.0760,
            longitude: 72.8777,
            speed: 62.4,
            recordedAt: minutesAgo(3)
        ),
        VehicleLocation(
            id: UUID(),
            vehicleId: vTruck2,
            latitude: 18.5204,
            longitude: 73.8567,
            speed: 0.0,           // stationary — in maintenance bay
            recordedAt: minutesAgo(45)
        ),
        VehicleLocation(
            id: UUID(),
            vehicleId: vTruck3,
            latitude: 12.9716,
            longitude: 77.5946,
            speed: 78.1,
            recordedAt: minutesAgo(1)
        ),
        VehicleLocation(
            id: UUID(),
            vehicleId: vVan1,
            latitude: 28.6139,
            longitude: 77.2090,
            speed: 0.0,
            recordedAt: hoursAgo(8)
        ),
        VehicleLocation(
            id: UUID(),
            vehicleId: vEV1,
            latitude: 19.1136,
            longitude: 72.8697,
            speed: 44.5,
            recordedAt: minutesAgo(2)
        ),
    ]

    // MARK: - Routes
    static let routes: [Route] = [
        Route(
            id: rDelhibMumbai,
            routeName: "Delhi - Mumbai Expressway",
            startLocation: "Naraina Industrial Area, New Delhi",
            endLocation: "Bhiwandi Logistics Park, Mumbai"
        ),
        Route(
            id: rPuneNagpur,
            routeName: "Pune - Nagpur Samruddhi",
            startLocation: "Chakan Industrial Zone, Pune",
            endLocation: "Butibori MIDC, Nagpur"
        ),
        Route(
            id: rBengaluruChennai,
            routeName: "Bengaluru - Chennai NH-48",
            startLocation: "Electronic City Phase 2, Bengaluru",
            endLocation: "Sriperumbudur Industrial Corridor, Chennai"
        ),
    ]

    // MARK: - Trips
    static let trips: [Trip] = [
        Trip(
            id: trip1,
            vehicleId: vTruck1,
            driverId: uDriver1,
            routeId: rDelhibMumbai,
            startTime: hoursAgo(6),
            endTime: nil,
            distance: 412.8,
            status: .active
        ),
        Trip(
            id: trip2,
            vehicleId: vTruck3,
            driverId: uDriver2,
            routeId: rBengaluruChennai,
            startTime: daysAgo(1),
            endTime: hoursAgo(2),
            distance: 346.5,
            status: .completed
        ),
        Trip(
            id: trip3,
            vehicleId: vEV1,
            driverId: uDriver1,
            routeId: rPuneNagpur,
            startTime: daysAhead(1),
            endTime: nil,
            distance: nil,
            status: .scheduled
        ),
        Trip(
            id: trip4,
            vehicleId: vVan1,
            driverId: uDriver3,
            routeId: rDelhibMumbai,
            startTime: daysAgo(3),
            endTime: daysAgo(2),
            distance: 498.0,
            status: .cancelled
        ),
    ]

    // MARK: - Trip Updates
    static let tripUpdates: [TripUpdate] = [
        TripUpdate(
            id: UUID(),
            tripId: trip1,
            updateType: .started,
            message: "Trip started from Naraina Industrial Area. Cargo sealed and manifest signed.",
            createdAt: hoursAgo(6)
        ),
        TripUpdate(
            id: UUID(),
            tripId: trip1,
            updateType: .enRoute,
            message: "Crossed Vadodara checkpoint. On schedule.",
            createdAt: hoursAgo(2)
        ),
        TripUpdate(
            id: UUID(),
            tripId: trip1,
            updateType: .delayed,
            message: "Traffic jam near Surat bypass — estimated 45 minute delay.",
            createdAt: hoursAgo(1)
        ),
        TripUpdate(
            id: UUID(),
            tripId: trip2,
            updateType: .completed,
            message: "Delivery confirmed at Sriperumbudur. Recipient signature obtained.",
            createdAt: hoursAgo(2)
        ),
        TripUpdate(
            id: UUID(),
            tripId: trip4,
            updateType: .cancelled,
            message: "Trip cancelled — customer postponed pickup by 5 days.",
            createdAt: daysAgo(3)
        ),
    ]

    // MARK: - Maintenance Tasks
    static let maintenanceTasks: [MaintenanceTask] = [
        MaintenanceTask(
            id: mt1,
            vehicleId: vTruck2,
            scheduledBy: uManager,
            assignedTo: uMech1,
            taskType: .repair,
            description: "Front brake pads worn beyond limit — replace pads on both axles. Inspect rotors for scoring.",
            scheduledDate: daysAgo(2),
            status: .inProgress
        ),
        MaintenanceTask(
            id: mt2,
            vehicleId: vTruck1,
            scheduledBy: uManager,
            assignedTo: uMech2,
            taskType: .oilChange,
            description: "Engine oil change + oil filter replacement at 200,000 km service interval.",
            scheduledDate: daysAhead(3),
            status: .pending
        ),
        MaintenanceTask(
            id: mt3,
            vehicleId: vTruck3,
            scheduledBy: uMech1,
            assignedTo: uMech1,
            taskType: .tireRotation,
            description: "Rotate all 10 tyres and balance. Replace inner duals showing sidewall cracks.",
            scheduledDate: daysAgo(10),
            status: .completed
        ),
    ]

    // MARK: - Work Orders
    static let workOrders: [WorkOrder] = [
        WorkOrder(
            id: wo1,
            vehicleId: vTruck2,
            createdBy: uManager,
            assignedTo: uMech1,
            priority: .high,
            status: .inProgress,
            createdAt: daysAgo(3)
        ),
        WorkOrder(
            id: wo2,
            vehicleId: vTruck1,
            createdBy: uManager,
            assignedTo: uMech2,
            priority: .medium,
            status: .open,
            createdAt: daysAgo(1)
        ),
        WorkOrder(
            id: wo3,
            vehicleId: vTruck3,
            createdBy: uMech1,
            assignedTo: uMech1,
            priority: .low,
            status: .completed,
            createdAt: daysAgo(10)
        ),
        WorkOrder(
            id: wo4,
            vehicleId: vVan1,
            createdBy: uManager,
            assignedTo: uMech2,
            priority: .critical,
            status: .open,
            createdAt: hoursAgo(4)
        ),
        WorkOrder(
            id: wo5,
            vehicleId: vEV1,
            createdBy: uManager,
            assignedTo: uMech1,
            priority: .medium,
            status: .inProgress,
            createdAt: daysAgo(1)
        ),
    ]

    // MARK: - Maintenance History
    static let maintenanceHistory: [MaintenanceHistory] = [
        MaintenanceHistory(
            id: mh1,
            vehicleId: vTruck3,
            workOrderId: wo3,
            serviceDetails: "Tyre rotation completed — all 10 tyres rotated and balanced. 2 inner dual tyres replaced due to sidewall cracking. Wheel alignment set to manufacturer spec.",
            cost: 35000,
            completedAt: daysAgo(8)
        ),
        MaintenanceHistory(
            id: mh2,
            vehicleId: vTruck1,
            workOrderId: nil,
            serviceDetails: "Regular 100,000 km service — oil change, air filter, fuel filter, spark plugs replaced. Battery terminals cleaned.",
            cost: 18500,
            completedAt: daysAgo(45)
        ),
        MaintenanceHistory(
            id: mh3,
            vehicleId: vVan1,
            workOrderId: nil,
            serviceDetails: "AC compressor replaced. Refrigerant recharged to spec. Cabin filter replaced.",
            cost: 22000,
            completedAt: daysAgo(20)
        ),
    ]

    // MARK: - Inventory
    static let inventory: [Inventory] = [
        Inventory(
            id: inv1,
            partName: "Engine Oil — 15W-40 (5L)",
            stockQuantity: 48,
            reorderLevel: 20,
            unitCost: 1250
        ),
        Inventory(
            id: inv2,
            partName: "Brake Pad Set — Front Axle",
            stockQuantity: 6,
            reorderLevel: 8,      // below reorder level — triggers alert
            unitCost: 4800
        ),
        Inventory(
            id: inv3,
            partName: "Oil Filter — Tata Prima",
            stockQuantity: 22,
            reorderLevel: 10,
            unitCost: 380
        ),
        Inventory(
            id: inv4,
            partName: "Air Filter — Heavy Duty",
            stockQuantity: 14,
            reorderLevel: 6,
            unitCost: 620
        ),
        Inventory(
            id: inv5,
            partName: "Tubeless Tyre 295/80 R22.5",
            stockQuantity: 4,
            reorderLevel: 6,      // below reorder level — triggers alert
            unitCost: 18500
        ),
    ]

    // MARK: - Work Order Parts
    static let workOrderParts: [WorkOrderPart] = [
        WorkOrderPart(
            id: UUID(),
            workOrderId: wo1,
            inventoryItemId: inv2,
            quantityUsed: 2,
            hoursSpent: 3.5
        ),
        WorkOrderPart(
            id: UUID(),
            workOrderId: wo2,
            inventoryItemId: inv1,
            quantityUsed: 4,
            hoursSpent: 1.0
        ),
        WorkOrderPart(
            id: UUID(),
            workOrderId: wo2,
            inventoryItemId: inv3,
            quantityUsed: 1,
            hoursSpent: nil
        ),
        WorkOrderPart(
            id: UUID(),
            workOrderId: wo3,
            inventoryItemId: inv5,
            quantityUsed: 2,
            hoursSpent: 5.0
        ),
        WorkOrderPart(
            id: UUID(),
            workOrderId: wo5,
            inventoryItemId: inv4,
            quantityUsed: 1,
            hoursSpent: 2.0
        ),
    ]

    // MARK: - Vehicle Inspections
    static let vehicleInspections: [VehicleInspection] = [
        VehicleInspection(
            id: insp1,
            vehicleId: vTruck1,
            driverId: uDriver1,
            tripId: trip1,
            inspectionType: .preTrip,
            notes: "All lights functional. Tyre pressure checked and topped. Cargo area clean. Brakes responsive.",
            createdAt: hoursAgo(6)
        ),
        VehicleInspection(
            id: insp2,
            vehicleId: vTruck3,
            driverId: uDriver2,
            tripId: trip2,
            inspectionType: .postTrip,
            notes: "Minor oil seepage noticed near engine block — flagged for workshop review. All tyres intact.",
            createdAt: hoursAgo(2)
        ),
        VehicleInspection(
            id: insp3,
            vehicleId: vVan1,
            driverId: uDriver3,
            tripId: trip4,
            inspectionType: .preTrip,
            notes: "Front left indicator not working. Reported to manager before departure.",
            createdAt: daysAgo(3)
        ),
    ]

    // MARK: - Inspection Photos
    static let inspectionPhotos: [InspectionPhoto] = [
        InspectionPhoto(
            id: UUID(),
            inspectionId: insp1,
            imageUrl: "https://storage.fleetpro.in/inspections/insp1_front.jpg"
        ),
        InspectionPhoto(
            id: UUID(),
            inspectionId: insp1,
            imageUrl: "https://storage.fleetpro.in/inspections/insp1_tyres.jpg"
        ),
        InspectionPhoto(
            id: UUID(),
            inspectionId: insp2,
            imageUrl: "https://storage.fleetpro.in/inspections/insp2_oilleak.jpg"
        ),
        InspectionPhoto(
            id: UUID(),
            inspectionId: insp3,
            imageUrl: "https://storage.fleetpro.in/inspections/insp3_indicator.jpg"
        ),
    ]

    // MARK: - Defect Reports
    static let defectReports: [DefectReport] = [
        DefectReport(
            id: dr1,
            inspectionId: insp2,
            reportedBy: uDriver2,
            description: "Engine oil seepage visible near lower gasket area on front-right side. Staining on undercarriage.",
            severity: .medium,
            status: .open
        ),
        DefectReport(
            id: dr2,
            inspectionId: insp3,
            reportedBy: uDriver3,
            description: "Front left turn indicator bulb failure. No flash response. Replacement needed before road use.",
            severity: .high,
            status: .resolved
        ),
        DefectReport(
            id: dr3,
            inspectionId: insp1,
            reportedBy: uDriver1,
            description: "Minor crack on rear mudguard — cosmetic damage only, does not affect vehicle operation.",
            severity: .low,
            status: .closed
        ),
    ]

    // MARK: - Geofences
    static let geofences: [Geofence] = [
        Geofence(
            id: gf1,
            zoneName: "Bhiwandi Warehouse Complex",
            zoneType: .allowed,
            coordinates: "19.2814,73.0483,19.2956,73.0621"   // bounding box lat,lng pairs
        ),
        Geofence(
            id: gf2,
            zoneName: "Restricted Industrial Zone — Chakan",
            zoneType: .restricted,
            coordinates: "18.7590,73.8517,18.7702,73.8634"
        ),
    ]

    // MARK: - Geofence Events
    static let geofenceEvents: [GeofenceEvent] = [
        GeofenceEvent(
            id: UUID(),
            geofenceId: gf1,
            vehicleId: vTruck1,
            eventType: .enter,
            triggeredAt: hoursAgo(5)
        ),
        GeofenceEvent(
            id: UUID(),
            geofenceId: gf1,
            vehicleId: vTruck1,
            eventType: .exit,
            triggeredAt: hoursAgo(4)
        ),
        GeofenceEvent(
            id: UUID(),
            geofenceId: gf2,
            vehicleId: vTruck3,
            eventType: .enter,
            triggeredAt: daysAgo(1)    // triggered alert
        ),
    ]

    // MARK: - Notifications
    static let notifications: [Notification] = [
        Notification(
            id: UUID(),
            userId: uManager,
            title: "SOS Alert — Ravi Kumar",
            message: "Driver Ravi Kumar triggered SOS near Surat bypass (NH-48). Coordinates: 21.1702° N, 72.8311° E.",
            type: .alert,
            isRead: false,
            createdAt: hoursAgo(1)
        ),
        Notification(
            id: UUID(),
            userId: uManager,
            title: "Document Expiry — MH-12-CX-4490",
            message: "Permit for vehicle MH-12-CX-4490 expires in 30 days. Please renew before it lapses.",
            type: .warning,
            isRead: false,
            createdAt: hoursAgo(3)
        ),
        Notification(
            id: UUID(),
            userId: uMech1,
            title: "Work Order Assigned — WO-001",
            message: "You have been assigned work order WO-001: Brake pad replacement on Ashok Leyland Boss 2518.",
            type: .maintenance,
            isRead: true,
            createdAt: daysAgo(3)
        ),
        Notification(
            id: UUID(),
            userId: uDriver1,
            title: "Trip Scheduled",
            message: "New trip scheduled for tomorrow. Route: Pune to Nagpur via Samruddhi Expressway. Departure: 06:00.",
            type: .info,
            isRead: true,
            createdAt: daysAgo(1)
        ),
        Notification(
            id: UUID(),
            userId: uManager,
            title: "Restricted Zone Entry — KA-01-PR-9902",
            message: "Vehicle KA-01-PR-9902 entered restricted zone at Chakan Industrial Area. Review required.",
            type: .alert,
            isRead: false,
            createdAt: daysAgo(1)
        ),
        Notification(
            id: UUID(),
            userId: uMech2,
            title: "Low Inventory — Brake Pad Sets",
            message: "Brake Pad Set (Front Axle) stock is at 6 units — below reorder level of 8. Please raise a purchase request.",
            type: .warning,
            isRead: false,
            createdAt: hoursAgo(2)
        ),
    ]

    // MARK: - Messages
    static let messages: [Message] = [
        Message(
            id: UUID(),
            senderId: uDriver1,
            receiverId: uManager,
            message: "Heavy traffic near Surat — expecting 45 min delay. Will update once I clear the bypass.",
            sentAt: hoursAgo(1)
        ),
        Message(
            id: UUID(),
            senderId: uManager,
            receiverId: uDriver1,
            message: "Acknowledged. Please share live location and call if delay exceeds 2 hours.",
            sentAt: minutesAgo(55)
        ),
        Message(
            id: UUID(),
            senderId: uDriver2,
            receiverId: uManager,
            message: "Delivery at Sriperumbudur completed. Recipient signed the manifest. Heading back now.",
            sentAt: hoursAgo(2)
        ),
        Message(
            id: UUID(),
            senderId: uMech1,
            receiverId: uManager,
            message: "Brake pad replacement on MH-12-CX-4490 will take another 2 hours. Rotors needed re-surfacing.",
            sentAt: hoursAgo(3)
        ),
    ]

    // MARK: - Reports
    static let reports: [Report] = [
        Report(
            id: UUID(),
            generatedBy: uManager,
            reportType: .trip,
            fileUrl: "https://storage.fleetpro.in/reports/trip_report_may2026.pdf",
            createdAt: daysAgo(1)
        ),
        Report(
            id: UUID(),
            generatedBy: uManager,
            reportType: .fuel,
            fileUrl: "https://storage.fleetpro.in/reports/fuel_report_may2026.csv",
            createdAt: daysAgo(2)
        ),
        Report(
            id: UUID(),
            generatedBy: uMech1,
            reportType: .maintenance,
            fileUrl: "https://storage.fleetpro.in/reports/maintenance_report_apr2026.pdf",
            createdAt: daysAgo(15)
        ),
        Report(
            id: UUID(),
            generatedBy: uManager,
            reportType: .inspection,
            fileUrl: "https://storage.fleetpro.in/reports/inspection_report_may2026.pdf",
            createdAt: daysAgo(3)
        ),
        Report(
            id: UUID(),
            generatedBy: uManager,
            reportType: .defect,
            fileUrl: "https://storage.fleetpro.in/reports/defect_report_may2026.pdf",
            createdAt: daysAgo(1)
        ),
    ]

    // MARK: - Fuel Logs
    static let fuelLogs: [FuelLog] = [
        FuelLog(
            id: UUID(),
            vehicleId: vTruck1,
            driverId: uDriver1,
            litersUsed: 85.4,
            fuelCost: 8881.6,
            recordedAt: hoursAgo(5)
        ),
        FuelLog(
            id: UUID(),
            vehicleId: vTruck3,
            driverId: uDriver2,
            litersUsed: 62.0,
            fuelCost: 6448.0,
            recordedAt: daysAgo(1)
        ),
        FuelLog(
            id: UUID(),
            vehicleId: vTruck2,
            driverId: uDriver2,
            litersUsed: 93.5,
            fuelCost: 9724.0,
            recordedAt: daysAgo(4)
        ),
        FuelLog(
            id: UUID(),
            vehicleId: vEV1,
            driverId: uDriver1,
            litersUsed: 0,        // EV — no fuel, units represent kWh charged
            fuelCost: 420.0,      // charging cost
            recordedAt: daysAgo(1)
        ),
        FuelLog(
            id: UUID(),
            vehicleId: vVan1,
            driverId: uDriver3,
            litersUsed: 44.2,
            fuelCost: 4596.8,
            recordedAt: daysAgo(3)
        ),
    ]
}
