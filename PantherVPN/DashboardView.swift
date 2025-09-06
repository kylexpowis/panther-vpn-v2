//
//  DashboardView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 05/09/2025.
//


import SwiftUI
import Supabase
import UIKit
import NetworkExtension

struct DashboardView: View {

    // MARK: - Model
    struct Plan: Identifiable, Hashable {
        let id: String   // "1m" | "3m" | "12m" | "3y"
        let name: String
        let price: String
        let amount: Double
    }
    enum Step { case plans, methods, success }
    enum Method: String, CaseIterable { case card, paypal, btc, xmr, sol, xrp }

    private let plans: [Plan] = [
        .init(id: "1m",  name: "1 Month",   price: "£4.99",  amount: 4.99),
        .init(id: "3m",  name: "3 Months",  price: "£9.99",  amount: 9.99),
        .init(id: "12m", name: "12 Months", price: "£39.99", amount: 39.99),
        .init(id: "3y",  name: "3 Years",   price: "£109.99",amount: 109.99),
    ]

    // MARK: - State
    @State private var username: String = "…"
    @State private var isActive: Bool = false
    @State private var activePlanCode: String? = nil
    @State private var selectedPlanId: String = "1m"
    @State private var step: Step = .plans
    @State private var method: Method = .card
    @State private var processing: Bool = false
    @State private var showMenu: Bool = false
    @State private var gotoPayment: Bool = false

    private let corner: CGFloat = 16

    // MARK: - Derived
    private var selectedPlan: Plan? { plans.first { $0.id == selectedPlanId } }
    private var statusColor: Color { isActive ? .green : .red }
    private var statusText: String { isActive ? "Active" : "Inactive — pick a plan to activate" }
    private var displayedPlanName: String {
        if isActive, let code = activePlanCode { return nameForPlan(code) }
        return selectedPlan?.name ?? "—"
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [.black, .black, Color.blue.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    header  // <- now includes the dropdown inline (pushes content)

                    if !isActive {
                        banner
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    ScrollView {
                        VStack(spacing: 14) {
                            AccountCardView(
                                username: username,
                                isActive: isActive,
                                planName: displayedPlanName
                            )

                            switch step {
                            case .plans:
                                PlansPanelView(
                                    corner: corner,
                                    plans: plans,
                                    selectedPlanId: $selectedPlanId,
                                    onContinue: { withAnimation { step = .methods } }
                                )

                            case .methods:
                                MethodsPanelView(
                                    corner: corner,
                                    method: $method,
                                    selectedPlanName: selectedPlan?.name ?? "—",
                                    selectedPlanPrice: selectedPlan?.price ?? "",
                                    processing: processing,
                                    onBack: { withAnimation { step = .plans } },
                                    onPayNow: { Task { await handlePayNow() } }
                                )

                            case .success:
                                SuccessPanelView(corner: corner, isActive: isActive)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(
                NavigationLink("", destination: PaymentView(), isActive: $gotoPayment)
                    .opacity(0)
            )
        }
        .task { await loadProfileStatus() }
    }

    // MARK: - Header & Banner
    private var header: some View {
        VStack(spacing: 8) {
            // Top row (status + settings button)
            HStack {
                HStack(spacing: 8) {
                    Circle().fill(statusColor).frame(width: 10, height: 10)
                    Text(username)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    let pillFill = (isActive ? Color.green : Color.red).opacity(0.12)
                    let pillStroke = (isActive ? Color.green : Color.red).opacity(0.3)
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(isActive ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(pillFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(pillStroke, lineWidth: 1)
                                )
                        )
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.25)) { showMenu.toggle() }
                } label: {
                    Text("Settings ▾")
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                }
            }

            // Inline dropdown (right-aligned, intrinsic width, pushes content)
            if showMenu {
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 0) {
                        menuButton(title: "Report an issue") {
                            if let url = URL(string: "mailto:support@panthervpn.app?subject=Issue%20Report") {
                                UIApplication.shared.open(url)
                            }
                            showMenu = false
                        }
                        Divider().background(Color.white.opacity(0.1))
                        menuButton(title: "Logout") {
                            Task { await logoutAndReturnToRoot() }
                            showMenu = false
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: Color.accentColor.opacity(0.25), radius: 10, y: 6)
                    )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.top, 14)
        .animation(.spring(response: 0.25), value: showMenu)
    }

    private var banner: some View {
        HStack {
            Text("✅ Account created. Choose a plan below to activate your VPN.")
                .foregroundColor(Color.blue.opacity(0.9))
                .font(.subheadline)
                .padding(10)
            Spacer(minLength: 0)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Small UI helpers
    private func menuButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                // no fixed width -> intrinsic sizing (just wider than text)
                .frame(alignment: .leading)
        }
        .contentShape(Rectangle())
    }

    private func nameForPlan(_ code: String) -> String {
        switch code {
        case "1m":  return "1 Month"
        case "3m":  return "3 Months"
        case "12m": return "12 Months"
        case "3y":  return "3 Years"
        default:    return "—"
        }
    }

    // MARK: - Actions
    private func handlePayNow() async {
        if processing { return }
        await MainActor.run { processing = true }
        defer { Task { await MainActor.run { processing = false } } }

        switch method {
        case .card:
            await MainActor.run { gotoPayment = true }
        case .paypal, .btc:
            await MainActor.run {
                step = .success
                isActive = true
                activePlanCode = selectedPlanId
            }
        case .xmr, .sol, .xrp:
            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }

    private func logoutAndReturnToRoot() async {
        let client = SupabaseManager.shared.client
        try? await client.auth.signOut()

        await MainActor.run {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else { return }
            window.rootViewController = UIHostingController(rootView: ContentView())
            window.makeKeyAndVisible()
        }
    }

    // MARK: - Profile / Status
    private func loadProfileStatus() async {
        struct ProfileRow: Decodable {
            let username: String?
            let is_active: Bool?
            let active_until: String?
            let plan_1_month: Bool?
            let plan_3_months: Bool?
            let plan_1_year: Bool?
            let plan_3_years: Bool?
        }

        do {
            let client = SupabaseManager.shared.client
            let session = try await client.auth.session

            if let email = session.user.email,
               let base = email.split(separator: "@").first {
                username = String(base)
            }

            let response = try await client
                .from("profiles")
                .select("username,is_active,active_until,plan_1_month,plan_3_months,plan_1_year,plan_3_years")
                .single()
                .execute()

            let data: Data = response.data

            if let decoded = try? JSONDecoder().decode(ProfileRow.self, from: data) {
                if let u = decoded.username, !u.isEmpty { username = u }

                var active = decoded.is_active ?? false
                if let ts = decoded.active_until,
                   let until = ISO8601DateFormatter().date(from: ts),
                   until < Date() {
                    active = false
                }
                isActive = active

                if active {
                    if decoded.plan_1_year == true { activePlanCode = "12m" }
                    else if decoded.plan_3_years == true { activePlanCode = "3y" }
                    else if decoded.plan_3_months == true { activePlanCode = "3m" }
                    else if decoded.plan_1_month == true { activePlanCode = "1m" }
                } else {
                    activePlanCode = nil
                }

                if isActive { step = .success }
            }
        } catch {
            // Non-fatal; keep defaults
        }
    }
}

// MARK: - Subviews

private struct AccountCardView: View {
    let username: String
    let isActive: Bool
    let planName: String
    private let corner: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Account")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Row(label: "Username", value: username)
            Row(label: "Status", value: isActive ? "Active" : "Inactive", valueColor: isActive ? .green : .red)
            Row(label: "Plan", value: planName)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.6), radius: 12, y: 6)
        )
    }
}

private struct Row: View {
    let label: String
    let value: String
    var valueColor: Color = .white

    var body: some View {
        HStack {
            Text(label).foregroundColor(.white.opacity(0.75))
            Spacer()
            Text(value).foregroundColor(valueColor).fontWeight(.medium)
        }
    }
}

private struct PlansPanelView: View {
    let corner: CGFloat
    let plans: [DashboardView.Plan]
    @Binding var selectedPlanId: String
    var onContinue: () -> Void

    private let cols: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose your plan")
                .foregroundColor(.white)
                .font(.headline)

            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(plans) { p in
                    Button {
                        selectedPlanId = p.id
                    } label: {
                        PlanCard(plan: p, isSelected: selectedPlanId == p.id, corner: corner)
                    }
                }
            }

            VStack(spacing: 6) {
                Button(action: onContinue) {
                    Text("Continue to Payment")
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: corner)
                                .fill(Color.blue)
                                .shadow(color: Color.blue.opacity(0.35), radius: 10, y: 5)
                        )
                }
                Text("You’ll pick a payment method on the next step.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct PlanCard: View {
    let plan: DashboardView.Plan
    let isSelected: Bool
    let corner: CGFloat

    var body: some View {
        let borderColor: Color = isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.1)

        VStack(alignment: .leading, spacing: 6) {
            Text(plan.name)
                .foregroundColor(.white)
                .fontWeight(.medium)
            Text("Unlimited speed · Zero logs")
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)

            Spacer()

            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .foregroundColor(.white)
                        .font(.headline)
                    Text("VAT included")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption2)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(borderColor, lineWidth: isSelected ? 1.5 : 1)
                )
        )
    }
}

private struct MethodsPanelView: View {
    let corner: CGFloat
    @Binding var method: DashboardView.Method
    let selectedPlanName: String
    let selectedPlanPrice: String
    let processing: Bool
    var onBack: () -> Void
    var onPayNow: () -> Void

    private let cols: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Button(action: onBack) {
                    Text("← Back")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
                Text("Select payment method")
                    .foregroundColor(.white)
                    .font(.headline)
            }

            HStack(spacing: 4) {
                Text("Selected:")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.footnote)
                Text(selectedPlanName)
                    .foregroundColor(.white)
                    .font(.footnote)
                Text("· \(selectedPlanPrice)")
                    .foregroundColor(.white)
                    .font(.footnote)
            }

            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(DashboardView.Method.allCases, id: \.self) { m in
                    Button {
                        method = m
                    } label: {
                        MethodRow(method: m, isSelected: method == m, corner: corner)
                    }
                }
            }

            VStack(spacing: 6) {
                Button(action: onPayNow) {
                    Text(processing ? "Processing…" : "Pay Now — \(selectedPlanPrice)")
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: corner)
                                .fill(Color.blue)
                                .shadow(color: Color.blue.opacity(0.35), radius: 10, y: 5)
                        )
                }
                .disabled(processing)

                Text("A popup/redirect will appear for \(method.rawValue.uppercased()).")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct MethodRow: View {
    let method: DashboardView.Method
    let isSelected: Bool
    let corner: CGFloat

    private var title: String {
        switch method {
        case .card:   return "Card"
        case .paypal: return "PayPal"
        case .btc:    return "BTC"
        case .xmr:    return "XMR"
        case .sol:    return "SOL"
        case .xrp:    return "XRP"
        }
    }

    var body: some View {
        let iconName = isSelected ? "checkmark.circle.fill" : "circle"
        let iconColor: Color = isSelected ? .blue : .gray
        let strokeColor: Color = isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.1)

        HStack {
            Text(title).foregroundColor(.white)
            Spacer()
            Image(systemName: iconName).foregroundColor(iconColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(strokeColor, lineWidth: 1)
                )
        )
    }
}

private struct SuccessPanelView: View {
    let corner: CGFloat
    let isActive: Bool

    var body: some View {
        let title = isActive ? "Account active" : "Account inactive"
        let titleColor: Color = isActive ? .green : .red

        let message = isActive
            ? "You can now secure the connection on your device."
            : "Please purchase a plan to activate your connection."

        let boxIcon = isActive ? "checkmark.seal.fill" : "xmark.octagon.fill"
        let boxColor: Color = isActive ? .green : .red
        let boxText = isActive
            ? "Open the app and connect."
            : "Please purchase a plan to activate your connection."

        return VStack(spacing: 12) {
            Text(title)
                .foregroundColor(titleColor)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            HStack(alignment: .center, spacing: 8) {
                Image(systemName: boxIcon)
                    .foregroundColor(boxColor)
                Text(boxText)
                    .foregroundColor(boxColor.opacity(0.9))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(boxColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(boxColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    DashboardView()
        .tint(.blue)
        .preferredColorScheme(.dark)
}






