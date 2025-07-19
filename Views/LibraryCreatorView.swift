import SwiftUI

struct LibraryCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var libraryManager = ComponentLibraryManager.shared
    
    @State private var libraryName = ""
    @State private var libraryDescription = ""
    @State private var authorName = "Custom"
    @State private var selectedIcon = "square.grid.2x2"
    @State private var selectedColorScheme = PackColorScheme.default
    @State private var selectedCategories: Set<ComponentCategory> = []
    @State private var selectedTemplates: Set<ComponentTemplate> = []
    @State private var showIconPicker = false
    @State private var showColorPicker = false
    
    private let availableIcons = [
        "square.grid.2x2", "rectangle.3.group", "square.stack.3d.up",
        "paintbrush", "wand.and.rays", "app.gift", "folder.badge.plus",
        "cube.box", "shippingbox", "archivebox", "tray.full",
        "grid", "squares.below.rectangle", "rectangle.grid.2x2"
    ]
    
    private let colorSchemes: [(String, PackColorScheme)] = [
        ("Default", .default),
        ("Material", .material),
        ("Bootstrap", .bootstrap),
        ("Tailwind", .tailwind),
        ("Purple", PackColorScheme(primary: "#8B5CF6", secondary: "#6B7280", accent: "#F59E0B", background: "#F3F4F6")),
        ("Green", PackColorScheme(primary: "#10B981", secondary: "#6B7280", accent: "#EF4444", background: "#F0FDF4")),
        ("Pink", PackColorScheme(primary: "#EC4899", secondary: "#6B7280", accent: "#8B5CF6", background: "#FDF2F8"))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Library Info Section
                    libraryInfoSection
                    
                    // Icon Selection
                    iconSelectionSection
                    
                    // Color Scheme Selection
                    colorSchemeSection
                    
                    // Categories Selection
                    categoriesSection
                    
                    // Templates Selection
                    templatesSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Create Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {
                        createLibrary()
                    }
                    .disabled(!canCreateLibrary)
                }
            })
        }
        .onAppear {
            // Pre-populate with some defaults
            selectedCategories = Set(ComponentCategory.allCases.prefix(3))
            selectedTemplates = Set(libraryManager.currentTemplates.prefix(8))
        }
    }
    
    // MARK: - Library Info Section
    
    private var libraryInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Library Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Library Name")
                        .font(.subheadline.weight(.medium))
                    TextField("Enter library name...", text: $libraryName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.subheadline.weight(.medium))
                    TextField("Describe your component library...", text: $libraryDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Author")
                        .font(.subheadline.weight(.medium))
                    TextField("Your name", text: $authorName)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Icon Selection Section
    
    private var iconSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Library Icon")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(availableIcons, id: \.self) { icon in
                    Button(action: { selectedIcon = icon }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedIcon == icon ? Color.blue : Color.clear)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Color Scheme Section
    
    private var colorSchemeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Color Scheme")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(Array(colorSchemes.enumerated()), id: \.offset) { index, scheme in
                    Button(action: { selectedColorScheme = scheme.1 }) {
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hexString: scheme.1.primary))
                                    .frame(width: 16, height: 16)
                                Circle()
                                    .fill(Color(hexString: scheme.1.secondary))
                                    .frame(width: 16, height: 16)
                                Circle()
                                    .fill(Color(hexString: scheme.1.accent))
                                    .frame(width: 16, height: 16)
                            }
                            
                            Text(scheme.0)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(selectedColorScheme.primary == scheme.1.primary ? Color.blue.opacity(0.1) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedColorScheme.primary == scheme.1.primary ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(ComponentCategory.allCases, id: \.self) { category in
                    Button(action: { toggleCategory(category) }) {
                        HStack {
                            Image(systemName: category.icon)
                                .font(.caption)
                            
                            Text(category.rawValue)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategories.contains(category) ? Color.blue.opacity(0.1) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedCategories.contains(category) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Templates Section
    
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Components")
                    .font(.headline)
                
                Spacer()
                
                Text("\(selectedTemplates.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(availableTemplates, id: \.id) { template in
                    Button(action: { toggleTemplate(template) }) {
                        VStack(spacing: 8) {
                            Image(systemName: template.icon)
                                .font(.title3)
                                .foregroundColor(selectedTemplates.contains(template) ? .white : .blue)
                            
                            Text(template.name)
                                .font(.caption.weight(.medium))
                                .foregroundColor(selectedTemplates.contains(template) ? .white : .primary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 70)
                        .frame(maxWidth: .infinity)
                        .background(selectedTemplates.contains(template) ? Color.blue : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedTemplates.contains(template) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var canCreateLibrary: Bool {
        !libraryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !libraryDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCategories.isEmpty &&
        !selectedTemplates.isEmpty
    }
    
    private var availableTemplates: [ComponentTemplate] {
        libraryManager.currentTemplates.filter { template in
            selectedCategories.contains(template.category)
        }
    }
    
    // MARK: - Actions
    
    private func toggleCategory(_ category: ComponentCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
            // Remove templates from unselected categories
            selectedTemplates = selectedTemplates.filter { selectedCategories.contains($0.category) }
        } else {
            selectedCategories.insert(category)
        }
    }
    
    private func toggleTemplate(_ template: ComponentTemplate) {
        if selectedTemplates.contains(template) {
            selectedTemplates.remove(template)
        } else {
            selectedTemplates.insert(template)
        }
    }
    
    private func createLibrary() {
        let newPack = ComponentLibraryPack(
            name: libraryName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: libraryDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: selectedIcon,
            version: "1.0",
            author: authorName.trimmingCharacters(in: .whitespacesAndNewlines),
            categories: Array(selectedCategories),
            templates: Array(selectedTemplates),
            isBuiltIn: false,
            colorScheme: selectedColorScheme
        )
        
        libraryManager.addCustomPack(newPack)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
}

// MARK: - Preview

#if DEBUG
struct LibraryCreatorView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryCreatorView()
    }
}
#endif 