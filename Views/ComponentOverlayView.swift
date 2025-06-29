import SwiftUI

struct ComponentOverlayView: View {
    let comp: DetectedComponent
    let idx: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // Component rectangle - this is the main touch target
            Rectangle()
                .stroke(isSelected ? Color.orange : Color.blue, lineWidth: 2)
                .background((isSelected ? Color.orange : Color.blue).opacity(0.2))
                .frame(width: comp.rect.width, height: comp.rect.height)
            
            // Label positioned above the component
            Text(comp.type.description.capitalized + " \(idx + 1)")
                .font(.caption2.bold())
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(6)
                .offset(y: -comp.rect.height/2 - 15) // Position above the rectangle
                .allowsHitTesting(false)  // Make label non-interactive
        }
        .position(x: comp.rect.midX, y: comp.rect.midY)
        .onTapGesture {
            print("🔘 Component \(idx + 1) tapped: \(comp.type.description)")
            onTap()
        }
        .zIndex(isSelected ? 10 : 5) // Selected components appear on top
        .accessibilityLabel("Component: \(comp.type.description)")
        .accessibilityHint("Tap to select or edit component.")
    }
} 