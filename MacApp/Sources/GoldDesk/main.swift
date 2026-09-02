import SwiftUI
import AppKit
import ApplicationServices

private let chatBundleID = "com.openai.codex"
private let tradingViewBundleID = "com.tradingview.tradingviewapp.desktop"
private let chartURL = URL(string: "https://www.tradingview.com/chart/?symbol=OANDA%3AXAUUSD&interval=15")!
private let starterPrompt = """
@Computer Use the signed-in TradingView Mac app. Keep OANDA:XAUUSD on the 15-minute chart. Manage only drawings labelled AUTO ZONE. Never place, close, or modify any live or demo trade.
"""

enum AppAvailability: Equatable {
    case ready
    case missing

    var label: String {
        switch self {
        case .ready: return "Installed"
        case .missing: return "Not found"
        }
    }

    var color: Color {
        switch self {
        case .ready: return Color(red: 0.31, green: 0.78, blue: 0.56)
        case .missing: return Color(red: 0.95, green: 0.45, blue: 0.38)
        }
    }
}

@MainActor
final class WorkspaceController: ObservableObject {
    @Published var chatAvailability: AppAvailability = .missing
    @Published var chartAvailability: AppAvailability = .missing
    @Published var hasAccessibilityAccess = AXIsProcessTrusted()
    @Published var activity = "Ready to open your Mac trading workspace."
    @Published var isWorking = false

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        chatAvailability = applicationURL(for: chatBundleID) == nil ? .missing : .ready
        chartAvailability = applicationURL(for: tradingViewBundleID) == nil ? .missing : .ready
        hasAccessibilityAccess = AXIsProcessTrusted()
    }

    func openWorkspace() {
        refreshStatus()
        guard chatAvailability == .ready, chartAvailability == .ready else {
            activity = "Install the missing app, then try again."
            return
        }

        isWorking = true
        activity = "Opening ChatGPT and the saved XAUUSD 15-minute chart…"
        launchChatGPT()
        launchTradingViewChart()

        Task {
            try? await Task.sleep(for: .seconds(2.2))
            arrangeWorkspace(promptForPermission: true)
            isWorking = false
        }
    }

    func openChart() {
        refreshStatus()
        guard chartAvailability == .ready else {
            activity = "TradingView for Mac was not found."
            return
        }
        activity = "Opening the saved OANDA:XAUUSD 15-minute chart…"
        launchTradingViewChart()
    }

    func arrangeAgain() {
        isWorking = true
        arrangeWorkspace(promptForPermission: true)
        isWorking = false
    }

    func copyStarterPrompt() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(starterPrompt, forType: .string)
        activity = "Starter instruction copied. Paste it into ChatGPT."
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    private func applicationURL(for bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    private func launchChatGPT() {
        guard let appURL = applicationURL(for: chatBundleID) else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
            if let error {
                Task { @MainActor in self.activity = "ChatGPT could not open: \(error.localizedDescription)" }
            }
        }
    }

    private func launchTradingViewChart() {
        guard let appURL = applicationURL(for: tradingViewBundleID) else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([chartURL], withApplicationAt: appURL, configuration: configuration) { _, error in
            if let error {
                Task { @MainActor in self.activity = "TradingView could not open: \(error.localizedDescription)" }
            }
        }
    }

    private func arrangeWorkspace(promptForPermission: Bool) {
        hasAccessibilityAccess = requestAccessibilityAccess(prompt: promptForPermission)
        guard hasAccessibilityAccess else {
            activity = "Allow GoldDesk in Accessibility, then click Arrange Again."
            return
        }

        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            activity = "No display was available for window arrangement."
            return
        }

        let visible = screen.visibleFrame
        let gap: CGFloat = 8
        let leftWidth = floor((visible.width - gap) * 0.42)
        let rightWidth = visible.width - gap - leftWidth
        let topInset = screen.frame.maxY - visible.maxY

        let chatFrame = CGRect(
            x: visible.minX,
            y: topInset,
            width: leftWidth,
            height: visible.height
        )
        let chartFrame = CGRect(
            x: visible.minX + leftWidth + gap,
            y: topInset,
            width: rightWidth,
            height: visible.height
        )

        let chatResult = arrangeFirstAvailableWindow(bundleID: chatBundleID, frame: chatFrame)
        let chartResult = arrangeFirstAvailableWindow(bundleID: tradingViewBundleID, frame: chartFrame)

        if chatResult.succeeded && chartResult.succeeded {
            activity = "Workspace ready: ChatGPT left, TradingView right."
            NSRunningApplication.runningApplications(withBundleIdentifier: chatBundleID).first?.activate(options: [.activateIgnoringOtherApps])
        } else {
            let missing = [
                chatResult.succeeded ? nil : "ChatGPT (\(chatResult.detail))",
                chartResult.succeeded ? nil : "TradingView (\(chartResult.detail))"
            ].compactMap { $0 }.joined(separator: ", ")
            activity = "Apps opened. Could not arrange: \(missing). Open that window once, then click Arrange Again."
        }
    }

    private func requestAccessibilityAccess(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private struct WindowArrangementResult {
        let succeeded: Bool
        let detail: String
    }

    private func arrangeFirstAvailableWindow(bundleID: String, frame: CGRect) -> WindowArrangementResult {
        guard let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            return WindowArrangementResult(succeeded: false, detail: "app is not running")
        }

        let appElement = AXUIElementCreateApplication(runningApp.processIdentifier)
        var candidates: [AXUIElement] = []

        for attribute in [kAXFocusedWindowAttribute, kAXMainWindowAttribute] {
            var value: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, attribute as CFString, &value) == .success,
               let window = value as! AXUIElement? {
                candidates.append(window)
            }
        }

        var windowsValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
        if result == .success, let windows = windowsValue as? [AXUIElement] {
            candidates.append(contentsOf: windows)
        }

        guard !candidates.isEmpty else {
            return WindowArrangementResult(succeeded: false, detail: "no movable window found")
        }

        var lastPositionResult: AXError = .failure
        var lastSizeResult: AXError = .failure

        var position = frame.origin
        var size = frame.size
        guard let positionValue = AXValueCreate(.cgPoint, &position),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            return WindowArrangementResult(succeeded: false, detail: "window frame unavailable")
        }

        for window in candidates {
            lastPositionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
            lastSizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
            if lastPositionResult == .success && lastSizeResult == .success {
                return WindowArrangementResult(succeeded: true, detail: "arranged")
            }
        }

        return WindowArrangementResult(
            succeeded: false,
            detail: "window control error \(lastPositionResult.rawValue)/\(lastSizeResult.rawValue)"
        )
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let availability: AppAvailability

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color(red: 0.90, green: 0.71, blue: 0.34))
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle().fill(availability.color).frame(width: 7, height: 7)
                Text(availability.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07)))
    }
}

struct WorkflowStep: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(red: 0.95, green: 0.78, blue: 0.42))
                .frame(width: 25, height: 25)
                .background(Color(red: 0.45, green: 0.31, blue: 0.10).opacity(0.55), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(detail).font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

struct ContentView: View {
    @StateObject private var controller = WorkspaceController()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.075, green: 0.075, blue: 0.065), Color(red: 0.025, green: 0.028, blue: 0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    HStack(spacing: 14) {
                        StatusRow(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "ChatGPT for Mac",
                            subtitle: "Uses your existing signed-in desktop app",
                            availability: controller.chatAvailability
                        )
                        StatusRow(
                            icon: "chart.xyaxis.line",
                            title: "TradingView for Mac",
                            subtitle: "Uses your existing signed-in chart and layout",
                            availability: controller.chartAvailability
                        )
                    }

                    actions
                    permissionCard
                    workflowCard
                    footer
                }
                .padding(30)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { controller.refreshStatus() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("MAC WORKSPACE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.1)
                    .foregroundStyle(Color(red: 0.93, green: 0.73, blue: 0.36))
                Text("GoldDesk")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Your signed-in ChatGPT and TradingView apps, ready side by side.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("MAC ONLY")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.3)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.10)))
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button(action: controller.openWorkspace) {
                HStack {
                    if controller.isWorking { ProgressView().controlSize(.small) }
                    Image(systemName: "rectangle.split.2x1.fill")
                    Text("Open Trading Workspace")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 18)
                .frame(height: 52)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(red: 0.09, green: 0.075, blue: 0.035))
            .background(Color(red: 0.93, green: 0.73, blue: 0.36), in: RoundedRectangle(cornerRadius: 13))
            .disabled(controller.isWorking)

            HStack(spacing: 10) {
                secondaryButton("Arrange Again", icon: "rectangle.split.2x1", action: controller.arrangeAgain)
                secondaryButton("Open XAUUSD 15m", icon: "chart.candlestick", action: controller.openChart)
                secondaryButton("Copy Starter Instruction", icon: "doc.on.doc", action: controller.copyStarterPrompt)
            }
        }
    }

    private func secondaryButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 39)
        }
        .buttonStyle(.plain)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.09)))
    }

    private var permissionCard: some View {
        HStack(spacing: 13) {
            Image(systemName: controller.hasAccessibilityAccess ? "checkmark.shield.fill" : "hand.raised.fill")
                .font(.system(size: 18))
                .foregroundStyle(controller.hasAccessibilityAccess ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text(controller.hasAccessibilityAccess ? "Window arrangement allowed" : "One-time Mac permission needed")
                    .font(.system(size: 13, weight: .semibold))
                Text(controller.hasAccessibilityAccess
                     ? "GoldDesk can place the two official apps side by side."
                     : "Allow GoldDesk in System Settings → Privacy & Security → Accessibility. This only lets GoldDesk arrange windows.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !controller.hasAccessibilityAccess {
                Button("Open Settings", action: controller.openAccessibilitySettings)
                    .controlSize(.small)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.065), in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.orange.opacity(0.18)))
    }

    private var workflowCard: some View {
        VStack(alignment: .leading, spacing: 17) {
            Text("How chart requests work")
                .font(.system(size: 15, weight: .semibold))
            WorkflowStep(number: "1", title: "Open the workspace", detail: "GoldDesk launches your official signed-in apps—no second website login.")
            WorkflowStep(number: "2", title: "Ask in ChatGPT", detail: "Example: “@Computer mark the nearest major BUY and SELL zones on XAUUSD 15m.”")
            WorkflowStep(number: "3", title: "Review the chart", detail: "Computer Use may draw or clear marked zones. You stay in control and place any trade yourself.")
        }
        .padding(18)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07)))
    }

    private var footer: some View {
        HStack(spacing: 9) {
            Image(systemName: "checkmark.shield")
                .foregroundStyle(Color(red: 0.31, green: 0.78, blue: 0.56))
            Text(controller.activity)
                .font(.system(size: 11, weight: .medium))
            Spacer()
            Text("Chart drawings only · Never places or modifies trades")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
    }
}

final class GoldDeskAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first else { return }
            window.setContentSize(NSSize(width: 840, height: 720))
            window.center()
        }
    }
}

@main
struct GoldDeskApp: App {
    @NSApplicationDelegateAdaptor(GoldDeskAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 690)
        }
        .defaultSize(width: 840, height: 760)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
