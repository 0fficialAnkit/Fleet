import Foundation
import Supabase

enum InventoryService {

    static func fetchAllInventory() async throws -> [Inventory] {
        try await supabase
            .from("inventory")
            .select()
            .execute()
            .value
    }

    static func fetchItem(id: UUID) async throws -> Inventory {
        try await supabase
            .from("inventory")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    static func updateStock(id: UUID, newQuantity: Int) async throws {
        struct StockUpdate: Encodable {
            let stock_quantity: Int
        }
        try await supabase
            .from("inventory")
            .update(StockUpdate(stock_quantity: newQuantity))
            .eq("id", value: id)
            .execute()
    }

    static func createItem(_ item: Inventory) async throws {
        try await supabase
            .from("inventory")
            .insert(item)
            .execute()
    }

    static func updateItem(_ item: Inventory) async throws {
        try await supabase
            .from("inventory")
            .update(item)
            .eq("id", value: item.id)
            .execute()
    }

    static func deleteItem(id: UUID) async throws {
        try await supabase
            .from("inventory")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
