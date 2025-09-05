//
//  ContentView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 06/08/2025.
//

import SwiftUI
import Supabase
import UIKit        // UIDevice.current.name
import Security     // Keychain
import NetworkExtension

private struct RegisterDeviceParams: Encodable {
    let p_device_id: String
    let p_platform: String
    let p_name: String
}

// MARK: - Simple Keychain helper
private enum Keychain {
    private static let service = "com.panthervpn.app"

    static func set(_ value: String, for key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

struct ContentView: View {
    // MARK: - State
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false

    @State private var rememberMe: Bool = false
    @State private var isLoggedIn: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    // For focused field styling
    @FocusState private var focusedField: Field?
    private enum Field { case username, password }

    // Keys for persistence
    private let rememberKey = "pvpn_remember"
    private let userKey = "pvpn_username"
    private let passKey = "pvpn_password"

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

                        // Password with eye toggle
                        ZStack(alignment: .trailing) {
                            let field = Group {
                                if showPassword {
                                    TextField(
                                        "",
                                        text: $password,
                                        prompt: Text("Password").foregroundColor(.gray)
                                    )
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                } else {
                                    SecureField(
                                        "",
                                        text: $password,
                                        prompt: Text("Password").foregroundColor(.gray)
                                    )
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .focused($focusedField, equals: .password)

                            field
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .password ? Color.accentColor : Color.gray.opacity(0.6), lineWidth: 1)
                                )
                                .shadow(color: focusedField == .password ? Color.accentColor.opacity(0.15) : .clear, radius: 6, y: 3)

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 12)
                            }
                            .accessibilityLabel(Text(showPassword ? "Hide Password" : "Show Password"))
                        }

                        // Remember Me
                        Toggle(isOn: $rememberMe) {
                            Text("Remember Me")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        .padding(.leading, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: rememberMe) { _, newVal in
                            UserDefaults.standard.set(newVal, forKey: rememberKey)
                            if !newVal {
                                Keychain.delete(userKey)
                                Keychain.delete(passKey)
                            }
                        }

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
                                .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 4)
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
                .task {
                    // Bootstraps: load remembered creds, and auto-enter if VPN is connected or session is valid
                    loadRememberedCredentials()
                    await bootstrapAuthState()
                }
            }
        }
    }

    // MARK: - Styled input field (shared for username)
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
        .foregroundColor(.white)
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
            .shadow(color: isFocused ? Color.accentColor.opacity(0.15) : .clear, radius: 6, y: 3)
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
                    .execute()

                // 3) Remember me
                if rememberMe {
                    Keychain.set(username, for: userKey)
                    Keychain.set(password, for: passKey)
                } else {
                    Keychain.delete(userKey)
                    Keychain.delete(passKey)
                }
                UserDefaults.standard.set(rememberMe, forKey: rememberKey)

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

    // MARK: - Bootstrap & helpers

    private func loadRememberedCredentials() {
        let remembered = UserDefaults.standard.bool(forKey: rememberKey)
        rememberMe = remembered
        if remembered {
            if let savedUser = Keychain.get(userKey) { username = savedUser }
            if let savedPass = Keychain.get(passKey) { password = savedPass }
        }
    }

    private func isVPNConnected() async -> Bool {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            if let m = managers.first {
                return m.connection.status == .connected
            }
        } catch { /* ignore */ }
        return false
    }

    private func bootstrapAuthState() async {
        // If VPN is still connected, skip login screen.
        if await isVPNConnected() {
            await MainActor.run { isLoggedIn = true }
            return
        }

        // Otherwise, if Supabase session exists and is valid, skip login.
        let client = SupabaseManager.shared.client
        do {
            _ = try await client.auth.session
            await MainActor.run { isLoggedIn = true }
        } catch {
            // stay on login
        }
    }
}

#Preview {
    ContentView()
        .tint(.blue)
        .preferredColorScheme(.dark)
}



