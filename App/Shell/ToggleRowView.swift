import SwiftUI

struct ToggleRowView: View {
    let model: ToggleRowModel
    let onStatefulChange: (Bool) -> Void
    let onAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if model.isAction && !model.usesToggleControl {
                Button(model.toggle.title) {
                    onAction()
                }
                .disabled(model.isBusy)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Toggle(isOn: Binding(
                    get: { model.snapshot.isOn ?? false },
                    set: { onStatefulChange($0) }
                )) {
                    Text(model.toggle.title)
                }
                .animation(PanelMotion.toggleSpring, value: model.snapshot.isOn)
                .disabled(model.isBusy || !model.snapshot.isEnabled)
            }

            if let message = model.snapshot.errorMessage, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}