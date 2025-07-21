import SwiftUI

/// Main menu view accessible from the canvas header - now as a sidebar
struct MainMenuView: View {
    @StateObject private var libraryManager = ComponentLibraryManager.shared
    
    let onOpenFiles: () -> Void
    let onOpenSettings: () -> Void
    let onSwitchLibrary: () -> Void
    let onAddLibrary: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top alignment padding (to match canvas header on iPad)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Color.clear
                        .frame(height: geometry.safeAreaInsets.top + 40)
                }
                
                // Header with app branding
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 4) {
                            Text("SketchSite")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .rotationEffect(.degrees(90)) // Rotate to point right for sidebar
                        }
                        
                        Spacer()
                        
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                }
                .padding()
                .background(.regularMaterial)
                
                // Menu Items
                ScrollView {
                    VStack(spacing: 0) {
                        MenuItemRow(
                            icon: "folder",
                            title: "Files",
                            subtitle: "Manage your sketches",
                            action: {
                                onOpenFiles()
                                onDismiss()
                            }
                        )
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        // Current Library Display
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hexString: libraryManager.currentPack.colorScheme.primary).opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: libraryManager.currentPack.icon)
                                        .font(.title3)
                                        .foregroundColor(Color(hexString: libraryManager.currentPack.colorScheme.primary))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("Current Library")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    
                                    Text(libraryManager.currentPack.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(libraryManager.currentPack.templates.count) components")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .background(.regularMaterial.opacity(0.5))
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        MenuItemRow(
                            icon: "arrow.2.squarepath",
                            title: "Switch Library",
                            subtitle: "Change design system",
                            action: {
                                onSwitchLibrary()
                                onDismiss()
                            }
                        )
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        MenuItemRow(
                            icon: "plus.rectangle.on.folder",
                            title: "Add Library",
                            subtitle: "Create custom library",
                            action: {
                                onAddLibrary()
                                onDismiss()
                            }
                        )
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        MenuItemRow(
                            icon: "gearshape",
                            title: "Settings",
                            subtitle: "App preferences",
                            isComingSoon: true,
                            action: {
                                onOpenSettings()
                                onDismiss()
                            }
                        )
                    }
                    .background(.regularMaterial)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Menu Item Row

struct MenuItemRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isComingSoon: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isComingSoon ? Color.gray.opacity(0.3) : Color.blue.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(isComingSoon ? .gray : .blue)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isComingSoon {
                            Text("Coming Soon")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isComingSoon)
    }
}

// MARK: - Preview

#if DEBUG
struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(
            onOpenFiles: { },
            onOpenSettings: { },
            onSwitchLibrary: { },
            onAddLibrary: { },
            onDismiss: { }
        )
    }
}
#endif 