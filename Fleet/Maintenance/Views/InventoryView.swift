import SwiftUI

struct InventoryView: View {
    @State private var searchText = ""
    @State private var showLowStockOnly = false
    @State private var inventoryItems: [Inventory] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                        VStack(spacing: themeModel.spacingMD) {

                            // MARK: - Summary Strip
                            HStack(spacing: themeModel.spacingMD) {
                                InventoryStat(
                                    value: "\(inventoryItems.count)",
                                    label: "Total Parts",
                                    color: themeModel.maintenancePrimary
                                )
                                InventoryStat(
                                    value: "\(lowStockCount)",
                                    label: "Low Stock",
                                    color: themeModel.danger
                                )
                                InventoryStat(
                                    value: "$\(String(format: "%.0f", inventoryItems.compactMap(\.unitCost).reduce(0, +)))",
                                    label: "Est. Value",
                                    color: themeModel.success
                                )
                            }
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
                                        InventoryRow(item: item)
                                    }
                                }
                                .padding(.horizontal, themeModel.spacingMD)
                            }
                        }
                        .padding(.vertical, themeModel.spacingMD)
                    }
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Search parts...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(themeModel.maintenancePrimary)
                            .font(.system(size: 20))
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
        VStack(spacing: 4) {
            Text(value)
                .font(themeModel.headline())
                .foregroundStyle(color)
            Text(label)
                .font(themeModel.small())
                .foregroundStyle(themeModel.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 0.8)
        )
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
                    Text("Unit Cost: $\(String(format: "%.2f", item.unitCost ?? 0.0))")
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
