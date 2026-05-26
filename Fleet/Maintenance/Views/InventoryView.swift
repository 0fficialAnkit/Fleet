import SwiftUI

struct InventoryView: View {
    @State private var searchText = ""
    @State private var showLowStockOnly = false
    @State private var inventoryItems: [Inventory] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedItem: Inventory? = nil
    @State private var isShowingSheet = false

    var lowStockCount: Int {
        inventoryItems.filter { ($0.stockQuantity ?? 0) <= ($0.reorderLevel ?? 0) }.count
    }

    var searchResults: [Inventory] {
        var result = inventoryItems
        if !searchText.isEmpty {
            result = result.filter { $0.partName?.localizedCaseInsensitiveContains(searchText) == true }
        }
        if showLowStockOnly {
            result = result.filter { ($0.stockQuantity ?? 0) <= ($0.reorderLevel ?? 0) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                if isLoading && inventoryItems.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView {
                        LazyVStack(spacing: themeModel.spacingMD) {

                            // MARK: - Summary Strip
                            HStack(spacing: 0) {
                                InventoryStat(
                                    value: "\(inventoryItems.count)",
                                    label: "Total Parts",
                                    color: themeModel.maintenancePrimary
                                )
                                Divider()
                                    .frame(height: 50)
                                    .overlay(themeModel.textTertiary.opacity(0.3))
                                InventoryStat(
                                    value: "\(lowStockCount)",
                                    label: "Low Stock",
                                    color: themeModel.danger
                                )
                                Divider()
                                    .frame(height: 50)
                                    .overlay(themeModel.textTertiary.opacity(0.3))
                                InventoryStat(
                                    value: "₹\(String(format: "%.0f", inventoryItems.compactMap(\.unitCost).reduce(0, +)))",
                                    label: "Est. Value",
                                    color: themeModel.success
                                )
                            }
                            .padding(.vertical, 28)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                            .padding(.horizontal, themeModel.spacingMD)

                            // MARK: - AI Forecast Banner
                            HStack(alignment: .top, spacing: themeModel.spacingMD) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(themeModel.warning)
                                    .font(.system(size: 18, weight: .semibold))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI Forecast")
                                        .font(themeModel.bodyMedium())
                                        .foregroundStyle(themeModel.warning)
                                    Text("High demand for **Oil Filters** expected next week. Consider restocking soon.")
                                        .font(themeModel.caption())
                                        .foregroundStyle(themeModel.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(themeModel.spacingMD)
                            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                                    .stroke(themeModel.warning.opacity(0.25), lineWidth: 0.8)
                            )
                            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                            .padding(.horizontal, themeModel.spacingMD)

                            // MARK: - Low Stock Filter Toggle
                            if lowStockCount > 0 {
                                Button(action: { withAnimation { showLowStockOnly.toggle() } }) {
                                    HStack {
                                        Image(systemName: showLowStockOnly ? "checkmark.circle.fill" : "exclamationmark.triangle")
                                            .foregroundStyle(themeModel.danger)
                                        Text(showLowStockOnly ? "Showing Low Stock Only" : "Show Low Stock Only (\(lowStockCount))")
                                            .font(themeModel.bodyMedium())
                                            .foregroundStyle(themeModel.danger)
                                        Spacer()
                                    }
                                    .padding(themeModel.spacingMD)
                                    .background(themeModel.danger.opacity(showLowStockOnly ? 0.15 : 0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                                            .stroke(themeModel.danger.opacity(0.3), lineWidth: showLowStockOnly ? 1 : 0.5)
                                    )
                                }
                                .padding(.horizontal, themeModel.spacingMD)
                            }

                            // MARK: - Items List
                            if searchResults.isEmpty {
                                VStack(spacing: themeModel.spacingMD) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundStyle(themeModel.textTertiary)
                                    Text("No parts found")
                                        .font(themeModel.bodyMedium())
                                        .foregroundStyle(themeModel.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, themeModel.spacingXXL)
                            } else {
                                LazyVStack(spacing: themeModel.spacingMD) {
                                    ForEach(searchResults) { item in
                                        Button(action: {
                                            selectedItem = item
                                            isShowingSheet = true
                                        }) {
                                            InventoryRow(item: item)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, themeModel.spacingMD)
                            }
                        }
                        .padding(.vertical, themeModel.spacingMD)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Search parts...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedItem = nil
                        isShowingSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingSheet) {
                InventoryItemSheet(editingItem: selectedItem) {
                    Task {
                        await loadInventory()
                    }
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

// MARK: - Inventory Stat
private struct InventoryStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(themeModel.caption())
                .foregroundStyle(themeModel.textTertiary)
        }
        .frame(maxWidth: .infinity)
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
        let reorder = Double(item.reorderLevel ?? 1)
        return min(qty / (reorder * 2), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.partName ?? "Unknown Part")
                        .font(themeModel.headline())
                        .foregroundStyle(themeModel.textPrimary)
                    Text("Unit Cost: ₹\(String(format: "%.2f", item.unitCost ?? 0.0))")
                        .font(themeModel.caption())
                        .foregroundStyle(themeModel.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(item.stockQuantity ?? 0)")
                        .font(themeModel.title(20))
                        .foregroundStyle(isLowStock ? themeModel.danger : themeModel.textPrimary)
                    Text("in stock")
                        .font(themeModel.small())
                        .foregroundStyle(themeModel.textTertiary)
                }
            }

            // Stock Level Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeModel.surfaceTertiary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isLowStock ? themeModel.danger : themeModel.success)
                        .frame(width: geo.size.width * stockFraction, height: 6)
                        .animation(.spring(response: 0.5), value: stockFraction)
                }
            }
            .frame(height: 6)

            if isLowStock {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(themeModel.danger)
                    Text("Below reorder level (\(item.reorderLevel ?? 0)). Restock recommended.")
                        .font(themeModel.small())
                        .foregroundStyle(themeModel.danger)
                }
            }
        }
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(isLowStock ? themeModel.danger.opacity(0.3) : Color.white.opacity(0.12), lineWidth: isLowStock ? 1 : 0.5)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
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
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        if let errorMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(themeModel.danger)
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundStyle(themeModel.danger)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(themeModel.danger.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Part Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PART NAME")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(themeModel.textSecondary)
                                    .kerning(1.2)
                                
                                TextField("", text: $partName, prompt: Text("e.g. Brake Pads").foregroundColor(themeModel.placeholder))
                                    .foregroundColor(themeModel.textPrimary)
                                    .padding(.horizontal, 18)
                                    .frame(height: 56)
                                    .background(themeModel.inputBackground)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(themeModel.divider, lineWidth: 1)
                                    )
                            }
                            
                            // Stock Quantity & Reorder Level (Side by Side)
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("STOCK QUANTITY")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(themeModel.textSecondary)
                                        .kerning(1.2)
                                    
                                    TextField("", text: $stockQuantity, prompt: Text("0").foregroundColor(themeModel.placeholder))
                                        .keyboardType(.numberPad)
                                        .foregroundColor(themeModel.textPrimary)
                                        .padding(.horizontal, 18)
                                        .frame(height: 56)
                                        .background(themeModel.inputBackground)
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(themeModel.divider, lineWidth: 1)
                                        )
                                        .onChange(of: stockQuantity) { _, newValue in
                                            let filtered = newValue.filter { $0.isNumber }
                                            if filtered != newValue { stockQuantity = filtered }
                                        }
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("REORDER LEVEL")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(themeModel.textSecondary)
                                        .kerning(1.2)
                                    
                                    TextField("", text: $reorderLevel, prompt: Text("0").foregroundColor(themeModel.placeholder))
                                        .keyboardType(.numberPad)
                                        .foregroundColor(themeModel.textPrimary)
                                        .padding(.horizontal, 18)
                                        .frame(height: 56)
                                        .background(themeModel.inputBackground)
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(themeModel.divider, lineWidth: 1)
                                        )
                                        .onChange(of: reorderLevel) { _, newValue in
                                            let filtered = newValue.filter { $0.isNumber }
                                            if filtered != newValue { reorderLevel = filtered }
                                        }
                                }
                            }
                            
                            // Unit Cost
                            VStack(alignment: .leading, spacing: 6) {
                                Text("UNIT COST (₹)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(themeModel.textSecondary)
                                    .kerning(1.2)
                                
                                TextField("", text: $unitCost, prompt: Text("0.00").foregroundColor(themeModel.placeholder))
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(themeModel.textPrimary)
                                    .padding(.horizontal, 18)
                                    .frame(height: 56)
                                    .background(themeModel.inputBackground)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(themeModel.divider, lineWidth: 1)
                                    )
                                    .onChange(of: unitCost) { _, newValue in
                                        let allowed = CharacterSet(charactersIn: "0123456789.")
                                        let filtered = String(newValue.unicodeScalars.filter { allowed.contains($0) })
                                        // Allow only one decimal point
                                        let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
                                        let sanitized = parts.count > 2 ? parts[0] + "." + parts.dropFirst().joined() : filtered
                                        if sanitized != newValue { unitCost = String(sanitized) }
                                    }
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
                                .foregroundColor(isButtonDisabled ? themeModel.buttonDisabledText : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(isButtonDisabled ? themeModel.buttonDisabled : themeModel.maintenancePrimary)
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
                                    .background(themeModel.danger)
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
                    .foregroundStyle(themeModel.textSecondary)
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
                    unitCost = item.unitCost != nil ? String(format: "%.2f", item.unitCost!) : ""
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
