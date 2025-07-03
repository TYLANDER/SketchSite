import SwiftUI

/// Modern chat interface for iterative conversations with AI about generated code
struct FollowUpChatView: View {
    @ObservedObject var conversationManager: ConversationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCodePreview = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages area
                messagesScrollView
                
                // Input area
                inputArea
            }
            .navigationTitle("Refine with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showCodePreview = true }) {
                        Image(systemName: "code")
                    }
                    .disabled(conversationManager.generatedCode.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showCodePreview) {
            CodePreviewView(code: conversationManager.generatedCode)
        }
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Welcome message if no conversation yet
                    if conversationManager.messages.isEmpty {
                        welcomeMessage
                    }
                    
                    // Conversation messages
                    ForEach(conversationManager.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
                .padding(.bottom, 8)
            }
            .onChange(of: conversationManager.messages.count) {
                if let lastMessage = conversationManager.messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Text input field
                TextField("Ask me to refine the code...", text: $conversationManager.currentInput, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .cornerRadius(24)
                    .lineLimit(1...4)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: conversationManager.state.isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(conversationManager.canSendMessage ? .blue : .secondary)
                }
                .disabled(!conversationManager.canSendMessage && !conversationManager.state.isLoading)
            }
            .padding(.horizontal)
            
            // Status indicator
            if conversationManager.state.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("AI is thinking...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 12)
        .background(.thinMaterial)
    }
    
    // MARK: - Welcome Message
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.and.wand.2")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Refine Your Code")
                .font(.title2.weight(.bold))
            
            Text("Ask me to improve your generated code! Try requests like:")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Add animations and transitions")
                Text("• Improve the visual design")
                Text("• Add form validation")
                Text("• Make it responsive")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text("Or type your own request below!")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 8)
        }
        .padding(24)
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        if conversationManager.state.isLoading {
            // TODO: Implement cancellation if needed
            return
        }
        
        conversationManager.sendMessage(conversationManager.currentInput)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ConversationMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 48)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Message content
                Group {
                    if message.isLoading {
                        LoadingBubble()
                    } else {
                        MessageContent(message: message)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if message.role == .user {
                            Color.blue
                        } else {
                            Color(.systemGray5)
                        }
                    }
                )
                .foregroundColor(message.role == .user ? .white : .primary)
                .cornerRadius(20)
                
                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if message.role != .user {
                Spacer(minLength: 48)
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Message Content

struct MessageContent: View {
    let message: ConversationMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if message.role != .user {
                Label(message.role.displayName, systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(message.role.color)
            }
            
            Text(message.content)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Loading Bubble

struct LoadingBubble: View {
    @State private var animatePhase = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatePhase == index ? 1.2 : 0.8)
                    .opacity(animatePhase == index ? 1.0 : 0.6)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                animatePhase = 0
            }
            
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.6)) {
                    animatePhase = (animatePhase + 1) % 3
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FollowUpChatView_Previews: PreviewProvider {
    static var previews: some View {
        FollowUpChatView(conversationManager: ConversationManager())
    }
}
#endif 