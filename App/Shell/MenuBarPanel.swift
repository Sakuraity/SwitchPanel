import AppKit
import SwiftUI

struct MenuBarPanel: View {
    @StateObject private var viewModel = PanelViewModel()
    @ObservedObject private var store = PreferencesStore.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, row in
                ToggleRowView(
                    model: row,
                    onStatefulChange: { on in
                        Task { await viewModel.performToggle(at: index, turnOn: on) }
                    },
                    onAction: {
                        Task { await viewModel.performAction(at: index) }
                    }
                )
            }

            Divider()

            Toggle(isOn: Binding(
                get: { viewModel.loginItem.isOn },
                set: { viewModel.loginItem.setEnabled($0) }
            )) {
                Text("登录时打开")
            }
            .onAppear { viewModel.loginItem.refreshStatus() }

            Divider()

            HStack {
                Button("设置…") {
                    SettingsOpener.open()
                    PanelDismissal.dismissMenuBarPanel()
                }
                Spacer()
                Button("退出 Switch Panel") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
        }
        .padding(12)
        .frame(width: 280)
        .background(
            ClickOutsideMonitor(enabled: true) {
                PanelDismissal.dismissMenuBarPanel()
            }
        )
        .onAppear {
            viewModel.reloadToggleList()
            Task { await viewModel.refreshAll() }
        }
        .onChange(of: store.toggleOrder) { _ in
            viewModel.reloadToggleList()
            Task { await viewModel.refreshAll() }
        }
        .onChange(of: store.hiddenToggleIDs) { _ in
            viewModel.reloadToggleList()
            Task { await viewModel.refreshAll() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .screenCleanStateDidChange)) { _ in
            Task { await viewModel.refreshAll() }
        }
    }
}