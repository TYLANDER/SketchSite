import SwiftUI

/// Professional sketch manager for multi-project support
struct SketchManagerView: View {
    @StateObject private var sketchManager = SketchManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingNewProjectDialog = false
    @State private var newProjectName = ""
    @State private var selectedProject: SketchProject?
    @State private var showingDeleteConfirmation = false
    @State private var showingRenameDialog = false
    @State private var renameText = ""
    
    let onProjectSelected: (SketchProject) -> Void
    let onNewProject: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search
                headerSection
                
                // Projects grid
                if sketchManager.hasProjects {
                    projectsGrid
                } else {
                    emptyState
                }
            }
            .navigationTitle("Sketch Manager")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewProjectDialog = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewProjectDialog) {
            newProjectDialog
        }
        .sheet(isPresented: $showingRenameDialog) {
            renameProjectDialog
        }
        .alert("Delete Project", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let project = selectedProject {
                    sketchManager.deleteProject(project)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(selectedProject?.name ?? "")'? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search projects...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Quick stats
            if sketchManager.hasProjects {
                HStack {
                    Text("\(sketchManager.projects.count) project\(sketchManager.projects.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let currentProject = sketchManager.currentProject {
                        Text("Current: \(currentProject.name)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Projects Grid
    
    private var projectsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 20) {
                ForEach(filteredProjects, id: \.id) { project in
                    ProjectCard(
                        project: project,
                        isCurrent: sketchManager.currentProject?.id == project.id,
                        onTap: { onProjectSelected(project) },
                        onRename: { 
                            selectedProject = project
                            renameText = project.name
                            showingRenameDialog = true
                        },
                        onDuplicate: { 
                            let duplicated = sketchManager.duplicateProject(project)
                            onProjectSelected(duplicated)
                        },
                        onDelete: {
                            selectedProject = project
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("No Sketches Yet")
                    .font(.title2.weight(.bold))
                
                Text("Create your first sketch to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingNewProjectDialog = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create New Sketch")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - New Project Dialog
    
    private var newProjectDialog: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Name")
                        .font(.headline)
                    
                    TextField("Enter project name", text: $newProjectName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onAppear {
                            newProjectName = "Untitled Sketch"
                        }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Sketch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        showingNewProjectDialog = false
                        newProjectName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onNewProject(newProjectName.isEmpty ? "Untitled Sketch" : newProjectName)
                        showingNewProjectDialog = false
                        newProjectName = ""
                        dismiss()
                    }
                    .disabled(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(300)])
    }
    
    // MARK: - Rename Project Dialog
    
    private var renameProjectDialog: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Name")
                        .font(.headline)
                    
                    TextField("Enter new name", text: $renameText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Rename Sketch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        showingRenameDialog = false
                        renameText = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Rename") {
                        if let project = selectedProject {
                            sketchManager.renameProject(project, to: renameText)
                        }
                        showingRenameDialog = false
                        renameText = ""
                    }
                    .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(300)])
    }
    
    // MARK: - Computed Properties
    
    private var filteredProjects: [SketchProject] {
        if searchText.isEmpty {
            return sketchManager.sortedProjects
        } else {
            return sketchManager.sortedProjects.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Project Card

struct ProjectCard: View {
    let project: SketchProject
    let isCurrent: Bool
    let onTap: () -> Void
    let onRename: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    @State private var showingContextMenu = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail
                thumbnailView
                
                // Project info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.name)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if isCurrent {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(project.relativeModifiedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(project.components.count) component\(project.components.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(project.canvasSize.width))×\(Int(project.canvasSize.height))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(.regularMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrent ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contextMenu {
            contextMenuItems
        }
    }
    
    // MARK: - Thumbnail View
    
    private var thumbnailView: some View {
        Group {
            if let thumbnailData = project.thumbnailData,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder thumbnail
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    VStack {
                        Image(systemName: "scribble.variable")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("No Preview")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .frame(height: 120)
        .clipped()
        .cornerRadius(12, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Context Menu
    
    private var contextMenuItems: some View {
        Group {
            Button(action: onTap) {
                Label("Open", systemImage: "folder.badge.gearshape")
            }
            
            Divider()
            
            Button(action: onRename) {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(action: onDuplicate) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#if DEBUG
struct SketchManagerView_Previews: PreviewProvider {
    static var previews: some View {
        SketchManagerView(
            onProjectSelected: { _ in },
            onNewProject: { _ in }
        )
    }
}
#endif 