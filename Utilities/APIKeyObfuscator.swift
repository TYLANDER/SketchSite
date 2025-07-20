import Foundation

/// Utility for obfuscating API keys for production builds
/// This provides basic protection against casual key extraction
class APIKeyObfuscator {
    
    /// Obfuscates a plaintext API key using XOR encryption
    /// - Parameter plaintext: The original API key
    /// - Returns: Array of obfuscated bytes
    static func obfuscateKey(_ plaintext: String) -> [UInt8] {
        let key: UInt8 = 0x42 // XOR key
        return plaintext.utf8.map { $0 ^ key }
    }
    
    /// Deobfuscates an obfuscated API key
    /// - Parameter obfuscated: Array of obfuscated bytes
    /// - Returns: Original plaintext API key
    static func deobfuscateKey(_ obfuscated: [UInt8]) -> String {
        let key: UInt8 = 0x42 // Same XOR key
        let deobfuscated = obfuscated.map { $0 ^ key }
        return String(bytes: deobfuscated, encoding: .utf8) ?? ""
    }
    
    /// Generates Swift code for embedding obfuscated keys
    /// - Parameters:
    ///   - openAIKey: Your OpenAI API key
    ///   - anthropicKey: Your Anthropic API key
    /// - Returns: Swift code to paste into ProductionAPIKeys
    static func generateObfuscatedCode(openAIKey: String, anthropicKey: String) -> String {
        let openAIObfuscated = obfuscateKey(openAIKey)
        let anthropicObfuscated = obfuscateKey(anthropicKey)
        
        return """
        // Replace the empty arrays in ProductionAPIKeys with these:
        
        private let openAIKeyObfuscated: [UInt8] = \(openAIObfuscated)
        
        private let anthropicKeyObfuscated: [UInt8] = \(anthropicObfuscated)
        """
    }
    
    /// Test function to verify obfuscation works correctly
    static func testObfuscation() {
        let testKey = "sk-test123"
        let obfuscated = obfuscateKey(testKey)
        let deobfuscated = deobfuscateKey(obfuscated)
        
        print("🔐 API Key Obfuscation Test:")
        print("Original: \(testKey)")
        print("Obfuscated: \(obfuscated)")
        print("Deobfuscated: \(deobfuscated)")
        print("Success: \(testKey == deobfuscated)")
    }
}

// MARK: - Usage Instructions

/*
 
 HOW TO USE THIS FOR PRODUCTION:
 
 1. Get your API keys:
    - OpenAI: https://platform.openai.com/api-keys
    - Anthropic: https://console.anthropic.com/account/keys
 
 2. Run this code in a playground or debug build:
    let code = APIKeyObfuscator.generateObfuscatedCode(
        openAIKey: "your-openai-key-here",
        anthropicKey: "your-anthropic-key-here"
    )
    print(code)
 
 3. Copy the output and replace the empty arrays in ProductionAPIKeys.swift
 
 4. Build for production - your keys will be embedded but obfuscated
 
 SECURITY NOTE:
 - This is basic obfuscation, not encryption
 - Determined attackers can still extract keys
 - Consider implementing a backend service for sensitive production apps
 - Monitor your API usage and set up billing alerts
 
 */ 