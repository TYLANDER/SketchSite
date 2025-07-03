import SwiftUI

/// Main menu view accessible from the canvas header
struct MainMenuView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onOpenFiles: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Menu")
                    .font(.title2.weight(.bold))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial)
            
            // Menu Items
            VStack(spacing: 0) {
                MenuItemRow(
                    icon: "folder",
                    title: "Files",
                    subtitle: "Manage your sketches",
                    action: {
                        onOpenFiles()
                        dismiss()
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
                        dismiss()
                    }
                )
            }
            .background(.regularMaterial)
            
            Spacer()
        }
        .background(Color.black.opacity(0.3))
        .ignoresSafeArea()
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
            onOpenSettings: { }
        )
    }
}
#endif 