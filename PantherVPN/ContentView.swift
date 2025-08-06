//
//  ContentView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 06/08/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image("transparentpanthertemplogo")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .aspectRatio(contentMode: .fit)

                    Image("panthertextlogo1")
                        .resizable()
                        .frame(width: 220, height: 35)
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
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black, Color.gray]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
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
        }
    }

    func handleLogin() {
        print("Logging in with \(username), remember me: \(rememberMe)")
    }
}

#Preview {
    ContentView()
}
