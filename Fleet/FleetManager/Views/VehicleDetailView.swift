import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle
    let viewModel: VehiclesViewModel

    @State private var isShowingEdit = false
    @State private var deleteError: String?
    @State private var maintenanceHistory: [MaintenanceHistory] = []
    @Environment(\.dismiss) private var dismiss

    // Always read from viewModel so edits propagate instantly throughout the app
    private var v: Vehicle {
        viewModel.vehicles.first(where: { $0.id == vehicle.id }) ?? vehicle
    }

    var driverName: String {
        viewModel.getDriver(for: v.assignedDriverId)?.fullName ?? "Unassigned"
    }

    var pastTrips: [Trip] {
        viewModel.getPastTrips(for: v.id)
    }

    var totalKmTravelled: Double {
        pastTrips.filter { $0.status == .completed }.compactMap(\.distance).reduce(0, +)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // ── Header ────────────────────────────────────
                    VStack(spacing: 8) {
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.teal)
                            .padding(.bottom, 8)

                        Text("\(v.make ?? "Unknown") \(v.model ?? "")")
                            .font(.title.bold())
                            .foregroundStyle(Color.primary)

                        StatusBadge(text: v.licensePlate ?? "No License Plate", color: Color.teal)
                    }
                    .padding(.top, 32)

                    // ── Vehicle Info Card ─────────────────────────
                    VStack(spacing: 0) {
                        InfoRow(icon: "building.2",   label: "Manufacturer",     value: v.make ?? "N/A")
                        Divider().background(Color(.separator))
                        InfoRow(icon: "tag",           label: "Model",           value: v.model ?? "N/A")
                        Divider().background(Color(.separator))
                        InfoRow(icon: "calendar",      label: "Year",            value: v.year.map(String.init) ?? "N/A")
                        Divider().background(Color(.separator))
                        InfoRow(icon: "fuelpump",      label: "Tank Capacity",   value: v.tankCapacity.map { String(format: "%.1f L", $0) } ?? "N/A")
                        Divider().background(Color(.separator))
                        InfoRow(icon: "gauge.open.with.lines.needle.33percent",
                                               label: "Fuel Economy",   value: v.mileage.map { String(format: "%.1f km/L", $0) } ?? "N/A")
                        Divider().background(Color(.separator))
                        InfoRow(icon: "creditcard",    label: "Purchase Date",   value: v.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                        Divider().background(Color(.separator))
                        InfoRow(icon: "road.lanes",    label: "Total km Travelled",
                                value: totalKmTravelled > 0 ? String(format: "%.1f km", totalKmTravelled) : "No trips yet")
                        if let vin = v.vin, !vin.isEmpty {
                            Divider().background(Color(.separator))
                            InfoRow(icon: "qrcode",    label: "VIN",             value: vin)
                        }
                        if let type = v.vehicleType {
                            Divider().background(Color(.separator))
                            InfoRow(icon: "car.fill",  label: "Vehicle Type",    value: type.displayName)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)

                    // ── Compliance & Reminders ────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Compliance & Reminders")
                            .padding(.horizontal, 16)
                        VehicleComplianceSection(vehicle: v, editable: true)
                            .padding(.horizontal, 16)
                    }

                    // ── Usage Report ──────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Usage Report")
                            .padding(.horizontal, 16)

                        NavigationLink(destination: UsageReportView(vehicle: v, viewModel: viewModel)) {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color.teal.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                    .overlay(Image(systemName: "chart.pie.fill")
                                        .foregroundStyle(Color.teal).font(.system(size: 20)))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View Analytics").font(.headline).foregroundStyle(Color.primary)
                                    Text("Distance, trips, and insights").font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Color(.tertiaryLabel))
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(.horizontal, 16)
                    }

                    // ── Assigned Driver ───────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Current Driver")
                            .padding(.horizontal, 16)
                        HStack(spacing: 16) {
                            Circle().fill(Color.teal.opacity(0.1)).frame(width: 40, height: 40)
                                .overlay(Image(systemName: "person.crop.circle.fill")
                                    .foregroundStyle(Color.teal).font(.system(size: 20)))
                            Text(driverName).font(.body).foregroundStyle(Color.primary)
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 16)
                    }

                    // ── Maintenance History ───────────────────────
                    if !maintenanceHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Maintenance History")
                                .padding(.horizontal, 16)
                            VStack(spacing: 0) {
                                ForEach(Array(maintenanceHistory.enumerated()), id: \.element.id) { idx, record in
                                    if idx > 0 { Divider().background(Color(.separator)) }
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(record.serviceDetails ?? "Service completed")
                                                .font(.body.weight(.medium)).lineLimit(2)
                                            if let date = record.completedAt {
                                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                                    .font(.caption).foregroundStyle(Color.secondary)
                                            }
                                        }
                                        Spacer()
                                        if let cost = record.cost {
                                            Text("₹\(Int(cost))").font(.subheadline.weight(.semibold)).foregroundStyle(Color.teal)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                }
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 16)
                        }
                    }

                    // ── Past Trips ────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Past Trips")
                            .padding(.horizontal, 16)
                        if pastTrips.isEmpty {
                            Text("No past trips recorded.")
                                .font(.subheadline).foregroundStyle(Color.secondary)
                                .padding(.horizontal, 16)
                        } else {
                            ForEach(pastTrips) { trip in
                                TripHistoryRow(trip: trip, viewModel: viewModel)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { isShowingEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) {
                        Task {
                            do { try await viewModel.deleteVehicle(v); dismiss() }
                            catch { deleteError = error.localizedDescription }
                        }
                    } label: { Label("Delete", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis") }
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            EditVehicleView(viewModel: viewModel, vehicle: v)
        }
        .alert("Unable to Delete Vehicle", isPresented: Binding(
            get: { deleteError != nil }, set: { if !$0 { deleteError = nil } }
        )) { Button("OK", role: .cancel) {} } message: { Text(deleteError ?? "") }
        .task {
            let all = (try? await MaintenanceHistoryService.fetchAllHistory()) ?? []
            maintenanceHistory = all.filter { $0.vehicleId == v.id }
                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        }
    }
}

// MARK: - Trip History Row (unchanged)

struct TripHistoryRow: View {
    let trip: Trip
    let viewModel: VehiclesViewModel

    var driverName: String {
        viewModel.getDriver(for: trip.driverId)?.fullName ?? "Unknown Driver"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "map.fill").foregroundStyle(Color.blue)
                Text("Distance: \(String(format: "%.1f", trip.distance ?? 0)) km")
                    .font(.body.bold()).foregroundStyle(Color.primary)
                Spacer()
                Text(trip.endTime?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption).foregroundStyle(Color(.tertiaryLabel))
            }
            HStack {
                Image(systemName: "person.fill").foregroundStyle(Color.secondary).font(.system(size: 14))
                Text("Driver: \(driverName)").font(.subheadline).foregroundStyle(Color.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VehicleDetailView(
            vehicle: Vehicle(id: UUID(), make: "Ford", model: "Transit", year: 2024,
                             vin: "123456789", licensePlate: "FL-99-TR",
                             tankCapacity: 80.0, mileage: 12.4, purchaseDate: Date(),
                             assignedDriverId: nil, adminId: nil, status: .active),
            viewModel: VehiclesViewModel()
        )
    }
}
