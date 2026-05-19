import SwiftUI

struct FuelView: View {

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 16) {

                    ForEach(0..<5) { _ in

                        VStack(alignment: .leading, spacing: 12) {

                            Text("Fuel Entry")
                                .font(.headline)

                            Text("48 Liters")
                                .foregroundStyle(.green)

                            Text("₹4200")
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Fuel")
        }
    }
}
