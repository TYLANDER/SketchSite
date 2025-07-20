import SwiftUI

/// Sidebar overlay that slides in from the left like a hamburger menu
/// Follows Apple HIG and WCAG guidelines for responsive sidebar widths
struct SidebarMenuOverlay: View {
    @Binding var isPresented: Bool
    let content: AnyView
    
    private let animationDuration: Double = 0.3
    
    init<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = AnyView(content())
    }
    
    var body: some View {
        GeometryReader { geometry in
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
                        content
                            .frame(width: calculateSidebarWidth(screenSize: geometry.size))
                            .frame(maxHeight: .infinity)
                            .clipped()
                        
                        Spacer()
                    }
                    .transition(.move(edge: .leading))
                }
            }
        }
        .animation(.easeInOut(duration: animationDuration), value: isPresented)
    }
    
    /// Calculate appropriate sidebar width based on device type and Apple HIG/WCAG guidelines
    private func calculateSidebarWidth(screenSize: CGSize) -> CGFloat {
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        // Determine if device is iPad-like (larger screen or landscape tablet)
        let isTablet = screenWidth >= 768 || (screenWidth > 600 && screenWidth > screenHeight)
        
        if isTablet {
            // iPad/Tablet: Use fixed width according to Apple HIG
            // Standard sidebar width: 320pt (compact) to 375pt (regular)
            // Ensure it doesn't exceed 50% of screen width for usability
            let standardSidebarWidth: CGFloat = 350
            let maxTabletWidth = screenWidth * 0.5 // Maximum 50% on tablets
            return min(standardSidebarWidth, maxTabletWidth)
        } else {
            // iPhone/Mobile: Use percentage-based width
            // Apple HIG recommends 75-85% for mobile sidebars
            let mobileWidthRatio: CGFloat = 0.8 // 80% for better mobile UX
            let maxMobileWidth = screenWidth - 60 // Always leave at least 60pt visible
            return min(screenWidth * mobileWidthRatio, maxMobileWidth)
        }
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