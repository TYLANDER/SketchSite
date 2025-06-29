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
- **Undo/Redo Drawing:** Instantly undo or redo your last drawing actions.
- **Vision Analysis:** Detects rectangles, groups, and text annotations.
- **Component Inference:** Classifies elements (button, image, nav bar, etc.) and allows manual override.
- **Auto-Naming:** Detected components are auto-named (e.g., "Button 1").
- **Interactive Overlays:** Tap detected elements to open the Inspector and edit their properties.
- **Inspector:** Edit type, label, and size of any detected component in a dedicated Inspector sheet.
- **Modern Toolbar:** Accessible, mobile-friendly controls for clearing, generating, undo/redo, regenerating, and previewing code.
- **Regenerate Button:** Instantly rerun code generation with the current detection results.
- **Browser Preview:** Live HTML/CSS preview inside the app using a built-in browser (WKWebView).
- **Code Preview:** View and copy generated code in a compact, readable window.
- **XcodeGen Integration:** Project structure is managed via `project.yml` for easy file management and reproducibility.

---

## Roadmap & Priorities

### High Priority
- [x] **Rectangle-to-Component Detection Refinement**  
  Improved grouping, heuristics, and support for more UI element types.
- [x] **Element Inspector**  
  Tap an element to view and edit properties (type, label, size, etc.).
- [x] **Undo Button**  
  Add undo/redo for drawing and detection pipeline.
- [x] **Regenerate Response Button**  
  Add a dedicated button to quickly rerun code generation.

### Medium Priority
- [x] **Auto Naming + Reordering**  
  Auto-naming for detected elements; manual renaming and reordering in Inspector.
- [x] **Open in Browser Preview (WKWebView)**  
  Live HTML/CSS preview inside the app.
- [ ] **Component Drag & Drop**  
  Allow users to drag component overlays to reposition them on the canvas.
- [ ] **Ask ChatGPT Follow-Up (Prompt Chaining UI)**  
  UI for follow-up questions and prompt chaining.
- [ ] **Model Selector**  
  Toggle between GPT-4, GPT-3.5, etc.
- [ ] **Preloaded Prompts**  
  Quick-select templates (SwiftUI, Tailwind CSS, etc.).

### Low Priority
- [ ] **Resizable Drawer**  
  Draggable/expandable code or inspector drawer.
- [ ] **Prompt Customization UI**  
  UI for editing system/user messages before sending to GPT.

---

## Usage
1. **Draw:** Use your finger or Apple Pencil to sketch UI elements on the canvas.
2. **Undo/Redo:** Instantly undo or redo your last drawing actions using the toolbar.
3. **Annotate:** Add text labels to clarify intent (e.g., "CTA", "Profile Image").
4. **Analyze:** Tap "Generate" to run Vision and AI analysis.
5. **Edit:** Tap any blue rectangle to open the Inspector and change its type, label, or size.
6. **Regenerate:** Use the Regenerate button to rerun code generation with the current detection results.
7. **Preview:** Tap the browser icon to preview your generated HTML/CSS live in the app.
8. **Export:** Preview, copy, or share the generated code.

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
