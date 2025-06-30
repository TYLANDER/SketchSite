import Foundation
import SwiftUI
import PencilKit

/// Manages canvas state, undo/redo functionality, and drawing state
class CanvasStateManager: ObservableObject {
    @Published var canvasView = PKCanvasView()
    @Published private(set) var undoStack: [PKDrawing] = []
    @Published private(set) var redoStack: [PKDrawing] = []
    @Published private(set) var currentStrokeCount = 0
    @Published var isDrawingEnabled = true
    
    private var canvasSize: CGSize = .zero
    
    init() {
        setupCanvas()
    }
    
    // MARK: - Canvas Setup
    
    private func setupCanvas() {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        updateDrawingState()
    }
    
    // MARK: - Canvas Size Management
    
    func updateCanvasSize(_ size: CGSize) {
        canvasSize = size
        print("📐 CanvasStateManager: Canvas size updated to \(size)")
    }
    
    var currentCanvasSize: CGSize {
        canvasSize
    }
    
    // MARK: - Drawing State Management
    
    func enableDrawing() {
        isDrawingEnabled = true
        updateDrawingState()
        print("🎨 CanvasStateManager: Drawing enabled")
    }
    
    func disableDrawing() {
        isDrawingEnabled = false
        updateDrawingState()
        print("🚫 CanvasStateManager: Drawing disabled")
    }
    
    private func updateDrawingState() {
        if isDrawingEnabled {
            // Enable drawing - set default tool
            canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
            canvasView.isUserInteractionEnabled = true
        } else {
            // Disable drawing by setting user interaction to false
            canvasView.isUserInteractionEnabled = false
        }
    }
    
    // MARK: - Stroke Count Monitoring
    
    func updateStrokeCount() {
        let newCount = canvasView.drawing.strokes.count
        if newCount != currentStrokeCount {
            print("📝 CanvasStateManager: Stroke count changed! Old: \(currentStrokeCount), New: \(newCount)")
            currentStrokeCount = newCount
        }
    }
    
    var hasStrokes: Bool {
        currentStrokeCount > 0
    }
    
    // MARK: - Undo/Redo Management
    
    func saveCurrentState() {
        undoStack.append(canvasView.drawing)
        redoStack.removeAll() // Clear redo stack when new action is performed
        print("💾 CanvasStateManager: Saved state to undo stack (\(undoStack.count) states)")
    }
    
    func undo() {
        guard let lastDrawing = undoStack.popLast() else {
            print("❌ CanvasStateManager: No states to undo")
            return
        }
        
        redoStack.append(canvasView.drawing)
        canvasView.drawing = lastDrawing
        updateStrokeCount()
        print("↶ CanvasStateManager: Undid action (\(undoStack.count) states remaining)")
    }
    
    func redo() {
        guard let nextDrawing = redoStack.popLast() else {
            print("❌ CanvasStateManager: No states to redo")
            return
        }
        
        undoStack.append(canvasView.drawing)
        canvasView.drawing = nextDrawing
        updateStrokeCount()
        print("↷ CanvasStateManager: Redid action (\(redoStack.count) states remaining)")
    }
    
    var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    var canRedo: Bool {
        !redoStack.isEmpty
    }
    
    // MARK: - Canvas Operations
    
    func clearCanvas() {
        saveCurrentState()
        canvasView.drawing = PKDrawing()
        currentStrokeCount = 0
        print("🗑️ CanvasStateManager: Canvas cleared")
    }
    
    func loadDrawing(_ drawing: PKDrawing) {
        saveCurrentState()
        canvasView.drawing = drawing
        updateStrokeCount()
        print("📂 CanvasStateManager: Loaded drawing with \(drawing.strokes.count) strokes")
    }
    
    // MARK: - Canvas Snapshot
    
    func captureSnapshot() -> UIImage? {
        guard let snapshot = canvasView.snapshotImage() else {
            print("❌ CanvasStateManager: Failed to capture canvas snapshot")
            return nil
        }
        print("📸 CanvasStateManager: Captured canvas snapshot")
        return snapshot
    }
    
    // MARK: - Drawing Analysis
    
    var currentDrawing: PKDrawing {
        canvasView.drawing
    }
    
    var isEmpty: Bool {
        canvasView.drawing.strokes.isEmpty
    }
    
    func getDrawingBounds() -> CGRect {
        guard !isEmpty else { return .zero }
        return canvasView.drawing.bounds
    }
    
    // MARK: - State Reset
    
    func resetToInitialState() {
        canvasView.drawing = PKDrawing()
        undoStack.removeAll()
        redoStack.removeAll()
        currentStrokeCount = 0
        isDrawingEnabled = true
        updateDrawingState()
        print("🔄 CanvasStateManager: Reset to initial state")
    }
    
    // MARK: - Debug Information
    
    func printDebugInfo() {
        print("🔍 CanvasStateManager Debug Info:")
        print("  - Stroke count: \(currentStrokeCount)")
        print("  - Undo stack size: \(undoStack.count)")
        print("  - Redo stack size: \(redoStack.count)")
        print("  - Drawing enabled: \(isDrawingEnabled)")
        print("  - Canvas size: \(canvasSize)")
        print("  - Drawing bounds: \(getDrawingBounds())")
    }
} 