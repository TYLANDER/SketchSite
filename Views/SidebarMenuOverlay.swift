import SwiftUI

/// Sidebar overlay that slides in from the left like a hamburger menu
struct SidebarMenuOverlay: View {
    @Binding var isPresented: Bool
    let content: AnyView
    
    private let sidebarWidthRatio: CGFloat = 0.75 // 75% of screen width
    private let animationDuration: Double = 0.3
    
    init<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = AnyView(content())
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                // Overlay background that can be tapped to dismiss
                Color.black
                    .opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: animationDuration)) {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
                
                // Sidebar content
                HStack(spacing: 0) {
                    GeometryReader { geometry in
                        content
                            .frame(width: geometry.size.width * sidebarWidthRatio)
                            .frame(maxHeight: .infinity)
                            .clipped()
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * sidebarWidthRatio)
                    
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: animationDuration), value: isPresented)
    }
}

// MARK: - View Extension for Sidebar

extension View {
    func sidebarOverlay<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.overlay {
            SidebarMenuOverlay(isPresented: isPresented, content: content)
        }
    }
} 