import SwiftUI

struct TripsView: View {

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    ForEach(0..<5) { _ in

                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 180)
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Trips")
        }
    }
}
