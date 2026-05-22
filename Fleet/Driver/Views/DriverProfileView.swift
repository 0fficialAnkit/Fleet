import SwiftUI

struct DriverProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 24) {

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.blue)

                    VStack(spacing: 8) {

                        Text("Alex Johnson")
                            .font(.title.bold())

                        Text("Fleet Driver")
                            .foregroundStyle(.gray)
                    }

                    VStack(spacing: 16) {

                        settingsRow(title: "Notifications", icon: "bell")

                        settingsRow(title: "Documents", icon: "doc")

                        settingsRow(title: "Support", icon: "questionmark.circle")

                        Button(action: {
                            Task {
                                await authViewModel.signOut()
                            }
                        }) {
                            settingsRow(title: "Logout", icon: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Profile")
        }
    }

    func settingsRow(title: String, icon: String) -> some View {

        HStack {

            Image(systemName: icon)

            Text(title)

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

