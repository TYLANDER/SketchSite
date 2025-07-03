# SketchSite

**Author:** Tyler Schmidt

---

## Overview

SketchSite is an innovative iOS app that lets you sketch user interface layouts by hand and instantly convert them into structured, code-ready UI descriptions. Using PencilKit for drawing, Vision for shape and text detection, and GPT for code generation, SketchSite bridges the gap between freeform design and real, usable code.

The app features a professional full-screen canvas experience with Instagram-like edge-to-edge layout, intuitive component interaction, and powerful AI-driven code generation capabilities.

---

## Goals
- **Rapid UI Prototyping:** Draw your ideas as rectangles, buttons, nav bars, and more—SketchSite recognizes and classifies them automatically.
- **AI-Powered Code Generation:** Instantly generate HTML/CSS (or other code) from your sketch, with support for user annotations.
- **Professional Mobile UX:** Full-screen canvas with responsive design optimized for iPhone and iPad.
- **Intuitive Component Interaction:** Touch-first design with drag, resize, and inspection capabilities.
- **No Vendor Lock-in:** 100% Swift, no external UI dependencies, and easy to extend.

---

## Key Features

### ✅ **Core Drawing & Analysis**
- **PencilKit Canvas:** Full-screen drawing with Apple Pencil and finger support
- **Undo/Redo Drawing:** Instant undo/redo for drawing actions with state management
- **Vision Analysis:** Advanced rectangle and text annotation detection
- **Component Inference:** AI-powered classification of UI elements (button, image, nav bar, etc.)
- **Smart Deduplication:** Removes overlapping and duplicate detected components

### ✅ **Component Interaction System**
- **Visual Component Overlays:** Blue semi-transparent overlays with type labels
- **Tap to Select:** Simple tap selection with orange highlight borders
- **Drag to Move:** Intuitive drag-and-drop component repositioning
- **Resize Handles:** 8-point resize handles (corners and edges) for precise sizing
- **Long Press Inspector:** 0.4s long press with progressive haptic feedback opens component inspector
- **Auto-Selection:** Components auto-select when inspector opens for seamless workflow

### ✅ **Professional UI/UX**
- **Full-Screen Canvas:** True edge-to-edge layout like Instagram and modern apps
- **Dynamic Safe Area Handling:** Proper positioning for status bar and home indicator
- **Responsive Header:** "SketchSite" title with model selector and status information
- **Icon-Only Toolbar:** 7 core actions (Undo, Clear, Redo, Library, Generate, Camera, Photo)
- **Haptic Feedback:** Contextual feedback for interactions (selection, dragging, clearing, etc.)
- **Professional Color Scheme:** Modern blue/gray palette with accessibility considerations

### ✅ **Component Library**
- **Pre-built Templates:** 24+ component templates across 6 categories
- **Categorized Organization:** Basic, Navigation, Forms, Media, Layout, Feedback
- **Search Functionality:** Quick search through component library
- **Quick Add Section:** Fast access to most commonly used components
- **Responsive Sizing:** Templates adapt to canvas size with proper aspect ratios

### ✅ **Inspector & Editing**
- **Component Inspector:** Edit type, label, size, and properties
- **Pixel/Percentage Units:** Toggle between absolute and responsive sizing
- **Type Override:** Change component classification with dropdown picker
- **Real-time Updates:** Changes reflect immediately on canvas
- **Position Information:** Display current X/Y coordinates and responsive percentages

### ✅ **Code Generation & Preview**
- **AI Code Generation:** GPT-4o/3.5 and Claude integration for HTML/CSS generation
- **Live Browser Preview:** Built-in WKWebView for instant HTML preview
- **Code Export:** Copy, share, and export generated code
- **Syntax Highlighting:** Color-coded HTML/CSS display
- **Multiple Models:** Support for OpenAI GPT and Anthropic Claude models

### ✅ **Image Integration**
- **Camera Capture:** Take photos directly in-app for analysis
- **Photo Library:** Import existing images for component detection
- **Image Analysis:** Extract UI components from screenshots and mockups

### 🔮 **Coming Soon: Multi-Project Support**
- **Sketch Manager:** Figma-style home screen with project thumbnails and metadata
- **Auto-Save & Sync:** Automatic project saving with iCloud synchronization
- **Project Templates:** Pre-built templates for common app design patterns
- **Search & Organization:** Filter and organize sketches by date, name, or tags

---

## Recent Major Updates

### 🎨 **Full-Screen UI Overhaul (v2.0)**
- **Instagram-like Layout:** True edge-to-edge canvas experience
- **Dynamic Safe Area Handling:** Proper positioning for all iPhone models
- **Professional Header/Toolbar:** Clean, modern interface with proper spacing
- **Responsive Design:** Adapts to iPhone and iPad screen sizes

### 🎯 **Component Interaction System (v2.1)**
- **Enhanced Touch Interactions:** Optimized for mobile-first experience
- **Progressive Long Press:** Visual and haptic feedback progression (0.4s timing)
- **Improved Resize Handles:** Round blue circles with better touch targets
- **Smart Gesture Handling:** Distinguishes between tap, drag, and long press

### 🔧 **Technical Improvements (v2.2)**
- **ID-Based Component Management:** Prevents crashes during component updates
- **Real-Time Binding Updates:** Components update immediately during resize/drag
- **Enhanced Error Handling:** Comprehensive error management system
- **Performance Optimizations:** Efficient rendering and state management

---

## Roadmap Status

### ✅ **Completed (High Priority)**
- [x] **Rectangle-to-Component Detection Refinement**  
  Advanced grouping, heuristics, and support for 25+ UI element types
- [x] **Element Inspector**  
  Comprehensive tap-to-inspect with type, label, and size editing
- [x] **Undo/Redo System**  
  Full undo/redo for drawing with state management
- [x] **Component Library**  
  24+ pre-built templates with categorized organization and search
- [x] **Auto Naming + Component Management**  
  Automatic naming, type classification, and manual override capabilities
- [x] **Live Browser Preview**  
  Built-in WKWebView for instant HTML/CSS preview
- [x] **Full-Screen Canvas Experience**  
  Professional edge-to-edge layout with proper safe area handling

### ✅ **Completed (Medium Priority)**
- [x] **Component Drag & Drop**  
  Intuitive drag-to-reposition with real-time visual feedback
- [x] **Component Resize System**  
  8-point resize handles with live preview and constraints
- [x] **Enhanced Touch Interactions**  
  Long press inspector, haptic feedback, and gesture recognition
- [x] **Model Selector**  
  Toggle between GPT-4o, GPT-3.5, and Claude models
- [x] **Professional Mobile UX**  
  Touch-optimized interface with modern design patterns

### ✅ **Completed (High Priority)**
- [x] **Ask ChatGPT Follow-Up (Prompt Chaining UI)**  
  Complete chat interface for iterative code refinement with conversation history, real-time updates, and multi-model support
- [x] **Editable Text Content**  
  Inspector-based text editing for all text-supporting components with intelligent defaults and type-aware visibility

### 🚧 **In Progress**
- [ ] **Advanced Component Properties (Phase 1)**  
  Boolean properties, instance swap properties, enhanced text properties, and color properties

### 🔮 **Planned (Beta Features)**
- [ ] **Advanced Component Properties (Phase 2)**  
  Size & spacing properties, interactive properties, conditional properties, and theme integration
- [ ] **Sketch Manager & Multi-Project Support**  
  Figma-style project management with thumbnail grid, recent files, search/filter, auto-save, and iCloud sync
- [ ] **Project Templates Gallery**  
  Pre-built sketch templates for common app patterns (login screens, dashboards, e-commerce, etc.)
- [ ] **Advanced Export Pipeline**  
  Export to multiple formats (SwiftUI, React, Flutter) with customizable templates and styling
- [ ] **Collaboration & Sharing**  
  Share sketches via link, real-time collaboration, and team workspaces

### 📋 **Planned (Low Priority)**
- [ ] **Resizable Drawer**  
  Draggable/expandable code or inspector drawer
- [ ] **Prompt Customization UI**  
  UI for editing system/user messages before sending to AI
- [ ] **Version History**  
  Timeline view of sketch iterations with restore capability
- [ ] **Advanced Analytics**  
  Usage metrics, component statistics, and design insights

---

## Usage

### **Quick Start**
1. **Draw:** Use your finger or Apple Pencil to sketch UI elements on the full-screen canvas
2. **Library:** Tap the library icon (grid) to add pre-built components from 6 categories
3. **Generate:** Tap the wand icon to analyze your drawing and detect components
4. **Interact:** Tap components to select, drag to move, use handles to resize
5. **Inspect:** Long press (0.4s) any component to open the inspector and edit properties
6. **Preview:** Tap the browser icon to see your generated HTML/CSS live in-app
7. **Export:** Copy, share, or export your generated code

### **Advanced Features**
- **Undo/Redo:** Use arrow buttons to undo/redo drawing actions
- **Component Selection:** Tap components to select (orange border), tap background to deselect
- **Resize Components:** Select a component and drag the blue circular handles
- **Inspector Editing:** Change component type, label, and size with pixel/percentage units
- **Model Selection:** Switch between GPT-4o, GPT-3.5, and Claude in the header
- **Camera Integration:** Import photos or take new ones to analyze existing UI designs

---

## Technical Architecture

### **Core Technologies**
- **SwiftUI + PencilKit:** Native iOS drawing and UI framework
- **Vision Framework:** Apple's ML for shape and text recognition
- **OpenAI GPT & Anthropic Claude:** AI-powered code generation
- **Combine Framework:** Reactive state management
- **XcodeGen:** Project structure management

### **Key Components**
- **CanvasStateManager:** Drawing state, undo/redo, and canvas operations
- **ComponentManager:** Component collection, selection, and manipulation
- **VisionAnalysisService:** Image analysis and component detection
- **ChatGPTService:** AI integration for code generation
- **ComponentLibrary:** Pre-built template management
- **ErrorManager:** Comprehensive error handling and user feedback

### **Performance Features**
- **ID-Based Component Tracking:** Prevents stale references and crashes
- **Real-Time Binding Updates:** Immediate visual feedback during interactions
- **Smart Deduplication:** Removes overlapping detected components
- **Responsive Canvas Sizing:** Adapts to all iPhone and iPad screen sizes
- **Efficient Rendering:** Optimized SwiftUI views with proper z-indexing

---

## Getting Started

### **Prerequisites**
- Xcode 15+ and Swift 5.9+
- iOS 18.0+ deployment target
- Apple Developer account (for device testing)
- OpenAI API key and/or Anthropic API key

### **Installation**
1. **Clone the repository:**
   ```bash
   git clone https://github.com/TYLANDER/SketchSite.git
   cd SketchSite
   ```

2. **Install XcodeGen (if not already installed):**
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

5. **Configure API keys:**
   - In Xcode: Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables
   - Add `OPENAI_API_KEY` with your OpenAI API key
   - Add `ANTHROPIC_API_KEY` with your Anthropic API key (optional)

6. **Build and run** on simulator or device

### **Project Structure**
```
SketchSite/
├── Views/                    # SwiftUI views and UI components
├── Utilities/               # Core logic and managers
├── Services/               # API services and external integrations
├── SketchSiteApp.swift     # App entry point
├── DiagnosticsRunner.swift # Startup diagnostics
├── Info.plist             # App configuration
└── project.yml            # XcodeGen project definition
```

---

## Contributing

SketchSite is designed to be easily extensible. Key areas for contribution:

- **New Component Types:** Add templates to `ComponentLibrary.swift`
- **AI Model Integration:** Extend `ChatGPTService.swift` for new providers
- **Export Formats:** Add SwiftUI, React, or Flutter code generation
- **Enhanced Detection:** Improve Vision analysis in `VisionAnalysisService.swift`
- **UI/UX Improvements:** Enhance the mobile-first interface

---

## Author

Created and maintained by **Tyler Schmidt**.

*SketchSite represents the evolution of UI design tools, bringing AI-powered code generation to the intuitive world of hand-drawn sketches.*

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
