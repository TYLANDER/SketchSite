import SwiftUI

/// Debug overlay view to visualize UI areas and identify truncation issues
struct DebugOverlayView: View {
    let geometry: GeometryProxy
    @State private var showDebug = true
    
    var body: some View {
        ZStack {
            if showDebug {
                // Canvas bounds (full geometry)
                Rectangle()
                    .stroke(Color.red, lineWidth: 3)
                    .fill(Color.red.opacity(0.1))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .overlay(
                        Text("CANVAS AREA\n\(Int(geometry.size.width)) × \(Int(geometry.size.height))")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4)
                            .position(x: geometry.size.width / 2, y: 50)
                    )
                
                // Safe area bounds
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .fill(Color.blue.opacity(0.1))
                    .frame(
                        width: geometry.size.width - geometry.safeAreaInsets.leading - geometry.safeAreaInsets.trailing,
                        height: geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                    .overlay(
                        Text("SAFE AREA\n\(Int(geometry.size.width - geometry.safeAreaInsets.leading - geometry.safeAreaInsets.trailing)) × \(Int(geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom))")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 50)
                    )
                
                // Top safe area
                Rectangle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: geometry.size.width, height: geometry.safeAreaInsets.top)
                    .position(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top / 2)
                    .overlay(
                        Text("TOP SAFE: \(Int(geometry.safeAreaInsets.top))pt")
                            .font(.caption2.bold())
                            .foregroundColor(.orange)
                            .position(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top / 2)
                    )
                
                // Bottom safe area
                Rectangle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: geometry.size.width, height: geometry.safeAreaInsets.bottom)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - geometry.safeAreaInsets.bottom / 2)
                    .overlay(
                        Text("BOTTOM SAFE: \(Int(geometry.safeAreaInsets.bottom))pt")
                            .font(.caption2.bold())
                            .foregroundColor(.orange)
                            .position(x: geometry.size.width / 2, y: geometry.size.height - geometry.safeAreaInsets.bottom / 2)
                    )
                
                // Header area estimate (assuming ~80pt height)
                Rectangle()
                    .stroke(Color.green, lineWidth: 2)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: geometry.size.width, height: 80)
                    .position(x: geometry.size.width / 2, y: 40)
                    .overlay(
                        Text("HEADER AREA (80pt)")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                            .position(x: geometry.size.width / 2, y: 40)
                    )
                
                // Toolbar area estimate (assuming ~80pt height)
                Rectangle()
                    .stroke(Color.purple, lineWidth: 2)
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: geometry.size.width, height: 80)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 40)
                    .overlay(
                        Text("TOOLBAR AREA (80pt)")
                            .font(.caption.bold())
                            .foregroundColor(.purple)
                            .position(x: geometry.size.width / 2, y: geometry.size.height - 40)
                    )
                
                // Drawable canvas area (between header and toolbar)
                Rectangle()
                    .stroke(Color.cyan, lineWidth: 2)
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: geometry.size.width, height: geometry.size.height - 160) // Minus header and toolbar
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .overlay(
                        Text("DRAWABLE AREA\n\(Int(geometry.size.width)) × \(Int(geometry.size.height - 160))")
                            .font(.caption.bold())
                            .foregroundColor(.cyan)
                            .multilineTextAlignment(.center)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 50)
                    )
                
                // Debug info panel
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEBUG INFO")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                    
                    Text("Screen: \(Int(UIScreen.main.bounds.width)) × \(Int(UIScreen.main.bounds.height))")
                        .font(.caption2)
                    
                    Text("Geometry: \(Int(geometry.size.width)) × \(Int(geometry.size.height))")
                        .font(.caption2)
                    
                    Text("Safe Top: \(Int(geometry.safeAreaInsets.top))")
                        .font(.caption2)
                    
                    Text("Safe Bottom: \(Int(geometry.safeAreaInsets.bottom))")
                        .font(.caption2)
                    
                    Text("Safe Leading: \(Int(geometry.safeAreaInsets.leading))")
                        .font(.caption2)
                    
                    Text("Safe Trailing: \(Int(geometry.safeAreaInsets.trailing))")
                        .font(.caption2)
                }
                .padding(8)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                .position(x: 100, y: geometry.size.height / 2)
                
                // Toggle button
                Button(action: { showDebug.toggle() }) {
                    Text(showDebug ? "Hide Debug" : "Show Debug")
                        .font(.caption.bold())
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .position(x: geometry.size.width - 70, y: 30)
            } else {
                // Just the toggle button when hidden
                Button(action: { showDebug.toggle() }) {
                    Text("Show Debug")
                        .font(.caption.bold())
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .position(x: geometry.size.width - 70, y: 30)
            }
        }
        .allowsHitTesting(true)
        .zIndex(9999) // Highest z-index to appear on top
    }
}

#if DEBUG
struct DebugOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            DebugOverlayView(geometry: geometry)
        }
    }
}
#endif 