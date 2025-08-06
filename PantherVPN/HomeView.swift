//
//  HomeView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 06/08/2025.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedServer = "Panther Server 1"
    @State private var showDropdown = false

    let servers = [
        "New York, USA",
        "Rio, Brazil",
        "Warsar Poland",
        "Tokyo, Japan"
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            VStack {
                // Top-right gear icon
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 10) {
                        Button(action: {
                            withAnimation {
                                showDropdown.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding(.top, 20)
                                .padding(.trailing, 20)
                        }

                        if showDropdown {
                            VStack(alignment: .leading) {
                                Button("Log Out", action: handleLogout)
                                    .foregroundColor(.white)
                                    .padding(10)
                            }
                            .background(Color.gray.opacity(0.9))
                            .cornerRadius(8)
                            .padding(.trailing)
                        }
                    }
                }

                Spacer()

                // Main content
                VStack(spacing: 24) {
                    Image("transparentpanthertemplogo")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .aspectRatio(contentMode: .fit)

                    Image("panthertextlogo1")
                        .resizable()
                        .frame(width: 220, height: 35)
                        .aspectRatio(contentMode: .fit)

                    Text("Select a server")
                        .foregroundColor(.white)
                        .font(.headline)

                    ZStack {
                        Color(red: 0.1, green: 0.1, blue: 0.1) // Near black
                            .cornerRadius(12)
                            .frame(height: 160)

                        Picker("Select Server", selection: $selectedServer) {
                            ForEach(servers, id: \.self) { server in
                                Text(server).tag(server)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 160)
                        .clipped()
                        .colorScheme(.dark)
                    }
                    .frame(maxWidth: 320)



                    Button(action: handleConnect) {
                        Text("Connect")
                            .foregroundColor(.white)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "609BD1"))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: 320)

                }

                Spacer()
            }
        }
    }

    func handleConnect() {
        print("Connecting to \(selectedServer)")
    }

    func handleLogout() {
        print("Logging out...")
        // Add Supabase logout logic later
    }
}

#Preview {
    HomeView()
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
