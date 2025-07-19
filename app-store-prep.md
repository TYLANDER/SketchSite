# App Store Preparation Checklist for SketchSite

## 📱 **Required Screenshots** (Must Complete)

### iPhone Screenshots (Required Sizes)
- **iPhone 6.7"** (iPhone 15 Pro Max, 14 Pro Max, etc.): 1290 × 2796 px
- **iPhone 6.5"** (iPhone 15 Plus, 14 Plus, etc.): 1242 × 2688 px  
- **iPhone 5.5"** (iPhone 8 Plus, etc.): 1242 × 2208 px

### iPad Screenshots (If supporting iPad)
- **iPad Pro 6th Gen**: 2048 × 2732 px
- **iPad Pro 5th Gen**: 2048 × 2732 px

### Screenshot Content Ideas
1. **Canvas with Drawing** - Show the full-screen drawing experience
2. **Component Detection** - Rectangles converted to UI components with overlays
3. **Component Inspector** - Show the editing interface
4. **Component Library** - Display the template gallery
5. **Generated Code** - Show the HTML/CSS output
6. **Browser Preview** - Live preview of generated code

## 🎨 **App Store Assets**

### App Icon (Required)
- **1024 × 1024 px** PNG (no transparency, no rounded corners)
- Use your existing icon from `Icons/` folder
- Must be high quality and recognizable

### App Preview Video (Optional but Recommended)
- **30 seconds max** showing key features
- Same sizes as screenshots
- Show: Drawing → Detection → Code Generation → Preview

## 📝 **App Store Metadata**

### App Information
- **App Name**: "SketchSite"
- **Subtitle**: "AI-Powered UI Design Tool" (30 chars max)
- **Category**: Productivity (already set in Info.plist)
- **Age Rating**: 4+ (no objectionable content)

### Description (4000 chars max)
```
Transform your hand-drawn UI sketches into real code instantly with SketchSite's AI-powered design tool.

KEY FEATURES:
• Full-Screen Drawing Canvas - Professional edge-to-edge design experience
• AI Component Detection - Automatically recognizes buttons, forms, navigation, and more
• Smart Code Generation - Generates clean HTML/CSS with GPT-4o and Claude AI
• Interactive Components - Tap, drag, resize, and inspect every element
• Component Library - 24+ pre-built templates across 6 categories
• Live Preview - See your generated code in action with built-in browser
• Camera Integration - Analyze existing UI screenshots and mockups

PERFECT FOR:
- UI/UX Designers creating rapid prototypes
- Developers sketching app layouts
- Product teams collaborating on designs
- Students learning web development
- Anyone who thinks better by drawing

HOW IT WORKS:
1. Draw your UI layout with finger or Apple Pencil
2. Tap Generate to detect components automatically  
3. Edit component types and properties with the inspector
4. Generate professional HTML/CSS code with AI
5. Preview your design live in the built-in browser
6. Export and share your code

SketchSite bridges the gap between creative sketching and technical implementation, making UI design accessible to everyone. No complex tools, no learning curve - just draw and create.

Privacy: All sketches stored locally on your device. AI features optional.
```

### Keywords (100 chars max)
```
ui design,sketch,drawing,html,css,ai,code,prototype,wireframe,mockup,web design
```

### URLs
- **Privacy Policy**: Upload your `privacy-policy.html` to a website first
- **Support URL**: Create a simple support page or use schmidt197@gmail.com

## 🔧 **Technical Checklist**

### Before Upload
- [ ] Test on physical iPhone device
- [ ] Verify all features work with API keys set
- [ ] Test camera and photo library permissions
- [ ] Ensure app works without network (drawing/local features)
- [ ] Test on different iPhone screen sizes
- [ ] Build Archive in Release mode

### Xcode Archive Steps
1. **Set Environment Variables** in scheme:
   - `OPENAI_API_KEY`: Your OpenAI API key
   - `ANTHROPIC_API_KEY`: Your Anthropic API key
2. **Select Generic iOS Device** (not simulator)
3. **Product → Archive**
4. **Distribute App → App Store Connect**

## 📋 **App Store Connect Setup**

### 1. Create App Record
- Go to [App Store Connect](https://appstoreconnect.apple.com)
- Apps → + → New App
- Platform: iOS
- Name: SketchSite
- Bundle ID: com.tylerschmidt.SketchSite (already created)

### 2. App Information
- **Category**: Productivity
- **Subcategory**: Design
- **Content Rights**: Tyler Schmidt
- **Age Rating**: Complete questionnaire (likely 4+)

### 3. Pricing and Availability
- **Price**: Free (recommended for first release)
- **Availability**: All territories
- **App Store Distribution**: Available

## 🧪 **TestFlight Strategy** (Recommended)

### Internal Testing (Immediate)
1. Upload first build
2. Apple review (24-48 hours)
3. Test with up to 100 internal users (your Apple Developer team)

### External Testing (Optional)
1. Create external group
2. Invite beta testers (friends, colleagues, potential users)
3. Collect feedback for 1-2 weeks
4. Iterate based on feedback
5. Upload final build for App Store review

### Beta Tester Recruitment Ideas
- Social media (Twitter, LinkedIn)
- Design/developer communities
- Friends and colleagues
- Local tech meetups

## 🚀 **Submission Timeline**

### Week 1: Asset Creation
- Create screenshots and app icon
- Write app description and metadata
- Set up App Store Connect record

### Week 2: TestFlight
- Upload first build
- Recruit and manage beta testers
- Collect feedback and iterate

### Week 3: Final Submission
- Upload final build
- Submit for App Store review
- Review process: 1-7 days typically

### Week 4: Launch
- App approved and live on App Store
- Marketing and promotion
- Monitor reviews and feedback

## 📊 **Post-Launch**

### Analytics & Monitoring
- App Store Connect analytics
- Crash reports and user feedback
- Performance monitoring
- User reviews and ratings

### Marketing Ideas
- Social media posts with demo videos
- ProductHunt launch
- Design community showcases (Dribbble, Behance)
- Developer/designer blog posts

## 🎯 **Success Metrics**

### Technical
- Crash-free rate > 99%
- App Store rating > 4.0
- Fast loading and smooth performance

### User Engagement
- Daily active users
- Feature usage (drawing vs AI generation)
- User retention rates

### Business
- App Store ranking in Productivity category
- Organic downloads and growth
- User feedback and testimonials 