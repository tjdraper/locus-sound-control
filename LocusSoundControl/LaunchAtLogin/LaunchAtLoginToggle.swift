import SwiftUI

struct LaunchAtLoginToggle: View {
    let store: LaunchAtLoginStore

    var body: some View {
        Toggle("Open at login", isOn: Binding(get: { store.isEnabled }, set: store.setEnabled))

        if store.needsApproval || store.changeFailed {
            LabeledContent {
                Button("Open Login Items") {
                    store.openLoginItemsSettings()
                }
            } label: {
                Text(store.needsApproval ? "Waiting for approval in System Settings" : "macOS didn’t accept the change")
            }
        }
    }
}
