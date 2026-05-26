import Foundation
import Supabase

enum RouteService {

    static func fetchAllRoutes() async throws -> [Route] {
        try await supabase
            .from("routes")
            .select()
            .execute()
            .value
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

    static func createRoute(_ route: Route) async throws {
        try await supabase
            .from("routes")
            .insert(route)
            .execute()
    }
}