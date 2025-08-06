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

    let plans = [
        ("1 Month £3.99", "1_month"),
        ("3 Months £11.97", "3_months"),
        ("6 Months £23.94", "6_months"),
        ("1 Year £47.88", "1_year")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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

                Group {
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .foregroundColor(.black)

                Text("Notice: Please make sure to note down your username and password, as we cannot recover or reset due to a security feature.")
                    .foregroundColor(.yellow)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)

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

                Text("Select Subscription:")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)

                Picker("Select Plan", selection: $selectedPlan) {
                    ForEach(plans, id: \.1) { plan in
                        Text(plan.0)
                            .foregroundColor(.white)
                            .tag(plan.1)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
                .clipped()

                Button(action: handleSignup) {
                    Text("Continue to Payment")
                        .foregroundColor(.white)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#609bd1"))
                        .cornerRadius(8)
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

    func handleSignup() {
        guard !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "Please fill all fields."
            showAlert = true
            return
        }

        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showAlert = true
            return
        }

        // TODO: Call your Supabase signup logic here
        print("Signing up \(username) for plan \(selectedPlan)")
    }
}

#Preview {
    SignupView()
}


