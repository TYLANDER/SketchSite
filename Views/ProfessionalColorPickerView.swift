import SwiftUI
import UIKit

/// Professional color picker similar to Figma's interface
struct ProfessionalColorPickerView: View {
    @Binding var property: ColorProperty
    @Environment(\.dismiss) private var dismiss
    @State private var selectedColor: Color = .blue
    @State private var hue: Double = 0
    @State private var saturation: Double = 1
    @State private var brightness: Double = 1
    @State private var alpha: Double = 1
    @State private var hexValue: String = "#0000FF"
    @State private var showingAdvanced = false
    
    // Color wheel dimensions
    private let wheelSize: CGFloat = 200
    private let wheelRadius: CGFloat = 100
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Color Preview
                    colorPreviewSection
                    
                    // Color Wheel
                    colorWheelSection
                    
                    // Saturation/Brightness Picker
                    saturationBrightnessSection
                    
                    // Preset Color Swatches
                    presetSwatchesSection
                    
                    // Advanced Controls
                    advancedControlsSection
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Color Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applyColor()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            initializeColor()
        }
    }
    
    // MARK: - Color Preview Section
    
    private var colorPreviewSection: some View {
        VStack(spacing: 12) {
            Text("Selected Color")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                // Large color preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedColor)
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hexValue.uppercased())
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.medium)
                    
                    Text("HSB: \(Int(hue))°, \(Int(saturation * 100))%, \(Int(brightness * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Color Wheel Section
    
    private var colorWheelSection: some View {
        VStack(spacing: 12) {
            Text("Hue")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                // Color wheel background
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: hueSpectrum()),
                            center: .center
                        )
                    )
                    .frame(width: wheelSize, height: wheelSize)
                    .overlay(
                        Circle()
                            .stroke(Color.secondary, lineWidth: 2)
                    )
                
                // Hue selector
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .position(hueSelectorPosition())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                updateHueFromPosition(value.location)
                            }
                    )
            }
            
            // Hue slider
            HStack {
                Text("0°")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: $hue, in: 0...360, step: 1)
                    .onChange(of: hue) { _ in
                        updateSelectedColor()
                    }
                
                Text("360°")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Saturation/Brightness Section
    
    private var saturationBrightnessSection: some View {
        VStack(spacing: 12) {
            Text("Saturation & Brightness")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                // Saturation/Brightness picker
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color(hue: hue/360, saturation: 1, brightness: 1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary, lineWidth: 1)
                        )
                    
                    // Saturation/Brightness selector
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .position(saturationBrightnessSelectorPosition())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    updateSaturationBrightnessFromPosition(value.location)
                                }
                        )
                }
                
                // Individual sliders
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Saturation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $saturation, in: 0...1, step: 0.01)
                            .onChange(of: saturation) { _ in
                                updateSelectedColor()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Brightness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $brightness, in: 0...1, step: 0.01)
                            .onChange(of: brightness) { _ in
                                updateSelectedColor()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Opacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $alpha, in: 0...1, step: 0.01)
                            .onChange(of: alpha) { _ in
                                updateSelectedColor()
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Preset Swatches Section
    
    private var presetSwatchesSection: some View {
        VStack(spacing: 12) {
            Text("Preset Colors")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                ForEach(presetColors, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                        updateColorComponents()
                    }) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color)
                            .frame(height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Advanced Controls Section
    
    private var advancedControlsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showingAdvanced.toggle() }) {
                HStack {
                    Text("Advanced")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showingAdvanced ? "chevron.up" : "chevron.down")
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if showingAdvanced {
                VStack(spacing: 16) {
                    // Hex input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hex Value")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Hex", text: $hexValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: hexValue) { newValue in
                                if let color = Color(hex: newValue) {
                                    selectedColor = color
                                    updateColorComponents()
                                }
                            }
                    }
                    
                    // RGB sliders
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RGB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        let rgb = selectedColor.rgbComponents
                        
                        HStack {
                            Text("R")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(width: 20)
                            
                            Slider(value: .constant(rgb.red), in: 0...1, step: 0.01)
                                .disabled(true)
                            
                            Text("\(Int(rgb.red * 255))")
                                .font(.caption)
                                .frame(width: 30)
                        }
                        
                        HStack {
                            Text("G")
                                .font(.caption)
                                .foregroundColor(.green)
                                .frame(width: 20)
                            
                            Slider(value: .constant(rgb.green), in: 0...1, step: 0.01)
                                .disabled(true)
                            
                            Text("\(Int(rgb.green * 255))")
                                .font(.caption)
                                .frame(width: 30)
                        }
                        
                        HStack {
                            Text("B")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Slider(value: .constant(rgb.blue), in: 0...1, step: 0.01)
                                .disabled(true)
                            
                            Text("\(Int(rgb.blue * 255))")
                                .font(.caption)
                                .frame(width: 30)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func hueSpectrum() -> [Color] {
        return stride(from: 0, through: 360, by: 1).map { hue in
            Color(hue: hue/360, saturation: 1, brightness: 1)
        }
    }
    
    private func hueSelectorPosition() -> CGPoint {
        let angle = hue * .pi / 180
        let x = wheelRadius + cos(angle) * (wheelRadius - 20)
        let y = wheelRadius + sin(angle) * (wheelRadius - 20)
        return CGPoint(x: x, y: y)
    }
    
    private func saturationBrightnessSelectorPosition() -> CGPoint {
        let x = saturation * 120
        let y = (1 - brightness) * 120
        return CGPoint(x: x, y: y)
    }
    
    private func updateHueFromPosition(_ position: CGPoint) {
        let center = CGPoint(x: wheelRadius, y: wheelRadius)
        let deltaX = position.x - center.x
        let deltaY = position.y - center.y
        let angle = atan2(deltaY, deltaX) * 180 / .pi
        hue = angle < 0 ? angle + 360 : angle
        updateSelectedColor()
    }
    
    private func updateSaturationBrightnessFromPosition(_ position: CGPoint) {
        saturation = max(0, min(1, position.x / 120))
        brightness = max(0, min(1, 1 - position.y / 120))
        updateSelectedColor()
    }
    
    private func updateSelectedColor() {
        selectedColor = Color(hue: hue/360, saturation: saturation, brightness: brightness, opacity: alpha)
        hexValue = selectedColor.toHex()
    }
    
    private func updateColorComponents() {
        let hsb = selectedColor.hsbComponents
        hue = hsb.hue * 360
        saturation = hsb.saturation
        brightness = hsb.brightness
        alpha = hsb.alpha
        hexValue = selectedColor.toHex()
    }
    
    private func initializeColor() {
        if let color = Color(hex: property.currentColor) {
            selectedColor = color
            updateColorComponents()
        }
    }
    
    private func applyColor() {
        let hexColor = selectedColor.toHex()
        switch property.currentMode {
        case .light, .auto:
            property.colorScheme["light"] = hexColor
        case .dark:
            property.colorScheme["dark"] = hexColor
        }
    }
    
    // MARK: - Preset Colors
    
    private var presetColors: [Color] {
        [
            .red, .orange, .yellow, .green, .blue, .purple, .pink,
            .brown, .gray, .black, .white,
            Color(red: 0.8, green: 0.2, blue: 0.2), // Dark red
            Color(red: 0.2, green: 0.8, blue: 0.2), // Dark green
            Color(red: 0.2, green: 0.2, blue: 0.8), // Dark blue
            Color(red: 0.8, green: 0.8, blue: 0.2), // Olive
            Color(red: 0.8, green: 0.2, blue: 0.8), // Magenta
            Color(red: 0.2, green: 0.8, blue: 0.8), // Cyan
            Color(red: 0.9, green: 0.6, blue: 0.2), // Orange
            Color(red: 0.6, green: 0.4, blue: 0.2), // Brown
            Color(red: 0.5, green: 0.5, blue: 0.5), // Gray
            Color(red: 0.9, green: 0.9, blue: 0.9), // Light gray
        ]
    }
}

// MARK: - Color Extensions

extension Color {
    var rgbComponents: (red: Double, green: Double, blue: Double) {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return (0, 0, 0)
        }
        return (Double(components[0]), Double(components[1]), Double(components[2]))
    }
    
    var hsbComponents: (hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        let uic = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uic.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return (Double(hue), Double(saturation), Double(brightness), Double(alpha))
    }
} 