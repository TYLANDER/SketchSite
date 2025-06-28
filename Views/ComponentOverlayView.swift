import SwiftUI

struct ComponentOverlayView: View {
    let comp: DetectedComponent
    let idx: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(isSelected ? Color.orange : Color.blue, lineWidth: 2)
                .background((isSelected ? Color.orange : Color.blue).opacity(0.2))
                .frame(width: comp.rect.width, height: comp.rect.height)
                .position(x: comp.rect.midX, y: comp.rect.midY)
            Text(comp.type.description.capitalized + " \(idx + 1)")
                .font(.caption2.bold())
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(6)
                .position(x: comp.rect.midX, y: comp.rect.minY - 10)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .accessibilityLabel("Component: \(comp.type.description)")
        .accessibilityHint("Double tap to inspect and edit component.")
    }
} 