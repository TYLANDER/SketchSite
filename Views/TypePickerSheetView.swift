import SwiftUI

struct TypePickerSheetView: View {
    @Binding var isPresented: Bool
    @Binding var typePickerSelection: UIComponentType?
    let detectedComponents: [DetectedComponent]
    let selectedComponentID: UUID?
    let onTypeSelected: (UIComponentType) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(UIComponentType.allCases, id: \.self) { type in
                    HStack {
                        Text(type.rawValue.capitalized)
                        Spacer()
                        if type == typePickerSelection {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTypeSelected(type)
                        isPresented = false
                    }
                    .accessibilityLabel(type.rawValue.capitalized)
                    .accessibilityAddTraits(type == typePickerSelection ? .isSelected : [])
                }
            }
            .navigationTitle("Select Component Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
} 