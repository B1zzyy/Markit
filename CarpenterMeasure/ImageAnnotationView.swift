import SwiftUI
import UIKit

struct ImageAnnotationView: View {
    let image: UIImage
    @ObservedObject var viewModel: MeasurementViewModel
    @State private var imageSize: CGSize = .zero
    @State private var showingValueInput = false
    @State private var tempMeasurementValue = ""
    @State private var pendingMeasurement: MeasurementLine?
    @State private var currentDragLine: MeasurementLine?
    @State private var isLongPressing = false
    @State private var longPressStartPoint: CGPoint = .zero
    @State private var showMagnifier = false
    @State private var magnifierPosition: CGPoint = .zero
    @State private var editingMeasurement: MeasurementLine?
    @State private var editingEndpoint: EndpointType?
    @State private var editingPreviewLine: MeasurementLine?
    @State private var lastHapticDistance: CGFloat = 0
    
    enum EndpointType {
        case start, end
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(
                        GeometryReader { imageGeometry in
                            Color.clear
                                .onAppear {
                                    imageSize = imageGeometry.size
                                }
                        }
                    )
                
                // Transparent overlay for gesture handling
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        // Combined gesture for both creating new measurements and editing endpoints
                        DragGesture(minimumDistance: 0)
                            .onChanged { dragValue in
                                if editingMeasurement == nil && currentDragLine == nil {
                                    // Check if we're starting to drag near an existing endpoint
                                    if let (measurement, endpointType) = findNearestEndpoint(at: dragValue.startLocation) {
                                        // Haptic feedback for grabbing an endpoint - like picking up a tape measure end
                                        let selectionFeedback = UISelectionFeedbackGenerator()
                                        selectionFeedback.selectionChanged()
                                        
                                        // Reset haptic distance tracking for endpoint editing
                                        lastHapticDistance = 0
                                        
                                        // Start editing existing measurement endpoint
                                        editingMeasurement = measurement
                                        editingEndpoint = endpointType
                                        showMagnifier = true
                                        magnifierPosition = dragValue.location
                                    }
                                } else if let editingMeasurement = editingMeasurement, let editingEndpoint = editingEndpoint {
                                    // Update the endpoint being dragged (preview only, don't save to viewModel yet)
                                    let newStartPoint = editingEndpoint == .start ? dragValue.location : editingMeasurement.startPoint
                                    let newEndPoint = editingEndpoint == .end ? dragValue.location : editingMeasurement.endPoint
                                    
                                    let pixelLength = sqrt(
                                        pow(newEndPoint.x - newStartPoint.x, 2) +
                                        pow(newEndPoint.y - newStartPoint.y, 2)
                                    )
                                    
                                    // Convert pixel length to proper unit
                                    let unitValue = viewModel.convertPixelsToUnit(pixelLength)
                                    
                                    // Provide continuous haptic feedback during endpoint editing
                                    provideContinuousHaptic(for: pixelLength)
                                    
                                    // Create preview line (don't update viewModel during drag)
                                    editingPreviewLine = MeasurementLine(
                                        startPoint: newStartPoint,
                                        endPoint: newEndPoint,
                                        value: unitValue,
                                        unit: editingMeasurement.unit,
                                        label: String(format: "%.1f %@", unitValue, editingMeasurement.unit.symbol)
                                    )
                                    
                                    // Update magnifier position
                                    magnifierPosition = dragValue.location
                                }
                            }
                            .onEnded { _ in
                                // Save the final changes if we were editing
                                if let editingMeasurement = editingMeasurement, let previewLine = editingPreviewLine {
                                    // Haptic feedback for finishing endpoint edit - like setting down a tape measure
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    
                                    viewModel.updateMeasurement(editingMeasurement, with: previewLine)
                                }
                                
                                // Reset editing states
                                editingMeasurement = nil
                                editingEndpoint = nil
                                editingPreviewLine = nil
                                showMagnifier = false
                            }
                    )
                    .simultaneousGesture(
                        // Long press gesture for creating new measurements
                        LongPressGesture(minimumDuration: 0.5)
                            .sequenced(before: DragGesture(minimumDistance: 0))
                            .onChanged { value in
                                // Only proceed if we're not already editing an endpoint
                                guard editingMeasurement == nil else { return }
                                
                                switch value {
                                case .first(true):
                                    // Long press started - haptic feedback like starting a tape measure
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    // Reset haptic distance tracking for new measurement
                                    lastHapticDistance = 0
                                    
                                    isLongPressing = true
                                    showMagnifier = true
                                case .second(true, let drag):
                                    if let dragValue = drag {
                                        if currentDragLine == nil {
                                            // Start new measurement line
                                            longPressStartPoint = dragValue.startLocation
                                            let pixelLength = sqrt(
                                                pow(dragValue.location.x - dragValue.startLocation.x, 2) +
                                                pow(dragValue.location.y - dragValue.startLocation.y, 2)
                                            )
                                            
                                            // Convert pixel length to proper unit
                                            let unitValue = viewModel.convertPixelsToUnit(pixelLength)
                                            
                                            // Provide continuous haptic feedback during dragging
                                            provideContinuousHaptic(for: pixelLength)
                                            
                                            currentDragLine = MeasurementLine(
                                                startPoint: dragValue.startLocation,
                                                endPoint: dragValue.location,
                                                value: unitValue,
                                                unit: viewModel.selectedUnit,
                                                label: String(format: "%.1f %@", unitValue, viewModel.selectedUnit.symbol)
                                            )
                                        } else {
                                            // Update existing line
                                            let pixelLength = sqrt(
                                                pow(dragValue.location.x - longPressStartPoint.x, 2) +
                                                pow(dragValue.location.y - longPressStartPoint.y, 2)
                                            )
                                            
                                            // Convert pixel length to proper unit
                                            let unitValue = viewModel.convertPixelsToUnit(pixelLength)
                                            
                                            // Provide continuous haptic feedback during dragging
                                            provideContinuousHaptic(for: pixelLength)
                                            
                                            currentDragLine = MeasurementLine(
                                                startPoint: longPressStartPoint,
                                                endPoint: dragValue.location,
                                                value: unitValue,
                                                unit: viewModel.selectedUnit,
                                                label: String(format: "%.1f %@", unitValue, viewModel.selectedUnit.symbol)
                                            )
                                        }
                                        
                                        // Update magnifier position - use the visual line endpoint
                                        magnifierPosition = dragValue.location
                                    }
                                default:
                                    break
                                }
                            }
                            .onEnded { _ in
                                // Gesture ended
                                if let dragLine = currentDragLine, dragLine.value >= 10 {
                                    // Haptic feedback for completing measurement - like locking a tape measure
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    
                                    pendingMeasurement = dragLine
                                    tempMeasurementValue = String(format: "%.1f", dragLine.value)
                                    showingValueInput = true
                                }
                                
                                // Reset states
                                isLongPressing = false
                                showMagnifier = false
                                currentDragLine = nil
                            }
                    )
                
                // Measurement lines overlay (on top of gesture layer)
                ForEach(viewModel.measurements) { measurement in
                    // Hide the measurement being edited, show preview instead
                    if editingMeasurement?.id != measurement.id {
                        MeasurementLineView(
                            measurement: measurement,
                            onDelete: {
                                viewModel.removeMeasurement(measurement)
                            },
                            onEdit: { updatedMeasurement in
                                viewModel.updateMeasurement(measurement, with: updatedMeasurement)
                            }
                        )
                    }
                }
                
                // Show preview of measurement being edited
                if let previewLine = editingPreviewLine {
                    MeasurementLineView(
                        measurement: previewLine,
                        onDelete: {},
                        onEdit: { _ in }
                    )
                    .opacity(0.8)
                }
                
                // Live drawing line (follows finger during drag)
                if let dragLine = currentDragLine {
                    MeasurementLineView(
                        measurement: dragLine,
                        onDelete: {},
                        onEdit: { _ in }
                    )
                    .opacity(0.8)
                }
                
                // Magnifying glass - fixed in top right corner (on top)
                if showMagnifier && isPointOverImage(magnifierPosition, imageSize: geometry.size) {
                    MagnifierView(
                        image: image,
                        position: magnifierPosition,
                        imageSize: geometry.size,
                        screenSize: geometry.size
                    )
                    .position(
                        x: geometry.size.width - 60,
                        y: 60
                    )
                }
            }
            .clipped()
        }
        .alert("Enter Measurement Value", isPresented: $showingValueInput) {
            TextField("Value", text: $tempMeasurementValue)
                .keyboardType(.decimalPad)
            
            Button("Cancel") {
                pendingMeasurement = nil
                tempMeasurementValue = ""
            }
            
            Button("Add") {
                if let measurement = pendingMeasurement,
                   let value = Double(tempMeasurementValue) {
                    // Haptic feedback for successfully adding measurement - like marking a measurement
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    
                    let finalMeasurement = MeasurementLine(
                        startPoint: measurement.startPoint,
                        endPoint: measurement.endPoint,
                        value: value,
                        unit: viewModel.selectedUnit,
                        label: String(format: "%.1f %@", value, viewModel.selectedUnit.symbol)
                    )
                    viewModel.addMeasurement(finalMeasurement)
                }
                pendingMeasurement = nil
                tempMeasurementValue = ""
            }
        } message: {
            Text("Enter the actual measurement value for this line")
        }
    }
    
    private func isPointOverImage(_ point: CGPoint, imageSize: CGSize) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        let originalWidth = CGFloat(cgImage.width)
        let originalHeight = CGFloat(cgImage.height)
        let originalAspectRatio = originalWidth / originalHeight
        let viewAspectRatio = imageSize.width / imageSize.height
        
        // Calculate actual image display area (aspect fit)
        var actualImageRect: CGRect
        
        if originalAspectRatio > viewAspectRatio {
            // Image is wider - fits to view width, centered vertically
            let displayHeight = imageSize.width / originalAspectRatio
            actualImageRect = CGRect(
                x: 0,
                y: (imageSize.height - displayHeight) / 2,
                width: imageSize.width,
                height: displayHeight
            )
        } else {
            // Image is taller - fits to view height, centered horizontally
            let displayWidth = imageSize.height * originalAspectRatio
            actualImageRect = CGRect(
                x: (imageSize.width - displayWidth) / 2,
                y: 0,
                width: displayWidth,
                height: imageSize.height
            )
        }
        
        return actualImageRect.contains(point)
    }
    
    private func findNearestEndpoint(at point: CGPoint, threshold: CGFloat = 30) -> (MeasurementLine, EndpointType)? {
        for measurement in viewModel.measurements {
            let startDistance = sqrt(pow(point.x - measurement.startPoint.x, 2) + pow(point.y - measurement.startPoint.y, 2))
            let endDistance = sqrt(pow(point.x - measurement.endPoint.x, 2) + pow(point.y - measurement.endPoint.y, 2))
            
            if startDistance <= threshold {
                return (measurement, .start)
            } else if endDistance <= threshold {
                return (measurement, .end)
            }
        }
        return nil
    }
    
    private func provideContinuousHaptic(for distance: CGFloat) {
        // Convert pixel distance to actual measurement units
        let unitDistance = viewModel.convertPixelsToUnit(distance)
        let lastUnitDistance = viewModel.convertPixelsToUnit(lastHapticDistance)
        
        // Provide haptic feedback every 1 unit (1 cm, 1 mm, or 1 inch)
        let currentInterval = floor(unitDistance)
        let lastInterval = floor(lastUnitDistance)
        
        if currentInterval != lastInterval && currentInterval > 0 {
            // Strong haptic for continuous feedback - like tape measure ticking every unit
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare() // Prepare for better performance
            impactFeedback.impactOccurred(intensity: 1.0) // Full intensity for stronger feel
        }
        
        lastHapticDistance = distance
    }
}

struct MeasurementLineView: View {
    let measurement: MeasurementLine
    let onDelete: () -> Void
    let onEdit: (MeasurementLine) -> Void
    @State private var showingDeleteConfirmation = false
    @State private var showingEditDialog = false
    @State private var editValue = ""
    @State private var showingDeleteButton = false
    
    var body: some View {
        ZStack {
            // Main measurement line
            Path { path in
                path.move(to: measurement.startPoint)
                path.addLine(to: measurement.endPoint)
            }
            .stroke(Color.red, lineWidth: 3)
            
            // Start point indicator
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .position(measurement.startPoint)
            
            // End point indicator
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .position(measurement.endPoint)
            
            // Measurement label with edit/delete functionality
            HStack(spacing: 4) {
                // Main measurement label
                Text(measurement.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture {
                        // Hide delete button if showing
                        if showingDeleteButton {
                            showingDeleteButton = false
                        } else {
                            // Edit measurement value
                            editValue = String(format: "%.1f", measurement.value)
                            showingEditDialog = true
                        }
                    }
                    .onLongPressGesture {
                        // Show/hide delete button
                        showingDeleteButton.toggle()
                    }
                
                // Delete button (appears on long press)
                if showingDeleteButton {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.red.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .position(
                x: measurement.midPoint.x,
                y: measurement.midPoint.y - 20
            )
            .animation(.easeInOut(duration: 0.2), value: showingDeleteButton)
        }
        .alert("Delete Measurement", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this measurement?")
        }
        .alert("Edit Measurement Value", isPresented: $showingEditDialog) {
            TextField("Value", text: $editValue)
                .keyboardType(.decimalPad)
            
            Button("Cancel") {
                editValue = ""
            }
            
            Button("Save") {
                if let value = Double(editValue) {
                    let updatedMeasurement = MeasurementLine(
                        startPoint: measurement.startPoint,
                        endPoint: measurement.endPoint,
                        value: value,
                        unit: measurement.unit,
                        label: String(format: "%.1f %@", value, measurement.unit.symbol)
                    )
                    onEdit(updatedMeasurement)
                }
                editValue = ""
            }
        } message: {
            Text("Enter the new measurement value for this line")
        }
    }
}

struct MagnifierView: View {
    let image: UIImage
    let position: CGPoint
    let imageSize: CGSize
    let screenSize: CGSize
    
    private var magnifierSize: CGFloat {
        return 100 // Fixed size, simple
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white)
                .frame(width: magnifierSize, height: magnifierSize)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(radius: 4)
            
            // Magnified image using the tutorial's approach but adapted for SwiftUI
            MagnifiedImageView(
                image: image,
                touchPoint: position,
                imageSize: imageSize,
                magnifierSize: magnifierSize
            )
            .frame(width: magnifierSize, height: magnifierSize)
            .clipShape(Circle())
            
            // Crosshair dot
            Circle()
                .fill(Color.red)
                .frame(width: 4, height: 4)
        }
    }
}

struct MagnifiedImageView: UIViewRepresentable {
    let image: UIImage
    let touchPoint: CGPoint
    let imageSize: CGSize
    let magnifierSize: CGFloat
    
    func makeUIView(context: Context) -> MagnifyImageUIView {
        let view = MagnifyImageUIView()
        view.image = image
        view.imageSize = imageSize
        return view
    }
    
    func updateUIView(_ uiView: MagnifyImageUIView, context: Context) {
        uiView.touchPoint = touchPoint
        uiView.setNeedsDisplay()
    }
}

class MagnifyImageUIView: UIView {
    var image: UIImage!
    var touchPoint: CGPoint = .zero
    var imageSize: CGSize = .zero
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Clear the context
        context.clear(rect)
        
        // Save the current context state
        context.saveGState()
        
        // Translate to center of magnifier (exactly like the tutorial)
        context.translateBy(x: rect.width * 0.5, y: rect.height * 0.5)
        
        // Scale by magnification factor (1.5x like the tutorial)
        context.scaleBy(x: 1.5, y: 1.5)
        
        // Translate to center the touch point in the magnifier
        context.translateBy(x: -touchPoint.x, y: -touchPoint.y)
        
        // Draw the image exactly as it appears in the view, accounting for aspect fit positioning
        let actualImageRect = getActualImageRect()
        image.draw(in: actualImageRect)
        
        // Restore context state
        context.restoreGState()
    }
    
    private func getActualImageRect() -> CGRect {
        guard let cgImage = image.cgImage else { 
            return CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height) 
        }
        
        let originalWidth = CGFloat(cgImage.width)
        let originalHeight = CGFloat(cgImage.height)
        let originalAspectRatio = originalWidth / originalHeight
        let viewAspectRatio = imageSize.width / imageSize.height
        
        if originalAspectRatio > viewAspectRatio {
            // Image is wider - fits to view width, centered vertically
            let displayHeight = imageSize.width / originalAspectRatio
            return CGRect(
                x: 0,
                y: (imageSize.height - displayHeight) / 2,
                width: imageSize.width,
                height: displayHeight
            )
        } else {
            // Image is taller - fits to view height, centered horizontally
            let displayWidth = imageSize.height * originalAspectRatio
            return CGRect(
                x: (imageSize.width - displayWidth) / 2,
                y: 0,
                width: displayWidth,
                height: imageSize.height
            )
        }
    }
}

#Preview {
    // Create a sample image for preview
    let sampleImage = UIImage(systemName: "photo") ?? UIImage()
    let viewModel = MeasurementViewModel()
    
    ImageAnnotationView(image: sampleImage, viewModel: viewModel)
}
