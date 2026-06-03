import Foundation
import Supabase

private struct RouteInsert: Encodable {
    let id: UUID
    let route_name: String
    let start_location: String
    let end_location: String
    let created_by_manager_id: UUID?
}

enum RouteService {

    /// Fetches routes. When `managerId` is provided, only routes created
    /// by that fleet manager are returned (isolated mode).
    static func fetchAllRoutes(managerId: UUID? = nil) async throws -> [Route] {
        if let managerId {
            return try await supabase
                .from("routes")
                .select()
                .eq("created_by_manager_id", value: managerId)
                .execute()
                .value
        } else {
            return try await supabase
                .from("routes")
                .select()
                .execute()
                .value
        }
    }

    static func fetchRoute(id: UUID) async throws -> Route {
        try await supabase
            .from("routes")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    static func createRoute(_ route: Route, managerId: UUID? = nil) async throws {
        let payload = RouteInsert(
            id: route.id,
            route_name: route.routeName ?? "",
            start_location: route.startLocation ?? "",
            end_location: route.endLocation ?? "",
            created_by_manager_id: managerId ?? route.createdByManagerId
        )
        try await supabase
            .from("routes")
            .insert(payload)
            .execute()
    }
}