import Foundation
import CoreGraphics

// MARK: - Component Library

/// Represents a pre-built component template that can be added to the canvas
struct ComponentTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: UIComponentType
    let category: ComponentCategory
    let description: String
    let defaultSize: CGSize
    let aspectRatio: CGFloat
    let icon: String
    
    init(name: String, type: UIComponentType, category: ComponentCategory, description: String, defaultSize: CGSize, icon: String) {
        self.name = name
        self.type = type
        self.category = category
        self.description = description
        self.defaultSize = defaultSize
        self.aspectRatio = defaultSize.width / defaultSize.height
        self.icon = icon
    }
}

/// Categories for organizing component templates
enum ComponentCategory: String, CaseIterable {
    case basic = "Basic"
    case navigation = "Navigation"
    case forms = "Forms"
    case media = "Media"
    case layout = "Layout"
    case feedback = "Feedback"
    
    var icon: String {
        switch self {
        case .basic: return "square.grid.2x2"
        case .navigation: return "list.bullet"
        case .forms: return "textformat"
        case .media: return "photo"
        case .layout: return "rectangle.3.group"
        case .feedback: return "exclamationmark.bubble"
        }
    }
}

/// Utility class for managing component library templates
class ComponentLibrary {
    static let shared = ComponentLibrary()
    
    private init() {}
    
    /// All available component templates organized by category
    lazy var allTemplates: [ComponentTemplate] = {
        return basicComponents + navigationComponents + formComponents + mediaComponents + layoutComponents + feedbackComponents
    }()
    
    /// Get templates by category
    func templates(for category: ComponentCategory) -> [ComponentTemplate] {
        return allTemplates.filter { $0.category == category }
    }
    
    /// Create a DetectedComponent from a template at a specific position
    func createComponent(from template: ComponentTemplate, at position: CGPoint, canvasSize: CGSize) -> DetectedComponent {
        // Calculate responsive size based on canvas
        let responsiveSize = calculateResponsiveSize(template: template, canvasSize: canvasSize)
        
        // Create rect centered at position
        let rect = CGRect(
            x: position.x - responsiveSize.width / 2,
            y: position.y - responsiveSize.height / 2,
            width: responsiveSize.width,
            height: responsiveSize.height
        )
        
        // Clamp to canvas bounds
        let clampedRect = clampRectToCanvas(rect, canvasSize: canvasSize)
        
        return DetectedComponent(
            rect: clampedRect,
            type: .ui(template.type),
            label: template.name,
            textContent: nil // Will use default text content from the initializer
        )
    }
    
    // MARK: - Private Template Definitions
    
    private var basicComponents: [ComponentTemplate] {
        [
            ComponentTemplate(
                name: "Button",
                type: .button,
                category: .basic,
                description: "Standard action button",
                defaultSize: CGSize(width: 120, height: 44),
                icon: "rectangle.roundedtop"
            ),
            ComponentTemplate(
                name: "Text Label",
                type: .label,
                category: .basic,
                description: "Text content display",
                defaultSize: CGSize(width: 100, height: 24),
                icon: "textformat"
            ),
            ComponentTemplate(
                name: "Icon",
                type: .icon,
                category: .basic,
                description: "Small icon or symbol",
                defaultSize: CGSize(width: 32, height: 32),
                icon: "star"
            ),
            ComponentTemplate(
                name: "Badge",
                type: .badge,
                category: .basic,
                description: "Small status indicator",
                defaultSize: CGSize(width: 60, height: 24),
                icon: "circle.fill"
            )
        ]
    }
    
    private var navigationComponents: [ComponentTemplate] {
        [
            ComponentTemplate(
                name: "Navigation Bar",
                type: .navbar,
                category: .navigation,
                description: "Top navigation bar",
                defaultSize: CGSize(width: 320, height: 64),
                icon: "menubar.rectangle"
            ),
            ComponentTemplate(
                name: "Tab Bar",
                type: .tab,
                category: .navigation,
                description: "Bottom tab navigation",
                defaultSize: CGSize(width: 320, height: 80),
                icon: "square.grid.3x1.below.line.grid.1x2"
            ),
            ComponentTemplate(
                name: "Breadcrumb",
                type: .breadcrumb,
                category: .navigation,
                description: "Navigation breadcrumb trail",
                defaultSize: CGSize(width: 250, height: 32),
                icon: "chevron.right"
            ),
            ComponentTemplate(
                name: "Pagination",
                type: .pagination,
                category: .navigation,
                description: "Page navigation controls",
                defaultSize: CGSize(width: 200, height: 40),
                icon: "ellipsis.circle"
            )
        ]
    }
    
    private var formComponents: [ComponentTemplate] {
        [
            ComponentTemplate(
                name: "Text Input",
                type: .formControl,
                category: .forms,
                description: "Single line text input",
                defaultSize: CGSize(width: 200, height: 44),
                icon: "textfield"
            ),
            ComponentTemplate(
                name: "Text Area",
                type: .formControl,
                category: .forms,
                description: "Multi-line text input",
                defaultSize: CGSize(width: 200, height: 100),
                icon: "text.alignleft"
            ),
            ComponentTemplate(
                name: "Dropdown",
                type: .dropdown,
                category: .forms,
                description: "Selection dropdown menu",
                defaultSize: CGSize(width: 160, height: 44),
                icon: "chevron.down.square"
            ),
            ComponentTemplate(
                name: "Form Container",
                type: .form,
                category: .forms,
                description: "Complete form layout",
                defaultSize: CGSize(width: 280, height: 200),
                icon: "doc.text"
            )
        ]
    }
    
    private var mediaComponents: [ComponentTemplate] {
        [
            ComponentTemplate(
                name: "Image",
                type: .image,
                category: .media,
                description: "Image placeholder",
                defaultSize: CGSize(width: 150, height: 150),
                icon: "photo"
            ),
            ComponentTemplate(
                name: "Avatar",
                type: .image,
                category: .media,
                description: "User profile image",
                defaultSize: CGSize(width: 60, height: 60),
                icon: "person.crop.circle"
            ),
            ComponentTemplate(
                name: "Thumbnail",
                type: .thumbnail,
                category: .media,
                description: "Small preview image",
                defaultSize: CGSize(width: 80, height: 80),
                icon: "photo.on.rectangle"
            ),
            ComponentTemplate(
                name: "Carousel",
                type: .carousel,
                category: .media,
                description: "Image carousel slider",
                defaultSize: CGSize(width: 300, height: 200),
                icon: "rectangle.stack"
            )
        ]
    }
    
    private var layoutComponents: [ComponentTemplate] {
        [
            ComponentTemplate(
                name: "Card",
                type: .mediaObject,
                category: .layout,
                description: "Content card container",
                defaultSize: CGSize(width: 200, height: 150),
                icon: "rectangle.portrait"
            ),
            ComponentTemplate(
                name: "List Item",
                type: .listGroup,
                category: .layout,
                description: "Single list item",
                defaultSize: CGSize(width: 250, height: 60),
                icon: "list.bullet.rectangle"
            ),
            ComponentTemplate(
                name: "Table",
                type: .table,
                category: .layout,
                description: "Data table",
                defaultSize: CGSize(width: 300, height: 200),
                icon: "tablecells"
            ),
            ComponentTemplate(
                name: "Well",
                type: .well,
                category: .layout,
                description: "Content well container",
                defaultSize: CGSize(width: 200, height: 100),
                icon: "rectangle.inset.filled"
            )
        ]
    }
    
    private var feedbackComponents: [ComponentTemplate] {
        [
            ComponentTemplate(
                name: "Alert",
                type: .alert,
                category: .feedback,
                description: "Alert notification",
                defaultSize: CGSize(width: 280, height: 80),
                icon: "exclamationmark.triangle"
            ),
            ComponentTemplate(
                name: "Progress Bar",
                type: .progressBar,
                category: .feedback,
                description: "Progress indicator",
                defaultSize: CGSize(width: 200, height: 20),
                icon: "progress.indicator"
            ),
            ComponentTemplate(
                name: "Modal",
                type: .modal,
                category: .feedback,
                description: "Modal dialog",
                defaultSize: CGSize(width: 300, height: 200),
                icon: "rectangle.center.inset.filled"
            ),
            ComponentTemplate(
                name: "Tooltip",
                type: .tooltip,
                category: .feedback,
                description: "Contextual tooltip",
                defaultSize: CGSize(width: 120, height: 40),
                icon: "bubble.left"
            )
        ]
    }
    
    // MARK: - Helper Methods
    
    private func calculateResponsiveSize(template: ComponentTemplate, canvasSize: CGSize) -> CGSize {
        let maxWidth = canvasSize.width * 0.8  // Max 80% of canvas width
        let maxHeight = canvasSize.height * 0.6 // Max 60% of canvas height
        
        var width = template.defaultSize.width
        var height = template.defaultSize.height
        
        // Scale down if too large for canvas
        if width > maxWidth {
            width = maxWidth
            height = width / template.aspectRatio
        }
        
        if height > maxHeight {
            height = maxHeight
            width = height * template.aspectRatio
        }
        
        // Ensure minimum size
        let minSize: CGFloat = 20
        width = max(width, minSize)
        height = max(height, minSize)
        
        return CGSize(width: width, height: height)
    }
    
    private func clampRectToCanvas(_ rect: CGRect, canvasSize: CGSize) -> CGRect {
        let canvasBounds = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)
        var clampedRect = rect
        
        // Adjust X position
        if clampedRect.minX < canvasBounds.minX {
            clampedRect.origin.x = canvasBounds.minX
        } else if clampedRect.maxX > canvasBounds.maxX {
            clampedRect.origin.x = canvasBounds.maxX - clampedRect.width
        }
        
        // Adjust Y position
        if clampedRect.minY < canvasBounds.minY {
            clampedRect.origin.y = canvasBounds.minY
        } else if clampedRect.maxY > canvasBounds.maxY {
            clampedRect.origin.y = canvasBounds.maxY - clampedRect.height
        }
        
        return clampedRect
    }
} 