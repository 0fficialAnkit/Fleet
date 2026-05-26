import SwiftUI
import Supabase

struct DriverFuelView: View {

    @State private var volume: String = ""
    @State private var price: String = ""
    @State private var showSuccess: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    @State private var viewModel = DriverFuelViewModel()
    @State private var assignedVehicleId: UUID?
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Input Form

                        VStack(alignment: .leading, spacing: 24) {
                            Text("Log Fuel Expense")
                                .font(.title3.bold())
                                .foregroundStyle(Color.primary)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "drop.fill")
                                        .foregroundStyle(Color.secondary)
                                    Text("Fuel Volume (Liters)")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.secondary)
                                }
                                TextField("0.0", text: $volume)
                                    .keyboardType(.decimalPad)
                                    .padding(16)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "indianrupeesign")
                                        .foregroundStyle(Color.secondary)
                                    Text("Total Price Paid")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.secondary)
                                }
                                TextField("0.00", text: $price)
                                    .keyboardType(.decimalPad)
                                    .padding(16)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                            }

                            // Auto-captured Location
                            HStack {
                                Image(systemName: "location.fill.viewfinder")
                                    .foregroundStyle(Color.green)
                                Text("Current Location: Downtown Station")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }

                            Button(action: submitFuelLog) {
                                HStack {
                                    if isSubmitting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "arrow.up.doc")
                                        Text("Submit")
                                    }
                                }
                                    .font(.body.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(volume.isEmpty || price.isEmpty || isSubmitting ? Color(.tertiarySystemFill) : Color.green)
                                    .foregroundColor(volume.isEmpty || price.isEmpty || isSubmitting ? Color(.tertiaryLabel) : Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(volume.isEmpty || price.isEmpty || isSubmitting)
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )

                    if showSuccess {

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.green)
                                Text("Synced with Fleet Manager")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.primary)
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.green.opacity(0.15))
                            .padding(0)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )

                    }

                    // History Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Recent Logs")

                        if viewModel.fuelLogs.isEmpty {
                            Text("No fuel logs recorded yet.")
                                .font(.body)
                                .foregroundStyle(Color.secondary)
                        } else {
                            ForEach(viewModel.fuelLogs) { log in

                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Image(systemName: "drop.fill")
                                                    .foregroundColor(Color.green)
                                                Text("\(String(format: "%.1f", log.litersUsed ?? 0.0)) Liters")
                                                    .font(.headline)
                                                    .foregroundColor(Color.primary)
                                            }
                                            HStack {
                                                Image(systemName: "calendar")
                                                    .foregroundColor(Color.secondary)
                                                Text((log.recordedAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                                    .font(.footnote)
                                                    .foregroundColor(Color.secondary)
                                            }
                                        }

                                        Spacer()

                                        HStack(spacing: 2) {
                                            Image(systemName: "indianrupeesign")
                                                .foregroundColor(Color.secondary)
                                            Text("\(Int(log.fuelCost ?? 0.0))")
                                                .font(.title3.bold())
                                                .foregroundColor(Color.primary)
                                        }
                                    }
                                    .padding(16)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                    )

                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Fuel")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
        .task {
            viewModel.currentUserId = authViewModel.currentUser?.id
            await viewModel.loadData()
            viewModel.setupRealtime()
            // Fetch assigned vehicle
            if let userId = authViewModel.currentUser?.id {
                let vehicle = try? await VehicleService.fetchVehicleForDriver(driverId: userId)
                assignedVehicleId = vehicle?.id
            }
        }
    }

    private func submitFuelLog() {
        let liters = Double(volume) ?? 0.0
        let cost = Double(price) ?? 0.0
        let vehicleId = assignedVehicleId ?? UUID()

        isSubmitting = true
        showSuccess = false
        errorMessage = nil

        Task {
            do {
                try await viewModel.addFuelLog(liters: liters, cost: cost, vehicleId: vehicleId)

                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                    volume = ""
                    price = ""
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    DriverFuelView()
        .environment(AuthViewModel())
}
