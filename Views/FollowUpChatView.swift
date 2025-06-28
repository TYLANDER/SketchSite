import SwiftUI

struct FollowUpChatView: View {
    @Binding var chatHistory: [(role: String, content: String)]
    @Binding var followUpInput: String
    let onSend: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Follow-up with AI").font(.headline)
            ScrollView {
                ForEach(Array(chatHistory.enumerated()), id: \.0) { idx, msg in
                    HStack(alignment: .top) {
                        Text(msg.role.capitalized + ":").bold().foregroundColor(msg.role == "user" ? .blue : .primary)
                        Text(msg.content).foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }.frame(maxHeight: 120)
            HStack {
                TextField("Ask a follow-up or clarify...", text: $followUpInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    let userMsg = followUpInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !userMsg.isEmpty else { return }
                    onSend(userMsg)
                }
            }
        }
        .padding()
    }
} 