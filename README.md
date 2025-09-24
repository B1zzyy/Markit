# Markit - Carpenter Measure iOS App

A minimalist iOS app designed for carpenters to take photos and add precise measurements to their work. Built with SwiftUI.

## Features

### Current Features
- 📸 **Camera Integration**: Take photos directly within the app
- 📏 **Interactive Measurements**: Press, hold, and drag to add dimension lines
- 📐 **Multiple Units**: Switch between millimeters (mm), centimeters (cm), and inches (in)
- 🎯 **Precision Input**: Enter exact measurement values for each dimension line
- 🗑️ **Easy Management**: Delete individual measurements or clear all at once
- 🎨 **Minimalist Design**: Clean, focused interface optimized for field work

### Planned Features (Future)
- 🔄 **3D Transformation**: Convert 2D images to interactive 3D shapes
- 📤 **Export Options**: Share measurements and annotated images
- 📊 **Measurement History**: Save and organize measurement sessions
- 🔧 **Calibration Tools**: Improve measurement accuracy with reference objects

## How to Use

1. **Take a Photo**: Tap the camera button to capture an image of your work
2. **Add Measurements**: Press and hold on the image, then drag to create a measurement line
3. **Enter Values**: Input the actual measurement value when prompted
4. **Switch Units**: Tap the unit button (mm/cm/in) to change measurement units
5. **Manage Measurements**: Tap measurement labels to delete individual lines, or use the trash button to clear all

## Setup Instructions

### Prerequisites
- macOS with Xcode 15.0 or later
- iOS 16.0 or later (for deployment)
- Apple Developer Account (for device testing)

### Installation

1. **Open in Xcode**:
   ```bash
   open CarpenterMeasure.xcodeproj
   ```

2. **Configure Signing**:
   - Select the project in Xcode's navigator
   - Go to "Signing & Capabilities" 
   - Choose your Apple ID under "Team"
   - Xcode will automatically generate a bundle identifier

3. **Run the App**:
   - **iOS Simulator**: Select any iPhone simulator and press ⌘R
   - **Physical Device**: Connect your iPhone, select it as the destination, and press ⌘R

### Testing Without App Store

You can test the app in several ways:

#### Option 1: iOS Simulator (Recommended for Development)
- No Apple Developer account required
- Camera functionality will be simulated
- Perfect for testing UI and measurement features

#### Option 2: Physical Device (Free Apple ID)
- Connect your iPhone to your Mac
- Sign in with your Apple ID in Xcode
- Apps installed this way expire after 7 days
- Full camera functionality available

#### Option 3: Physical Device (Paid Developer Account)
- $99/year Apple Developer Program membership
- Apps valid for 1 year
- Can distribute to up to 100 devices for testing
- Access to advanced features and analytics

## Technical Architecture

### Core Components

- **`MeasurementViewModel`**: Manages app state, measurements, and user interactions
- **`ContentView`**: Main interface with toolbar and empty state handling
- **`CameraView`**: UIKit wrapper for camera functionality
- **`ImageAnnotationView`**: Interactive canvas for adding measurements
- **`MeasurementModels`**: Data structures for measurements and units

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: Camera access and image capture
- **Core Graphics**: Drawing measurement lines and annotations
- **Combine**: Reactive data binding and state management

## Customization

### Adding New Measurement Units
Add new cases to the `MeasurementUnit` enum in `MeasurementModels.swift`:

```swift
enum MeasurementUnit: String, CaseIterable {
    case millimeters = "mm"
    case centimeters = "cm"  
    case inches = "in"
    case feet = "ft"        // New unit
}
```

### Adjusting Pixel-to-Unit Conversion
Modify the `pixelsPerUnit` property in `MeasurementViewModel` for better accuracy:

```swift
@Published var pixelsPerUnit: Double = 10.0 // Adjust this value
```

### Styling Customizations
Colors and styling can be adjusted in the respective view files:
- Line colors: `ImageAnnotationView.swift`
- UI colors: `ContentView.swift`
- Button styles: Throughout view files

## Troubleshooting

### Camera Not Working
- Ensure `NSCameraUsageDescription` is set in `Info.plist`
- Check that camera permissions are granted in iOS Settings
- Camera won't work in iOS Simulator (this is expected)

### Build Errors
- Ensure Xcode is up to date (15.0+)
- Check that iOS Deployment Target is set to 16.0+
- Verify signing certificates are valid

### Measurement Accuracy
- The current implementation uses a basic pixel-to-unit conversion
- For production use, implement calibration using known reference objects
- Consider using ARKit for more accurate spatial measurements

## Contributing

This is a foundational implementation. Areas for improvement:
- Calibration system for accurate measurements
- Better gesture handling for complex shapes
- Export functionality (PDF, image with annotations)
- Measurement history and project organization
- Integration with 3D frameworks for future 3D features

## License

This project is created as a development template. Customize and extend as needed for your specific use case.
