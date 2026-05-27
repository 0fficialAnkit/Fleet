import SwiftUI
import MapKit

// MARK: - Data

struct SelectedLocation: Equatable {
    let title: String
    let subtitle: String

    /// Full address string stored in Supabase and used for geocoding.
    var fullAddress: String {
        [title, subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

// MARK: - Search Completer

@Observable
final class SearchCompleter: NSObject, MKLocalSearchCompleterDelegate {

    var results: [MKLocalSearchCompletion] = []
    var isSearching = false

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func search(_ query: String) {
        if query.isEmpty {
            results = []
            isSearching = false
        } else {
            isSearching = true
        }
        completer.queryFragment = query
    }

    // MARK: MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
        isSearching = false
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
        isSearching = false
    }
}

// MARK: - View

struct LocationSearchView: View {

    /// Label shown in the navigation title ("Pickup Location" or "Drop-off Location").
    let prompt: String

    /// Called when the user picks a result.
    let onSelect: (SelectedLocation) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var completer = SearchCompleter()

    var body: some View {
        NavigationStack {
            List {
                if completer.isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                if query.isEmpty {
                    emptyPrompt
                } else if completer.results.isEmpty && !completer.isSearching {
                    noResults
                } else {
                    ForEach(completer.results, id: \.self) { completion in
                        Button {
                            let location = SelectedLocation(
                                title: completion.title,
                                subtitle: completion.subtitle
                            )
                            onSelect(location)
                            dismiss()
                        } label: {
                            resultRow(completion)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(prompt)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.teal)
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search address or place")
            .onChange(of: query) { _, new in
                completer.search(new)
            }
        }
    }

    // MARK: - Sub-views

    private var emptyPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 38))
                .foregroundStyle(Color.teal.opacity(0.5))
            Text("Start typing to search for an address or place")
                .font(.body)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }

    private var noResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 38))
                .foregroundStyle(Color(.quaternaryLabel))
            Text("No results for \"\(query)\"")
                .font(.body)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }

    private func resultRow(_ completion: MKLocalSearchCompletion) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "mappin")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.teal)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(completion.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.primary)
                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Color(.quaternaryLabel))
        }
        .padding(.vertical, 4)
    }
}