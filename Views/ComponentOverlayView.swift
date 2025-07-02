import SwiftUI
import UIKit

// MARK: - Component Overlay with Integrated Resize Handles

struct ComponentOverlayView: View {
    @Binding var comp: DetectedComponent
    let idx: Int
    let isSelected: Bool
    let onTap: () -> Void
    let onDrag: (CGPoint) -> Void
    let onResize: (CGRect) -> Void
    let onInspect: () -> Void
    let canvasSize: CGSize
    
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var isLongPressing = false
    @State private var showInspectorHighlight = false
    @State private var longPressProgress: CGFloat = 0.0
    
    // Resize handle properties
    private let handleSize: CGFloat = 12
    private let handlePositions: [HandlePosition] = [
        .topLeft, .top, .topRight,
        .left, .right,
        .bottomLeft, .bottom, .bottomRight
    ]
    
    // Geometry calculator for centralized calculations
    private let geometryCalculator = GeometryCalculator()

    var body: some View {
        ZStack {
            // Main component rectangle with visual feedback
            Rectangle()
                .stroke(strokeColor, lineWidth: strokeWidth)
                .fill(Color.blue.opacity(0.2))
                .frame(width: componentWidth, height: componentHeight)
                .scaleEffect(componentScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: componentScale)
                .animation(.easeInOut(duration: 0.2), value: strokeColor)
                .animation(.easeInOut(duration: 0.2), value: strokeWidth)
            
            // Purple highlight glow effect for long press feedback
            if showInspectorHighlight {
                Rectangle()
                    .stroke(Color.purple, lineWidth: 2)
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: componentWidth + 4, height: componentHeight + 4)
                    .blur(radius: 4)
                    .opacity(longPressProgress * 0.6)
                    .animation(.easeInOut(duration: 0.4), value: longPressProgress)
            }
            
            // Resize handles - only show when selected
            if isSelected {
                resizeHandles
            }
            
            // Component label - always visible
            componentLabel
        }
        .position(x: clampedX, y: clampedY)
        .simultaneousGesture(dragGesture)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onChanged { pressing in
                    handleLongPressStateChange(pressing: pressing)
                }
                .onEnded { _ in
                    handleLongPress()
                }
        )
        .onTapGesture {
            handleTap()
        }
        .allowsHitTesting(true)
        .zIndex(isSelected ? 100 : 50) // Selected components appear above others
        .accessibilityLabel("Component: \(comp.type.description)")
        .accessibilityHint("Tap to select, long press to inspect, drag to move, or use handles to resize component.")
    }
    
    // MARK: - Visual Feedback Properties
    
    private var strokeWidth: CGFloat {
        if isResizing {
            return 10
        } else if isDragging {
            return 8
        } else if showInspectorHighlight {
            return 6
        } else if isSelected {
            return 3 // Show border when selected
        } else {
            return 2 // Show border for unselected components too
        }
    }
    
    private var componentScale: CGFloat {
        if isDragging {
            return 1.0
        } else if showInspectorHighlight && longPressProgress > 0.5 {
            return 1.05
        } else {
            return 1.0
        }
    }
    
    // MARK: - Resize Handles as Component Attributes
    
    private var resizeHandles: some View {
        ZStack {
            ForEach(handlePositions, id: \.self) { position in
                ResizeHandle(
                    position: position,
                    onResizeStart: handleResizeStart,
                    onResize: { translation in handleResize(position: position, translation: translation) },
                    onResizeEnd: handleResizeEnd
                )
                .offset(handleOffset(for: position))
            }
        }
        .frame(width: componentWidth, height: componentHeight)
    }
    
    // MARK: - Component Label
    
    private var componentLabel: some View {
        Text(comp.type.description.capitalized)
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.8))
            .cornerRadius(4)
            .offset(y: -componentHeight/2 - 12)
            .allowsHitTesting(false)
    }
    
    // MARK: - Computed Properties
    
    private var componentWidth: CGFloat {
        min(comp.rect.width, canvasSize.width)
    }
    
    private var componentHeight: CGFloat {
        min(comp.rect.height, canvasSize.height)
    }
    
    private var strokeColor: Color {
        if isDragging || isResizing {
            return .green
        } else if showInspectorHighlight {
            return .purple
        } else if isSelected {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var clampedX: CGFloat {
        let halfWidth = componentWidth / 2
        let minX = halfWidth
        let maxX = canvasSize.width - halfWidth
        return max(minX, min(maxX, comp.rect.midX))
    }
    
    private var clampedY: CGFloat {
        let halfHeight = componentHeight / 2
        let minY = halfHeight + 20 // Extra space for label
        let maxY = canvasSize.height - halfHeight
        return max(minY, min(maxY, comp.rect.midY))
    }

    
    // MARK: - Handle Positioning Logic
    
    /// Returns the offset for a resize handle relative to the component rectangle center
    private func handleOffset(for position: HandlePosition) -> CGSize {
        return geometryCalculator.calculateHandleOffset(
            for: position,
            componentSize: CGSize(width: componentWidth, height: componentHeight),
            handleSize: handleSize
        )
    }
    
    // MARK: - Gesture Handlers
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8) // Require minimum distance to distinguish from tap/long press
            .onChanged { value in
                if !isDragging && !isResizing && !isLongPressing {
                    isDragging = true
                    // Cancel long press feedback when dragging starts
                    showInspectorHighlight = false
                    longPressProgress = 0.0
                    print("🤏 Started dragging component \(idx + 1): \(comp.type.description)")
                }
                if isDragging {
                    // Update component position in real-time during drag
                    let newX = clampedX + value.translation.width
                    let newY = clampedY + value.translation.height
                    let newPosition = CGPoint(x: newX, y: newY)
                    onDrag(newPosition)
                }
            }
            .onEnded { value in
                if isDragging {
                    isDragging = false
                    print("🎯 Finished dragging component \(idx + 1)")
                }
            }
    }
    
    private func handleTap() {
        if !isDragging && !isResizing && !isLongPressing {
            print("🔘 Component \(idx + 1) tapped: \(comp.type.description)")
            onTap()
        }
    }
    
    private func handleLongPressStateChange(pressing: Bool) {
        if !isDragging && !isResizing {
            if pressing {
                // Start long press feedback
                showInspectorHighlight = true
                longPressProgress = 0.0
                
                // Light haptic feedback at start
                provideTactileFeedback(.light)
                print("🔍 Started long press on component \(idx + 1)")
                
                // Progressive feedback animation
                withAnimation(.easeInOut(duration: 0.4)) {
                    longPressProgress = 1.0
                }
                
                // Medium haptic at halfway point
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if self.showInspectorHighlight && !self.isDragging && !self.isResizing {
                        self.provideTactileFeedback(.medium)
                    }
                }
                
            } else {
                // Cancelled long press
                showInspectorHighlight = false
                longPressProgress = 0.0
                print("🔍 Cancelled long press on component \(idx + 1)")
            }
        }
    }
    
    private func handleLongPress() {
        if !isDragging && !isResizing {
            isLongPressing = true
            showInspectorHighlight = false
            longPressProgress = 0.0
            
            print("🔍 Long press completed on component \(idx + 1) - opening inspector")
            
            // Strong haptic feedback for inspector opening
            provideTactileFeedback(.heavy)
            
            // Select component if not already selected (auto-selection)
            onTap()
            
            // Open inspector
            onInspect()
            
            // Reset long press state after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLongPressing = false
            }
        }
    }
    
    // MARK: - Resize Handlers
    
    private func handleResizeStart() {
        isResizing = true
        // Cancel long press feedback when resizing starts
        showInspectorHighlight = false
        longPressProgress = 0.0
    }
    
    private func handleResize(position: HandlePosition, translation: CGSize) {
        let newRect = calculateNewRect(for: position, with: translation)
        print("🔧 Resize handle \(position): translation=\(translation), newRect=\(newRect)")
        print("🔧 Component before resize: \(comp.rect)")
        onResize(newRect)
        print("🔧 Component after resize: \(comp.rect)")
    }
    
    private func handleResizeEnd() {
        isResizing = false
    }
    
    // MARK: - Resize Calculation Logic
    
    private func calculateNewRect(for position: HandlePosition, with translation: CGSize) -> CGRect {
        let newRect = geometryCalculator.calculateNewRect(
            for: position,
            translation: translation,
            originalRect: comp.rect,
            minSize: 20
        )
        
        // Clamp to canvas bounds
        return geometryCalculator.clampRectToCanvas(newRect, canvasSize: canvasSize)
    }
    
    // MARK: - Utility Methods
    
    private func provideTactileFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Handle Position Enum

enum HandlePosition: CaseIterable, Hashable {
    case topLeft, topRight, bottomLeft, bottomRight
    case top, bottom, left, right
}

// MARK: - Individual Resize Handle

struct ResizeHandle: View {
    let position: HandlePosition
    let onResizeStart: () -> Void
    let onResize: (CGSize) -> Void
    let onResizeEnd: () -> Void
    
    @State private var isBeingDragged = false
    private let handleSize: CGFloat = 12 // Back to larger size for easier interaction
    
    var body: some View {
        ZStack {
            // Larger invisible touch area for easier interaction
            Circle()
                .fill(Color.clear)
                .frame(width: handleSize + 12, height: handleSize + 12)
                .contentShape(Circle())
            
            // Visible handle - back to white circle
            Circle()
                .fill(Color.white)
                .overlay(
                    Circle()
                        .stroke(isBeingDragged ? Color.green : Color.blue, lineWidth: 2)
                )
                .frame(width: handleSize, height: handleSize)
                .scaleEffect(isBeingDragged ? 1.3 : 1.0) // More pronounced scaling
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0) // Allow immediate response
                .onChanged { value in
                    if !isBeingDragged {
                        isBeingDragged = true
                        onResizeStart()
                        print("🔧 Started resizing with \(position) handle")
                    }
                    onResize(value.translation)
                }
                .onEnded { value in
                    isBeingDragged = false
                    onResizeEnd()
                    print("🔧 Finished resizing with \(position) handle")
                }
        )
        .animation(.easeInOut(duration: 0.2), value: isBeingDragged)
        .zIndex(2000) // Highest possible z-index for handles
        .allowsHitTesting(true) // Ensure this view can receive touches
    }
} 