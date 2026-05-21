import SwiftUI

struct InventoryView: View {
    @State private var searchText = ""

    let inventoryItems = [
        Inventory(id: UUID(), partName: "Brake Pads (Front)",  stockQuantity: 12, reorderLevel: 5,  unitCost: 45.0),
        Inventory(id: UUID(), partName: "Oil Filter",          stockQuantity: 3,  reorderLevel: 10, unitCost: 12.5),
        Inventory(id: UUID(), partName: "Windshield Wipers",   stockQuantity: 25, reorderLevel: 8,  unitCost: 18.0),
        Inventory(id: UUID(), partName: "Headlight Bulb",      stockQuantity: 4,  reorderLevel: 5,  unitCost: 22.0),
        Inventory(id: UUID(), partName: "Air Filter",          stockQuantity: 8,  reorderLevel: 6,  unitCost: 15.0),
        Inventory(id: UUID(), partName: "Spark Plugs (x4)",    stockQuantity: 2,  reorderLevel: 4,  unitCost: 32.0)
    ]

    var searchResults: [Inventory] {
        if searchText.isEmpty { return inventoryItems }
        return inventoryItems.filter { $0.partName?.localizedCaseInsensitiveContains(searchText) == true }
    }

    var lowStockCount: Int {
        inventoryItems.filter { ($0.stockQuantity ?? 0) <= ($0.reorderLevel ?? 0) }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // ── AI Forecast Banner ──
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(MBlue.accent.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(MBlue.accentBright)
                                    .symbolRenderingMode(.hierarchical)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("AI Forecast")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(MBlue.accentLight)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                Text("High demand for **Oil Filters** expected next week.")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(MBlue.textPrimary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .glassEffect(
                            .regular.tint(MBlue.accent.opacity(0.10)),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(MBlue.accent.opacity(0.25), lineWidth: 0.8)
                        )
                        .padding(.horizontal)

                        // ── Quick Stats ──
                        HStack(spacing: 12) {
                            InvStatPill(label: "Total Parts",  value: "\(inventoryItems.count)",  icon: "shippingbox",        tint: MBlue.accent)
                            InvStatPill(label: "Low Stock",    value: "\(lowStockCount)",          icon: "exclamationmark.triangle", tint: MBlue.critical)
                        }
                        .padding(.horizontal)

                        // ── Search Bar ──
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(MBlue.textMuted)
                                .symbolRenderingMode(.hierarchical)
                            TextField("Search parts…", text: $searchText)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(MBlue.textPrimary)
                                .tint(MBlue.accentLight)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(MBlue.textMuted)
                                        .symbolRenderingMode(.hierarchical)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(MBlue.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(MBlue.cardBorder, lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)

                        // ── Items List ──
                        VStack(spacing: 10) {
                            ForEach(searchResults) { item in
                                InvItemCard(item: item)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MBlue.accentLight)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }
}

// MARK: - Inventory Stat Pill
struct InvStatPill: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(MBlue.textPrimary)
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(MBlue.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .mCard()
    }
}

// MARK: - Inventory Item Card
struct InvItemCard: View {
    let item: Inventory

    var isLowStock: Bool {
        (item.stockQuantity ?? 0) <= (item.reorderLevel ?? 0)
    }

    var stockFraction: Double {
        let qty = Double(item.stockQuantity ?? 0)
        let max = Double((item.reorderLevel ?? 1) * 3)
        return min(qty / max, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isLowStock ? MBlue.critical.opacity(0.15) : MBlue.accentSoft)
                        .frame(width: 40, height: 40)
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isLowStock ? MBlue.critical : MBlue.accentLight)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.partName ?? "Unknown Part")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(MBlue.textPrimary)
                    Text("$\(String(format: "%.2f", item.unitCost ?? 0.0)) per unit")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(MBlue.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(item.stockQuantity ?? 0)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(isLowStock ? MBlue.critical : MBlue.textPrimary)
                    Text("in stock")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(MBlue.textMuted)
                }
            }

            // Stock level bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MBlue.divider)
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: isLowStock ? [MBlue.critical, MBlue.critical.opacity(0.7)] : [MBlue.accent, MBlue.accentLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * stockFraction, height: 5)
                    }
                }
                .frame(height: 5)

                HStack {
                    Text("Reorder at \(item.reorderLevel ?? 0)")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(MBlue.textMuted)
                    Spacer()
                    if isLowStock {
                        Text("REORDER NOW")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(MBlue.critical)
                            .tracking(0.5)
                    }
                }
            }
        }
        .padding(16)
        .mCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MBlue.critical.opacity(isLowStock ? 0.45 : 0), lineWidth: 1.5)
        )
    }
}

#Preview {
    InventoryView()
}
