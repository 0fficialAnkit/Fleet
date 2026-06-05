import SwiftUI
import Supabase

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct VehicleReportView: View {
    let vehicle: Vehicle
    @State private var viewModel: VehicleReportViewModel
    @State private var selectedTab = ReportTab.overview
    
    @State private var ordersViewModel = OrdersViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var invoiceToView: IdentifiableURL?
    
    enum ReportTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case fuel = "Fuel"
        case maintenance = "Maintenance"
        case trips = "Trips"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.xaxis"
            case .fuel: return "fuelpump.fill"
            case .maintenance: return "wrench.and.screwdriver.fill"
            case .trips: return "map.fill"
            }
        }
    }
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._viewModel = State(initialValue: VehicleReportViewModel(vehicle: vehicle))
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Native Picker Segmented Control
                Picker("Tab Selection", selection: $selectedTab) {
                    ForEach(ReportTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // Tab Content
                Group {
                    if viewModel.isLoading && viewModel.fuelLogs.isEmpty && viewModel.trips.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView("Loading report data...")
                                .tint(.teal)
                            Spacer()
                        }
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.red)
                            Text("Failed to Load Data")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Button {
                                Task { await viewModel.loadData() }
                            } label: {
                                Text("Retry")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(Color.teal)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                    } else {
                        switch selectedTab {
                        case .overview:
                            overviewTabContent
                        case .fuel:
                            fuelTabContent
                        case .maintenance:
                            maintenanceTabContent
                        case .trips:
                            tripsTabContent
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Vehicle Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let adminId = authViewModel.currentUser?.id {
                ordersViewModel.adminId = adminId
                async let _ = ordersViewModel.loadData()
            }
            await viewModel.loadData()
            viewModel.setupRealtime()
        }
        .refreshable {
            await viewModel.loadData()
            await ordersViewModel.loadData()
        }
        .fullScreenCover(item: $invoiceToView) { item in
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    AsyncImage(url: item.url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .failure:
                            VStack {
                                Image(systemName: "photo.slash")
                                    .font(.largeTitle)
                                Text("Failed to load image")
                            }
                            .foregroundStyle(.gray)
                        default:
                            ProgressView().tint(.white)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            invoiceToView = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .toolbarBackground(.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
    }
    

    
    // MARK: - Overview Tab
    
    private var overviewTabContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Section: Fuel Analytics
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Fuel Analytics Summary")
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricBlock(
                            icon: "fuelpump.fill",
                            value: String(format: "₹%.2f", viewModel.totalFuelCost),
                            label: "Total Spent",
                            color: .green
                        )
                        MetricBlock(
                            icon: "drop.fill",
                            value: String(format: "%.1f L", viewModel.totalLitersUsed),
                            label: "Total Fuel Used",
                            color: .orange
                        )
                        MetricBlock(
                            icon: "indianrupeesign.circle.fill",
                            value: String(format: "₹%.2f/L", viewModel.averageFuelPricePerLiter),
                            label: "Avg Fuel Price",
                            color: .blue
                        )
                        MetricBlock(
                            icon: "gauge.open.with.lines.needle.33percent",
                            value: vehicle.mileage != nil ? String(format: "%.1f km/L", vehicle.mileage!) : "N/A",
                            label: "Mileage Rate",
                            color: .purple
                        )
                    }
                }
                .padding(.horizontal, 16)
                
                // Section: Maintenance summary
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Maintenance Status")
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricBlock(
                            icon: "wrench.and.screwdriver.fill",
                            value: "\(viewModel.activeMaintenanceCount)",
                            label: "Active Issues",
                            color: .orange
                        )
                        MetricBlock(
                            icon: "checkmark.circle.fill",
                            value: "\(viewModel.completedMaintenanceCount)",
                            label: "Resolved Issues",
                            color: .green
                        )
                        MetricBlock(
                            icon: "creditcard.fill",
                            value: String(format: "₹%.2f", viewModel.totalMaintenanceCost),
                            label: "Total Repair Cost",
                            color: .red
                        )
                        MetricBlock(
                            icon: "building.2.fill",
                            value: vehicle.status == .maintenance ? "In Service" : "Active Fleet",
                            label: "Fleet Status",
                            color: vehicle.status == .maintenance ? .orange : .teal
                        )
                    }
                }
                .padding(.horizontal, 16)
                
                // Section: Operations
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Operational History")
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricBlock(
                            icon: "map.fill",
                            value: "\(viewModel.totalTripsCount)",
                            label: "Trips Logged",
                            color: .blue
                        )
                        MetricBlock(
                            icon: "arrow.triangle.pull.to.value",
                            value: String(format: "%.1f km", viewModel.totalDistanceTraveled),
                            label: "Total Distance",
                            color: .indigo
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Fuel Tab
    
    private var fuelTabContent: some View {
        Group {
            if viewModel.fuelLogs.isEmpty {
                emptyHistoryView(icon: "fuelpump", title: "No Fuel Logs Found", subtitle: "There are no recorded fuel logs for this vehicle.")
            } else {
                List {
                    ForEach(viewModel.fuelLogs) { log in
                        fuelLogRow(log)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private func fuelLogRow(_ log: FuelLog) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.recordedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown Date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.driverName(for: log.driverId))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "₹%.2f", log.fuelCost ?? 0))
                        .font(.body.bold())
                        .foregroundStyle(Color.primary)
                    
                    Text(String(format: "%.2f Liters", log.litersUsed ?? 0))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.teal)
                }
            }
            
            if let billUrl = log.billUrl, let url = URL(string: billUrl) {
                Divider().background(Color(.separator))
                
                HStack {
                    Spacer()
                    Button {
                        invoiceToView = IdentifiableURL(url: url)
                    } label: {
                        Label("View Receipt / Invoice", systemImage: "doc.text.viewfinder")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.teal)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Maintenance Tab
    
    private var maintenanceTabContent: some View {
        Group {
            if viewModel.activeMaintenanceTasks.isEmpty && viewModel.maintenanceHistories.isEmpty {
                emptyHistoryView(icon: "wrench.and.screwdriver", title: "No Maintenance Found", subtitle: "No current tasks or past maintenance history exists.")
            } else {
                List {
                    if !viewModel.activeMaintenanceTasks.isEmpty {
                        Section("Active & Scheduled Tasks") {
                            ForEach(viewModel.activeMaintenanceTasks) { task in
                                maintenanceTaskRow(task)
                            }
                        }
                    }
                    
                    if !viewModel.maintenanceHistories.isEmpty {
                        Section("Completed Service Logs") {
                            ForEach(viewModel.maintenanceHistories) { history in
                                maintenanceHistoryRow(history)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private func maintenanceTaskRow(_ task: MaintenanceTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.taskType?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "General Service")
                    .font(.body.weight(.semibold))
                Spacer()
                StatusBadge(
                    text: task.status?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "PENDING",
                    color: taskStatusColor(for: task.status)
                )
            }
            
            if let desc = task.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Divider().background(Color(.separator))
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("Staff: \(viewModel.staffName(for: task.assignedTo))")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                if let date = task.scheduledDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func maintenanceHistoryRow(_ history: MaintenanceHistory) -> some View {
        let rawText = history.serviceDetails ?? "Completed Maintenance"
        let parts = rawText.components(separatedBy: "[Photos]")
        let detailsText = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? rawText
        
        let photoUrls: [URL]
        if parts.count > 1 {
            let lines = parts[1].components(separatedBy: .newlines)
            photoUrls = lines.compactMap { line -> URL? in
                let cleaned = line.replacingOccurrences(of: "- ", with: "").trimmingCharacters(in: .whitespaces)
                guard cleaned.hasPrefix("http") else { return nil }
                return URL(string: cleaned)
            }
        } else {
            photoUrls = []
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(detailsText)
                        .font(.subheadline)
                    
                    Text("Date: \(history.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let cost = history.cost {
                    Text(String(format: "₹%.2f", cost))
                        .font(.body.bold())
                        .foregroundStyle(.red)
                }
            }
            
            if !photoUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photoUrls, id: \.self) { url in
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Color(.secondarySystemBackground)
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(ProgressView())
                                }
                            }
                            .onTapGesture {
                                invoiceToView = IdentifiableURL(url: url)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Trips Tab
    
    private var tripsTabContent: some View {
        Group {
            if viewModel.trips.isEmpty {
                emptyHistoryView(icon: "map", title: "No Trips Found", subtitle: "There are no logged trips for this vehicle.")
            } else {
                List {
                    ForEach(viewModel.trips) { trip in
                        NavigationLink(destination: OrderDetailView(trip: trip, viewModel: ordersViewModel)) {
                            tripRow(trip)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private func tripRow(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text(String(format: "%.1f km", viewModel.distanceForTrip(trip)))
                        .font(.body.bold())
                } icon: {
                    Image(systemName: "map.fill")
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                StatusBadge(
                    text: trip.status?.rawValue.capitalized ?? "Completed",
                    color: tripStatusColor(for: trip.status)
                )
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Driver: \(viewModel.driverName(for: trip.driverId))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let start = trip.startTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Started: \(start.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Shared Empty History Helper
    
    private func emptyHistoryView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Color(.tertiaryLabel))
            
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.secondary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .padding(.vertical, 32)
    }
    
    // MARK: - Color and Icon Helpers
    
    private var vehicleIcon: String {
        switch vehicle.vehicleType {
        case .twoWheeler: return "bicycle"
        case .threeWheeler: return "car.2.fill"
        case .car: return "car.fill"
        case .truck: return "truck.box.fill"
        case nil: return "truck.box.fill"
        }
    }
    
    private func statusColor(for status: VehicleStatus?) -> Color {
        switch status {
        case .active: return .green
        case .inactive: return .red
        case .maintenance: return .orange
        case nil: return .secondary
        }
    }
    
    private func taskStatusColor(for status: MaintenanceTaskStatus?) -> Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .cancelled: return .gray
        case nil: return .orange
        }
    }
    
    private func tripStatusColor(for status: TripStatus?) -> Color {
        switch status {
        case .scheduled: return .orange
        case .active: return .blue
        case .completed: return .green
        case .cancelled: return .red
        case nil: return .green
        }
    }
}

// MARK: - Local Custom MetricBlock UI Component

struct MetricBlock: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Spacer()
            }
            
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color(.secondaryLabel))
                .lineLimit(1)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.015), radius: 3, x: 0, y: 1)
    }
}
