import SwiftUI

struct InspectorView: View {
    @Binding var component: DetectedComponent
    @State private var label: String = ""
    @State private var width: CGFloat = 0
    @State private var height: CGFloat = 0
    @State private var type: UIComponentType = .label
    @State private var usePercentages: Bool = false
    
    // Canvas size for percentage calculations (passed from parent)
    var canvasSize: CGSize = UIScreen.main.bounds.size

    var body: some View {
        Form {
            Section(header: Text("Component Type")) {
                Picker("Type", selection: $type) {
                    ForEach(UIComponentType.allCases, id: \.self) { t in
                        Text(t.rawValue.capitalized).tag(t)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: type) { oldValue, newValue in
                    component.type = .ui(newValue)
                }
            }
            
            Section(header: Text("Label")) {
                TextField("Component Label", text: $label, prompt: Text("Optional label"))
                    .onChange(of: label) { oldValue, newValue in
                        component.label = newValue.isEmpty ? nil : newValue
                    }
            }
            
            Section(header: sizeHeaderView) {
                // Size unit toggle
                Picker("Size Unit", selection: $usePercentages) {
                    Text("Pixels").tag(false)
                    Text("Percentages").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 8)
                
                // Width input
                HStack {
                    Text("Width")
                        .foregroundColor(.primary)
                    Spacer()
                    TextField("Width", value: $width, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    Text(usePercentages ? "%" : "px")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .frame(width: 20)
                }
                
                // Height input
                HStack {
                    Text("Height")
                        .foregroundColor(.primary)
                    Spacer()
                    TextField("Height", value: $height, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    Text(usePercentages ? "%" : "px")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .frame(width: 20)
                }
                
                // Apply button
                Button(action: applySizeChanges) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Apply Size Changes")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(width <= 0 || height <= 0)
            }
            
            Section(header: Text("Position")) {
                HStack {
                    Text("X Position")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(component.rect.minX)) px")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Y Position")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(component.rect.minY)) px")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Section(header: Text("Responsive Info")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Width:")
                        Spacer()
                        Text("\(Int(component.rect.width))px (\(String(format: "%.1f", (component.rect.width / canvasSize.width) * 100))%)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Height:")
                        Spacer()
                        Text("\(Int(component.rect.height))px (\(String(format: "%.1f", (component.rect.height / canvasSize.height) * 100))%)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("💡 Use percentages for responsive design that adapts to different screen sizes.")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
        }
        .onAppear {
            updateFromComponent()
        }
        .onChange(of: usePercentages) { oldValue, newValue in
            convertSizeUnits(toPercentages: newValue)
        }
    }
    
    private var sizeHeaderView: some View {
        HStack {
            Text("Size")
            Spacer()
            Image(systemName: usePercentages ? "percent" : "ruler")
                .foregroundColor(.blue)
                .font(.caption)
        }
    }
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = usePercentages ? 1 : 0
        return formatter
    }
    
    private func updateFromComponent() {
        label = component.label ?? ""
        if case let .ui(t) = component.type { 
            type = t 
        } else {
            type = UIComponentType.allCases.first ?? .label
        }
        
        // Initialize with pixel values
        width = component.rect.width
        height = component.rect.height
        usePercentages = false
    }
    
    private func convertSizeUnits(toPercentages: Bool) {
        if toPercentages {
            // Convert pixels to percentages
            width = (component.rect.width / canvasSize.width) * 100
            height = (component.rect.height / canvasSize.height) * 100
        } else {
            // Convert percentages to pixels
            width = component.rect.width
            height = component.rect.height
        }
    }
    
    private func applySizeChanges() {
        let newWidth: CGFloat
        let newHeight: CGFloat
        
        if usePercentages {
            // Convert percentages to pixels
            newWidth = (width / 100) * canvasSize.width
            newHeight = (height / 100) * canvasSize.height
        } else {
            // Use pixel values directly
            newWidth = width
            newHeight = height
        }
        
        // Ensure minimum size
        let minSize: CGFloat = 20
        let clampedWidth = max(minSize, newWidth)
        let clampedHeight = max(minSize, newHeight)
        
        // Update component rect while maintaining position
        component.rect = CGRect(
            x: component.rect.origin.x,
            y: component.rect.origin.y,
            width: clampedWidth,
            height: clampedHeight
        )
        
        // Update the displayed values to reflect any clamping
        if usePercentages {
            width = (clampedWidth / canvasSize.width) * 100
            height = (clampedHeight / canvasSize.height) * 100
        } else {
            width = clampedWidth
            height = clampedHeight
        }
        
        print("📐 Applied size changes: \(Int(clampedWidth))×\(Int(clampedHeight)) px")
        
        // Haptic feedback for successful change
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
} 