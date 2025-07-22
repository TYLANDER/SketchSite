import Foundation
import SwiftUI

// MARK: - Component Usage Tracking

/// Tracks usage statistics for component templates
struct ComponentUsageData: Codable {
    var templateUsageCount: [UUID: Int] = [:]
    var lastUsed: [UUID: Date] = [:]
    
    mutating func recordUsage(for templateId: UUID) {
        templateUsageCount[templateId, default: 0] += 1
        lastUsed[templateId] = Date()
    }
    
    func getUsageCount(for templateId: UUID) -> Int {
        return templateUsageCount[templateId, default: 0]
    }
    
    func getMostUsedTemplates(from templates: [ComponentTemplate], limit: Int = 4) -> [ComponentTemplate] {
        let sortedByUsage = templates.sorted { template1, template2 in
            let usage1 = getUsageCount(for: template1.id)
            let usage2 = getUsageCount(for: template2.id)
            
            if usage1 != usage2 {
                return usage1 > usage2
            }
            
            // If usage is equal, sort by most recently used
            let date1 = lastUsed[template1.id] ?? Date.distantPast
            let date2 = lastUsed[template2.id] ?? Date.distantPast
            return date1 > date2
        }
        
        return Array(sortedByUsage.prefix(limit))
    }
}

// MARK: - Component Library Pack

/// Represents a complete set of component templates
struct ComponentLibraryPack: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let version: String
    let author: String
    let categories: [ComponentCategory]
    let templates: [ComponentTemplate]
    let isBuiltIn: Bool
    let colorScheme: PackColorScheme
    
    init(name: String, description: String, icon: String, version: String = "1.0", author: String, categories: [ComponentCategory], templates: [ComponentTemplate], isBuiltIn: Bool = true, colorScheme: PackColorScheme) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.icon = icon
        self.version = version
        self.author = author
        self.categories = categories
        self.templates = templates
        self.isBuiltIn = isBuiltIn
        self.colorScheme = colorScheme
    }
}

/// Color scheme for a component library pack
struct PackColorScheme: Codable {
    let primary: String
    let secondary: String
    let accent: String
    let background: String
    
    static let `default` = PackColorScheme(
        primary: "#007AFF",
        secondary: "#8E8E93", 
        accent: "#FF9500",
        background: "#F2F2F7"
    )
    
    static let material = PackColorScheme(
        primary: "#1976D2",
        secondary: "#424242",
        accent: "#FF5722",
        background: "#FAFAFA"
    )
    
    static let bootstrap = PackColorScheme(
        primary: "#0D6EFD",
        secondary: "#6C757D",
        accent: "#DC3545",
        background: "#F8F9FA"
    )
    
    static let tailwind = PackColorScheme(
        primary: "#3B82F6",
        secondary: "#6B7280",
        accent: "#EF4444",
        background: "#F9FAFB"
    )
}

// MARK: - Component Library Manager

class ComponentLibraryManager: ObservableObject {
    @Published var availablePacks: [ComponentLibraryPack] = []
    @Published var currentPack: ComponentLibraryPack
    @Published var usageData = ComponentUsageData()
    
    private let userDefaults = UserDefaults.standard
    private let currentPackKey = "SketchSite_CurrentComponentPack"
    private let customPacksKey = "SketchSite_CustomComponentPacks"
    private let usageDataKey = "SketchSite_ComponentUsageData"
    
    static let shared = ComponentLibraryManager()
    
    private init() {
        // Initialize with default pack
        self.currentPack = Self.createDefaultPack()
        self.availablePacks = []
        
        loadBuiltInPacks()
        loadCustomPacks()
        loadCurrentPack()
        loadUsageData()
    }
    
    // MARK: - Pack Management
    
    func switchToPack(_ pack: ComponentLibraryPack) {
        currentPack = pack
        saveCurrentPack()
        print("📦 Switched to component library pack: \(pack.name)")
    }
    
    func addCustomPack(_ pack: ComponentLibraryPack) {
        var customPack = pack
        // Ensure custom packs are marked as not built-in
        customPack = ComponentLibraryPack(
            name: pack.name,
            description: pack.description,
            icon: pack.icon,
            version: pack.version,
            author: pack.author,
            categories: pack.categories,
            templates: pack.templates,
            isBuiltIn: false,
            colorScheme: pack.colorScheme
        )
        
        availablePacks.append(customPack)
        saveCustomPacks()
        print("➕ Added custom component pack: \(pack.name)")
    }
    
    func removePack(_ pack: ComponentLibraryPack) {
        guard !pack.isBuiltIn else {
            print("❌ Cannot remove built-in pack: \(pack.name)")
            return
        }
        
        availablePacks.removeAll { $0.id == pack.id }
        
        // If we're removing the current pack, switch to default
        if currentPack.id == pack.id {
            currentPack = Self.createDefaultPack()
            saveCurrentPack()
        }
        
        saveCustomPacks()
        print("🗑️ Removed custom component pack: \(pack.name)")
    }
    
    // MARK: - Access Current Pack Templates
    
    var currentTemplates: [ComponentTemplate] {
        return currentPack.templates
    }
    
    func templates(for category: ComponentCategory) -> [ComponentTemplate] {
        return currentPack.templates.filter { $0.category == category }
    }
    
    var availableCategories: [ComponentCategory] {
        return currentPack.categories
    }
    
    // MARK: - Usage Tracking
    
    func recordTemplateUsage(_ template: ComponentTemplate) {
        usageData.recordUsage(for: template.id)
        saveUsageData()
        print("📊 Recorded usage for template: \(template.name)")
    }
    
    func getQuickAddTemplates(limit: Int = 4) -> [ComponentTemplate] {
        // If we have usage data, use most frequently used
        let mostUsed = usageData.getMostUsedTemplates(from: currentPack.templates, limit: limit)
        
        if !mostUsed.isEmpty {
            return mostUsed
        }
        
        // Fallback to common component types (works across all design systems)
        let commonTypes: [UIComponentType] = [.button, .label, .formControl, .image]
        var quickAddTemplates: [ComponentTemplate] = []
        
        for type in commonTypes {
            if let template = currentPack.templates.first(where: { $0.type == type }) {
                quickAddTemplates.append(template)
            }
            
            if quickAddTemplates.count >= limit {
                break
            }
        }
        
        // If we still don't have enough, add the first few templates from basic category
        if quickAddTemplates.count < limit {
            let basicTemplates = currentPack.templates.filter { $0.category == .basic }
            for template in basicTemplates {
                if !quickAddTemplates.contains(where: { $0.id == template.id }) {
                    quickAddTemplates.append(template)
                    
                    if quickAddTemplates.count >= limit {
                        break
                    }
                }
            }
        }
        
        return quickAddTemplates
    }
    
    // MARK: - Persistence
    
    private func saveCurrentPack() {
        do {
            let data = try JSONEncoder().encode(currentPack)
            userDefaults.set(data, forKey: currentPackKey)
        } catch {
            print("❌ Failed to save current pack: \(error)")
        }
    }
    
    private func loadCurrentPack() {
        guard let data = userDefaults.data(forKey: currentPackKey) else { return }
        
        do {
            let pack = try JSONDecoder().decode(ComponentLibraryPack.self, from: data)
            if availablePacks.contains(where: { $0.id == pack.id }) {
                currentPack = pack
            }
        } catch {
            print("❌ Failed to load current pack: \(error)")
        }
    }
    
    private func saveCustomPacks() {
        let customPacks = availablePacks.filter { !$0.isBuiltIn }
        do {
            let data = try JSONEncoder().encode(customPacks)
            userDefaults.set(data, forKey: customPacksKey)
        } catch {
            print("❌ Failed to save custom packs: \(error)")
        }
    }
    
    private func loadCustomPacks() {
        guard let data = userDefaults.data(forKey: customPacksKey) else { return }
        
        do {
            let customPacks = try JSONDecoder().decode([ComponentLibraryPack].self, from: data)
            availablePacks.append(contentsOf: customPacks)
        } catch {
            print("❌ Failed to load custom packs: \(error)")
        }
    }
    
    private func saveUsageData() {
        do {
            let data = try JSONEncoder().encode(usageData)
            userDefaults.set(data, forKey: usageDataKey)
        } catch {
            print("❌ Failed to save usage data: \(error)")
        }
    }
    
    private func loadUsageData() {
        guard let data = userDefaults.data(forKey: usageDataKey) else {
            print("📊 No usage data found, starting fresh")
            return
        }
        
        do {
            usageData = try JSONDecoder().decode(ComponentUsageData.self, from: data)
            print("📊 Loaded usage data with \(usageData.templateUsageCount.count) tracked templates")
        } catch {
            print("❌ Failed to load usage data: \(error)")
            usageData = ComponentUsageData()
        }
    }
    
    // MARK: - Built-in Packs
    
    private func loadBuiltInPacks() {
        availablePacks = [
            Self.createDefaultPack(),
            Self.createMaterialDesignPack(),
            Self.createBootstrapPack(),
            Self.createiOSPack(),
            Self.createTailwindPack(),
            Self.createGitLabPajamasPack(),
            Self.createIBMCarbonPack()
        ]
    }
    
    // MARK: - Pack Definitions
    
    static func createDefaultPack() -> ComponentLibraryPack {
        return ComponentLibraryPack(
            name: "Default",
            description: "Standard UI components for general web development",
            icon: "square.grid.2x2",
            author: "SketchSite",
            categories: ComponentCategory.allCases,
            templates: ComponentLibrary.shared.allTemplates,
            colorScheme: .default
        )
    }
    
    static func createMaterialDesignPack() -> ComponentLibraryPack {
        let templates = [
            // Basic Components
            ComponentTemplate(name: "Material Button", type: .button, category: .basic, description: "Material Design button", defaultSize: CGSize(width: 120, height: 48), icon: "rectangle.roundedtop"),
            ComponentTemplate(name: "FAB", type: .button, category: .basic, description: "Floating Action Button", defaultSize: CGSize(width: 56, height: 56), icon: "plus.circle.fill"),
            ComponentTemplate(name: "Text Button", type: .button, category: .basic, description: "Material text button", defaultSize: CGSize(width: 100, height: 40), icon: "textformat"),
            ComponentTemplate(name: "Outlined Button", type: .button, category: .basic, description: "Material outlined button", defaultSize: CGSize(width: 120, height: 48), icon: "rectangle"),
            ComponentTemplate(name: "Material Icon", type: .icon, category: .basic, description: "Material Design icon", defaultSize: CGSize(width: 24, height: 24), icon: "star"),
            ComponentTemplate(name: "Chip", type: .badge, category: .basic, description: "Material chip component", defaultSize: CGSize(width: 80, height: 32), icon: "capsule"),
            ComponentTemplate(name: "Material Label", type: .label, category: .basic, description: "Material text label", defaultSize: CGSize(width: 100, height: 24), icon: "textformat"),
            
            // Navigation Components
            ComponentTemplate(name: "App Bar", type: .navbar, category: .navigation, description: "Material top app bar", defaultSize: CGSize(width: 320, height: 64), icon: "menubar.rectangle"),
            ComponentTemplate(name: "Bottom Nav", type: .tab, category: .navigation, description: "Bottom navigation", defaultSize: CGSize(width: 320, height: 80), icon: "square.grid.3x1.below.line.grid.1x2"),
            ComponentTemplate(name: "Tabs", type: .tab, category: .navigation, description: "Material tabs", defaultSize: CGSize(width: 300, height: 48), icon: "rectangle.3.group"),
            ComponentTemplate(name: "Navigation Drawer", type: .navs, category: .navigation, description: "Side navigation drawer", defaultSize: CGSize(width: 280, height: 400), icon: "sidebar.left"),
            ComponentTemplate(name: "Breadcrumbs", type: .breadcrumb, category: .navigation, description: "Material breadcrumbs", defaultSize: CGSize(width: 250, height: 32), icon: "chevron.right"),
            
            // Form Components
            ComponentTemplate(name: "Material Input", type: .formControl, category: .forms, description: "Material text field", defaultSize: CGSize(width: 200, height: 56), icon: "textfield"),
            ComponentTemplate(name: "Outlined Input", type: .formControl, category: .forms, description: "Outlined text field", defaultSize: CGSize(width: 200, height: 56), icon: "rectangle"),
            ComponentTemplate(name: "Material Textarea", type: .formControl, category: .forms, description: "Material text area", defaultSize: CGSize(width: 200, height: 100), icon: "text.alignleft"),
            ComponentTemplate(name: "Select", type: .dropdown, category: .forms, description: "Material select dropdown", defaultSize: CGSize(width: 200, height: 56), icon: "chevron.down.square"),
            ComponentTemplate(name: "Checkbox", type: .formControl, category: .forms, description: "Material checkbox", defaultSize: CGSize(width: 20, height: 20), icon: "checkmark.square"),
            ComponentTemplate(name: "Radio Button", type: .formControl, category: .forms, description: "Material radio button", defaultSize: CGSize(width: 20, height: 20), icon: "circle"),
            ComponentTemplate(name: "Switch", type: .formControl, category: .forms, description: "Material switch", defaultSize: CGSize(width: 36, height: 20), icon: "switch.2"),
            ComponentTemplate(name: "Slider", type: .formControl, category: .forms, description: "Material slider", defaultSize: CGSize(width: 200, height: 20), icon: "slider.horizontal.3"),
            
            // Media Components
            ComponentTemplate(name: "Material Image", type: .image, category: .media, description: "Material image container", defaultSize: CGSize(width: 150, height: 150), icon: "photo"),
            ComponentTemplate(name: "Avatar", type: .image, category: .media, description: "Material avatar", defaultSize: CGSize(width: 56, height: 56), icon: "person.crop.circle"),
            ComponentTemplate(name: "Material Thumbnail", type: .thumbnail, category: .media, description: "Material thumbnail", defaultSize: CGSize(width: 80, height: 80), icon: "photo.on.rectangle"),
            
            // Layout Components
            ComponentTemplate(name: "Material Card", type: .mediaObject, category: .layout, description: "Material Design card", defaultSize: CGSize(width: 240, height: 160), icon: "rectangle.portrait"),
            ComponentTemplate(name: "Elevated Card", type: .mediaObject, category: .layout, description: "Material elevated card", defaultSize: CGSize(width: 240, height: 160), icon: "rectangle.portrait.fill"),
            ComponentTemplate(name: "List Item", type: .listGroup, category: .layout, description: "Material list item", defaultSize: CGSize(width: 280, height: 56), icon: "list.bullet.rectangle"),
            ComponentTemplate(name: "Divider", type: .well, category: .layout, description: "Material divider", defaultSize: CGSize(width: 200, height: 1), icon: "minus"),
            ComponentTemplate(name: "Data Table", type: .table, category: .layout, description: "Material data table", defaultSize: CGSize(width: 300, height: 200), icon: "tablecells"),
            
            // Feedback Components
            ComponentTemplate(name: "Snackbar", type: .alert, category: .feedback, description: "Material snackbar", defaultSize: CGSize(width: 280, height: 48), icon: "exclamationmark.bubble"),
            ComponentTemplate(name: "Banner", type: .alert, category: .feedback, description: "Material banner", defaultSize: CGSize(width: 320, height: 80), icon: "flag"),
            ComponentTemplate(name: "Dialog", type: .modal, category: .feedback, description: "Material dialog", defaultSize: CGSize(width: 280, height: 160), icon: "rectangle.center.inset.filled"),
            ComponentTemplate(name: "Bottom Sheet", type: .modal, category: .feedback, description: "Material bottom sheet", defaultSize: CGSize(width: 320, height: 200), icon: "rectangle.bottomhalf.filled"),
            ComponentTemplate(name: "Progress Bar", type: .progressBar, category: .feedback, description: "Material progress bar", defaultSize: CGSize(width: 200, height: 4), icon: "progress.indicator"),
            ComponentTemplate(name: "Circular Progress", type: .progressBar, category: .feedback, description: "Material circular progress", defaultSize: CGSize(width: 40, height: 40), icon: "arrow.triangle.2.circlepath"),
            ComponentTemplate(name: "Tooltip", type: .tooltip, category: .feedback, description: "Material tooltip", defaultSize: CGSize(width: 120, height: 40), icon: "bubble.left")
        ]
        
        return ComponentLibraryPack(
            name: "Material Design",
            description: "Google's Material Design component library",
            icon: "circle.grid.3x3",
            author: "Google",
            categories: ComponentCategory.allCases,
            templates: templates,
            colorScheme: .material
        )
    }
    
    static func createBootstrapPack() -> ComponentLibraryPack {
        let templates = [
            // Basic Components
            ComponentTemplate(name: "Bootstrap Button", type: .button, category: .basic, description: "Bootstrap button component", defaultSize: CGSize(width: 120, height: 44), icon: "rectangle.roundedtop"),
            ComponentTemplate(name: "Outline Button", type: .button, category: .basic, description: "Bootstrap outline button", defaultSize: CGSize(width: 120, height: 44), icon: "rectangle"),
            ComponentTemplate(name: "Link Button", type: .button, category: .basic, description: "Bootstrap link button", defaultSize: CGSize(width: 100, height: 44), icon: "link"),
            ComponentTemplate(name: "Button Group", type: .buttonGroup, category: .basic, description: "Bootstrap button group", defaultSize: CGSize(width: 200, height: 44), icon: "rectangle.3.group"),
            ComponentTemplate(name: "Badge", type: .badge, category: .basic, description: "Bootstrap badge", defaultSize: CGSize(width: 60, height: 24), icon: "circle.fill"),
            ComponentTemplate(name: "Bootstrap Icon", type: .icon, category: .basic, description: "Bootstrap icon", defaultSize: CGSize(width: 24, height: 24), icon: "star"),
            ComponentTemplate(name: "Bootstrap Text", type: .label, category: .basic, description: "Bootstrap text content", defaultSize: CGSize(width: 100, height: 24), icon: "textformat"),
            
            // Navigation Components
            ComponentTemplate(name: "Bootstrap Navbar", type: .navbar, category: .navigation, description: "Bootstrap navigation bar", defaultSize: CGSize(width: 320, height: 56), icon: "menubar.rectangle"),
            ComponentTemplate(name: "Nav Pills", type: .tab, category: .navigation, description: "Bootstrap nav pills", defaultSize: CGSize(width: 300, height: 44), icon: "capsule"),
            ComponentTemplate(name: "Nav Tabs", type: .tab, category: .navigation, description: "Bootstrap nav tabs", defaultSize: CGSize(width: 300, height: 44), icon: "rectangle.3.group"),
            ComponentTemplate(name: "Breadcrumb", type: .breadcrumb, category: .navigation, description: "Bootstrap breadcrumb", defaultSize: CGSize(width: 250, height: 32), icon: "chevron.right"),
            ComponentTemplate(name: "Pagination", type: .pagination, category: .navigation, description: "Bootstrap pagination", defaultSize: CGSize(width: 200, height: 40), icon: "ellipsis.circle"),
            ComponentTemplate(name: "Navbar Brand", type: .label, category: .navigation, description: "Bootstrap navbar brand", defaultSize: CGSize(width: 100, height: 32), icon: "textformat.alt"),
            
            // Form Components
            ComponentTemplate(name: "Form Control", type: .formControl, category: .forms, description: "Bootstrap form input", defaultSize: CGSize(width: 200, height: 40), icon: "textfield"),
            ComponentTemplate(name: "Form Select", type: .dropdown, category: .forms, description: "Bootstrap select dropdown", defaultSize: CGSize(width: 200, height: 40), icon: "chevron.down.square"),
            ComponentTemplate(name: "Form Check", type: .formControl, category: .forms, description: "Bootstrap checkbox", defaultSize: CGSize(width: 20, height: 20), icon: "checkmark.square"),
            ComponentTemplate(name: "Form Radio", type: .formControl, category: .forms, description: "Bootstrap radio button", defaultSize: CGSize(width: 20, height: 20), icon: "circle"),
            ComponentTemplate(name: "Form Switch", type: .formControl, category: .forms, description: "Bootstrap switch", defaultSize: CGSize(width: 40, height: 20), icon: "switch.2"),
            ComponentTemplate(name: "Form Range", type: .formControl, category: .forms, description: "Bootstrap range slider", defaultSize: CGSize(width: 200, height: 20), icon: "slider.horizontal.3"),
            ComponentTemplate(name: "Input Group", type: .form, category: .forms, description: "Bootstrap input group", defaultSize: CGSize(width: 250, height: 40), icon: "rectangle.3.group"),
            ComponentTemplate(name: "Form Floating", type: .formControl, category: .forms, description: "Bootstrap floating label", defaultSize: CGSize(width: 200, height: 50), icon: "textfield"),
            
            // Media Components
            ComponentTemplate(name: "Bootstrap Image", type: .image, category: .media, description: "Bootstrap responsive image", defaultSize: CGSize(width: 150, height: 150), icon: "photo"),
            ComponentTemplate(name: "Bootstrap Figure", type: .image, category: .media, description: "Bootstrap figure with caption", defaultSize: CGSize(width: 150, height: 180), icon: "photo.on.rectangle"),
            ComponentTemplate(name: "Bootstrap Thumbnail", type: .thumbnail, category: .media, description: "Bootstrap thumbnail", defaultSize: CGSize(width: 80, height: 80), icon: "photo.on.rectangle"),
            ComponentTemplate(name: "Carousel", type: .carousel, category: .media, description: "Bootstrap carousel", defaultSize: CGSize(width: 300, height: 200), icon: "rectangle.stack"),
            
            // Layout Components
            ComponentTemplate(name: "Bootstrap Card", type: .mediaObject, category: .layout, description: "Bootstrap card component", defaultSize: CGSize(width: 220, height: 140), icon: "rectangle.portrait"),
            ComponentTemplate(name: "Card Group", type: .mediaObject, category: .layout, description: "Bootstrap card group", defaultSize: CGSize(width: 300, height: 140), icon: "rectangle.3.group"),
            ComponentTemplate(name: "List Group", type: .listGroup, category: .layout, description: "Bootstrap list group", defaultSize: CGSize(width: 250, height: 200), icon: "list.bullet.rectangle"),
            ComponentTemplate(name: "List Group Item", type: .listGroup, category: .layout, description: "Bootstrap list item", defaultSize: CGSize(width: 250, height: 50), icon: "list.bullet"),
            ComponentTemplate(name: "Bootstrap Table", type: .table, category: .layout, description: "Bootstrap table", defaultSize: CGSize(width: 300, height: 200), icon: "tablecells"),
            ComponentTemplate(name: "Accordion", type: .collapse, category: .layout, description: "Bootstrap accordion", defaultSize: CGSize(width: 280, height: 150), icon: "list.triangle"),
            ComponentTemplate(name: "Jumbotron", type: .well, category: .layout, description: "Bootstrap jumbotron", defaultSize: CGSize(width: 320, height: 200), icon: "rectangle.inset.filled"),
            
            // Feedback Components
            ComponentTemplate(name: "Alert", type: .alert, category: .feedback, description: "Bootstrap alert", defaultSize: CGSize(width: 280, height: 60), icon: "exclamationmark.triangle"),
            ComponentTemplate(name: "Toast", type: .alert, category: .feedback, description: "Bootstrap toast notification", defaultSize: CGSize(width: 250, height: 80), icon: "bell"),
            ComponentTemplate(name: "Progress Bar", type: .progressBar, category: .feedback, description: "Bootstrap progress", defaultSize: CGSize(width: 200, height: 20), icon: "progress.indicator"),
            ComponentTemplate(name: "Spinner", type: .progressBar, category: .feedback, description: "Bootstrap spinner", defaultSize: CGSize(width: 40, height: 40), icon: "arrow.triangle.2.circlepath"),
            ComponentTemplate(name: "Modal", type: .modal, category: .feedback, description: "Bootstrap modal", defaultSize: CGSize(width: 300, height: 200), icon: "rectangle.center.inset.filled"),
            ComponentTemplate(name: "Tooltip", type: .tooltip, category: .feedback, description: "Bootstrap tooltip", defaultSize: CGSize(width: 120, height: 40), icon: "bubble.left"),
            ComponentTemplate(name: "Popover", type: .tooltip, category: .feedback, description: "Bootstrap popover", defaultSize: CGSize(width: 150, height: 100), icon: "bubble.right")
        ]
        
        return ComponentLibraryPack(
            name: "Bootstrap",
            description: "Popular CSS framework components",
            icon: "square.stack.3d.up.fill",
            author: "Bootstrap Team",
            categories: ComponentCategory.allCases,
            templates: templates,
            colorScheme: .bootstrap
        )
    }
    
    static func createiOSPack() -> ComponentLibraryPack {
        let templates = [
            // Basic Components
            ComponentTemplate(name: "iOS Button", type: .button, category: .basic, description: "iOS style button", defaultSize: CGSize(width: 120, height: 44), icon: "rectangle.roundedtop"),
            ComponentTemplate(name: "System Button", type: .button, category: .basic, description: "iOS system button", defaultSize: CGSize(width: 100, height: 44), icon: "rectangle"),
            ComponentTemplate(name: "SF Symbol", type: .icon, category: .basic, description: "SF Symbols icon", defaultSize: CGSize(width: 32, height: 32), icon: "star"),
            ComponentTemplate(name: "iOS Label", type: .label, category: .basic, description: "iOS text label", defaultSize: CGSize(width: 100, height: 24), icon: "textformat"),
            ComponentTemplate(name: "Badge", type: .badge, category: .basic, description: "iOS notification badge", defaultSize: CGSize(width: 20, height: 20), icon: "circle.fill"),
            ComponentTemplate(name: "Activity Indicator", type: .progressBar, category: .basic, description: "iOS activity indicator", defaultSize: CGSize(width: 20, height: 20), icon: "arrow.triangle.2.circlepath"),
            
            // Navigation Components
            ComponentTemplate(name: "Navigation Bar", type: .navbar, category: .navigation, description: "iOS navigation bar", defaultSize: CGSize(width: 320, height: 64), icon: "menubar.rectangle"),
            ComponentTemplate(name: "Tab Bar", type: .tab, category: .navigation, description: "iOS tab bar", defaultSize: CGSize(width: 320, height: 80), icon: "square.grid.3x1.below.line.grid.1x2"),
            ComponentTemplate(name: "Tab Bar Item", type: .tab, category: .navigation, description: "iOS tab bar item", defaultSize: CGSize(width: 60, height: 80), icon: "square.grid.1x2"),
            ComponentTemplate(name: "Toolbar", type: .navbar, category: .navigation, description: "iOS toolbar", defaultSize: CGSize(width: 320, height: 44), icon: "rectangle.bottomthird.inset.filled"),
            ComponentTemplate(name: "Page Control", type: .pagination, category: .navigation, description: "iOS page dots", defaultSize: CGSize(width: 100, height: 20), icon: "ellipsis.circle"),
            ComponentTemplate(name: "Breadcrumb", type: .breadcrumb, category: .navigation, description: "iOS breadcrumb", defaultSize: CGSize(width: 200, height: 32), icon: "chevron.right"),
            
            // Form Components
            ComponentTemplate(name: "Text Field", type: .formControl, category: .forms, description: "iOS text field", defaultSize: CGSize(width: 200, height: 44), icon: "textfield"),
            ComponentTemplate(name: "Text View", type: .formControl, category: .forms, description: "iOS text view", defaultSize: CGSize(width: 200, height: 100), icon: "text.alignleft"),
            ComponentTemplate(name: "Search Bar", type: .formControl, category: .forms, description: "iOS search bar", defaultSize: CGSize(width: 280, height: 44), icon: "magnifyingglass"),
            ComponentTemplate(name: "Segmented Control", type: .tab, category: .forms, description: "iOS segmented picker", defaultSize: CGSize(width: 200, height: 32), icon: "rectangle.3.group"),
            ComponentTemplate(name: "Picker", type: .dropdown, category: .forms, description: "iOS picker", defaultSize: CGSize(width: 200, height: 120), icon: "list.bullet"),
            ComponentTemplate(name: "Date Picker", type: .formControl, category: .forms, description: "iOS date picker", defaultSize: CGSize(width: 280, height: 120), icon: "calendar"),
            ComponentTemplate(name: "Switch", type: .formControl, category: .forms, description: "iOS switch control", defaultSize: CGSize(width: 50, height: 30), icon: "switch.2"),
            ComponentTemplate(name: "Slider", type: .formControl, category: .forms, description: "iOS slider", defaultSize: CGSize(width: 200, height: 30), icon: "slider.horizontal.3"),
            ComponentTemplate(name: "Stepper", type: .formControl, category: .forms, description: "iOS stepper control", defaultSize: CGSize(width: 100, height: 30), icon: "plus.forwardslash.minus"),
            
            // Media Components
            ComponentTemplate(name: "Image View", type: .image, category: .media, description: "iOS image view", defaultSize: CGSize(width: 150, height: 150), icon: "photo"),
            ComponentTemplate(name: "Profile Image", type: .image, category: .media, description: "iOS profile image", defaultSize: CGSize(width: 80, height: 80), icon: "person.crop.circle"),
            ComponentTemplate(name: "Collection View", type: .carousel, category: .media, description: "iOS collection view", defaultSize: CGSize(width: 300, height: 200), icon: "rectangle.grid.3x2"),
            ComponentTemplate(name: "Scroll View", type: .carousel, category: .media, description: "iOS scroll view", defaultSize: CGSize(width: 280, height: 200), icon: "rectangle.stack"),
            
            // Layout Components
            ComponentTemplate(name: "Table View", type: .table, category: .layout, description: "iOS table view", defaultSize: CGSize(width: 320, height: 300), icon: "tablecells"),
            ComponentTemplate(name: "Table Cell", type: .listGroup, category: .layout, description: "iOS table cell", defaultSize: CGSize(width: 280, height: 60), icon: "list.bullet.rectangle"),
            ComponentTemplate(name: "Collection Cell", type: .listGroup, category: .layout, description: "iOS collection cell", defaultSize: CGSize(width: 100, height: 100), icon: "square.grid.3x3"),
            ComponentTemplate(name: "Stack View", type: .well, category: .layout, description: "iOS stack view", defaultSize: CGSize(width: 200, height: 100), icon: "rectangle.stack"),
            ComponentTemplate(name: "Container View", type: .well, category: .layout, description: "iOS container view", defaultSize: CGSize(width: 280, height: 200), icon: "rectangle.inset.filled"),
            ComponentTemplate(name: "Card View", type: .mediaObject, category: .layout, description: "iOS card-style view", defaultSize: CGSize(width: 280, height: 160), icon: "rectangle.portrait"),
            
            // Feedback Components
            ComponentTemplate(name: "Alert Dialog", type: .alert, category: .feedback, description: "iOS alert", defaultSize: CGSize(width: 280, height: 120), icon: "exclamationmark.triangle"),
            ComponentTemplate(name: "Action Sheet", type: .alert, category: .feedback, description: "iOS action sheet", defaultSize: CGSize(width: 320, height: 200), icon: "list.bullet.rectangle"),
            ComponentTemplate(name: "Toast", type: .alert, category: .feedback, description: "iOS toast notification", defaultSize: CGSize(width: 280, height: 60), icon: "bell"),
            ComponentTemplate(name: "Progress View", type: .progressBar, category: .feedback, description: "iOS progress bar", defaultSize: CGSize(width: 200, height: 4), icon: "progress.indicator"),
            ComponentTemplate(name: "HUD", type: .modal, category: .feedback, description: "iOS heads-up display", defaultSize: CGSize(width: 120, height: 120), icon: "rectangle.center.inset.filled"),
            ComponentTemplate(name: "Modal Sheet", type: .modal, category: .feedback, description: "iOS modal sheet", defaultSize: CGSize(width: 320, height: 400), icon: "rectangle.bottomhalf.filled"),
            ComponentTemplate(name: "Popover", type: .tooltip, category: .feedback, description: "iOS popover", defaultSize: CGSize(width: 200, height: 150), icon: "bubble.right")
        ]
        
        return ComponentLibraryPack(
            name: "iOS Human Interface",
            description: "Apple's iOS design system components",
            icon: "iphone",
            author: "Apple",
            categories: ComponentCategory.allCases,
            templates: templates,
            colorScheme: .default
        )
    }
    
    static func createTailwindPack() -> ComponentLibraryPack {
        let templates = [
            // Basic Components
            ComponentTemplate(name: "Tailwind Button", type: .button, category: .basic, description: "Tailwind CSS button", defaultSize: CGSize(width: 120, height: 44), icon: "rectangle.roundedtop"),
            ComponentTemplate(name: "Ghost Button", type: .button, category: .basic, description: "Tailwind ghost button", defaultSize: CGSize(width: 120, height: 44), icon: "rectangle"),
            ComponentTemplate(name: "Icon Button", type: .button, category: .basic, description: "Tailwind icon button", defaultSize: CGSize(width: 44, height: 44), icon: "circle"),
            ComponentTemplate(name: "Button Group", type: .buttonGroup, category: .basic, description: "Tailwind button group", defaultSize: CGSize(width: 200, height: 44), icon: "rectangle.3.group"),
            ComponentTemplate(name: "Badge", type: .badge, category: .basic, description: "Tailwind badge", defaultSize: CGSize(width: 60, height: 24), icon: "circle.fill"),
            ComponentTemplate(name: "Pill Badge", type: .badge, category: .basic, description: "Tailwind pill badge", defaultSize: CGSize(width: 80, height: 24), icon: "capsule"),
            ComponentTemplate(name: "Tailwind Icon", type: .icon, category: .basic, description: "Tailwind icon", defaultSize: CGSize(width: 24, height: 24), icon: "star"),
            ComponentTemplate(name: "Tailwind Text", type: .label, category: .basic, description: "Tailwind text content", defaultSize: CGSize(width: 100, height: 24), icon: "textformat"),
            
            // Navigation Components
            ComponentTemplate(name: "Navigation", type: .navbar, category: .navigation, description: "Tailwind navigation", defaultSize: CGSize(width: 320, height: 64), icon: "menubar.rectangle"),
            ComponentTemplate(name: "Mobile Menu", type: .navbar, category: .navigation, description: "Tailwind mobile menu", defaultSize: CGSize(width: 280, height: 200), icon: "line.3.horizontal"),
            ComponentTemplate(name: "Tabs", type: .tab, category: .navigation, description: "Tailwind tab navigation", defaultSize: CGSize(width: 300, height: 44), icon: "rectangle.3.group"),
            ComponentTemplate(name: "Breadcrumbs", type: .breadcrumb, category: .navigation, description: "Tailwind breadcrumbs", defaultSize: CGSize(width: 250, height: 32), icon: "chevron.right"),
            ComponentTemplate(name: "Pagination", type: .pagination, category: .navigation, description: "Tailwind pagination", defaultSize: CGSize(width: 200, height: 40), icon: "ellipsis.circle"),
            ComponentTemplate(name: "Sidebar", type: .navs, category: .navigation, description: "Tailwind sidebar", defaultSize: CGSize(width: 240, height: 400), icon: "sidebar.left"),
            
            // Form Components
            ComponentTemplate(name: "Input Field", type: .formControl, category: .forms, description: "Tailwind form input", defaultSize: CGSize(width: 200, height: 44), icon: "textfield"),
            ComponentTemplate(name: "Textarea", type: .formControl, category: .forms, description: "Tailwind textarea", defaultSize: CGSize(width: 200, height: 100), icon: "text.alignleft"),
            ComponentTemplate(name: "Select", type: .dropdown, category: .forms, description: "Tailwind select", defaultSize: CGSize(width: 200, height: 44), icon: "chevron.down.square"),
            ComponentTemplate(name: "Dropdown", type: .dropdown, category: .forms, description: "Tailwind dropdown", defaultSize: CGSize(width: 160, height: 44), icon: "chevron.down.square"),
            ComponentTemplate(name: "Checkbox", type: .formControl, category: .forms, description: "Tailwind checkbox", defaultSize: CGSize(width: 20, height: 20), icon: "checkmark.square"),
            ComponentTemplate(name: "Radio Button", type: .formControl, category: .forms, description: "Tailwind radio", defaultSize: CGSize(width: 20, height: 20), icon: "circle"),
            ComponentTemplate(name: "Toggle Switch", type: .formControl, category: .forms, description: "Tailwind toggle", defaultSize: CGSize(width: 44, height: 24), icon: "switch.2"),
            ComponentTemplate(name: "Range Slider", type: .formControl, category: .forms, description: "Tailwind slider", defaultSize: CGSize(width: 200, height: 20), icon: "slider.horizontal.3"),
            ComponentTemplate(name: "Search Bar", type: .formControl, category: .forms, description: "Tailwind search", defaultSize: CGSize(width: 250, height: 44), icon: "magnifyingglass"),
            ComponentTemplate(name: "File Upload", type: .formControl, category: .forms, description: "Tailwind file input", defaultSize: CGSize(width: 200, height: 100), icon: "doc.badge.plus"),
            
            // Media Components
            ComponentTemplate(name: "Image", type: .image, category: .media, description: "Tailwind responsive image", defaultSize: CGSize(width: 150, height: 150), icon: "photo"),
            ComponentTemplate(name: "Avatar", type: .image, category: .media, description: "Tailwind avatar", defaultSize: CGSize(width: 64, height: 64), icon: "person.crop.circle"),
            ComponentTemplate(name: "Gallery", type: .carousel, category: .media, description: "Tailwind image gallery", defaultSize: CGSize(width: 300, height: 200), icon: "rectangle.grid.3x2"),
            ComponentTemplate(name: "Video Player", type: .carousel, category: .media, description: "Tailwind video player", defaultSize: CGSize(width: 320, height: 180), icon: "play.rectangle"),
            
            // Layout Components
            ComponentTemplate(name: "Tailwind Card", type: .mediaObject, category: .layout, description: "Tailwind card component", defaultSize: CGSize(width: 200, height: 140), icon: "rectangle.portrait"),
            ComponentTemplate(name: "Feature Card", type: .mediaObject, category: .layout, description: "Tailwind feature card", defaultSize: CGSize(width: 240, height: 160), icon: "rectangle.portrait.fill"),
            ComponentTemplate(name: "List Group", type: .listGroup, category: .layout, description: "Tailwind list", defaultSize: CGSize(width: 250, height: 200), icon: "list.bullet.rectangle"),
            ComponentTemplate(name: "Timeline", type: .listGroup, category: .layout, description: "Tailwind timeline", defaultSize: CGSize(width: 280, height: 300), icon: "timeline.selection"),
            ComponentTemplate(name: "Data Table", type: .table, category: .layout, description: "Tailwind table", defaultSize: CGSize(width: 320, height: 200), icon: "tablecells"),
            ComponentTemplate(name: "Stats Card", type: .well, category: .layout, description: "Tailwind stats", defaultSize: CGSize(width: 200, height: 100), icon: "chart.bar"),
            ComponentTemplate(name: "Hero Section", type: .well, category: .layout, description: "Hero banner section", defaultSize: CGSize(width: 320, height: 200), icon: "rectangle.inset.filled"),
            ComponentTemplate(name: "CTA Section", type: .well, category: .layout, description: "Call-to-action section", defaultSize: CGSize(width: 320, height: 120), icon: "megaphone"),
            
            // Feedback Components
            ComponentTemplate(name: "Alert", type: .alert, category: .feedback, description: "Tailwind alert", defaultSize: CGSize(width: 280, height: 60), icon: "exclamationmark.triangle"),
            ComponentTemplate(name: "Notification", type: .alert, category: .feedback, description: "Tailwind notification", defaultSize: CGSize(width: 300, height: 80), icon: "bell"),
            ComponentTemplate(name: "Toast", type: .alert, category: .feedback, description: "Tailwind toast", defaultSize: CGSize(width: 280, height: 60), icon: "bubble.right"),
            ComponentTemplate(name: "Banner", type: .alert, category: .feedback, description: "Tailwind banner", defaultSize: CGSize(width: 320, height: 80), icon: "flag"),
            ComponentTemplate(name: "Progress Bar", type: .progressBar, category: .feedback, description: "Tailwind progress", defaultSize: CGSize(width: 200, height: 8), icon: "progress.indicator"),
            ComponentTemplate(name: "Loading Spinner", type: .progressBar, category: .feedback, description: "Tailwind spinner", defaultSize: CGSize(width: 32, height: 32), icon: "arrow.triangle.2.circlepath"),
            ComponentTemplate(name: "Modal", type: .modal, category: .feedback, description: "Tailwind modal", defaultSize: CGSize(width: 300, height: 200), icon: "rectangle.center.inset.filled"),
            ComponentTemplate(name: "Slide Over", type: .modal, category: .feedback, description: "Tailwind slide over", defaultSize: CGSize(width: 280, height: 400), icon: "rectangle.righthalf.filled"),
            ComponentTemplate(name: "Tooltip", type: .tooltip, category: .feedback, description: "Tailwind tooltip", defaultSize: CGSize(width: 120, height: 40), icon: "bubble.left"),
            ComponentTemplate(name: "Popover", type: .tooltip, category: .feedback, description: "Tailwind popover", defaultSize: CGSize(width: 180, height: 100), icon: "bubble.right")
        ]
        
        return ComponentLibraryPack(
            name: "Tailwind CSS",
            description: "Utility-first CSS framework components",
            icon: "wind",
            author: "Tailwind Labs",
            categories: ComponentCategory.allCases,
            templates: templates,
            colorScheme: .tailwind
        )
    }
    
    static func createGitLabPajamasPack() -> ComponentLibraryPack {
        let templates = ComponentLibrary.shared.allTemplates.filter { $0.category == .gitlabPajamas }
        
        return ComponentLibraryPack(
            name: "GitLab Pajamas",
            description: "GitLab's open-source design system for building cohesive experiences",
            icon: "fox.circle.fill",
            author: "GitLab",
            categories: [.gitlabPajamas],
            templates: templates,
            colorScheme: PackColorScheme(
                primary: "#1F75CB",
                secondary: "#666666",
                accent: "#FC6D26",
                background: "#FAFAFA"
            )
        )
    }
    
    static func createIBMCarbonPack() -> ComponentLibraryPack {
        let templates = ComponentLibrary.shared.allTemplates.filter { $0.category == .ibmCarbon }
        
        return ComponentLibraryPack(
            name: "IBM Carbon",
            description: "IBM's enterprise-grade design system for digital products and experiences",
            icon: "atom",
            author: "IBM",
            categories: [.ibmCarbon],
            templates: templates,
            colorScheme: PackColorScheme(
                primary: "#0F62FE",
                secondary: "#525252",
                accent: "#DA1E28",
                background: "#F4F4F4"
            )
        )
    }
} 