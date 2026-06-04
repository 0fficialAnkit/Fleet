// ESGService.swift
// Fleet
//
// Service for calculating Carbon Footprint and ESG Metrics.

import Foundation

enum ESGService {
    
    // Baseline CO2 emissions per kilometer based on vehicle type (in kg)
    // Estimates: 
    // Two Wheeler: 0.05 kg/km
    // Three Wheeler: 0.08 kg/km
    // Car: 0.12 kg/km
    // Truck: 1.05 kg/km
    static func baselineEmissionsPerKm(for vehicleType: VehicleType?) -> Double {
        guard let type = vehicleType else { return 0.2 } // default average
        switch type {
        case .twoWheeler: return 0.05
        case .threeWheeler: return 0.08
        case .car: return 0.12
        case .truck: return 1.05
        }
    }
    
    /// Calculate CO2 emissions for a specific trip
    /// - Parameters:
    ///   - trip: The trip to evaluate
    ///   - vehicle: The vehicle used for the trip
    ///   - fuelLog: Optional fuel log associated with this trip timeframe
    /// - Returns: CO2 emissions in kg
    static func calculateEmissions(for trip: Trip, vehicle: Vehicle, fuelLog: FuelLog? = nil) -> Double {
        if let log = fuelLog, let liters = log.litersUsed, liters > 0 {
            // Precise calculation: 1 Liter of fuel produces ~2.68 kg of CO2
            // We apportion this if we assume the fuel was purely for this trip.
            // For simplicity, if we have a direct fuel log for a trip, we can use it.
            return liters * 2.68
        }
        
        // Estimate based on distance
        let distance = trip.distance ?? 0.0
        return distance * baselineEmissionsPerKm(for: vehicle.vehicleType)
    }
    
    /// Generates total ESG metrics for a fleet
    static func generateFleetMetrics(trips: [Trip], vehicles: [Vehicle], fuelLogs: [FuelLog]) -> FleetESGMetrics {
        var totalEmissions = 0.0
        var totalDistance = 0.0
        var emissionsByVehicleType: [VehicleType: Double] = [:]
        
        for trip in trips {
            guard let vehicle = vehicles.first(where: { $0.id == trip.vehicleId }) else { continue }
            
            // In a real app, we'd match fuel logs by date/time. Here we rely on estimation if no exact log matches.
            // For simplicity in this USP demonstration, we will rely on distance estimation.
            let emissions = calculateEmissions(for: trip, vehicle: vehicle)
            
            totalEmissions += emissions
            totalDistance += trip.distance ?? 0.0
            if let type = vehicle.vehicleType {
                emissionsByVehicleType[type, default: 0.0] += emissions
            }
        }
        
        // Recommended limit based on a 20% carbon reduction target relative to the vehicle-specific baseline emissions.
        var totalBaselineEmissions = 0.0
        for trip in trips {
            guard let vehicle = vehicles.first(where: { $0.id == trip.vehicleId }) else { continue }
            let distance = trip.distance ?? 0.0
            totalBaselineEmissions += distance * baselineEmissionsPerKm(for: vehicle.vehicleType)
        }
        let recommendedCO2LimitKg = totalBaselineEmissions > 0 ? totalBaselineEmissions * 1.20 : 150.0
        
        return FleetESGMetrics(
            totalCO2EmissionsKg: totalEmissions,
            recommendedCO2LimitKg: recommendedCO2LimitKg,
            emissionsByVehicleType: emissionsByVehicleType
        )
    }
    
    /// Calculate a driver's carbon score out of 100 based on their recent trips
    static func calculateDriverCarbonScore(driverId: UUID, trips: [Trip], vehicles: [Vehicle]) -> Int {
        let driverTrips = trips.filter { $0.driverId == driverId }
        guard !driverTrips.isEmpty else { return 100 } // Perfect score if no driving history
        
        // A simple algorithm:
        // Score starts at 100. We deduct points for high total emissions relative to distance.
        // For a more advanced algorithm, we would compare against a fleet average.
        var totalDistance = 0.0
        var totalEmissions = 0.0
        
        for trip in driverTrips {
            guard let vehicle = vehicles.first(where: { $0.id == trip.vehicleId }) else { continue }
            totalDistance += trip.distance ?? 0.0
            totalEmissions += calculateEmissions(for: trip, vehicle: vehicle)
        }
        
        guard totalDistance > 0 else { return 100 }
        
        let avgEmissionsPerKm = totalEmissions / totalDistance
        
        // Assuming average fleet emission is ~0.15 kg/km. 
        // If driver is below 0.15, score is high. If above, score drops.
        let targetEmission = 0.15
        
        if avgEmissionsPerKm <= targetEmission {
            return 90 + Int.random(in: 0...10) // 90-100 excellent
        } else {
            let penalty = ((avgEmissionsPerKm - targetEmission) / targetEmission) * 100
            let score = 100 - Int(penalty)
            return max(30, min(100, score)) // clamp between 30 and 100
        }
    }
}

struct FleetESGMetrics {
    let totalCO2EmissionsKg: Double
    let recommendedCO2LimitKg: Double
    let emissionsByVehicleType: [VehicleType: Double]
}
