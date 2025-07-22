import Foundation
import CoreGraphics

// MARK: - Component Library

/// Represents a pre-built component template that can be added to the canvas
struct ComponentTemplate: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let type: UIComponentType
    let category: ComponentCategory
    let description: String
    let defaultSize: CGSize
    let aspectRatio: CGFloat
    let icon: String
    
    init(name: String, type: UIComponentType, category: ComponentCategory, description: String, defaultSize: CGSize, icon: String) {
        self.id = UUID()
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
enum ComponentCategory: String, CaseIterable, Codable {
    case basic = "Basic"
    case navigation = "Navigation"
    case forms = "Forms"
    case media = "Media"
    case layout = "Layout"
    case feedback = "Feedback"
    case gitlabPajamas = "GitLab Pajamas"
    case ibmCarbon = "IBM Carbon"
    
    var icon: String {
        switch self {
        case .basic: return "square.grid.2x2"
        case .navigation: return "list.bullet"
        case .forms: return "textformat"
        case .media: return "photo"
        case .layout: return "rectangle.3.group"
        case .feedback: return "exclamationmark.bubble"
        case .gitlabPajamas: return "fox.circle.fill"
        case .ibmCarbon: return "atom"
        }
    }
    
    var description: String {
        switch self {
        case .basic: return "Essential UI components"
        case .navigation: return "Navigation and wayfinding"
        case .forms: return "Input and form elements"
        case .media: return "Images and media content"
        case .layout: return "Layout and container components"
        case .feedback: return "Notifications and status"
        case .gitlabPajamas: return "GitLab's design system components"
        case .ibmCarbon: return "IBM's enterprise design system"
        }
    }
}

/// Utility class for managing component library templates
class ComponentLibrary {
    static let shared = ComponentLibrary()
    
    private init() {}
    
    /// All available component templates organized by category
    lazy var allTemplates: [ComponentTemplate] = {
        return basicComponents + navigationComponents + formComponents + mediaComponents + layoutComponents + feedbackComponents + gitlabPajamasComponents + ibmCarbonComponents
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
    
    // MARK: - GitLab Pajamas Design System Components
    
    private var gitlabPajamasComponents: [ComponentTemplate] {
        [
            // Foundation Components
            ComponentTemplate(
                name: "Pajamas Button",
                type: .button,
                category: .gitlabPajamas,
                description: "GitLab's primary button component",
                defaultSize: CGSize(width: 120, height: 32),
                icon: "rectangle.roundedtop"
            ),
            ComponentTemplate(
                name: "Pajamas Button Group",
                type: .buttonGroup,
                category: .gitlabPajamas,
                description: "GitLab's grouped button component",
                defaultSize: CGSize(width: 250, height: 32),
                icon: "rectangle.split.3x1"
            ),
            ComponentTemplate(
                name: "Pajamas Alert",
                type: .alert,
                category: .gitlabPajamas,
                description: "GitLab's alert notification component",
                defaultSize: CGSize(width: 300, height: 60),
                icon: "exclamationmark.triangle.fill"
            ),
            ComponentTemplate(
                name: "Pajamas Badge",
                type: .badge,
                category: .gitlabPajamas,
                description: "GitLab's status badge component",
                defaultSize: CGSize(width: 60, height: 20),
                icon: "circle.badge.checkmark"
            ),
            ComponentTemplate(
                name: "Pajamas Avatar",
                type: .image,
                category: .gitlabPajamas,
                description: "GitLab's user avatar component",
                defaultSize: CGSize(width: 40, height: 40),
                icon: "person.circle.fill"
            ),
            ComponentTemplate(
                name: "Pajamas Banner",
                type: .alert,
                category: .gitlabPajamas,
                description: "GitLab's banner notification",
                defaultSize: CGSize(width: 320, height: 80),
                icon: "megaphone.fill"
            ),
            ComponentTemplate(
                name: "Pajamas Breadcrumb",
                type: .breadcrumb,
                category: .gitlabPajamas,
                description: "GitLab's breadcrumb navigation",
                defaultSize: CGSize(width: 280, height: 32),
                icon: "point.3.connected.trianglepath.dotted"
            ),
            ComponentTemplate(
                name: "Pajamas Card",
                type: .mediaObject,
                category: .gitlabPajamas,
                description: "GitLab's content card",
                defaultSize: CGSize(width: 240, height: 160),
                icon: "rectangle.portrait.fill"
            ),
            ComponentTemplate(
                name: "Pajamas Accordion",
                type: .collapse,
                category: .gitlabPajamas,
                description: "GitLab's collapsible content section",
                defaultSize: CGSize(width: 280, height: 120),
                icon: "chevron.down.square"
            ),
            
            // Form Components
            ComponentTemplate(
                name: "Pajamas Text Input",
                type: .formControl,
                category: .gitlabPajamas,
                description: "GitLab's text input field",
                defaultSize: CGSize(width: 200, height: 36),
                icon: "textfield"
            ),
            ComponentTemplate(
                name: "Pajamas Textarea",
                type: .textarea,
                category: .gitlabPajamas,
                description: "GitLab's multi-line text input",
                defaultSize: CGSize(width: 200, height: 80),
                icon: "text.alignleft"
            ),
            ComponentTemplate(
                name: "Pajamas Dropdown",
                type: .dropdown,
                category: .gitlabPajamas,
                description: "GitLab's select dropdown",
                defaultSize: CGSize(width: 180, height: 36),
                icon: "chevron.up.chevron.down"
            ),
            ComponentTemplate(
                name: "Pajamas Search",
                type: .formControl,
                category: .gitlabPajamas,
                description: "GitLab's search input",
                defaultSize: CGSize(width: 220, height: 36),
                icon: "magnifyingglass"
            ),
            ComponentTemplate(
                name: "Pajamas Date Picker",
                type: .formControl,
                category: .gitlabPajamas,
                description: "GitLab's date selection input",
                defaultSize: CGSize(width: 160, height: 36),
                icon: "calendar"
            ),
            ComponentTemplate(
                name: "Pajamas Color Picker",
                type: .formControl,
                category: .gitlabPajamas,
                description: "GitLab's color selection input",
                defaultSize: CGSize(width: 120, height: 36),
                icon: "paintpalette"
            ),
            
            // Navigation Components
            ComponentTemplate(
                name: "Pajamas Tabs",
                type: .tab,
                category: .gitlabPajamas,
                description: "GitLab's tab navigation",
                defaultSize: CGSize(width: 300, height: 48),
                icon: "square.grid.3x1.below.line.grid.1x2"
            ),
            ComponentTemplate(
                name: "Pajamas Pagination",
                type: .pagination,
                category: .gitlabPajamas,
                description: "GitLab's page navigation",
                defaultSize: CGSize(width: 200, height: 40),
                icon: "ellipsis.circle"
            ),
            ComponentTemplate(
                name: "Pajamas Link",
                type: .button,
                category: .gitlabPajamas,
                description: "GitLab's link component",
                defaultSize: CGSize(width: 80, height: 20),
                icon: "link"
            ),
            
            // Data Display
            ComponentTemplate(
                name: "Pajamas Table",
                type: .table,
                category: .gitlabPajamas,
                description: "GitLab's data table",
                defaultSize: CGSize(width: 320, height: 200),
                icon: "tablecells"
            ),
            ComponentTemplate(
                name: "Pajamas Progress Bar",
                type: .progressBar,
                category: .gitlabPajamas,
                description: "GitLab's progress indicator",
                defaultSize: CGSize(width: 200, height: 8),
                icon: "progress.indicator"
            ),
            ComponentTemplate(
                name: "Pajamas Skeleton Loader",
                type: .progressBar,
                category: .gitlabPajamas,
                description: "GitLab's loading skeleton",
                defaultSize: CGSize(width: 200, height: 20),
                icon: "rectangle.dashed"
            ),
            ComponentTemplate(
                name: "Pajamas Spinner",
                type: .progressBar,
                category: .gitlabPajamas,
                description: "GitLab's loading spinner",
                defaultSize: CGSize(width: 24, height: 24),
                icon: "arrow.clockwise.circle"
            ),
            
            // Feedback Components
            ComponentTemplate(
                name: "Pajamas Modal",
                type: .modal,
                category: .gitlabPajamas,
                description: "GitLab's modal dialog",
                defaultSize: CGSize(width: 400, height: 300),
                icon: "rectangle.center.inset.filled"
            ),
            ComponentTemplate(
                name: "Pajamas Toast",
                type: .alert,
                category: .gitlabPajamas,
                description: "GitLab's toast notification",
                defaultSize: CGSize(width: 300, height: 60),
                icon: "bell.fill"
            ),
            ComponentTemplate(
                name: "Pajamas Tooltip",
                type: .tooltip,
                category: .gitlabPajamas,
                description: "GitLab's contextual tooltip",
                defaultSize: CGSize(width: 120, height: 36),
                icon: "bubble.left.fill"
            ),
            ComponentTemplate(
                name: "Pajamas Popover",
                type: .tooltip,
                category: .gitlabPajamas,
                description: "GitLab's popover component",
                defaultSize: CGSize(width: 200, height: 100),
                icon: "bubble.middle.top.fill"
            ),
            ComponentTemplate(
                name: "Pajamas Drawer",
                type: .modal,
                category: .gitlabPajamas,
                description: "GitLab's slide-out drawer",
                defaultSize: CGSize(width: 300, height: 400),
                icon: "sidebar.left"
            )
        ]
    }
    
    // MARK: - IBM Carbon Design System Components
    
    private var ibmCarbonComponents: [ComponentTemplate] {
        [
            // Foundation Components
            ComponentTemplate(
                name: "Carbon Button",
                type: .button,
                category: .ibmCarbon,
                description: "IBM Carbon's primary button",
                defaultSize: CGSize(width: 128, height: 48),
                icon: "rectangle.roundedtop"
            ),
            ComponentTemplate(
                name: "Carbon Button Set",
                type: .buttonGroup,
                category: .ibmCarbon,
                description: "IBM Carbon's button group",
                defaultSize: CGSize(width: 260, height: 48),
                icon: "rectangle.split.3x1"
            ),
            ComponentTemplate(
                name: "Carbon Tag",
                type: .badge,
                category: .ibmCarbon,
                description: "IBM Carbon's tag component",
                defaultSize: CGSize(width: 80, height: 24),
                icon: "tag.fill"
            ),
            ComponentTemplate(
                name: "Carbon Link",
                type: .button,
                category: .ibmCarbon,
                description: "IBM Carbon's link component",
                defaultSize: CGSize(width: 100, height: 20),
                icon: "link"
            ),
            ComponentTemplate(
                name: "Carbon Loading",
                type: .progressBar,
                category: .ibmCarbon,
                description: "IBM Carbon's loading indicator",
                defaultSize: CGSize(width: 32, height: 32),
                icon: "arrow.clockwise.circle"
            ),
            
            // Form Components
            ComponentTemplate(
                name: "Carbon Text Input",
                type: .formControl,
                category: .ibmCarbon,
                description: "IBM Carbon's text input field",
                defaultSize: CGSize(width: 224, height: 40),
                icon: "textfield"
            ),
            ComponentTemplate(
                name: "Carbon Text Area",
                type: .textarea,
                category: .ibmCarbon,
                description: "IBM Carbon's multi-line text input",
                defaultSize: CGSize(width: 224, height: 80),
                icon: "text.alignleft"
            ),
            ComponentTemplate(
                name: "Carbon Select",
                type: .dropdown,
                category: .ibmCarbon,
                description: "IBM Carbon's select dropdown",
                defaultSize: CGSize(width: 224, height: 40),
                icon: "chevron.up.chevron.down"
            ),
            ComponentTemplate(
                name: "Carbon Dropdown",
                type: .dropdown,
                category: .ibmCarbon,
                description: "IBM Carbon's dropdown menu",
                defaultSize: CGSize(width: 160, height: 40),
                icon: "ellipsis.circle"
            ),
            ComponentTemplate(
                name: "Carbon Search",
                type: .formControl,
                category: .ibmCarbon,
                description: "IBM Carbon's search input",
                defaultSize: CGSize(width: 224, height: 40),
                icon: "magnifyingglass"
            ),
            ComponentTemplate(
                name: "Carbon Date Picker",
                type: .formControl,
                category: .ibmCarbon,
                description: "IBM Carbon's date picker",
                defaultSize: CGSize(width: 160, height: 40),
                icon: "calendar"
            ),
            ComponentTemplate(
                name: "Carbon Checkbox",
                type: .formControl,
                category: .ibmCarbon,
                description: "IBM Carbon's checkbox input",
                defaultSize: CGSize(width: 20, height: 20),
                icon: "checkmark.square"
            ),
            ComponentTemplate(
                name: "Carbon Radio Button",
                type: .formControl,
                category: .ibmCarbon,
                description: "IBM Carbon's radio button",
                defaultSize: CGSize(width: 20, height: 20),
                icon: "circle.circle"
            ),
            ComponentTemplate(
                name: "Carbon Toggle",
                type: .formControl,
                category: .ibmCarbon,
                description: "IBM Carbon's toggle switch",
                defaultSize: CGSize(width: 48, height: 24),
                icon: "switch.2"
            ),
            ComponentTemplate(
                name: "Carbon Slider",
                type: .formControl,
                category: .ibmCarbon,
                description: "IBM Carbon's range slider",
                defaultSize: CGSize(width: 200, height: 24),
                icon: "slider.horizontal.3"
            ),
            ComponentTemplate(
                name: "Carbon Number Input",
                type: .formControl,
                category: .ibmCarbon,
                description: "IBM Carbon's number input",
                defaultSize: CGSize(width: 128, height: 40),
                icon: "textformat.123"
            ),
            
            // Navigation Components
            ComponentTemplate(
                name: "Carbon Tabs",
                type: .tab,
                category: .ibmCarbon,
                description: "IBM Carbon's tab navigation",
                defaultSize: CGSize(width: 320, height: 48),
                icon: "square.grid.3x1.below.line.grid.1x2"
            ),
            ComponentTemplate(
                name: "Carbon Breadcrumb",
                type: .breadcrumb,
                category: .ibmCarbon,
                description: "IBM Carbon's breadcrumb navigation",
                defaultSize: CGSize(width: 280, height: 32),
                icon: "point.3.connected.trianglepath.dotted"
            ),
            ComponentTemplate(
                name: "Carbon Pagination",
                type: .pagination,
                category: .ibmCarbon,
                description: "IBM Carbon's pagination",
                defaultSize: CGSize(width: 240, height: 40),
                icon: "ellipsis.circle"
            ),
            ComponentTemplate(
                name: "Carbon UI Shell Header",
                type: .navbar,
                category: .ibmCarbon,
                description: "IBM Carbon's top navigation header",
                defaultSize: CGSize(width: 320, height: 48),
                icon: "menubar.rectangle"
            ),
            ComponentTemplate(
                name: "Carbon Side Nav",
                type: .navs,
                category: .ibmCarbon,
                description: "IBM Carbon's side navigation",
                defaultSize: CGSize(width: 256, height: 400),
                icon: "sidebar.left"
            ),
            ComponentTemplate(
                name: "Carbon Progress Indicator",
                type: .progressBar,
                category: .ibmCarbon,
                description: "IBM Carbon's step progress indicator",
                defaultSize: CGSize(width: 300, height: 8),
                icon: "progress.indicator"
            ),
            
            // Data Display Components
            ComponentTemplate(
                name: "Carbon Data Table",
                type: .table,
                category: .ibmCarbon,
                description: "IBM Carbon's data table",
                defaultSize: CGSize(width: 320, height: 240),
                icon: "tablecells"
            ),
            ComponentTemplate(
                name: "Carbon List",
                type: .listGroup,
                category: .ibmCarbon,
                description: "IBM Carbon's list component",
                defaultSize: CGSize(width: 280, height: 200),
                icon: "list.bullet.rectangle"
            ),
            ComponentTemplate(
                name: "Carbon Tree View",
                type: .listGroup,
                category: .ibmCarbon,
                description: "IBM Carbon's hierarchical tree",
                defaultSize: CGSize(width: 240, height: 300),
                icon: "list.bullet.indent"
            ),
            ComponentTemplate(
                name: "Carbon Structured List",
                type: .listGroup,
                category: .ibmCarbon,
                description: "IBM Carbon's structured list",
                defaultSize: CGSize(width: 280, height: 160),
                icon: "list.bullet.below.rectangle"
            ),
            ComponentTemplate(
                name: "Carbon Code Snippet",
                type: .well,
                category: .ibmCarbon,
                description: "IBM Carbon's code display",
                defaultSize: CGSize(width: 240, height: 80),
                icon: "chevron.left.forwardslash.chevron.right"
            ),
            ComponentTemplate(
                name: "Carbon Tile",
                type: .mediaObject,
                category: .ibmCarbon,
                description: "IBM Carbon's content tile",
                defaultSize: CGSize(width: 200, height: 120),
                icon: "rectangle.portrait"
            ),
            ComponentTemplate(
                name: "Carbon Accordion",
                type: .collapse,
                category: .ibmCarbon,
                description: "IBM Carbon's accordion component",
                defaultSize: CGSize(width: 280, height: 120),
                icon: "chevron.down.square"
            ),
            
            // Feedback Components
            ComponentTemplate(
                name: "Carbon Modal",
                type: .modal,
                category: .ibmCarbon,
                description: "IBM Carbon's modal dialog",
                defaultSize: CGSize(width: 400, height: 300),
                icon: "rectangle.center.inset.filled"
            ),
            ComponentTemplate(
                name: "Carbon Notification",
                type: .alert,
                category: .ibmCarbon,
                description: "IBM Carbon's notification",
                defaultSize: CGSize(width: 320, height: 80),
                icon: "bell.fill"
            ),
            ComponentTemplate(
                name: "Carbon Tooltip",
                type: .tooltip,
                category: .ibmCarbon,
                description: "IBM Carbon's tooltip",
                defaultSize: CGSize(width: 120, height: 32),
                icon: "bubble.left.fill"
            ),
            ComponentTemplate(
                name: "Carbon Popover",
                type: .tooltip,
                category: .ibmCarbon,
                description: "IBM Carbon's popover component",
                defaultSize: CGSize(width: 200, height: 100),
                icon: "bubble.middle.top.fill"
            ),
            ComponentTemplate(
                name: "Carbon Progress Bar",
                type: .progressBar,
                category: .ibmCarbon,
                description: "IBM Carbon's progress bar",
                defaultSize: CGSize(width: 200, height: 8),
                icon: "progress.indicator"
            ),
            ComponentTemplate(
                name: "Carbon Skeleton Text",
                type: .progressBar,
                category: .ibmCarbon,
                description: "IBM Carbon's skeleton loading text",
                defaultSize: CGSize(width: 200, height: 16),
                icon: "rectangle.dashed"
            ),
            ComponentTemplate(
                name: "Carbon Overflow Menu",
                type: .dropdown,
                category: .ibmCarbon,
                description: "IBM Carbon's overflow menu",
                defaultSize: CGSize(width: 32, height: 32),
                icon: "ellipsis"
            ),
            ComponentTemplate(
                name: "Carbon Content Switcher",
                type: .tab,
                category: .ibmCarbon,
                description: "IBM Carbon's content switcher",
                defaultSize: CGSize(width: 240, height: 40),
                icon: "rectangle.2.swap"
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