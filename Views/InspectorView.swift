import SwiftUI

struct InspectorView: View {
    @Binding var component: DetectedComponent
    @State private var label: String = ""
    @State private var width: CGFloat = 0
    @State private var height: CGFloat = 0
    @State private var type: UIComponentType = .label

    var body: some View {
        Form {
            Section(header: Text("Type")) {
                Picker("Component Type", selection: $type) {
                    ForEach(UIComponentType.allCases, id: \.self) { t in
                        Text(t.rawValue.capitalized).tag(t)
                    }
                }
                .onChange(of: type) { oldValue, newValue in
                    component.type = .ui(newValue)
                }
            }
            Section(header: Text("Label")) {
                TextField("Label", text: $label)
                    .onChange(of: label) { oldValue, newValue in
                        component.label = newValue
                    }
            }
            Section(header: Text("Size")) {
                HStack {
                    Text("Width")
                    Spacer()
                    TextField("Width", value: $width, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                }
                HStack {
                    Text("Height")
                    Spacer()
                    TextField("Height", value: $height, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                }
                Button("Apply Size") {
                    component.rect = CGRect(x: component.rect.origin.x, y: component.rect.origin.y, width: width, height: height)
                }
            }
        }
        .onAppear {
            label = component.label ?? ""
            width = component.rect.width
            height = component.rect.height
            if case let .ui(t) = component.type { type = t }
            if !UIComponentType.allCases.contains(type) {
                type = UIComponentType.allCases.first ?? .label
            }
        }
    }
} 