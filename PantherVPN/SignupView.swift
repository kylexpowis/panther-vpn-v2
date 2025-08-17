//
//  SignupView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 06/08/2025.
//


import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss

    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedPlan = "1_month"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoggedIn = false

    // Focus to style the active field (blue glow)
    @FocusState private var focusedField: Field?
    private enum Field { case username, password, confirm }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Back button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding()
                    }
                    Spacer()
                }

                Text("Create Your Account")
                    .foregroundColor(.white)
                    .font(.title)
                    .padding(.bottom, 8)

                // MARK: Inputs
                VStack(spacing: 12) {
                    inputField(
                        text: $username,
                        placeholder: "Username",
                        isSecure: false,
                        isFocused: focusedField == .username
                    )
                    .focused($focusedField, equals: .username)

                    inputField(
                        text: $password,
                        placeholder: "Password",
                        isSecure: true,
                        isFocused: focusedField == .password
                    )
                    .focused($focusedField, equals: .password)

                    inputField(
                        text: $confirmPassword,
                        placeholder: "Confirm Password",
                        isSecure: true,
                        isFocused: focusedField == .confirm
                    )
                    .focused($focusedField, equals: .confirm)
                }

                Text("Notice: Please make sure to note down your username and password, as we cannot recover or reset due to a security feature.")
                    .foregroundColor(.yellow)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)

                // Website link row
                HStack(spacing: 4) {
                    Text("Visit our website to see how subscriptions work")
                        .foregroundColor(.white)
                        .font(.footnote)

                    Text("here")
                        .foregroundColor(.blue)
                        .underline()
                        .font(.footnote)
                        .onTapGesture {
                            if let url = URL(string: "https://www.kaizendevelopment.uk") {
                                UIApplication.shared.open(url)
                            }
                        }
                }

                // MARK: Terms & Conditions box
                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms & Conditions")
                        .font(.headline)
                        .foregroundColor(.white)

                    ScrollView {
                        Text(termsText)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 4)
                    }
                    .frame(height: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    )
                }
                .padding(.top, 4)

                // Continue button (blue glow)
                Button(action: handleSignup) {
                    Text("Continue to Payment")
                        .foregroundColor(.white)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentColor)
                        )
                        .shadow(color: Color.accentColor.opacity(0.6), radius: 12, y: 6)
                }
                .padding(.top)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .alert("Signup Failed", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Styled input field
    @ViewBuilder
    private func inputField(text: Binding<String>,
                            placeholder: String,
                            isSecure: Bool,
                            isFocused: Bool) -> some View {

        let base = Group {
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
        .foregroundColor(.white)           // typed text color
        .padding(.horizontal, 14)
        .padding(.vertical, 12)

        base
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)     // field background (black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.accentColor : Color.gray.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: isFocused ? Color.accentColor.opacity(0.25) : .clear, radius: 10, y: 6)
    }

    // MARK: - Actions
    func handleSignup() {
        guard !username.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }

        let email = "\(username)@vpn.fake"
        let client = SupabaseManager.shared.client

        Task {
            do {
                _ = try await client.auth.signUp(email: email, password: password)
                await MainActor.run { isLoggedIn = true }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    // MARK: - Sample terms text
    private var termsText: String {
        """
        By creating an account you agree to our Terms & Conditions and Privacy Policy. \
        Your subscription will be managed through our backend and is tied to your account credentials. \
        We do not log your browsing activity. Refunds and cancellations are detailed on our website.
        """
    }
}

#Preview {
    SignupView()
        .tint(.blue) // keep your blue accent for glow & strokes
        .preferredColorScheme(.dark)
}



