import Foundation
import SwiftUI
import PencilKit

// MARK: - Sketch Project

/// Represents a saved sketch project with metadata
public struct SketchProject: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var createdDate: Date
    public var modifiedDate: Date
    public var thumbnailData: Data?
    public var canvasSize: CGSize
    public var components: [DetectedComponent]
    public var drawingData: Data? // PKDrawing encoded data
    public var tags: [String]
    
    public init(name: String, canvasSize: CGSize, components: [DetectedComponent] = [], drawing: PKDrawing? = nil) {
        self.id = UUID()
        self.name = name
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.canvasSize = canvasSize
        self.components = components
        self.tags = []
        
        // Encode drawing data
        if let drawing = drawing {
            self.drawingData = try? drawing.dataRepresentation()
        } else {
            self.drawingData = nil
        }
    }
    
    /// Gets the PKDrawing from stored data
    public var drawing: PKDrawing? {
        guard let data = drawingData else { return nil }
        return try? PKDrawing(data: data)
    }
    
    /// Updates the drawing data
    mutating func updateDrawing(_ drawing: PKDrawing) {
        self.drawingData = try? drawing.dataRepresentation()
        self.modifiedDate = Date()
    }
    
    /// Updates components and modified date
    mutating func updateComponents(_ components: [DetectedComponent]) {
        self.components = components
        self.modifiedDate = Date()
    }
    
    /// Updates thumbnail data
    mutating func updateThumbnail(_ thumbnailData: Data) {
        self.thumbnailData = thumbnailData
        self.modifiedDate = Date()
    }
    
    /// Formatted creation date
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }
    
    /// Formatted modified date
    var formattedModifiedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modifiedDate)
    }
    
    /// Relative modified date (e.g., "2 hours ago")
    var relativeModifiedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: modifiedDate, relativeTo: Date())
    }
}

// MARK: - Sketch Manager

/// Centralized manager for sketch projects with persistence
public class SketchManager: ObservableObject {
    @Published public var projects: [SketchProject] = []
    @Published public var currentProject: SketchProject?
    @Published public var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let projectsKey = "SketchSite_SavedProjects"
    private let currentProjectKey = "SketchSite_CurrentProject"
    
    public static let shared = SketchManager()
    
    private init() {
        loadProjects()
        loadCurrentProject()
    }
    
    // MARK: - Project Management
    
    /// Creates a new sketch project
    public func createNewProject(name: String, canvasSize: CGSize) -> SketchProject {
        let project = SketchProject(name: name, canvasSize: canvasSize)
        projects.append(project)
        currentProject = project
        saveProjects()
        saveCurrentProject()
        
        print("📁 SketchManager: Created new project '\(name)'")
        return project
    }
    
    /// Saves the current working state to the current project
    public func saveCurrentState(components: [DetectedComponent], drawing: PKDrawing?, canvasSize: CGSize) {
        guard let project = currentProject else {
            // Create a new project if none exists
            let newProject = createNewProject(name: "Untitled Sketch", canvasSize: canvasSize)
            saveProjectState(project: newProject, components: components, drawing: drawing)
            return
        }
        
        saveProjectState(project: project, components: components, drawing: drawing)
    }
    
    /// Saves state to a specific project
    private func saveProjectState(project: SketchProject, components: [DetectedComponent], drawing: PKDrawing?) {
        var updatedProject = project
        updatedProject.updateComponents(components)
        
        if let drawing = drawing {
            updatedProject.updateDrawing(drawing)
        }
        
        // Update project in array
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = updatedProject
        }
        
        currentProject = updatedProject
        saveProjects()
        saveCurrentProject()
        
        print("💾 SketchManager: Saved state for project '\(project.name)'")
    }
    
    /// Loads a project and sets it as current
    public func loadProject(_ project: SketchProject) {
        currentProject = project
        saveCurrentProject()
        print("📂 SketchManager: Loaded project '\(project.name)'")
    }
    
    /// Duplicates a project
    func duplicateProject(_ project: SketchProject) -> SketchProject {
        let duplicated = SketchProject(
            name: "\(project.name) Copy",
            canvasSize: project.canvasSize,
            components: project.components,
            drawing: project.drawing
        )
        
        projects.append(duplicated)
        saveProjects()
        
        print("📋 SketchManager: Duplicated project '\(project.name)'")
        return duplicated
    }
    
    /// Renames a project
    func renameProject(_ project: SketchProject, to newName: String) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        
        projects[index].name = newName
        projects[index].modifiedDate = Date()
        
        if currentProject?.id == project.id {
            currentProject?.name = newName
            currentProject?.modifiedDate = Date()
            saveCurrentProject()
        }
        
        saveProjects()
        print("✏️ SketchManager: Renamed project to '\(newName)'")
    }
    
    /// Deletes a project
    func deleteProject(_ project: SketchProject) {
        projects.removeAll { $0.id == project.id }
        
        if currentProject?.id == project.id {
            currentProject = projects.first
            saveCurrentProject()
        }
        
        saveProjects()
        print("🗑️ SketchManager: Deleted project '\(project.name)'")
    }
    
    /// Generates and saves a thumbnail for a project
    public func generateThumbnail(for project: SketchProject, from image: UIImage) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        
        // Resize image to thumbnail size
        let thumbnailSize = CGSize(width: 200, height: 150)
        let thumbnail = image.resized(to: thumbnailSize)
        
        if let thumbnailData = thumbnail?.pngData() {
            projects[index].updateThumbnail(thumbnailData)
            
            if currentProject?.id == project.id {
                currentProject?.updateThumbnail(thumbnailData)
                saveCurrentProject()
            }
            
            saveProjects()
            print("🖼️ SketchManager: Generated thumbnail for '\(project.name)'")
        }
    }
    
    // MARK: - Persistence
    
    private func saveProjects() {
        do {
            let data = try JSONEncoder().encode(projects)
            userDefaults.set(data, forKey: projectsKey)
            print("💾 SketchManager: Saved \(projects.count) projects to UserDefaults")
        } catch {
            print("❌ SketchManager: Failed to save projects: \(error)")
        }
    }
    
    private func loadProjects() {
        guard let data = userDefaults.data(forKey: projectsKey) else {
            print("📁 SketchManager: No saved projects found")
            return
        }
        
        do {
            projects = try JSONDecoder().decode([SketchProject].self, from: data)
            print("📂 SketchManager: Loaded \(projects.count) projects from UserDefaults")
        } catch {
            print("❌ SketchManager: Failed to load projects: \(error)")
            projects = []
        }
    }
    
    private func saveCurrentProject() {
        do {
            if let currentProject = currentProject {
                let data = try JSONEncoder().encode(currentProject)
                userDefaults.set(data, forKey: currentProjectKey)
                print("💾 SketchManager: Saved current project '\(currentProject.name)'")
            } else {
                userDefaults.removeObject(forKey: currentProjectKey)
                print("💾 SketchManager: Cleared current project")
            }
        } catch {
            print("❌ SketchManager: Failed to save current project: \(error)")
        }
    }
    
    private func loadCurrentProject() {
        guard let data = userDefaults.data(forKey: currentProjectKey) else {
            print("📁 SketchManager: No current project found")
            return
        }
        
        do {
            currentProject = try JSONDecoder().decode(SketchProject.self, from: data)
            print("📂 SketchManager: Loaded current project '\(currentProject?.name ?? "Unknown")'")
        } catch {
            print("❌ SketchManager: Failed to load current project: \(error)")
            currentProject = nil
        }
    }
    
    // MARK: - Computed Properties
    
    public var hasProjects: Bool {
        !projects.isEmpty
    }
    
    public var recentProjects: [SketchProject] {
        projects.sorted { $0.modifiedDate > $1.modifiedDate }.prefix(5).map { $0 }
    }
    
    /// Gets projects sorted by modification date (most recent first)
    public var sortedProjects: [SketchProject] {
        projects.sorted { $0.modifiedDate > $1.modifiedDate }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
} 