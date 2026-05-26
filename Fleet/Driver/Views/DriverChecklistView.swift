import SwiftUI

struct DriverChecklistView: View {

    let checklistType: InspectionType
    let onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var checkedItems: Set<String> = []
    @State private var isSubmitted = false

    let preTripItems = [
        "Tire Pressure & Condition",
        "Brake System Test",
        "Fluid Levels (Oil, Coolant)",
        "Lights & Signals",
        "Mirrors & Windshield"
    ]

    let postTripItems = [
        "Vehicle Cleanliness",
        "New Damage Inspection",
        "Fuel Level Check",
        "Cargo Area Secured"
    ]

    var currentItems: [String] {
        checklistType == .preTrip ? preTripItems : postTripItems
    }

    var isFormValid: Bool {
        checkedItems.count == currentItems.count
    }

    func iconFor(item: String) -> String {
        switch item {
        case "Tire Pressure & Condition": return "tire"
        case "Brake System Test": return "pedal.brake"
        case "Fluid Levels (Oil, Coolant)": return "drop.fill"
        case "Lights & Signals": return "headlight.high.beam"
        case "Mirrors & Windshield": return "mirror.side.right"
        case "Vehicle Cleanliness": return "sparkles"
        case "New Damage Inspection": return "exclamationmark.triangle"
        case "Fuel Level Check": return "fuelpump"
        case "Cargo Area Secured": return "shippingbox"
        default: return "circle"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: checklistType == .preTrip ? "Pre-Trip Inspection" : "Post-Trip Inspection")
                            .padding(.top)

                        Text("Mandatory Safety Checks")
                            .font(.headline)
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal, 4)

                        ForEach(currentItems, id: \.self) { item in
                            Button(action: {
                                if checkedItems.contains(item) {
                                    checkedItems.remove(item)
                                } else {
                                    checkedItems.insert(item)
                                }
                            }) {

                                    HStack {
                                        Image(systemName: iconFor(item: item))
                                            .font(.system(size: 20))
                                            .foregroundColor(Color.green)
                                            .frame(width: 30)

                                        Text(item)
                                            .font(.body)
                                            .foregroundColor(Color.primary)
                                            .padding(.leading, 8)

                                        Spacer()

                                        Image(systemName: checkedItems.contains(item) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(checkedItems.contains(item) ? Color.green : Color(.tertiaryLabel))
                                            .font(.title3)
                                    }
                                    .padding(16)
                                    .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                    )

                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Button(action: {
                    isSubmitted = true
                    let notes = "Checked items: " + checkedItems.joined(separator: ", ")
                    onSubmit(notes)
                    dismiss()
                }) {
                    Text(isSubmitted ? "Submitted Successfully" : "Submit Checklist")
                        .font(.headline)
                        .foregroundColor(isFormValid && !isSubmitted ? Color(.systemBackground) : Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(isFormValid && !isSubmitted ? Color.green : Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid || isSubmitted)
                .padding()
            }
            .navigationTitle(checklistType == .preTrip ? "Pre-Trip Safety" : "Post-Trip Safety")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.secondary)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}

#Preview {
    DriverChecklistView(checklistType: .preTrip, onSubmit: { _ in })
}