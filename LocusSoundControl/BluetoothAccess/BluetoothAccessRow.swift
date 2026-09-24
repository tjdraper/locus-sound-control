import CoreBluetooth
import SwiftUI

struct BluetoothAccessRow: View {
    let store: BluetoothAccessStore

    var body: some View {
        LabeledContent {
            switch store.authorization {
            case .allowedAlways:
                Label {
                    Text("Allowed")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            case .notDetermined:
                Button("Allow…") {
                    store.requestAccess()
                }
            case .restricted:
                Text("Restricted")
                    .foregroundStyle(.secondary)
            default:
                Button("Open System Settings") {
                    store.openBluetoothSettings()
                }
            }
        } label: {
            Text("Bluetooth access")
            Text(explanation)
        }
    }

    private var explanation: String {
        switch store.authorization {
        case .allowedAlways:
            "Bluetooth speakers, headphones and car audio each get their own icon."
        case .restricted:
            "This Mac’s administrator doesn’t allow it. Some Bluetooth speakers show a headphones icon."
        default:
            "Without it, some Bluetooth speakers and car audio show a headphones icon."
        }
    }
}
