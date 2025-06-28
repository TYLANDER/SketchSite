import SwiftUI

struct ToolbarButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.title2)
                Text(label).font(.caption)
            }
            .frame(minWidth: 60, minHeight: 44)
        }
    }
} 