# SketchSite

**Author:** Tyler Schmidt

---

## Overview

SketchSite is an innovative iOS app that lets you sketch user interface layouts by hand and instantly convert them into structured, code-ready UI descriptions. Using PencilKit for drawing, Vision for shape and text detection, and GPT for code generation, SketchSite bridges the gap between freeform design and real, usable code.

---

## Goals
- **Rapid UI Prototyping:** Draw your ideas as rectangles, buttons, nav bars, and more—SketchSite recognizes and classifies them automatically.
- **AI-Powered Code Generation:** Instantly generate HTML/CSS (or other code) from your sketch, with support for user annotations.
- **Accessibility & Modern UX:** Full-screen canvas, accessible toolbars, and responsive design for iPhone and iPad.
- **No Vendor Lock-in:** 100% Swift, no external UI dependencies, and easy to extend.

---

## Features
- **PencilKit Canvas:** Draw UI elements freehand.
- **Vision Analysis:** Detects rectangles, groups, and text annotations.
- **Component Inference:** Classifies elements (button, image, nav bar, etc.) and allows manual override.
- **Interactive Overlays:** Tap detected elements to change their type.
- **Modern Toolbar:** Accessible, mobile-friendly controls for clearing, generating, and previewing code.
- **Code Preview:** View and copy generated code in a compact, readable window.
- **XcodeGen Integration:** Project structure is managed via `project.yml` for easy file management and reproducibility.

---

## Usage
1. **Draw:** Use your finger or Apple Pencil to sketch UI elements on the canvas.
2. **Annotate:** Add text labels to clarify intent (e.g., "CTA", "Profile Image").
3. **Analyze:** Tap "Generate" to run Vision and AI analysis.
4. **Edit:** Tap any blue rectangle to change its inferred type.
5. **Export:** Preview, copy, or share the generated code.

---

## Getting Started
1. **Clone the repo:**
   ```bash
   git clone https://github.com/TYLANDER/SketchSite.git
   cd SketchSite
   ```
2. **Install dependencies:**
   - Requires Xcode 14+ and Swift 5.7+
   - Install [XcodeGen](https://github.com/yonaskolb/XcodeGen):
     ```bash
     brew install xcodegen
     ```
3. **Generate the Xcode project:**
   ```bash
   xcodegen
   ```
4. **Open in Xcode:**
   ```bash
   xed .
   ```
5. **Set your OpenAI API key:**
   - In Xcode, go to Product > Scheme > Edit Scheme > Run > Arguments > Environment Variables.
   - Add `OPENAI_API_KEY` with your key as the value.
6. **Build and run on a simulator or device.**

---

## Author

Created and maintained by **Tyler Schmidt**.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
