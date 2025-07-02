import SwiftUI
import UIKit

// MARK: - Component Overlay with Modern Drag Interaction (2025 HIG)

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
    
    // Modern drag interaction state (2025 HIG)
    @State private var dragStartLocation: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var dragVelocity: CGSize = .zero
    @State private var lastDragTime: Date = Date()
    @State private var dragMagnification: CGFloat = 1.0
    @State private var showDragShadow = false
    
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
            // Main component rectangle with Liquid Glass-inspired visual feedback
            Rectangle()
                .stroke(strokeColor, lineWidth: strokeWidth)
                .fill(fillColor)
                .frame(width: componentWidth, height: componentHeight)
                .scaleEffect(componentScale)
                .offset(dragOffset)
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius,
                    x: shadowOffset.width,
                    y: shadowOffset.height
                )
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: componentScale)
                .animation(.easeInOut(duration: 0.2), value: strokeColor)
                .animation(.easeInOut(duration: 0.2), value: fillColor)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
            
            // Liquid Glass highlight glow effect for long press feedback
            if showInspectorHighlight {
                Rectangle()
                    .stroke(Color.purple, lineWidth: 2)
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: componentWidth + 4, height: componentHeight + 4)
                    .blur(radius: 6)
                    .opacity(longPressProgress * 0.7)
                    .animation(.easeInOut(duration: 0.4), value: longPressProgress)
            }
            
            // Resize handles - only show when selected
            if isSelected && !isDragging {
                resizeHandles
            }
            
            // Component label - always visible
            componentLabel
        }
        .position(x: clampedX, y: clampedY)
        .simultaneousGesture(modernDragGesture)
        .simultaneousGesture(longPressGesture)
        .onTapGesture {
            handleTap()
        }
        .allowsHitTesting(true)
        .zIndex(dragZIndex)
        .accessibilityLabel("Component: \(comp.type.description)")
        .accessibilityHint("Tap to select, long press to inspect, drag to move, or use handles to resize component.")
    }
    
    // MARK: - Modern Visual Feedback Properties (2025 HIG)
    
    private var strokeWidth: CGFloat {
        if isResizing {
            return 3
        } else if isDragging {
            return 2
        } else if showInspectorHighlight {
            return 2
        } else if isSelected {
            return 2
        } else {
            return 1.5
        }
    }
    
    private var fillColor: Color {
        if isDragging {
            return Color.blue.opacity(0.3) // More prominent during drag
        } else if showInspectorHighlight {
            return Color.purple.opacity(0.2)
        } else if isSelected {
            return Color.orange.opacity(0.15)
        } else {
            return Color.blue.opacity(0.1)
        }
    }
    
    private var strokeColor: Color {
        if isDragging {
            return .blue
        } else if showInspectorHighlight {
            return .purple
        } else if isSelected {
            return .orange
        } else {
            return .blue.opacity(0.7)
        }
    }
    
    private var componentScale: CGFloat {
        if isDragging {
            return dragMagnification
        } else if showInspectorHighlight && longPressProgress > 0.5 {
            return 1.03
        } else {
            return 1.0
        }
    }
    
    // Liquid Glass-inspired shadow effects
    private var shadowColor: Color {
        if isDragging {
            return .black.opacity(0.3)
        } else if isSelected {
            return .black.opacity(0.15)
        } else {
            return .clear
        }
    }
    
    private var shadowRadius: CGFloat {
        if isDragging {
            return 12
        } else if isSelected {
            return 4
        } else {
            return 0
        }
    }
    
    private var shadowOffset: CGSize {
        if isDragging {
            return CGSize(width: 0, height: 6)
        } else if isSelected {
            return CGSize(width: 0, height: 2)
        } else {
            return .zero
        }
    }
    
    private var dragZIndex: Double {
        if isDragging {
            return 1000 // Highest priority during drag
        } else if isSelected {
            return 100
        } else {
            return 50
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
            .offset(dragOffset)
            .allowsHitTesting(false)
    }
    
    // MARK: - Computed Properties
    
    private var componentWidth: CGFloat {
        min(comp.rect.width, canvasSize.width)
    }
    
    private var componentHeight: CGFloat {
        min(comp.rect.height, canvasSize.height)
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
    
    // MARK: - Modern Drag Gesture (2025 HIG Best Practices)
    
    private var modernDragGesture: some Gesture {
        DragGesture(minimumDistance: 6) // Slightly lower threshold for better responsiveness
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { value in
                handleDragEnded(value)
            }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        let currentTime = Date()
        
        if !isDragging && !isResizing && !isLongPressing {
            // Initialize drag state
            isDragging = true
            dragStartLocation = value.startLocation
            showInspectorHighlight = false
            longPressProgress = 0.0
            showDragShadow = true
            
            // Immediate visual feedback with subtle haptic
            provideTactileFeedback(.light)
            
            // Smooth scale animation for lift-off effect
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                dragMagnification = 1.05
            }
            
            print("🤏 Started modern drag on component \(idx + 1): \(comp.type.description)")
        }
        
        if isDragging {
            // Calculate velocity for predictive behavior
            let timeDelta = currentTime.timeIntervalSince(lastDragTime)
            if timeDelta > 0 {
                let velocityX = (value.translation.width - dragOffset.width) / timeDelta
                let velocityY = (value.translation.height - dragOffset.height) / timeDelta
                dragVelocity = CGSize(width: velocityX, height: velocityY)
            }
            
            // Apply drag offset with bounds checking
            let proposedOffset = value.translation
            let newCenter = CGPoint(
                x: comp.rect.midX + proposedOffset.width,
                y: comp.rect.midY + proposedOffset.height
            )
            
            // Clamp to canvas bounds
            let clampedCenter = clampPointToCanvas(newCenter)
            let clampedOffset = CGSize(
                width: clampedCenter.x - comp.rect.midX,
                height: clampedCenter.y - comp.rect.midY
            )
            
            dragOffset = clampedOffset
            lastDragTime = currentTime
            
            // Provide subtle haptic feedback for edge resistance
            if newCenter != clampedCenter {
                provideTactileFeedback(.light)
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        if isDragging {
            // Calculate final position with momentum
            let finalCenter = CGPoint(
                x: comp.rect.midX + dragOffset.width,
                y: comp.rect.midY + dragOffset.height
            )
            
            // Apply the final position
            onDrag(finalCenter)
            
            // Reset drag state with smooth animations
            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                dragOffset = .zero
                dragMagnification = 1.0
            }
            
            // Completion haptic feedback
            provideTactileFeedback(.medium)
            
            isDragging = false
            showDragShadow = false
            dragVelocity = .zero
            
            print("🎯 Finished modern drag on component \(idx + 1)")
        }
    }
    
    // MARK: - Long Press Gesture
    
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.4)
            .onChanged { pressing in
                handleLongPressStateChange(pressing: pressing)
            }
            .onEnded { _ in
                handleLongPress()
            }
    }
    
    // MARK: - Utility Methods
    
    private func clampPointToCanvas(_ point: CGPoint) -> CGPoint {
        let halfWidth = componentWidth / 2
        let halfHeight = componentHeight / 2
        
        let clampedX = max(halfWidth, min(canvasSize.width - halfWidth, point.x))
        let clampedY = max(halfHeight + 20, min(canvasSize.height - halfHeight, point.y))
        
        return CGPoint(x: clampedX, y: clampedY)
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
        onResize(newRect)
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
    
    // MARK: - Haptic Feedback
    
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
    private let handleSize: CGFloat = 12
    
    var body: some View {
        ZStack {
            // Larger invisible touch area for easier interaction
            Circle()
                .fill(Color.clear)
                .frame(width: handleSize + 12, height: handleSize + 12)
                .contentShape(Circle())
            
            // Visible handle with Liquid Glass-inspired styling
            Circle()
                .fill(Color.white)
                .overlay(
                    Circle()
                        .stroke(isBeingDragged ? Color.green : Color.blue, lineWidth: 2)
                )
                .frame(width: handleSize, height: handleSize)
                .scaleEffect(isBeingDragged ? 1.2 : 1.0)
                .shadow(color: .black.opacity(0.3), radius: isBeingDragged ? 6 : 3, x: 0, y: isBeingDragged ? 4 : 2)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isBeingDragged {
                        isBeingDragged = true
                        onResizeStart()
                    }
                    onResize(value.translation)
                }
                .onEnded { value in
                    isBeingDragged = false
                    onResizeEnd()
                }
        )
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: isBeingDragged)
        .zIndex(2000)
        .allowsHitTesting(true)
    }
} 