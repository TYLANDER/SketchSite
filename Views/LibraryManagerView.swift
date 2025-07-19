import SwiftUI

struct LibraryManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var libraryManager = ComponentLibraryManager.shared
    @State private var showingPackDetails: ComponentLibraryPack? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Current Pack Header
                currentPackHeader
                
                // Available Packs List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(libraryManager.availablePacks) { pack in
                            PackRow(
                                pack: pack,
                                isSelected: pack.id == libraryManager.currentPack.id,
                                onSelect: {
                                    libraryManager.switchToPack(pack)
                                },
                                onShowDetails: {
                                    showingPackDetails = pack
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Component Libraries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Add Custom") {
                        // TODO: Implement custom pack creation
                        print("Add custom pack - Coming soon!")
                    }
                    .foregroundColor(.blue)
                }
            })
        }
        .sheet(item: $showingPackDetails) { pack in
            PackDetailsView(pack: pack)
        }
    }
    
    // MARK: - Current Pack Header
    
    private var currentPackHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: libraryManager.currentPack.icon)
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Library")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(libraryManager.currentPack.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(libraryManager.currentPack.templates.count)")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                    
                    Text("components")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(libraryManager.currentPack.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Pack Row

struct PackRow: View {
    let pack: ComponentLibraryPack
    let isSelected: Bool
    let onSelect: () -> Void
    let onShowDetails: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Pack Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hexString: pack.colorScheme.primary).opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: pack.icon)
                        .font(.title2)
                        .foregroundColor(Color(hexString: pack.colorScheme.primary))
                }
                
                // Pack Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pack.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if pack.isBuiltIn {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text("by \(pack.author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(pack.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Pack Stats
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.2x2")
                                .font(.caption)
                            Text("\(pack.templates.count) components")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.caption)
                            Text("\(pack.categories.count) categories")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Details") {
                            onShowDetails()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .onTapGesture {
                onSelect()
            }
        }
    }
}

// MARK: - Pack Details View

struct PackDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let pack: ComponentLibraryPack
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Pack Header
                    VStack(spacing: 16) {
                        Image(systemName: pack.icon)
                            .font(.system(size: 60))
                            .foregroundColor(Color(hexString: pack.colorScheme.primary))
                        
                        VStack(spacing: 8) {
                            Text(pack.name)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)
                            
                            Text("by \(pack.author)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if pack.isBuiltIn {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption)
                                    Text("Official Library")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(pack.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Library Stats")
                            .font(.headline)
                        
                        HStack(spacing: 24) {
                            StatItem(
                                icon: "square.grid.2x2",
                                value: "\(pack.templates.count)",
                                label: "Components"
                            )
                            
                            StatItem(
                                icon: "folder",
                                value: "\(pack.categories.count)",
                                label: "Categories"
                            )
                            
                            StatItem(
                                icon: "tag",
                                value: pack.version,
                                label: "Version"
                            )
                        }
                    }
                    
                    // Color Scheme
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color Scheme")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ColorSwatch(color: pack.colorScheme.primary, label: "Primary")
                            ColorSwatch(color: pack.colorScheme.secondary, label: "Secondary")
                            ColorSwatch(color: pack.colorScheme.accent, label: "Accent")
                            ColorSwatch(color: pack.colorScheme.background, label: "Background")
                        }
                    }
                    
                    // Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(pack.categories, id: \.self) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text(category.rawValue)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text("\(pack.templates.filter { $0.category == category }.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.regularMaterial)
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Library Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            })
        }
    }
}

// MARK: - Helper Views

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .cornerRadius(8)
    }
}

struct ColorSwatch: View {
    let color: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color(hexString: color))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}



// MARK: - Preview

#if DEBUG
struct LibraryManagerView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryManagerView()
    }
}
#endif 