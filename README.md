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
- **Advanced Vision Analysis:** Multi-layered detection combining rectangle detection, text recognition, and professional UI pattern recognition
- **Professional Sketching Recognition:** Detects 35+ hand-drawn UI/UX sketching patterns including hamburger menus, form fields, checkboxes, radio buttons, image placeholders, and wireframe symbols
- **Component Inference:** AI-powered classification of 26 UI element types (button, image, nav bar, textarea, etc.)
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

### ✅ **Professional Component Library Management**
- **5 Built-in Design Systems:** Default, Material Design, Bootstrap, iOS HIG, Tailwind CSS
- **Library Switching:** Seamless switching between design systems with persistent state
- **Custom Library Creation:** Full-featured library creator with icon, color scheme & component selection
- **Pre-built Templates:** 26+ component templates across 6 categories per library including textarea for multi-line text
- **Categorized Organization:** Basic, Navigation, Forms, Media, Layout, Feedback
- **Search Functionality:** Quick search through component library
- **Quick Add Section:** Fast access to most commonly used components
- **Responsive Sizing:** Templates adapt to canvas size with proper aspect ratios
- **Library-Aware Code Generation:** AI automatically uses appropriate CSS frameworks

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
- **Sketch Manager:** Professional home screen with project thumbnails and metadata
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

### 🎨 **Component Library Management System (v3.0)**
- **Professional Library Architecture:** 5 built-in design systems with complete component sets
- **Custom Library Creation:** Full-featured library creator with 13 icons, 7 color schemes, category/component selection
- **Library-Aware Code Generation:** AI automatically detects library type and uses appropriate CSS frameworks
- **Persistent Library State:** UserDefaults-based persistence with automatic library switching
- **Visual Library Interface:** Professional library manager with pack details, statistics, and color swatches

### 📱 **iPhone 16 Pro UI Optimization (v3.1)**
- **Perfect Canvas Layout:** 40pt top padding, 20pt bottom toolbar padding, 16pt edge spacing
- **Consistent Margin System:** Left/right alignment with 4pt trailing padding on model picker
- **Clean Interface Design:** Removed clutter (redo button, photo upload), streamlined 6-button toolbar
- **Model Picker Optimization:** 70-120pt width, single-line text, proper truncation support
- **Professional Spacing:** All elements have proper breathing room with iPhone 16 Pro specific tuning

### 🎨 **Professional Sketching Recognition System (v3.2)**
- **Comprehensive Pattern Detection:** Advanced recognition of 35+ professional UI/UX sketching patterns and wireframe symbols
- **Designer-Friendly Detection:** Recognizes standard sketching conventions like hamburger menus (3 horizontal lines), image placeholders (X or diagonal lines), form fields, checkboxes, radio buttons
- **Multi-Layered Analysis:** Combines geometric pattern detection, aspect ratio analysis, and contextual relationships for accurate classification
- **Apple Pencil + iPad Optimized:** Real-time pattern recognition optimized for professional design workflows
- **26 Component Types:** Full coverage including new textarea component for multi-line text input and body copy
- **Clean Visual Feedback:** Removed potentially confusing pattern recognition indicators for cleaner user experience

---

## Roadmap Status

### ✅ **Completed (High Priority)**
- [x] **Rectangle-to-Component Detection Refinement**  
  Advanced grouping, heuristics, and support for 26 UI element types including textarea
- [x] **Professional Sketching Recognition System**  
  Comprehensive pattern detection for 35+ UI/UX sketching patterns and wireframe symbols optimized for Apple Pencil + iPad workflows
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
- [x] **Advanced Component Properties (Phase 1)**  
  Boolean properties, instance swap properties, enhanced text properties, color properties, and navigation items properties
- [x] **Advanced Component Properties (Phase 2)**  
  Size & spacing properties, theme integration through library color schemes, and interactive property management
- [x] **Component Library Management System**  
  Professional library management with 5 built-in design systems, custom library creation, and library-aware code generation
- [x] **iPhone 16 Pro UI Optimization**  
  Perfect canvas layout with professional spacing, consistent margins, and ideal toolbar positioning

### 🚧 **In Progress**
- [ ] **Sketch Manager & Multi-Project Support**  
  Professional project management with thumbnail grid, recent files, search/filter, auto-save, and iCloud sync

### 🔮 **Planned (Beta Features)**
- [ ] **Project Templates Gallery**  
  Pre-built sketch templates for common app patterns (login screens, dashboards, e-commerce, etc.)
- [ ] **Advanced Export Pipeline**  
  Export to multiple formats (SwiftUI, React, Flutter) with customizable templates and styling
- [ ] **Collaboration & Sharing**  
  Share sketches via link, real-time collaboration, and team workspaces
- [ ] **Component Import/Export**  
  Import custom libraries from JSON, export libraries to share with others
- [ ] **iPad Optimization**  
  Optimize the current iPhone 16 Pro layout for iPad screen sizes and interactions

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
1. **Draw:** Use your finger or Apple Pencil to sketch UI elements using standard wireframe conventions (rectangles, lines, circles, X's for images, etc.)
2. **Library:** Tap the plus icon (➕) to add pre-built components from the current design system
3. **Generate:** Tap the wand icon to analyze your drawing and automatically detect 35+ UI patterns and classify 26 component types
4. **Interact:** Tap components to select, drag to move, use handles to resize
5. **Inspect:** Long press (0.4s) any component to open the inspector and edit properties
6. **Preview:** Tap the browser icon to see your generated HTML/CSS live in-app
7. **Export:** Copy, share, or export your generated code

### **Library Management**
1. **Switch Libraries:** Tap "SketchSite" header → "Switch Library" → Choose from 5 design systems
2. **Create Custom Library:** Main menu → "Add Library" → Configure name, icon, colors, components
3. **Library-Aware Generation:** AI automatically uses appropriate CSS framework (Bootstrap, Material, etc.)

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
- **ComponentManager:** Component collection, selection, and manipulation with ID-based tracking
- **ComponentLibraryManager:** Professional library management with 5 design systems and custom creation
- **VisionAnalysisService:** Image analysis and component detection with pattern recognition integration
- **SketchPatternRecognitionService:** Advanced pattern recognition for 35+ professional UI/UX sketching patterns and wireframe symbols
- **ChatGPTService:** AI integration for code generation with library-aware prompts
- **ComponentLibrary:** Enhanced template management with responsive sizing
- **LibraryCreatorView:** Full-featured custom library creation interface
- **ErrorManager:** Comprehensive error handling and user feedback
- **ColorExtensions:** Shared utilities for hex color parsing and CGSize Codable support

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
