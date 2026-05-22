import SwiftUI

struct DriverChecklistView: View {

    @State private var checklistType: InspectionType = .preTrip
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

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Checklist Type", selection: $checklistType) {
                    Text("Pre-Trip").tag(InspectionType.preTrip)
                    Text("Post-Trip").tag(InspectionType.postTrip)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: checklistType) { _ in
                    checkedItems.removeAll()
                    isSubmitted = false
                }
                
                List {
                    Section(header: Text("Mandatory Safety Checks")) {
                        ForEach(currentItems, id: \.self) { item in
                            Button(action: {
                                if checkedItems.contains(item) {
                                    checkedItems.remove(item)
                                } else {
                                    checkedItems.insert(item)
                                }
                            }) {
                                HStack {
                                    Image(systemName: checkedItems.contains(item) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(checkedItems.contains(item) ? .green : .gray)
                                        .font(.title3)
                                    
                                    Text(item)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 8)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                Button(action: {
                    isSubmitted = true
                    // In a real app, this would update the server and unlock the "Start Trip" or "End Trip" button
                    checkedItems.removeAll()
                }) {
                    Text(isSubmitted ? "Submitted Successfully" : "Submit Checklist")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid || isSubmitted)
                .padding()
            }
            .navigationTitle("Vehicle Checklist")
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

#Preview {
    DriverChecklistView()
}
