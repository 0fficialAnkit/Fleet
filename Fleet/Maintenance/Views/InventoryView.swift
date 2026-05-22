import SwiftUI

struct InventoryView: View {
    @State private var searchText = ""
    
    // Dummy Data based on DataModel
    let inventoryItems = [
        Inventory(id: UUID(), partName: "Brake Pads (Front)", stockQuantity: 12, reorderLevel: 5, unitCost: 45.0),
        Inventory(id: UUID(), partName: "Oil Filter", stockQuantity: 3, reorderLevel: 10, unitCost: 12.5),
        Inventory(id: UUID(), partName: "Windshield Wipers", stockQuantity: 25, reorderLevel: 8, unitCost: 18.0),
        Inventory(id: UUID(), partName: "Headlight Bulb", stockQuantity: 4, reorderLevel: 5, unitCost: 22.0)
    ]
    
    var searchResults: [Inventory] {
        if searchText.isEmpty {
            return inventoryItems
        } else {
            return inventoryItems.filter { $0.partName?.localizedCaseInsensitiveContains(searchText) == true }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: themeModel.spacingMD) {
                        LazyVStack(spacing: themeModel.spacingMD) {
                            ForEach(searchResults) { item in
                                InventoryRow(item: item)
                            }
                        }
                        .padding(.horizontal, themeModel.spacingMD)
                    }
                    .padding(.vertical, themeModel.spacingMD)
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Search parts...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Action to add new inventory item
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(themeModel.maintenancePrimary)
                    }
                }
            }
            // AI Forecast Alert Banner
            .safeAreaInset(edge: .top) {
                
                    HStack(alignment: .top) {
                        Image(systemName: "sparkles")
                            .foregroundColor(themeModel.warning)
                        Text("AI Forecast: High demand for **Oil Filters** expected next week.")
                            .font(themeModel.bodyMedium())
                            .foregroundStyle(themeModel.textPrimary)
                        Spacer()
                    }
                    .padding(themeModel.spacingMD)
                    .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
                .padding(.horizontal, themeModel.spacingMD)
                .padding(.bottom, themeModel.spacingMD)
            }
        }
    }
}

struct InventoryRow: View {
    let item: Inventory
    
    var isLowStock: Bool {
        return (item.stockQuantity ?? 0) <= (item.reorderLevel ?? 0)
    }
    
    var body: some View {
        
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.partName ?? "Unknown Part")
                        .font(themeModel.headline())
                        .foregroundStyle(themeModel.textPrimary)
                    
                    Text("Cost: $\(String(format: "%.2f", item.unitCost ?? 0.0))")
                        .font(themeModel.bodyMedium())
                        .foregroundColor(themeModel.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Stock: \(item.stockQuantity ?? 0)")
                        .font(themeModel.headline())
                        .foregroundColor(isLowStock ? themeModel.danger : themeModel.textPrimary)
                    
                    if isLowStock {
                        StatusBadge(text: "Reorder!", color: themeModel.danger, icon: "exclamationmark.triangle.fill")
                    }
                }
            }
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
    }
}

#Preview {
    InventoryView()
}
