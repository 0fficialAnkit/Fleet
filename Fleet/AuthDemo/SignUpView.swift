import SwiftUI
import Supabase

struct SignUpView: View {
    var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @Binding var showSignUp: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                Task {
                    await viewModel.signUp(email: email, password: password)
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                } else {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
            .padding(.horizontal)
            
            Button(action: {
                showSignUp = false
            }) {
                Text("Already have an account? Log In")
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(.top, 50)
    }
}
