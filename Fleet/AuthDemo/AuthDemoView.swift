import SwiftUI
import Supabase

struct AuthDemoView: View {
    @State private var viewModel = AuthViewModel()
    @State private var showSignUp = false
    
    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                VStack(spacing: 20) {
                    Text("Welcome!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("You are logged in as:")
                    Text(viewModel.currentUser?.email ?? "Unknown User")
                        .fontWeight(.semibold)
                    
                    Button(action: {
                        Task {
                            await viewModel.signOut()
                        }
                    }) {
                        Text("Log Out")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            } else {
                if showSignUp {
                    SignUpView(viewModel: viewModel, showSignUp: $showSignUp)
                } else {
                    LoginView(viewModel: viewModel, showSignUp: $showSignUp)
                }
            }
        }
        .task {
            await viewModel.checkUserSession()
        }
    }
}

#Preview {
    AuthDemoView()
}
