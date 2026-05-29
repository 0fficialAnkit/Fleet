import SwiftUI

struct InventoryView: View {
    @State private var searchText = ""
    @State private var inventoryItems: [Inventory] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedItem: Inventory? = nil
    @State private var isShowingAddSheet = false
    @State private var selectedFilter: InventoryFilter = .all

    enum InventoryFilter: String, CaseIterable {
        case all = "All"
        case lowStock = "Low Stock"
        case inStock = "In Stock"
    }

    var filteredItems: [Inventory] {
        let base: [Inventory]
        switch selectedFilter {
        case .all:      base = inventoryItems
        case .lowStock: base = inventoryItems.filter { ($0.stockQuantity ?? 0) <= ($0.reorderLevel ?? 0) }
        case .inStock:  base = inventoryItems.filter { ($0.stockQuantity ?? 0) > ($0.reorderLevel ?? 0) }
        }
        if searchText.isEmpty { return base }
        return base.filter { $0.partName?.localizedCaseInsensitiveContains(searchText) == true }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if isLoading && inventoryItems.isEmpty {
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .brown))
                            .scaleEffect(1.1)
                        Text("Loading inventory…")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {

                            // MARK: - AI Forecast Banner
                            HStack(alignment: .center, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.yellow.opacity(0.25), Color.orange.opacity(0.15)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 42, height: 42)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(Color.yellow)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("AI Forecast")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.primary)
                                    Text("High demand for **Oil Filters** expected next week. Consider restocking soon.")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.yellow.opacity(0.2), lineWidth: 0.8)
                            )
                            .padding(.horizontal, 16)

                            // MARK: - Filter Chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(InventoryFilter.allCases, id: \.self) { filter in
                                        InventoryFilterChip(
                                            label: filter.rawValue,
                                            count: countFor(filter),
                                            isSelected: selectedFilter == filter
                                        ) {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                selectedFilter = filter
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }

                            // MARK: - Section Header
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Parts")
                                        .font(.headline)
                                        .foregroundStyle(Color.primary)
                                    Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")
                                        .font(.footnote)
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)

                            // MARK: - Items List
                            if filteredItems.isEmpty {
                                InventoryEmptyState(isFiltered: selectedFilter != .all || !searchText.isEmpty)
                            } else {
                                LazyVStack(spacing: 14) {
                                    ForEach(filteredItems) { item in
                                        Button(action: {
                                            selectedItem = item
                                        }) {
                                            InventoryRow(item: item)
                                        }
                                        .buttonStyle(InventoryCardButtonStyle())
                                        .scrollTransition { content, phase in
                                            content
                                                .opacity(phase.isIdentity ? 1 : 0.7)
                                                .scaleEffect(phase.isIdentity ? 1 : 0.97)
                                                .offset(y: phase.isIdentity ? 0 : 6)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable { await loadInventory() }
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Search parts...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            // Sheet for ADDING a new item
            .sheet(isPresented: $isShowingAddSheet) {
                InventoryItemSheet(editingItem: nil) {
                    Task { await loadInventory() }
                }
            }
            // Sheet for EDITING an existing item
            .sheet(item: $selectedItem) { item in
                InventoryItemSheet(editingItem: item) {
                    Task { await loadInventory() }
                }
            }
            .task {
                await loadInventory()
            }
        }
    }

    private func countFor(_ filter: InventoryFilter) -> Int {
        switch filter {
        case .all:      return inventoryItems.count
        case .lowStock: return inventoryItems.filter { ($0.stockQuantity ?? 0) <= ($0.reorderLevel ?? 0) }.count
        case .inStock:  return inventoryItems.filter { ($0.stockQuantity ?? 0) > ($0.reorderLevel ?? 0) }.count
        }
    }

    private func loadInventory() async {
        isLoading = true
        do {
            inventoryItems = try await InventoryService.fetchAllInventory()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Filter Chip
private struct InventoryFilterChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.footnote.weight(isSelected ? .semibold : .regular))

                Text("\(count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected
                            ? Color.white.opacity(0.2)
                            : Color(.tertiarySystemBackground)
                    )
                    .clipShape(Capsule())
            }
            .foregroundStyle(isSelected ? .white : Color.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.brown : Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : Color(.separator).opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Card Button Style
private struct InventoryCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Empty State
private struct InventoryEmptyState: View {
    let isFiltered: Bool
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.brown.opacity(0.06))
                    .frame(width: 100, height: 100)

                Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle" : "shippingbox")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.brown.opacity(0.5))
                    .symbolEffect(.pulse)
                    .offset(y: floatOffset)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            floatOffset = -6
                        }
                    }
            }

            VStack(spacing: 6) {
                Text(isFiltered ? "No matching parts" : "No parts yet")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text(isFiltered ? "Try adjusting your filters or search query." : "Tap + to add your first inventory item.")
                    .font(.subheadline)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Inventory Row
struct InventoryRow: View {
    let item: Inventory

    var isLowStock: Bool {
        (item.stockQuantity ?? 0) <= (item.reorderLevel ?? 0)
    }

    var stockFraction: Double {
        let qty = Double(item.stockQuantity ?? 0)
        let reorder = Double(max(item.reorderLevel ?? 1, 1))
        // reorder level sits at the 20% mark, so full bar = reorder * 5
        return min(qty / (reorder * 5), 1.0)
    }

    var stockStatusColor: Color {
        if stockFraction <= 0.20 { return .red }
        if stockFraction < 0.50 { return .orange }
        return .green
    }

    var stockBarGradient: LinearGradient {
        if stockFraction <= 0.20 {
            return LinearGradient(colors: [.red, .red.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
        }
        if stockFraction < 0.50 {
            return LinearGradient(colors: [.orange, .yellow.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(colors: [.green.opacity(0.7), .green], startPoint: .leading, endPoint: .trailing)
    }

    /// Pick an SF Symbol based on the part name
    var partIcon: String {
        let name = (item.partName ?? "").lowercased()
        if name.contains("oil") || name.contains("filter") { return "drop.fill" }
        if name.contains("brake")                          { return "circle.slash" }
        if name.contains("tire") || name.contains("tyre")  { return "circle.circle" }
        if name.contains("battery")                        { return "battery.100" }
        if name.contains("belt")                           { return "arrow.triangle.2.circlepath" }
        if name.contains("light") || name.contains("lamp") { return "lightbulb.fill" }
        if name.contains("spark") || name.contains("plug") { return "bolt.fill" }
        if name.contains("wiper")                          { return "windshield.front.and.wiper" }
        return "gearshape.fill"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent stripe for low-stock items
            if isLowStock {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.red)
                    .frame(width: 4)
                    .padding(.vertical, 10)
                    .padding(.leading, 4)
            }

            VStack(alignment: .leading, spacing: 0) {
                // Top section: Icon + Info + Stock count
                HStack(spacing: 14) {
                    // Part Icon Badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                isLowStock
                                    ? Color.red.opacity(0.1)
                                    : Color.brown.opacity(0.08)
                            )
                            .frame(width: 48, height: 48)
                        Image(systemName: partIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(isLowStock ? Color.red : Color.brown)
                    }

                    // Part Name + Info Pills
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(item.partName ?? "Unknown Part")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)

                            if isLowStock {
                                HStack(spacing: 3) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 8))
                                    Text("LOW")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.red, in: Capsule())
                            }
                        }

                        // Info Pills Row
                        HStack(spacing: 8) {
                            // Unit Cost Pill
                            HStack(spacing: 4) {
                                Image(systemName: "indianrupeesign")
                                    .font(.system(size: 9, weight: .semibold))
                                Text("\(String(format: "%.0f", item.unitCost ?? 0.0))")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())

                            // Reorder Level Pill
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.to.line")
                                    .font(.system(size: 9, weight: .semibold))
                                Text("Reorder: \(item.reorderLevel ?? 0)")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                        }
                    }

                    Spacer(minLength: 0)

                    // Stock Count
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(item.stockQuantity ?? 0)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(stockStatusColor)
                        Text("in stock")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

                // Stock Level Bar with Reorder Marker
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 5)

                        // Filled portion
                        RoundedRectangle(cornerRadius: 3)
                            .fill(stockBarGradient)
                            .frame(width: max(geo.size.width * stockFraction, 4), height: 5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: stockFraction)

                        // Reorder level marker (at the 20% point)
                        Rectangle()
                            .fill(Color(.tertiaryLabel).opacity(0.4))
                            .frame(width: 1.5, height: 11)
                            .offset(x: geo.size.width * 0.2 - 0.75)
                    }
                }
                .frame(height: 11)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isLowStock
                        ? Color.red.opacity(0.25)
                        : Color(.separator).opacity(0.2),
                    lineWidth: isLowStock ? 1.0 : 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    InventoryView()
}

// MARK: - InventoryItemSheet
struct InventoryItemSheet: View {
    @Environment(\.dismiss) private var dismiss

    let editingItem: Inventory?
    let onSave: () -> Void

    @State private var partName: String = ""
    @State private var stockQuantity: String = ""
    @State private var reorderLevel: String = ""
    @State private var unitCost: String = ""

    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var showingDeleteAlert = false
    @State private var isDeleting = false

    var isFormValid: Bool {
        !partName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        if let errorMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.red)
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.red)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            // Part Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PART NAME")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.secondary)
                                    .kerning(1.2)

                                TextField("", text: $partName, prompt: Text("e.g. Brake Pads").foregroundColor(Color(.placeholderText)))
                                    .foregroundColor(Color.primary)
                                    .padding(.horizontal, 18)
                                    .frame(height: 56)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(.separator), lineWidth: 1)
                                    )
                            }

                            // Stock Quantity & Reorder Level (Side by Side)
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("STOCK QUANTITY")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.secondary)
                                        .kerning(1.2)

                                    TextField("", text: $stockQuantity, prompt: Text("0").foregroundColor(Color(.placeholderText)))
                                        .keyboardType(.numberPad)
                                        .foregroundColor(Color.primary)
                                        .padding(.horizontal, 18)
                                        .frame(height: 56)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color(.separator), lineWidth: 1)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("REORDER LEVEL")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.secondary)
                                        .kerning(1.2)

                                    TextField("", text: $reorderLevel, prompt: Text("0").foregroundColor(Color(.placeholderText)))
                                        .keyboardType(.numberPad)
                                        .foregroundColor(Color.primary)
                                        .padding(.horizontal, 18)
                                        .frame(height: 56)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color(.separator), lineWidth: 1)
                                        )
                                }
                            }

                            // Unit Cost
                            VStack(alignment: .leading, spacing: 6) {
                                Text("UNIT COST (₹)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.secondary)
                                    .kerning(1.2)

                                TextField("", text: $unitCost, prompt: Text("0").foregroundColor(Color(.placeholderText)))
                                    .keyboardType(.numberPad)
                                    .foregroundColor(Color.primary)
                                    .padding(.horizontal, 18)
                                    .frame(height: 56)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(.separator), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 20)

                        // Action Buttons
                        VStack(spacing: 14) {
                            let isButtonDisabled = !isFormValid || isSaving

                            Button(action: saveAction) {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(editingItem == nil ? "Add Item" : "Update Item")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                                .foregroundColor(isButtonDisabled ? Color(.tertiaryLabel) : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(isButtonDisabled ? Color(.tertiarySystemFill) : Color.brown)
                                .cornerRadius(16)
                            }
                            .disabled(isButtonDisabled)

                            if editingItem != nil {
                                Button(action: { showingDeleteAlert = true }) {
                                    HStack {
                                        if isDeleting {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Delete Item")
                                                .font(.system(size: 18, weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.red)
                                    .cornerRadius(16)
                                }
                                .disabled(isDeleting)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle(editingItem == nil ? "New Inventory Item" : "Edit Inventory Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.secondary)
                }
            }
            .alert("Delete Item?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAction()
                }
            } message: {
                Text("Are you sure you want to delete this inventory item? This action cannot be undone.")
            }
            .onAppear {
                if let item = editingItem {
                    partName = item.partName ?? ""
                    stockQuantity = "\(item.stockQuantity ?? 0)"
                    reorderLevel = "\(item.reorderLevel ?? 0)"
                    unitCost = item.unitCost != nil ? "\(Int(item.unitCost!))" : ""
                }
            }
            .onChange(of: stockQuantity) { _, newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if filtered != newValue {
                    stockQuantity = filtered
                }
            }
            .onChange(of: reorderLevel) { _, newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if filtered != newValue {
                    reorderLevel = filtered
                }
            }
            .onChange(of: unitCost) { _, newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if filtered != newValue {
                    unitCost = filtered
                }
            }
        }
    }

    private func saveAction() {
        guard isFormValid else { return }
        isSaving = true
        errorMessage = nil

        let qty = Int(stockQuantity) ?? 0
        let reorder = Int(reorderLevel) ?? 0
        let cost = Double(unitCost) ?? 0.0

        Task {
            do {
                if let item = editingItem {
                    let updated = Inventory(
                        id: item.id,
                        partName: partName,
                        stockQuantity: qty,
                        reorderLevel: reorder,
                        unitCost: cost
                    )
                    try await InventoryService.updateItem(updated)
                } else {
                    let new = Inventory(
                        id: UUID(),
                        partName: partName,
                        stockQuantity: qty,
                        reorderLevel: reorder,
                        unitCost: cost
                    )
                    try await InventoryService.createItem(new)
                }
                onSave()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func deleteAction() {
        guard let item = editingItem else { return }
        isDeleting = true
        errorMessage = nil

        Task {
            do {
                try await InventoryService.deleteItem(id: item.id)
                onSave()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isDeleting = false
        }
    }
}