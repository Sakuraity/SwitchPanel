import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var store = PreferencesStore.shared

    var body: some View {
        TabView {
            Form {
                Text("拖动调整菜单栏面板中的开关顺序。取消勾选可在面板中隐藏该项（不改变系统状态）。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                List {
                    ForEach(store.toggleOrder, id: \.self) { id in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { !store.isHidden(id) },
                                set: { store.setHidden(id, hidden: !$0) }
                            )) {
                                Text(id.displayName)
                            }
                        }
                    }
                    .onMove(perform: store.moveToggle)
                }
                .frame(minHeight: 200)
            }
            .padding()
            .tabItem {
                Label {
                    Text("开关")
                } icon: {
                    Image(nsImage: MenuBarIcon.settingsImage)
                }
            }
        }
        .frame(width: 420, height: 320)
    }
}