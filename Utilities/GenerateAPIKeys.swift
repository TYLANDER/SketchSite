import Foundation

/**
 * PRODUCTION API KEY GENERATOR
 * 
 * This file helps you safely generate obfuscated API keys for production builds.
 * Run this once to get your obfuscated keys, then delete this file for security.
 *
 * INSTRUCTIONS:
 * 1. Replace the placeholder keys below with your actual API keys
 * 2. Build and run this in Debug mode to see the obfuscated output
 * 3. Copy the output and paste into ChatGPTService.swift
 * 4. Delete this file or move it outside your project
 */

class GenerateAPIKeys {
    
    // STEP 1: Replace these with your actual API keys
    private static let YOUR_OPENAI_KEY = "sk-your-openai-key-here"
    private static let YOUR_ANTHROPIC_KEY = "sk-ant-your-anthropic-key-here"
    
    /// Call this function to generate your obfuscated keys
    static func generateProductionKeys() {
        print("\n🔑 GENERATING PRODUCTION API KEYS")
        print("=" * 50)
        
        // Validate keys look correct
        guard YOUR_OPENAI_KEY.hasPrefix("sk-") && YOUR_OPENAI_KEY.count > 20 else {
            print("❌ OpenAI key looks invalid. Make sure it starts with 'sk-' and is the full key.")
            return
        }
        
        guard YOUR_ANTHROPIC_KEY.hasPrefix("sk-ant-") && YOUR_ANTHROPIC_KEY.count > 20 else {
            print("❌ Anthropic key looks invalid. Make sure it starts with 'sk-ant-' and is the full key.")
            return
        }
        
        // Generate obfuscated arrays
        let openAIObfuscated = APIKeyObfuscator.obfuscateKey(YOUR_OPENAI_KEY)
        let anthropicObfuscated = APIKeyObfuscator.obfuscateKey(YOUR_ANTHROPIC_KEY)
        
        // Generate the code to paste
        let codeOutput = """
        
        ✅ SUCCESS! Copy the code below and paste it into ChatGPTService.swift
        
        Replace this section in ProductionAPIKeys:
        
        // Obfuscated OpenAI API key bytes (REPLACE BEFORE PRODUCTION)
        private static let obfuscatedOpenAIKey: [UInt8] = \(openAIObfuscated)
        
        // Obfuscated Anthropic API key bytes (REPLACE BEFORE PRODUCTION)  
        private static let obfuscatedAnthropicKey: [UInt8] = \(anthropicObfuscated)
        
        """
        
        print(codeOutput)
        
        // Test deobfuscation to make sure it works
        let testOpenAI = APIKeyObfuscator.deobfuscateKey(openAIObfuscated)
        let testAnthropic = APIKeyObfuscator.deobfuscateKey(anthropicObfuscated)
        
        print("\n🧪 TESTING DEOBFUSCATION:")
        print("OpenAI matches: \(testOpenAI == YOUR_OPENAI_KEY)")
        print("Anthropic matches: \(testAnthropic == YOUR_ANTHROPIC_KEY)")
        
        if testOpenAI == YOUR_OPENAI_KEY && testAnthropic == YOUR_ANTHROPIC_KEY {
            print("\n✅ All tests passed! Your keys are ready for production.")
            print("\n⚠️  SECURITY REMINDER:")
            print("   1. Copy the obfuscated arrays above into ChatGPTService.swift")
            print("   2. DELETE this GenerateAPIKeys.swift file from your project")
            print("   3. The keys will work in production builds without environment variables")
        } else {
            print("\n❌ TESTING FAILED - Something went wrong with obfuscation")
        }
        
        print("\n" + "=" * 50)
    }
}

// MARK: - Quick Test Function
extension GenerateAPIKeys {
    
    /// Test the obfuscation system with dummy keys
    static func testObfuscationSystem() {
        print("\n🧪 TESTING OBFUSCATION SYSTEM")
        print("-" * 30)
        
        let testKeys = [
            "sk-test123456789",
            "sk-ant-test987654321"
        ]
        
        for testKey in testKeys {
            let obfuscated = APIKeyObfuscator.obfuscateKey(testKey)
            let deobfuscated = APIKeyObfuscator.deobfuscateKey(obfuscated)
            
            print("Original: \(testKey)")
            print("Obfuscated: \(obfuscated)")
            print("Deobfuscated: \(deobfuscated)")
            print("Match: \(testKey == deobfuscated)")
            print("---")
        }
    }
}

// MARK: - String Extension for Formatting
extension String {
    static func *(left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

/*
 
 USAGE INSTRUCTIONS:
 
 1. In Xcode, add this line somewhere in your app (like SketchSiteApp.swift):
    
    #if DEBUG
    GenerateAPIKeys.generateProductionKeys()
    #endif
 
 2. Build and run your app in DEBUG mode
 
 3. Check the Xcode console for the obfuscated output
 
 4. Copy the arrays and paste them into ChatGPTService.swift
 
 5. Delete this file or move it outside your project
 
 6. Your app will now work on device without environment variables!
 
 */ 