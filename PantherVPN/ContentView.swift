//
//  ContentView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 06/08/2025.
//

import SwiftUI
import Supabase



struct ContentView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isLoggedIn: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationStack {
            if isLoggedIn {
                HomeView()
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()

                    VStack(spacing: 20) {
                        Image("transparentpanthertemplogo")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .aspectRatio(contentMode: .fit)

                        Image("panthertextlogo1")
                            .resizable()
                            .frame(width: 220, height: 32)
                            .aspectRatio(contentMode: .fit)

                        TextField("Username", text: $username)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)

                        Toggle(isOn: $rememberMe) {
                            Text("Remember Me")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        .padding(.leading, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: handleLogin) {
                            Text("Log In")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#609bd1"))
                                .cornerRadius(8)
                        }

                        HStack(spacing: 4) {
                            Text("Don’t have an account?")
                                .foregroundColor(.gray)

                            NavigationLink(destination: SignupView()) {
                                Text("Sign Up")
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
                .alert("Login Failed", isPresented: $showAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(alertMessage)
                }
            }
        }
    }

    func handleLogin() {
        guard !username.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in both fields."
            showAlert = true
            return
        }

        let email = "\(username)@vpn.fake"
        let client = SupabaseManager.shared.client

        Task {
            do {
                // v2 API
                _ = try await client.auth.signIn(email: email, password: password)

                if rememberMe {
                    // store whatever you need locally (e.g., Keychain) if you want
                }
                await MainActor.run { isLoggedIn = true }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

}

#Preview {
    ContentView()
}

