import SwiftUI

struct InventoryView: View {
    @State private var searchText = ""
    @State private var inventoryItems: [Inventory] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedItem: Inventory? = nil
    @State private var isShowingAddSheet = false

    var lowStockCount: Int {
        inventoryItems.filter { ($0.stockQuantity ?? 0) <= ($0.reorderLevel ?? 0) }.count
    }

    var searchResults: [Inventory] {
        if searchText.isEmpty { return inventoryItems }
        return inventoryItems.filter { $0.partName?.localizedCaseInsensitiveContains(searchText) == true }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if isLoading && inventoryItems.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView {
                        VStack(spacing: 16) {

                            // MARK: - Summary Card
                            VStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    // Total Parts
                                    VStack(spacing: 8) {
                                        Image(systemName: "shippingbox.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color.brown)
                                        Text("\(inventoryItems.count)")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.primary)
                                        Text("Total Parts")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .frame(maxWidth: .infinity)

                                    Divider()
                                        .frame(height: 40)
                                        .foregroundStyle(Color(.separator))

                                    // Low Stock
                                    VStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color.red)
                                        Text("\(lowStockCount)")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundStyle(lowStockCount > 0 ? Color.red : Color.primary)
                                        Text("Low Stock")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .frame(maxWidth: .infinity)

                                    Divider()
                                        .frame(height: 40)
                                        .foregroundStyle(Color(.separator))

                                    // Est. Value
                                    VStack(spacing: 8) {
                                        Image(systemName: "indianrupeesign.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color.green)
                                        Text("₹\(String(format: "%.0f", inventoryItems.compactMap(\.unitCost).reduce(0, +)))")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.green)
                                        Text("Est. Value")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.vertical, 20)
                            }
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                            .padding(.horizontal, 16)

                            // MARK: - AI Forecast Banner
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color.yellow)
                                    .font(.system(size: 18, weight: .semibold))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI Forecast")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.yellow)
                                    Text("High demand for **Oil Filters** expected next week. Consider restocking soon.")
                                        .font(.footnote)
                                        .foregroundStyle(Color.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.yellow.opacity(0.25), lineWidth: 0.8)
                            )

                            .padding(.horizontal, 16)


                            // MARK: - Items List
                            if searchResults.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                    Text("No parts found")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(searchResults) { item in
                                        Button(action: {
                                            selectedItem = item
                                        }) {
                                            InventoryRow(item: item)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
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

    var stockBarColor: Color {
        if stockFraction <= 0.20 { return .red }
        if stockFraction <  0.50 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.partName ?? "Unknown Part")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text("Unit Cost: ₹\(String(format: "%.2f", item.unitCost ?? 0.0))")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(item.stockQuantity ?? 0)")
                        .font(.title3.bold())
                        .foregroundStyle(Color.primary)
                    Text("in stock")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }

            // Stock Level Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stockBarColor)
                        .frame(width: geo.size.width * stockFraction, height: 6)
                        .animation(.spring(response: 0.5), value: stockFraction)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
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