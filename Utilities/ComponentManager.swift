import Foundation
import SwiftUI
import CoreGraphics

/// Centralized manager for handling detected components, their selection, and manipulation
class ComponentManager: ObservableObject {
    @Published private(set) var components: [DetectedComponent] = []
    @Published var selectedComponentID: UUID? = nil
    
    private let geometryCalculator = GeometryCalculator()
    private var canvasSize: CGSize
    
    init(canvasSize: CGSize = .zero) {
        self.canvasSize = canvasSize
    }
    
    // MARK: - Canvas Size Management
    
    func updateCanvasSize(_ size: CGSize) {
        canvasSize = size
        print("📐 ComponentManager: Canvas size updated to \(size)")
    }
    
    // MARK: - Component Collection Management
    
    func setComponents(_ newComponents: [DetectedComponent]) {
        components = newComponents
        print("📦 ComponentManager: Set \(newComponents.count) components")
    }
    
    func addComponent(_ component: DetectedComponent) {
        components.append(component)
        print("➕ ComponentManager: Added component \(component.type.description)")
    }
    
    func addLibraryComponent(from template: ComponentTemplate, at position: CGPoint? = nil) {
        let targetPosition = position ?? CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let component = ComponentLibrary.shared.createComponent(from: template, at: targetPosition, canvasSize: canvasSize)
        addComponent(component)
        selectComponent(withID: component.id)
        print("📚 ComponentManager: Added library component '\(template.name)' at \(targetPosition)")
    }
    
    func removeComponent(withID id: UUID) {
        components.removeAll { $0.id == id }
        if selectedComponentID == id {
            selectedComponentID = nil
        }
        print("🗑️ ComponentManager: Removed component with ID \(id)")
    }
    
    func clearAllComponents() {
        components.removeAll()
        selectedComponentID = nil
        print("🗑️ ComponentManager: Cleared all components")
    }
    
    // MARK: - Component Selection
    
    func selectComponent(withID id: UUID) {
        guard components.contains(where: { $0.id == id }) else {
            print("❌ ComponentManager: Cannot select component - ID not found: \(id)")
            return
        }
        selectedComponentID = id
        print("🔵 ComponentManager: Selected component \(id)")
    }
    
    func deselectComponent() {
        if let selectedID = selectedComponentID {
            print("🔘 ComponentManager: Deselected component \(selectedID)")
        }
        selectedComponentID = nil
    }
    
    func toggleComponentSelection(withID id: UUID) {
        if selectedComponentID == id {
            deselectComponent()
        } else {
            selectComponent(withID: id)
        }
    }
    
    var selectedComponent: DetectedComponent? {
        guard let selectedID = selectedComponentID else { return nil }
        return components.first { $0.id == selectedID }
    }
    
    var isComponentSelected: Bool {
        selectedComponentID != nil
    }
    
    // MARK: - Component Updates
    
    func updateComponent(withID id: UUID, newComponent: DetectedComponent) {
        guard let index = components.firstIndex(where: { $0.id == id }) else {
            print("❌ ComponentManager: Cannot update component - ID not found: \(id)")
            return
        }
        components[index] = newComponent
        print("✏️ ComponentManager: Updated component \(newComponent.type.description)")
    }
    
    func updateComponentPosition(withID id: UUID, to position: CGPoint) {
        guard let index = components.firstIndex(where: { $0.id == id }) else {
            print("❌ ComponentManager: Cannot update position - ID not found: \(id)")
            return
        }
        
        let component = components[index]
        let newRect = geometryCalculator.createRectAtPosition(
            position: position,
            size: CGSize(width: component.rect.width, height: component.rect.height),
            canvasSize: canvasSize
        )
        
        components[index].rect = newRect
        print("📍 ComponentManager: Updated component position to \(position)")
    }
    
    func updateComponentSize(withID id: UUID, to newRect: CGRect) {
        guard let index = components.firstIndex(where: { $0.id == id }) else {
            print("❌ ComponentManager: Cannot update size - ID not found: \(id)")
            return
        }
        
        let clampedRect = geometryCalculator.clampRectToCanvas(newRect, canvasSize: canvasSize)
        components[index].rect = clampedRect
        print("📏 ComponentManager: Updated component size to \(clampedRect)")
    }
    
    // MARK: - Component Merging
    
    func mergeComponents(existing: [DetectedComponent], new: [DetectedComponent]) -> [DetectedComponent] {
        var merged = existing
        let positionTolerance: CGFloat = 30.0
        let sizeTolerance: CGFloat = 20.0
        
        for newComponent in new {
            var isDuplicate = false
            
            for existingComponent in existing {
                let positionDistance = geometryCalculator.calculateDistance(
                    from: newComponent.rect.center,
                    to: existingComponent.rect.center
                )
                let sizeDistance = hypot(
                    newComponent.rect.width - existingComponent.rect.width,
                    newComponent.rect.height - existingComponent.rect.height
                )
                
                if positionDistance < positionTolerance && sizeDistance < sizeTolerance {
                    print("🔄 ComponentManager: Skipping duplicate component: \(newComponent.type.description)")
                    isDuplicate = true
                    break
                }
            }
            
            if !isDuplicate {
                merged.append(newComponent)
                print("➕ ComponentManager: Added new component: \(newComponent.type.description)")
            }
        }
        
        return merged
    }
    
    // MARK: - Validation
    
    func validateComponentBounds(_ rect: CGRect) -> Bool {
        return geometryCalculator.isRectWithinBounds(rect, canvasSize: canvasSize)
    }
    
    // MARK: - Component Access by Index
    
    func component(at index: Int) -> DetectedComponent? {
        guard index >= 0 && index < components.count else { return nil }
        return components[index]
    }
    
    func updateComponent(at index: Int, with newComponent: DetectedComponent) {
        guard index >= 0 && index < components.count else {
            print("❌ ComponentManager: Invalid index \(index)")
            return
        }
        components[index] = newComponent
    }
    
    func updateComponentPosition(at index: Int, to position: CGPoint) {
        guard index >= 0 && index < components.count else {
            print("❌ ComponentManager: Invalid index \(index)")
            return
        }
        
        let component = components[index]
        let newRect = geometryCalculator.createRectAtPosition(
            position: position,
            size: CGSize(width: component.rect.width, height: component.rect.height),
            canvasSize: canvasSize
        )
        
        components[index].rect = newRect
        print("📍 ComponentManager: Updated component \(index) position to \(position)")
    }
    
    func updateComponentSize(at index: Int, to newRect: CGRect) {
        guard index >= 0 && index < components.count else {
            print("❌ ComponentManager: Invalid index \(index)")
            return
        }
        
        let oldRect = components[index].rect
        let clampedRect = geometryCalculator.clampRectToCanvas(newRect, canvasSize: canvasSize)
        components[index].rect = clampedRect
        print("📏 ComponentManager: Updated component \(index) size from \(oldRect) to \(clampedRect)")
    }
}

// MARK: - CGRect Extension for Center Point

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
} 