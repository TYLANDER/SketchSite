import Foundation
import SwiftUI

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
    
    private let userDefaults = UserDefaults.standard
    private let currentPackKey = "SketchSite_CurrentComponentPack"
    private let customPacksKey = "SketchSite_CustomComponentPacks"
    
    static let shared = ComponentLibraryManager()
    
    private init() {
        // Initialize with default pack
        self.currentPack = Self.createDefaultPack()
        self.availablePacks = []
        
        loadBuiltInPacks()
        loadCustomPacks()
        loadCurrentPack()
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
    
    // MARK: - Built-in Packs
    
    private func loadBuiltInPacks() {
        availablePacks = [
            Self.createDefaultPack(),
            Self.createMaterialDesignPack(),
            Self.createBootstrapPack(),
            Self.createiOSPack(),
            Self.createTailwindPack()
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
            ComponentTemplate(name: "Material Button", type: .button, category: .basic, description: "Material Design button", defaultSize: CGSize(width: 120, height: 48), icon: "rectangle.roundedtop"),
            ComponentTemplate(name: "FAB", type: .button, category: .basic, description: "Floating Action Button", defaultSize: CGSize(width: 56, height: 56), icon: "plus.circle.fill"),
            ComponentTemplate(name: "Material Card", type: .mediaObject, category: .layout, description: "Material Design card", defaultSize: CGSize(width: 240, height: 160), icon: "rectangle.portrait"),
            ComponentTemplate(name: "App Bar", type: .navbar, category: .navigation, description: "Material top app bar", defaultSize: CGSize(width: 320, height: 64), icon: "menubar.rectangle"),
            ComponentTemplate(name: "Bottom Nav", type: .tab, category: .navigation, description: "Bottom navigation", defaultSize: CGSize(width: 320, height: 80), icon: "square.grid.3x1.below.line.grid.1x2"),
            ComponentTemplate(name: "Material Input", type: .formControl, category: .forms, description: "Material text field", defaultSize: CGSize(width: 200, height: 56), icon: "textfield"),
            ComponentTemplate(name: "Chip", type: .badge, category: .basic, description: "Material chip component", defaultSize: CGSize(width: 80, height: 32), icon: "capsule"),
            ComponentTemplate(name: "Snackbar", type: .alert, category: .feedback, description: "Material snackbar", defaultSize: CGSize(width: 280, height: 48), icon: "exclamationmark.bubble")
        ]
        
        return ComponentLibraryPack(
            name: "Material Design",
            description: "Google's Material Design component library",
            icon: "circle.grid.3x3",
            author: "Google",
            categories: [.basic, .navigation, .forms, .layout, .feedback],
            templates: templates,
            colorScheme: .material
        )
    }
    
    static func createBootstrapPack() -> ComponentLibraryPack {
        let templates = [
            ComponentTemplate(name: "Bootstrap Button", type: .button, category: .basic, description: "Bootstrap button component", defaultSize: CGSize(width: 120, height: 44), icon: "rectangle.roundedtop"),
            ComponentTemplate(name: "Bootstrap Navbar", type: .navbar, category: .navigation, description: "Bootstrap navigation bar", defaultSize: CGSize(width: 320, height: 56), icon: "menubar.rectangle"),
            ComponentTemplate(name: "Bootstrap Card", type: .mediaObject, category: .layout, description: "Bootstrap card component", defaultSize: CGSize(width: 220, height: 140), icon: "rectangle.portrait"),
            ComponentTemplate(name: "Form Control", type: .formControl, category: .forms, description: "Bootstrap form input", defaultSize: CGSize(width: 200, height: 40), icon: "textfield"),
            ComponentTemplate(name: "Alert", type: .alert, category: .feedback, description: "Bootstrap alert", defaultSize: CGSize(width: 280, height: 60), icon: "exclamationmark.triangle"),
            ComponentTemplate(name: "Badge", type: .badge, category: .basic, description: "Bootstrap badge", defaultSize: CGSize(width: 60, height: 24), icon: "circle.fill"),
            ComponentTemplate(name: "Breadcrumb", type: .breadcrumb, category: .navigation, description: "Bootstrap breadcrumb", defaultSize: CGSize(width: 250, height: 32), icon: "chevron.right"),
            ComponentTemplate(name: "Progress Bar", type: .progressBar, category: .feedback, description: "Bootstrap progress", defaultSize: CGSize(width: 200, height: 20), icon: "progress.indicator")
        ]
        
        return ComponentLibraryPack(
            name: "Bootstrap",
            description: "Popular CSS framework components",
            icon: "square.stack.3d.up.fill",
            author: "Bootstrap Team",
            categories: [.basic, .navigation, .forms, .layout, .feedback],
            templates: templates,
            colorScheme: .bootstrap
        )
    }
    
    static func createiOSPack() -> ComponentLibraryPack {
        let templates = [
            ComponentTemplate(name: "iOS Button", type: .button, category: .basic, description: "iOS style button", defaultSize: CGSize(width: 120, height: 44), icon: "rectangle.roundedtop"),
            ComponentTemplate(name: "Navigation Bar", type: .navbar, category: .navigation, description: "iOS navigation bar", defaultSize: CGSize(width: 320, height: 64), icon: "menubar.rectangle"),
            ComponentTemplate(name: "Tab Bar", type: .tab, category: .navigation, description: "iOS tab bar", defaultSize: CGSize(width: 320, height: 80), icon: "square.grid.3x1.below.line.grid.1x2"),
            ComponentTemplate(name: "Table Cell", type: .listGroup, category: .layout, description: "iOS table cell", defaultSize: CGSize(width: 280, height: 60), icon: "list.bullet.rectangle"),
            ComponentTemplate(name: "Text Field", type: .formControl, category: .forms, description: "iOS text field", defaultSize: CGSize(width: 200, height: 44), icon: "textfield"),
            ComponentTemplate(name: "SF Symbol", type: .icon, category: .basic, description: "SF Symbols icon", defaultSize: CGSize(width: 32, height: 32), icon: "star"),
            ComponentTemplate(name: "Alert Dialog", type: .alert, category: .feedback, description: "iOS alert", defaultSize: CGSize(width: 280, height: 120), icon: "exclamationmark.triangle"),
            ComponentTemplate(name: "Segmented Control", type: .tab, category: .forms, description: "iOS segmented picker", defaultSize: CGSize(width: 200, height: 32), icon: "rectangle.3.group")
        ]
        
        return ComponentLibraryPack(
            name: "iOS Human Interface",
            description: "Apple's iOS design system components",
            icon: "iphone",
            author: "Apple",
            categories: [.basic, .navigation, .forms, .layout, .feedback],
            templates: templates,
            colorScheme: .default
        )
    }
    
    static func createTailwindPack() -> ComponentLibraryPack {
        let templates = [
            ComponentTemplate(name: "Tailwind Button", type: .button, category: .basic, description: "Tailwind CSS button", defaultSize: CGSize(width: 120, height: 44), icon: "rectangle.roundedtop"),
            ComponentTemplate(name: "Hero Section", type: .well, category: .layout, description: "Hero banner section", defaultSize: CGSize(width: 320, height: 200), icon: "rectangle.inset.filled"),
            ComponentTemplate(name: "Tailwind Card", type: .mediaObject, category: .layout, description: "Tailwind card component", defaultSize: CGSize(width: 200, height: 140), icon: "rectangle.portrait"),
            ComponentTemplate(name: "Navigation", type: .navbar, category: .navigation, description: "Tailwind navigation", defaultSize: CGSize(width: 320, height: 64), icon: "menubar.rectangle"),
            ComponentTemplate(name: "Input Field", type: .formControl, category: .forms, description: "Tailwind form input", defaultSize: CGSize(width: 200, height: 44), icon: "textfield"),
            ComponentTemplate(name: "Badge", type: .badge, category: .basic, description: "Tailwind badge", defaultSize: CGSize(width: 60, height: 24), icon: "circle.fill"),
            ComponentTemplate(name: "Modal", type: .modal, category: .feedback, description: "Tailwind modal", defaultSize: CGSize(width: 300, height: 200), icon: "rectangle.center.inset.filled"),
            ComponentTemplate(name: "Dropdown", type: .dropdown, category: .forms, description: "Tailwind dropdown", defaultSize: CGSize(width: 160, height: 44), icon: "chevron.down.square")
        ]
        
        return ComponentLibraryPack(
            name: "Tailwind CSS",
            description: "Utility-first CSS framework components",
            icon: "wind",
            author: "Tailwind Labs",
            categories: [.basic, .navigation, .forms, .layout, .feedback],
            templates: templates,
            colorScheme: .tailwind
        )
    }
} 