import SwiftUI

struct OutputDeviceRow: View {
    let device: AudioOutputDevice
    let isCurrentOutput: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: device.symbolName)
                .font(.title3)
                .frame(width: 28, alignment: .center)
                .foregroundStyle(isCurrentOutput ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))

            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)

                // The identifiers slice 6 matches on, shown because they are the whole reason
                // that slice is hard and this is where they can be read against a real setup.
                Text("\(device.transport.displayName) · \(device.uid)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                if let modelUID = device.modelUID {
                    Text(modelUID)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .textSelection(.enabled)
                }
            }

            Spacer(minLength: 12)

            if isCurrentOutput {
                Text("Current Output")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
