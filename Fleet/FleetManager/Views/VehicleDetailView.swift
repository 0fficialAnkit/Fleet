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


    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 8) {
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.teal)
                            .padding(.bottom, 8)

                        Text("\(vehicle.make ?? "Unknown") \(vehicle.model ?? "")")
                            .font(.title.bold())
                            .foregroundStyle(Color.primary)

                        StatusBadge(text: vehicle.licensePlate ?? "No License Plate", color: Color.teal)
                    }
                    .padding(.top, 32)

                    // Vehicle Info Card

                        VStack(spacing: 0) {
                            InfoRow(icon: "building.2", label: "Manufacturer", value: vehicle.make ?? "N/A")
                            Divider().background(Color(.separator))
                            InfoRow(icon: "tag", label: "Model", value: vehicle.model ?? "N/A")
                            Divider().background(Color(.separator))
                            InfoRow(icon: "number", label: "License Plate", value: vehicle.licensePlate ?? "N/A")
                            Divider().background(Color(.separator))
                            InfoRow(icon: "calendar", label: "Year", value: vehicle.year != nil ? String(vehicle.year!) : "N/A")
                            Divider().background(Color(.separator))
                            InfoRow(icon: "fuelpump", label: "Tank Capacity", value: vehicle.tankCapacity != nil ? "\(String(format: "%.1f", vehicle.tankCapacity!)) L" : "N/A")
                            Divider().background(Color(.separator))
                            InfoRow(icon: "gauge.open.with.lines.needle.33percent", label: "Mileage", value: vehicle.mileage != nil ? "\(String(format: "%.1f", vehicle.mileage!)) km/l" : "N/A")
                            Divider().background(Color(.separator))
                            InfoRow(icon: "creditcard", label: "Purchase Date", value: vehicle.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)

                    // Compliance & Reminders
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Compliance & Reminders")
                            .padding(.horizontal, 16)
                        VehicleComplianceSection(vehicle: vehicle, editable: true)
                            .padding(.horizontal, 16)
                    }

                    // Usage Report
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Usage Report")
                            .padding(.horizontal, 16)
                        
                        NavigationLink(destination: VehicleReportView(vehicle: vehicle)) {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color.teal.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "chart.pie.fill")
                                            .foregroundStyle(Color.teal)
                                            .font(.system(size: 20))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View Analytics")
                                        .font(.headline)
                                        .foregroundStyle(Color.primary)
                                    Text("Distance, trips, and insights")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(.horizontal, 16)
                    }

                    // Assigned Driver Card
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Current Driver")
                            .padding(.horizontal, 16)

                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color.teal.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .foregroundStyle(Color.teal)
                                            .font(.system(size: 20))
                                    )

                                Text(driverName)
                                    .font(.body)
                                    .foregroundStyle(Color.primary)

                                Spacer()
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 16)
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
                    Button(action: {
                        isShowingEdit = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: {
                        Task {
                            do {
                                try await viewModel.deleteVehicle(vehicle)
                                dismiss()
                            } catch {
                                deleteError = error.localizedDescription
                            }
                        }
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            EditVehicleView(viewModel: viewModel, vehicle: vehicle)
        }
        .alert("Unable to Delete Vehicle", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let msg = deleteError {
                Text(msg)
            }
        }
    }
}


#Preview {
    NavigationStack {
        VehicleDetailView(
            vehicle: Vehicle(
                id: UUID(),
                make: "Ford",
                model: "Transit",
                year: 2024,
                vin: "123456789",
                licensePlate: "FL-99-TR",
                tankCapacity: 80.0,
                mileage: 12.4,
                purchaseDate: Date(),
                assignedDriverId: nil,
                status: .active
            ),
            viewModel: VehiclesViewModel()
        )
    }
}
