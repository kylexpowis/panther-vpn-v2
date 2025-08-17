//
//  PaymentView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 17/08/2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Models

struct Plan: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let price: String
    let period: String
    let tag: String?
}

enum PaymentMethod: String, CaseIterable, Identifiable {
    case card = "Card"
    case paypal = "PayPal"
    case btc = "BTC"
    case xmr = "XMR"
    case sol = "SOL"
    case xrp = "XRP"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .card:   return "creditcard"
        case .paypal: return "dollarsign.circle"
        case .btc:    return "bitcoinsign.circle"
        case .xmr:    return "lock.circle"
        case .sol:    return "s.circle"
        case .xrp:    return "x.circle"
        }
    }
}

// MARK: - Payment View

struct PaymentView: View {
    private let plans: [Plan] = [
        .init(name: "1 Month",  price: "£2.99",  period: "/mo",   tag: nil),
        .init(name: "3 Months", price: "£8.97",  period: "/3 mo", tag: "Popular"),
        .init(name: "12 Months", price: "£34.99", period: "/yr",  tag: "Best Value")
    ]

    @State private var selectedPlanIndex = 1
    @State private var selectedMethod: PaymentMethod = .card
    @State private var showingCryptoSheet = false
    @State private var cryptoAddress = ""
    @State private var cryptoAmount: String = ""
    @State private var cryptoTicker: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Empty placeholder instead of title
                Color.clear.frame(height: 0)

                // Header
                VStack(spacing: 6) {
                    Text("Choose Your Plan")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Secure high-speed VPN. Cancel anytime.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 12)

                // Plans
                VStack(spacing: 12) {
                    ForEach(plans.indices, id: \.self) { i in
                        planCard(plans[i], isSelected: i == selectedPlanIndex)
                            .onTapGesture { selectedPlanIndex = i }
                    }
                }

                // Payment methods
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Method")
                        .font(.headline)
                        .foregroundColor(.white)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(PaymentMethod.allCases) { method in
                            methodTile(method, isSelected: method == selectedMethod)
                                .onTapGesture { selectedMethod = method }
                        }
                    }
                }
                .padding(.top, 8)

                // Pay button
                Button(action: handlePay) {
                    HStack(spacing: 8) {
                        if isProcessing { ProgressView().tint(.white) }
                        Text(isProcessing ? "Processing…" : "Continue")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentColor))
                    .foregroundColor(.white)
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 4) // softer glow
                }
                .disabled(isProcessing)
                .padding(.top, 8)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.top, 4)
                }
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showingCryptoSheet) {
            CryptoSheetView(
                ticker: cryptoTicker,
                amount: cryptoAmount,
                address: cryptoAddress
            )
            .presentationDetents([.height(420), .large])
        }
    }

    // MARK: - UI Pieces

    @ViewBuilder
    private func planCard(_ plan: Plan, isSelected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(plan.name).font(.headline).foregroundColor(.white)
                    if let tag = plan.tag {
                        Text(tag)
                            .font(.caption2).bold()
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                            .foregroundColor(Color.accentColor)
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(plan.price).font(.system(size: 22, weight: .semibold)).foregroundColor(.white)
                    Text(plan.period).font(.subheadline).foregroundColor(.gray)
                }
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? Color.accentColor : .gray)
                .font(.system(size: 24, weight: .semibold))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .shadow(color: isSelected ? Color.accentColor.opacity(0.25) : .black.opacity(0.8), radius: 10, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.6), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func methodTile(_ method: PaymentMethod, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: method.systemIcon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            Text(method.rawValue).font(.headline).foregroundColor(.white)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? Color.accentColor : .gray)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .shadow(color: isSelected ? Color.accentColor.opacity(0.25) : .black.opacity(0.8), radius: 10, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func handlePay() {
        isProcessing = true
        errorMessage = nil

        let plan = plans[selectedPlanIndex]

        switch selectedMethod {
        case .card:
            isProcessing = false
            errorMessage = "Card flow not wired yet. Hook up Stripe Checkout/PaymentSheet."

        case .paypal:
            isProcessing = false
            openURL("https://your-backend.example.com/paypal/checkout?plan=\(plan.name)")

        case .btc, .xmr, .sol, .xrp:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isProcessing = false
                switch selectedMethod {
                case .btc:
                    cryptoTicker = "BTC"
                    cryptoAmount = "0.00042"
                    cryptoAddress = "bc1qyourbtcdepositaddressgeneratedbybackend"
                case .xmr:
                    cryptoTicker = "XMR"
                    cryptoAmount = "0.12"
                    cryptoAddress = "47gYourMoneroIntegratedAddrFromBackend"
                case .sol:
                    cryptoTicker = "SOL"
                    cryptoAmount = "1.25"
                    cryptoAddress = "YourSolanaWalletAddressFromBackend"
                case .xrp:
                    cryptoTicker = "XRP"
                    cryptoAmount = "22.5"
                    cryptoAddress = "YourRippleWalletAddressFromBackend"
                default: break
                }
                showingCryptoSheet = true
            }
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Crypto Sheet

struct CryptoSheetView: View {
    let ticker: String
    let amount: String
    let address: String

    @State private var copied = false

    var body: some View {
        VStack(spacing: 18) {
            Capsule().frame(width: 36, height: 4).foregroundColor(.gray).padding(.top, 8)

            Text("\(ticker) Payment")
                .font(.title3).bold()
                .foregroundColor(.white)

            if !amount.isEmpty {
                Text("Amount: \(amount) \(ticker)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            QRView(string: address)
                .frame(width: 200, height: 200)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.black).shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 6))

            VStack(spacing: 8) {
                Text("Address").font(.footnote).foregroundColor(.gray)
                Text(address)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                    .padding(.horizontal)
            }

            Button {
                UIPasteboard.general.string = address
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
            } label: {
                Label(copied ? "Copied" : "Copy Address", systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentColor))
                    .foregroundColor(.white)
            }
            .padding(.top, 6)

            Spacer(minLength: 8)
        }
        .padding(20)
        .background(Color.black)
    }
}

// MARK: - QR Generator

struct QRView: View {
    let string: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let image = generateQR(from: string) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Color.gray.opacity(0.3)
        }
    }

    private func generateQR(from string: String) -> UIImage? {
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        if let cgimg = context.createCGImage(scaled, from: scaled.extent) {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
}

// MARK: - Preview

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { PaymentView() }
            .tint(.blue)
            .preferredColorScheme(.dark)
    }
}


