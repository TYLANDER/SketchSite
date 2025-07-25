import SwiftUI

/// Component Library View - displays categorized component templates that can be added to the canvas
struct ComponentLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onComponentSelected: (ComponentTemplate) -> Void
    
    @State private var selectedCategory: ComponentCategory = .basic
    @State private var searchText = ""
    @State private var showingQuickAdd = false
    
    @StateObject private var libraryManager = ComponentLibraryManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Category picker
                categoryPicker
                
                // Component grid
                componentGrid
                
                // Quick add section
                if showingQuickAdd {
                    quickAddSection
                }
            }
            .navigationTitle("Component Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingQuickAdd.toggle() }) {
                        Image(systemName: showingQuickAdd ? "minus.circle" : "plus.circle")
                    }
                }
            })
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search components...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(libraryManager.availableCategories, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .onAppear {
            // Set initial category to first available category
            if let firstCategory = libraryManager.availableCategories.first {
                selectedCategory = firstCategory
            }
        }
    }
    
    // MARK: - Component Grid
    
    private var componentGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(filteredComponents, id: \.id) { template in
                    ComponentCard(
                        template: template,
                        onTap: { handleComponentSelection(template) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Quick Add Section
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Add")
                    .font(.headline)
                
                Spacer()
                
                // Show status indicator
                if hasUsageData {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                        Text("Personalized")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("Common")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            .padding(.horizontal)
            
            if quickAddComponents.isEmpty {
                // Fallback when no quick add components available
                Text("No components available for quick add")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(quickAddComponents, id: \.id) { template in
                            QuickAddButton(
                                template: template,
                                usageCount: getUsageCount(for: template),
                                onTap: { handleComponentSelection(template) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Properties
    
    private var hasUsageData: Bool {
        quickAddComponents.contains { template in
            getUsageCount(for: template) > 0
        }
    }
    
    private func getUsageCount(for template: ComponentTemplate) -> Int {
        libraryManager.usageData.getUsageCount(for: template.id)
    }
    
    // MARK: - Computed Properties
    
    private var filteredComponents: [ComponentTemplate] {
        let categoryComponents = libraryManager.templates(for: selectedCategory)
        
        if searchText.isEmpty {
            return categoryComponents
        } else {
            return categoryComponents.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.type.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var quickAddComponents: [ComponentTemplate] {
        // Get most frequently used components, falls back to common types
        return libraryManager.getQuickAddTemplates(limit: 4)
    }
    
    // MARK: - Actions
    
    private func handleComponentSelection(_ template: ComponentTemplate) {
        // Record usage for better quick add suggestions
        libraryManager.recordTemplateUsage(template)
        
        onComponentSelected(template)
        dismiss()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: ComponentCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                                    Image(systemName: category.icon)
                        .font(.caption)
                    Text(category.rawValue)
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.clear)
                .foregroundColor(isSelected ? Color.white : Color.primary)
                            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Component Card

struct ComponentCard: View {
    let template: ComponentTemplate
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .frame(height: 80)
                    
                    Image(systemName: template.icon)
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.blue)
                }
                
                // Content
                VStack(spacing: 4) {
                    Text(template.name)
                        .font(.system(.subheadline, weight: .semibold))
                        .multilineTextAlignment(.center)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Size info
                    Text("\(Int(template.defaultSize.width)) × \(Int(template.defaultSize.height))")
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .cornerRadius(16)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: .black.opacity(0.1), radius: isPressed ? 2 : 8, x: 0, y: isPressed ? 1 : 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let template: ComponentTemplate
    let usageCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                VStack(spacing: 6) {
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(template.name)
                        .font(.caption2.weight(.medium))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(width: 80, height: 70)
                .background(.regularMaterial)
                .cornerRadius(12)
                
                // Usage count badge
                if usageCount > 0 {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Text("\(usageCount)")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 4, y: -4)
                        }
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct ComponentLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        ComponentLibraryView { template in
            print("Selected: \(template.name)")
        }
    }
}
#endif 