import SwiftUI

/// Demo view to showcase component library functionality
struct ComponentLibraryDemoView: View {
    @State private var showLibrary = false
    @State private var addedComponents: [DetectedComponent] = []
    @State private var canvasSize = CGSize(width: 375, height: 812)
    
    var body: some View {
        NavigationView {
            VStack {
                // Demo canvas area
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .border(Color.gray, width: 1)
                        .frame(width: canvasSize.width * 0.8, height: canvasSize.height * 0.6)
                    
                    // Show added components
                    ForEach(Array(addedComponents.enumerated()), id: \.element.id) { index, component in
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 2)
                            .background(Color.blue.opacity(0.2))
                            .frame(width: component.rect.width * 0.8, height: component.rect.height * 0.8)
                            .position(
                                x: component.rect.midX * 0.8,
                                y: component.rect.midY * 0.6
                            )
                            .overlay(
                                Text(component.label ?? component.type.description)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(4)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(4)
                                    .position(
                                        x: component.rect.midX * 0.8,
                                        y: component.rect.minY * 0.6 - 15
                                    )
                            )
                    }
                    
                    if addedComponents.isEmpty {
                        Text("Tap 'Add Component' to add items from the library")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Stats
                VStack(spacing: 8) {
                    Text("Components Added: \(addedComponents.count)")
                        .font(.headline)
                    
                    if !addedComponents.isEmpty {
                        Text("Types: \(uniqueComponentTypes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                // Controls
                HStack(spacing: 20) {
                    Button("Add Component") {
                        showLibrary = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Clear All") {
                        addedComponents.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(addedComponents.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Component Library Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showLibrary) {
            ComponentLibraryView { template in
                addComponentFromTemplate(template)
            }
        }
    }
    
    private var uniqueComponentTypes: String {
        let types = Set(addedComponents.map { $0.type.description })
        return types.sorted().joined(separator: ", ")
    }
    
    private func addComponentFromTemplate(_ template: ComponentTemplate) {
        let position = CGPoint(
            x: canvasSize.width * 0.4 + CGFloat.random(in: -50...50),
            y: canvasSize.height * 0.3 + CGFloat.random(in: -50...50)
        )
        
        let component = ComponentLibrary.shared.createComponent(
            from: template,
            at: position,
            canvasSize: canvasSize
        )
        
        addedComponents.append(component)
        print("📚 Demo: Added \(template.name) component")
    }
}

#if DEBUG
struct ComponentLibraryDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ComponentLibraryDemoView()
    }
}
#endif 