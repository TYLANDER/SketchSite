import SwiftUI
import UIKit

// MARK: - Component Overlay with Integrated Resize Handles

struct ComponentOverlayView: View {
    let comp: DetectedComponent
    let idx: Int
    let isSelected: Bool
    let onTap: () -> Void
    let onDrag: (CGPoint) -> Void
    let onResize: (CGRect) -> Void
    let onInspect: () -> Void
    let canvasSize: CGSize
    
    @State private var isDragging: Bool = false
    @State private var isResizing: Bool = false
    
    // Resize handle properties
    private let handleSize: CGFloat = 12
    private let handlePositions: [HandlePosition] = [
        .topLeft, .topRight, .bottomLeft, .bottomRight,
        .top, .bottom, .left, .right
    ]
    
    // Geometry calculator for centralized calculations
    private let geometryCalculator = GeometryCalculator()

    var body: some View {
        ZStack {
            // Main component rectangle
            componentRectangle
                .allowsHitTesting(!isResizing) // Disable hit testing when resizing
                .onTapGesture {
                    handleTap()
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    // Long press to open inspector when selected
                    if isSelected {
                        print("🔍 Long press detected - opening inspector")
                        onInspect()
                    }
                }
                .gesture(isResizing ? nil : dragGesture) // Only allow dragging when not resizing
            
            // Resize handles (positioned as overlay attributes)
            if isSelected && !isDragging {
                resizeHandles
                    .zIndex(1000) // Very high z-index to ensure handles are always on top
                    .allowsHitTesting(true) // Explicitly allow hit testing for handles
            }
            
            // Component label
            componentLabel
        }
        .position(x: clampedX, y: clampedY)
        .zIndex(isDragging ? 20 : (isSelected ? 10 : 5))
        .accessibilityLabel("Component: \(comp.type.description)")
        .accessibilityHint("Tap to select, drag to move, or use handles to resize component.")
    }
    
    // MARK: - Component Rectangle
    
    private var componentRectangle: some View {
        Rectangle()
            .stroke(strokeColor, lineWidth: isDragging ? 3 : 2)
            .background(strokeColor.opacity(isDragging ? 0.3 : 0.2))
            .frame(width: componentWidth, height: componentHeight)
            .shadow(color: isDragging ? .black.opacity(0.3) : .clear, radius: isDragging ? 8 : 0, x: 0, y: 4)
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
        Text(comp.type.description.capitalized + " \(idx + 1)")
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(4)
            .background(Color.black.opacity(0.7))
            .cornerRadius(6)
            .offset(y: -componentHeight/2 - 15)
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
        DragGesture()
            .onChanged { value in
                if !isDragging && !isResizing {
                    isDragging = true
                    provideTactileFeedback(.medium)
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
                    provideTactileFeedback(.light)
                    print("🎯 Finished dragging component \(idx + 1)")
                }
            }
    }
    
    private func handleTap() {
        if !isDragging && !isResizing {
            print("🔘 Component \(idx + 1) tapped: \(comp.type.description)")
            onTap()
        }
    }
    
    // MARK: - Resize Handlers
    
    private func handleResizeStart() {
        isResizing = true
        provideTactileFeedback(.medium)
    }
    
    private func handleResize(position: HandlePosition, translation: CGSize) {
        let newRect = calculateNewRect(for: position, with: translation)
        onResize(newRect)
    }
    
    private func handleResizeEnd() {
        isResizing = false
        provideTactileFeedback(.light)
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
    private let handleSize: CGFloat = 14 // Slightly larger for easier touch
    
    var body: some View {
        ZStack {
            // Larger invisible touch area for easier interaction
            Circle()
                .fill(Color.clear)
                .frame(width: handleSize + 8, height: handleSize + 8)
                .contentShape(Circle())
            
            // Visible handle
            Circle()
                .fill(Color.white)
                .overlay(
                    Circle()
                        .stroke(isBeingDragged ? Color.green : Color.orange, lineWidth: 2)
                )
                .frame(width: handleSize, height: handleSize)
                .scaleEffect(isBeingDragged ? 1.4 : 1.2) // More prominent scaling
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0) // Allow immediate response
                .onChanged { value in
                    if !isBeingDragged {
                        isBeingDragged = true
                        onResizeStart()
                        print("🔧 Started resizing with \(position) handle")
                        
                        // Provide strong haptic feedback to indicate resize mode
                        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        impactFeedback.impactOccurred()
                    }
                    onResize(value.translation)
                }
                .onEnded { value in
                    isBeingDragged = false
                    onResizeEnd()
                    print("🔧 Finished resizing with \(position) handle")
                    
                    // Light haptic feedback on completion
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
        )
        .animation(.easeInOut(duration: 0.15), value: isBeingDragged)
        .zIndex(2000) // Highest possible z-index for handles
        .allowsHitTesting(true) // Ensure this view can receive touches
    }
} 