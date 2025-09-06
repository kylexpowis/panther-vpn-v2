//
//  ReportIssueView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 06/09/2025.
//


import SwiftUI
import Supabase
import UIKit

struct ReportIssueView: View {
    // Dismiss back to HomeView
    @Environment(\.dismiss) private var dismiss

    // Fields
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var message: String = ""

    // UI
    @FocusState private var focused: Field?
    private enum Field { case username, email, message }

    @State private var showThanks = false
    private let corner: CGFloat = 16

    var body: some View {
        ZStack(alignment: .top) {
            // Dashboard-like background
            LinearGradient(
                colors: [.black, .black, Color.blue.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (custom, so no gray system bar)
                header
                    .padding(.horizontal)
                    .padding(.top, 14)

                ScrollView {
                    VStack(spacing: 14) {
                        // Description banner (optional, matches dashboard tone)
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundColor(.blue)
                            Text("Tell us what's wrong. If your issue is account related, add your email so we can contact you. We delete emails as soon as cases are resolved.")
                                .foregroundColor(.white.opacity(0.85))
                                .font(.subheadline)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                        )

                        // Form card styled like Dashboard panels
                        VStack(alignment: .leading, spacing: 12) {
                            fieldLabel("Username")
                            inputField(text: $username, placeholder: "e.g. kaiwan", isSecure: false, focusedEquals: .username)
                                .focused($focused, equals: .username)

                            fieldLabel("Email (optional)")
                            inputField(text: $email, placeholder: "Only if we should contact you", isSecure: false, focusedEquals: .email, keyboardType: .emailAddress)
                                .focused($focused, equals: .email)

                            fieldLabel("Message")
                            messageField
                                .focused($focused, equals: .message)

                            // Submit button (Dashboard blue style)
                            Button(action: submit) {
                                Text("Submit")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: corner)
                                            .fill(Color.blue)
                                            .shadow(color: Color.blue.opacity(0.35), radius: 10, y: 5)
                                    )
                            }
                            .padding(.top, 4)
                            .disabled(username.isEmpty || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity((username.isEmpty || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.7 : 1)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: corner)
                                .fill(Color.white.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        // Hide the system nav bar; we use our custom header
        .navigationBarHidden(true)
        .onAppear(perform: prefillUsername)
        .alert("Thanks!", isPresented: $showThanks) {
            Button("OK") { dismiss() }
        } message: {
            Text("We will resolve your issue as soon as possible. If your issue is account related we will email you.")
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            Text("Report an Issue")
                .foregroundColor(.white)
                .font(.headline)

            Spacer()

            // keep spacing balanced
            Color.clear.frame(width: 60, height: 1)
        }
    }

    // MARK: - Fields

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .foregroundColor(.white)
            .font(.subheadline)
            .fontWeight(.semibold)
    }

    private func inputField(
        text: Binding<String>,
        placeholder: String,
        isSecure: Bool,
        focusedEquals: Field,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        let base = Group {
            if isSecure {
                SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.gray))
            } else {
                TextField("", text: text, prompt: Text(placeholder).foregroundColor(.gray))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(keyboardType)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)

        return base
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focused == focusedEquals ? Color.accentColor : Color.gray.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: focused == focusedEquals ? Color.accentColor.opacity(0.15) : .clear, radius: 6, y: 3)
    }

    private var messageField: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $message)
                .foregroundColor(.white)
                .padding(10)
                .frame(minHeight: 140)
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(Color.black)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focused == .message ? Color.accentColor : Color.gray.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: focused == .message ? Color.accentColor.opacity(0.15) : .clear, radius: 6, y: 3)
                .onTapGesture { focused = .message }

            if message.isEmpty {
                Text("Describe your issue…")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Actions

    private func prefillUsername() {
        // Try to grab username from your Supabase session (username@vpn.fake)
        do {
            let client = SupabaseManager.shared.client
            Task {
                if let email = try? await client.auth.session.user.email,
                   let base = email.split(separator: "@").first {
                    if username.isEmpty { username = String(base) }
                }
            }
        }
    }

    private func submit() {
        // You can add real submission to Supabase or email here later.
        showThanks = true
    }
}

#Preview {
    NavigationStack { ReportIssueView() }
        .tint(.blue)
        .preferredColorScheme(.dark)
}
