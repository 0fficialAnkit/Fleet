import SwiftUI

struct ChecklistView: View {

    let items = [
        "Brakes Checked",
        "Fuel Checked",
        "Lights Working",
        "Tires Checked",
        "Documents Available"
    ]

    var body: some View {

        NavigationStack {

            List {

                ForEach(items, id: \.self) { item in

                    HStack {

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        Text(item)
                    }
                }
            }
            .navigationTitle("Checklist")
        }
    }
}
