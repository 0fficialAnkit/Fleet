import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle
    let viewModel: VehiclesViewModel

    @State private var isShowingEdit = false
    @State private var deleteError: String?
    @Environment(\.dismiss) private var dismiss

    var driverName: String {
        viewModel.getDriver(for: vehicle.assignedDriverId)?.fullName ?? "Unassigned"
    }

    var vehicleIcon: String {
        guard let type = vehicle.vehicleType else { return "truck.box" }
        switch type {
        case .twoWheeler:   return "scooter"
        case .threeWheeler: return "car.2"
        case .car:          return "car"
        case .truck:        return "truck.box"
        }
    }

    var body: some View {
        List {
            // Header — icon + name + plate
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.teal.opacity(0.1))
                                .frame(width: 72, height: 72)
                            Image(systemName: vehicleIcon)
                                .font(.system(size: 30, weight: .medium))
                                .foregroundStyle(.teal)
                        }
                        Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                            .font(.title2.bold())
                        StatusBadge(text: vehicle.licensePlate ?? "No Plate", color: .teal)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            // Vehicle info
            Section("Details") {
                InfoRow(icon: "building.2",    label: "Manufacturer",   value: vehicle.make ?? "N/A")
                InfoRow(icon: "tag",           label: "Model",           value: vehicle.model ?? "N/A")
                InfoRow(icon: "number",        label: "License Plate",   value: vehicle.licensePlate ?? "N/A")
                InfoRow(icon: "calendar",      label: "Year",            value: vehicle.year.map(String.init) ?? "N/A")
                InfoRow(icon: "fuelpump",      label: "Tank",            value: vehicle.tankCapacity.map { "\(String(format: "%.0f", $0)) L" } ?? "N/A")
                InfoRow(icon: "gauge.open.with.lines.needle.33percent", label: "Mileage",
                        value: vehicle.mileage.map { "\(String(format: "%.1f", $0)) km/L" } ?? "N/A")
                InfoRow(icon: "creditcard",    label: "Purchase Date",   value: vehicle.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
            }

            // Assigned driver
            Section("Driver") {
                Label(driverName, systemImage: "person.fill")
                    .foregroundStyle(vehicle.assignedDriverId != nil ? .primary : .secondary)
            }

            // Compliance
            Section("Compliance & Reminders") {
                VehicleComplianceSection(vehicle: vehicle, editable: true)
            }

            // Usage report
            Section("Analytics") {
                NavigationLink(destination: VehicleReportView(vehicle: vehicle)) {
                    Label("View Usage Report", systemImage: "chart.bar.xaxis")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { isShowingEdit = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        Task {
                            do {
                                try await viewModel.deleteVehicle(vehicle)
                                dismiss()
                            } catch {
                                deleteError = error.localizedDescription
                            }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.black)
                }
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            EditVehicleView(viewModel: viewModel, vehicle: vehicle)
        }
        .alert("Unable to Delete", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let msg = deleteError { Text(msg) }
        }
    }
}
