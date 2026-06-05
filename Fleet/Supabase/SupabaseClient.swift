import Foundation
import Supabase

// Helper to read from Secrets.plist
var supabaseConfig: (url: URL, key: String) {
    guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
          let urlString = dict["SUPABASE_URL"] as? String,
          let url = URL(string: urlString),
          let key = dict["SUPABASE_KEY"] as? String else {
        fatalError("Secrets.plist is missing or invalid. Please add your Supabase keys to it.")
    }
    return (url, key)
}

let supabaseURL = supabaseConfig.url
let supabaseKey = supabaseConfig.key

let customDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) { return date }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) { return date }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) { return date }
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
    }
    return decoder
}()

let customEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()

let supabase = SupabaseClient(
    supabaseURL: supabaseURL,
    supabaseKey: supabaseKey,
    options: SupabaseClientOptions(
        db: SupabaseClientOptions.DatabaseOptions(
            encoder: customEncoder,
            decoder: customDecoder
        )
    )
)