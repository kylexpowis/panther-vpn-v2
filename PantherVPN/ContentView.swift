//
//  ContentView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 06/08/2025.
//

import SwiftUI
import Supabase
import UIKit   // ← for UIDevice.current.name

private struct RegisterDeviceParams: Encodable {
    let p_device_id: String
    let p_platform: String
    let p_name: String
}

struct ContentView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isLoggedIn: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    // For focused field styling
    @FocusState private var focusedField: Field?
    private enum Field { case username, password }

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

                        // Username
                        inputField(
                            text: $username,
                            placeholder: "Username",
                            isSecure: false,
                            isFocused: focusedField == .username
                        )
                        .focused($focusedField, equals: .username)

                        // Password
                        inputField(
                            text: $password,
                            placeholder: "Password",
                            isSecure: true,
                            isFocused: focusedField == .password
                        )
                        .focused($focusedField, equals: .password)

                        // Remember Me
                        Toggle(isOn: $rememberMe) {
                            Text("Remember Me")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        .padding(.leading, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Log In button
                        Button(action: handleLogin) {
                            Text("Log In")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentColor)
                                )
                                .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 4) // softer glow
                        }

                        // Sign Up link
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

    // MARK: - Styled input field
    @ViewBuilder
    private func inputField(text: Binding<String>,
                            placeholder: String,
                            isSecure: Bool,
                            isFocused: Bool) -> some View {

        let field = Group {
            if isSecure {
                SecureField(
                    "",
                    text: text,
                    prompt: Text(placeholder).foregroundColor(.gray)
                )
            } else {
                TextField(
                    "",
                    text: text,
                    prompt: Text(placeholder).foregroundColor(.gray)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            }
        }
        .foregroundColor(.white) // typed text
        .padding(.horizontal, 14)
        .padding(.vertical, 12)

        field
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.accentColor : Color.gray.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: isFocused ? Color.accentColor.opacity(0.15) : .clear, radius: 6, y: 3) // softer glow than Signup
    }

    // MARK: - Actions
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
                // 1) sign in
                _ = try await client.auth.signIn(email: email, password: password)

                // 2) register this device (DB enforces max 5)
                let deviceId = DeviceID.current()
                let params = RegisterDeviceParams(
                    p_device_id: deviceId,
                    p_platform: "ios",
                    p_name: UIDevice.current.name
                )

                _ = try await client.database
                    .rpc("register_device", params: params)
                    .execute()  // we don't need the return row

                await MainActor.run { isLoggedIn = true }

            } catch {
                let msg = error.localizedDescription.lowercased()
                let friendly = msg.contains("device_limit_exceeded")
                    ? "You’ve reached the 5-device limit. Remove an old device to continue."
                    : error.localizedDescription

                await MainActor.run {
                    alertMessage = friendly
                    showAlert = true
                }
            }
        }
    }

}

#Preview {
    ContentView()
        .tint(.blue)
        .preferredColorScheme(.dark)
}


