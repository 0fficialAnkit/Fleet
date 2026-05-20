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
            List(searchResults) { item in
                InventoryRow(item: item)
            }
            .listStyle(.plain)
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Search parts...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Action to add new inventory item
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            // AI Forecast Alert Banner
            .safeAreaInset(edge: .top) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("AI Forecast: High demand for **Oil Filters** expected next week.")
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
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
                    .font(.headline)
                
                Text("Cost: $\(String(format: "%.2f", item.unitCost ?? 0.0))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Stock: \(item.stockQuantity ?? 0)")
                    .font(.headline)
                    .foregroundColor(isLowStock ? .red : .primary)
                
                if isLowStock {
                    Text("Reorder!")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InventoryView()
}
