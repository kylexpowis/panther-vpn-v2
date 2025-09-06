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

    // Eye toggles
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    // Alerts & flow
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showPrePaymentConfirm = false
    @State private var isBusy = false

    // Navigation to PaymentView
    @State private var goToPayment = false

    // Focus to style the active field (blue glow)
    @FocusState private var focusedField: Field?
    private enum Field { case username, password, confirm }

    var body: some View {
        NavigationStack {
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
                        // Username (plain)
                        inputField(
                            text: $username,
                            placeholder: "Username",
                            isSecure: false,
                            isFocused: focusedField == .username
                        )
                        .focused($focusedField, equals: .username)

                        // Password (with eye)
                        secureInputField(
                            text: $password,
                            placeholder: "Password",
                            isRevealed: $showPassword,
                            isFocused: focusedField == .password,
                            target: .password
                        )

                        // Confirm Password (with eye)
                        secureInputField(
                            text: $confirmPassword,
                            placeholder: "Confirm Password",
                            isRevealed: $showConfirmPassword,
                            isFocused: focusedField == .confirm,
                            target: .confirm
                        )
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
                    Button(action: handleContinueTapped) {
                        HStack(spacing: 8) {
                            if isBusy { ProgressView().tint(.white) }
                            Text("Continue to Payment")
                                .foregroundColor(.white)
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentColor)
                        )
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 4)
                    }
                    .padding(.top)
                    .disabled(isBusy)

                    // Invisible NavigationLink to route to PaymentView on success
                    NavigationLink(destination: PaymentView(), isActive: $goToPayment) { EmptyView() }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            // Error alert
            .alert("Signup Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            // Pre-payment confirmation
            .alert("Before you continue", isPresented: $showPrePaymentConfirm) {
                Button("Yes") { performSignupAndRoute() }
                Button("No", role: .cancel) { /* just close */ }
            } message: {
                Text("Have you made a note of your username and password?")
            }
        }
        .tint(.blue) // keep your blue accent for glow & strokes
        .preferredColorScheme(.dark)
    }

    // MARK: - Styled input field (plain or secure without eye)
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

    // MARK: - Secure input with eye toggle
    @ViewBuilder
    private func secureInputField(text: Binding<String>,
                                  placeholder: String,
                                  isRevealed: Binding<Bool>,
                                  isFocused: Bool,
                                  target: Field) -> some View {

        let field = Group {
            if isRevealed.wrappedValue {
                TextField(
                    "",
                    text: text,
                    prompt: Text(placeholder).foregroundColor(.gray)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: target)
            } else {
                SecureField(
                    "",
                    text: text,
                    prompt: Text(placeholder).foregroundColor(.gray)
                )
                .focused($focusedField, equals: target)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)

        field
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
            )
            // Eye button overlay
            .overlay(
                HStack {
                    Spacer()
                    Button {
                        isRevealed.wrappedValue.toggle()
                    } label: {
                        Image(systemName: isRevealed.wrappedValue ? "eye.slash" : "eye")
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.trailing, 10)
                    }
                    .buttonStyle(.plain)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.accentColor : Color.gray.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: isFocused ? Color.accentColor.opacity(0.25) : .clear, radius: 10, y: 6)
    }

    // MARK: - Actions

    /// Validates inputs and shows the "note your credentials" popup.
    private func handleContinueTapped() {
        // Basic validation
        guard !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            showErrorAlert = true
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            showErrorAlert = true
            return
        }

        // Passed local validation; ask the user to confirm they've noted creds
        showPrePaymentConfirm = true
    }

    /// Calls signup and on success routes to PaymentView.
    private func performSignupAndRoute() {
        isBusy = true

        let email = "\(username)@vpn.fake"
        let client = SupabaseManager.shared.client

        Task {
            do {
                _ = try await client.auth.signUp(email: email, password: password)
                await MainActor.run {
                    isBusy = false
                    goToPayment = true
                }
            } catch {
                await MainActor.run {
                    isBusy = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
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
}




