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
    let price: String       // display only
    let period: String      // e.g. "per month"
    let tag: String?        // e.g. "Best Value"
}

enum PaymentMethod: String, CaseIterable, Identifiable {
    case card = "Card"
    case paypal = "PayPal"
    case btc = "BTC"
    case xmr = "Monero"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .card:   return "creditcard"
        case .paypal: return "link"                 // SF Symbols doesn’t have PayPal; use link icon
        case .btc:    return "bitcoinsign.circle"
        case .xmr:    return "lock.circle"
        }
    }
}

// MARK: - Payment View

struct PaymentView: View {
    private let plans: [Plan] = [
        .init(name: "1 Month",  price: "£9.99",  period: "/mo",   tag: nil),
        .init(name: "3 Months", price: "£24.99", period: "/3 mo", tag: "Popular"),
        .init(name: "12 Months", price: "£79.99", period: "/yr",  tag: "Best Value")
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

                // Header
                VStack(spacing: 6) {
                    Text("Choose Your Plan")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Secure high-speed VPN. Cancel anytime.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)

                // Plans (segmented cards)
                VStack(spacing: 12) {
                    ForEach(plans.indices, id: \.self) { i in
                        planCard(plans[i], isSelected: i == selectedPlanIndex)
                            .onTapGesture { selectedPlanIndex = i }
                    }
                }

                // Payment method selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Method")
                        .font(.headline)

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
                        Text(isProcessing ? "Processing…" : "Continue to Payment")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentColor))
                    .foregroundColor(.white)
                    .shadow(radius: 8, y: 6)
                }
                .disabled(isProcessing)
                .padding(.top, 8)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                        .padding(.top, 4)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Subscribe")
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
                    Text(plan.name).font(.headline)
                    if let tag = plan.tag {
                        Text(tag)
                            .font(.caption2).bold()
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(plan.price).font(.system(size: 22, weight: .semibold))
                    Text(plan.period).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .font(.system(size: 24, weight: .semibold))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: isSelected ? Color.accentColor.opacity(0.15) : .black.opacity(0.06), radius: 10, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func methodTile(_ method: PaymentMethod, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: method.systemIcon)
                .font(.system(size: 22, weight: .semibold))
            Text(method.rawValue).font(.headline)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: isSelected ? Color.accentColor.opacity(0.15) : .black.opacity(0.06), radius: 10, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func handlePay() {
        isProcessing = true
        errorMessage = nil

        let plan = plans[selectedPlanIndex]

        switch selectedMethod {
        case .card:
            // TODO: Present your real card sheet (Stripe SDK suggested)
            isProcessing = false
            errorMessage = "Card flow not wired yet. Hook up Stripe Checkout/PaymentSheet."

        case .paypal:
            // TODO: Open PayPal Checkout URL from your backend
            isProcessing = false
            openURL("https://your-backend.example.com/paypal/checkout?plan=\(plan.name)")

        case .btc, .xmr:
            // Ask your backend for a unique address+amount, then show QR
            // For now we demo with placeholders:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isProcessing = false
                cryptoTicker = (selectedMethod == .btc) ? "BTC" : "XMR"
                cryptoAmount = (selectedMethod == .btc) ? "0.00042" : "0.12"
                cryptoAddress = (selectedMethod == .btc)
                ? "bc1qyourbtcdepositaddressgeneratedbybackend"
                : "47gYourMoneroIntegratedAddrFromBackend"
                showingCryptoSheet = true
            }
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Crypto Sheet (QR + copy)

struct CryptoSheetView: View {
    let ticker: String      // "BTC" / "XMR"
    let amount: String      // display only
    let address: String

    @State private var copied = false

    var body: some View {
        VStack(spacing: 18) {
            Capsule().frame(width: 36, height: 4).foregroundStyle(.secondary.opacity(0.5)).padding(.top, 8)

            Text("\(ticker) Payment")
                .font(.title3).bold()

            if !amount.isEmpty {
                Text("Amount: \(amount) \(ticker)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            QRView(string: address)
                .frame(width: 200, height: 200)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 16).fill(.background).shadow(radius: 8, y: 6))

            VStack(spacing: 8) {
                Text("Address").font(.footnote).foregroundStyle(.secondary)
                Text(address)
                    .font(.footnote)
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
        .presentationBackground(.ultraThinMaterial)
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
            Color.secondary.opacity(0.1)
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
            .tint(Color.blue)
    }
}
