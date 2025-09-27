import SwiftUI
import UIKit

struct ImageAnnotationView: View {
    let image: UIImage
    @ObservedObject var viewModel: MeasurementViewModel
    @State private var imageSize: CGSize = .zero
    @State private var currentDragLine: MeasurementLine?
    @State private var isLongPressing = false
    @State private var longPressStartPoint: CGPoint = .zero
    @State private var showMagnifier = false
    @State private var magnifierPosition: CGPoint = .zero
    @State private var editingMeasurement: MeasurementLine?
    @State private var editingEndpoint: EndpointType?
    @State private var editingPreviewLine: MeasurementLine?
    @State private var lastHapticDistance: CGFloat = 0
    @State private var isCreatingNewLineFromEndpoint = false
    @State private var newLineStartPoint: CGPoint = .zero
    @State private var longPressTimer: Timer?
    @State private var waitingForLongPress = false
    @State private var pendingEndpointEdit: (MeasurementLine, EndpointType)?
    @State private var lastProximityHapticTime: Date = Date.distantPast
    @State private var isSnappedToEndpoint = false
    @State private var snappedEndpointPosition: CGPoint?
    @State private var editingAngle: AngleMeasurement?
    @State private var editingAnglePoint: AnglePointType?
    @State private var editingAnglePreview: AngleMeasurement?
    
    enum EndpointType {
        case start, end
    }
    
    enum AnglePointType {
        case center, firstEnd, secondEnd
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
                                if editingMeasurement == nil && currentDragLine == nil && !isCreatingNewLineFromEndpoint && !waitingForLongPress && editingAngle == nil {
                                    // Check if we're starting to drag near an angle point first
                                    if let (angle, anglePointType) = findNearestAnglePoint(at: dragValue.startLocation) {
                                        // Start editing angle point
                                        let selectionFeedback = UISelectionFeedbackGenerator()
                                        selectionFeedback.selectionChanged()
                                        
                                        editingAngle = angle
                                        editingAnglePoint = anglePointType
                                        showMagnifier = true
                                        magnifierPosition = dragValue.location
                                    }
                                    // Check if we're starting to drag near an existing measurement endpoint
                                    else if let (measurement, endpointType) = findNearestEndpoint(at: dragValue.startLocation) {
                                        // Start waiting for long press - don't do anything yet!
                                        waitingForLongPress = true
                                        pendingEndpointEdit = (measurement, endpointType)
                                        
                                        // Start timer to detect long press
                                        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                            // Long press detected - start creating new line from endpoint
                                            isCreatingNewLineFromEndpoint = true
                                            newLineStartPoint = endpointType == .start ? measurement.startPoint : measurement.endPoint
                                            waitingForLongPress = false
                                            
                                            // Haptic feedback for starting new line creation
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                            impactFeedback.impactOccurred()
                                            
                                            // Reset haptic distance tracking
                                            lastHapticDistance = 0
                                            showMagnifier = true
                                            magnifierPosition = dragValue.location
                                        }
                                    }
                                }
                                // Handle drag movement during waiting period
                                else if waitingForLongPress {
                                    // If user moves too much during wait, cancel long press and start endpoint editing
                                    if let (measurement, endpointType) = pendingEndpointEdit {
                                        let distance = sqrt(
                                            pow(dragValue.location.x - dragValue.startLocation.x, 2) +
                                            pow(dragValue.location.y - dragValue.startLocation.y, 2)
                                        )
                                        
                                        // If moved more than 20 pixels, cancel long press and start editing
                                        if distance > 20 {
                                            longPressTimer?.invalidate()
                                            waitingForLongPress = false
                                            
                                            // Start editing existing measurement endpoint
                                            let selectionFeedback = UISelectionFeedbackGenerator()
                                            selectionFeedback.selectionChanged()
                                            
                                            // Reset haptic distance tracking for endpoint editing
                                            lastHapticDistance = 0
                                            
                                            editingMeasurement = measurement
                                            editingEndpoint = endpointType
                                            showMagnifier = true
                                            magnifierPosition = dragValue.location
                                        }
                                    }
                                } else if isCreatingNewLineFromEndpoint {
                                    // Continue creating new line from endpoint
                                    let pixelLength = sqrt(
                                        pow(dragValue.location.x - newLineStartPoint.x, 2) +
                                        pow(dragValue.location.y - newLineStartPoint.y, 2)
                                    )
                                    let unitValue = viewModel.convertPixelsToUnit(pixelLength)
                                    
                                    // Check for snapping to existing endpoints and get the final position
                                    let finalEndPoint = checkAndSnapToEndpoint(at: dragValue.location)
                                    
                                    // Recalculate distance with potentially snapped position
                                    let finalPixelLength = sqrt(
                                        pow(finalEndPoint.x - newLineStartPoint.x, 2) +
                                        pow(finalEndPoint.y - newLineStartPoint.y, 2)
                                    )
                                    let finalUnitValue = viewModel.convertPixelsToUnit(finalPixelLength)
                                    
                                    // Provide continuous haptic feedback
                                    provideContinuousHaptic(for: finalPixelLength)
                                    
                                    currentDragLine = MeasurementLine(
                                        startPoint: newLineStartPoint,
                                        endPoint: finalEndPoint,
                                        value: finalUnitValue,
                                        unit: viewModel.selectedUnit,
                                        label: "?" // Show "?" while drawing
                                    )
                                    
                                    magnifierPosition = finalEndPoint
                                } else if let editingMeasurement = editingMeasurement, let editingEndpoint = editingEndpoint {
                                    // Check for snapping to existing endpoints and get the final position
                                    let snappedPosition = checkAndSnapToEndpoint(at: dragValue.location)
                                    
                                    // Update the endpoint being dragged with potentially snapped position
                                    let newStartPoint = editingEndpoint == .start ? snappedPosition : editingMeasurement.startPoint
                                    let newEndPoint = editingEndpoint == .end ? snappedPosition : editingMeasurement.endPoint
                                    
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
                                    
                                    // Update magnifier position to snapped position
                                    magnifierPosition = snappedPosition
                                } else if let editingAngle = editingAngle, let editingAnglePoint = editingAnglePoint {
                                    // Check for snapping to existing endpoints and get the final position
                                    let snappedPosition = checkAndSnapToEndpoint(at: dragValue.location)
                                    
                                    // Update the angle point being dragged
                                    var newCenterPoint = editingAngle.centerPoint
                                    var newFirstLineEnd = editingAngle.firstLineEnd
                                    var newSecondLineEnd = editingAngle.secondLineEnd
                                    
                                    switch editingAnglePoint {
                                    case .center:
                                        // Move entire angle - offset all points by the same amount
                                        let deltaX = snappedPosition.x - editingAngle.centerPoint.x
                                        let deltaY = snappedPosition.y - editingAngle.centerPoint.y
                                        newCenterPoint = snappedPosition
                                        newFirstLineEnd = CGPoint(x: editingAngle.firstLineEnd.x + deltaX, y: editingAngle.firstLineEnd.y + deltaY)
                                        newSecondLineEnd = CGPoint(x: editingAngle.secondLineEnd.x + deltaX, y: editingAngle.secondLineEnd.y + deltaY)
                                    case .firstEnd:
                                        newFirstLineEnd = snappedPosition
                                    case .secondEnd:
                                        newSecondLineEnd = snappedPosition
                                    }
                                    
                                    // Calculate new angle in degrees
                                    let angle1 = atan2(newFirstLineEnd.y - newCenterPoint.y, newFirstLineEnd.x - newCenterPoint.x)
                                    let angle2 = atan2(newSecondLineEnd.y - newCenterPoint.y, newSecondLineEnd.x - newCenterPoint.x)
                                    var angleDiff = angle2 - angle1
                                    
                                    // Normalize angle to 0-360 degrees
                                    if angleDiff < 0 { angleDiff += 2 * .pi }
                                    if angleDiff > .pi { angleDiff = 2 * .pi - angleDiff }
                                    let degrees = angleDiff * 180 / .pi
                                    
                                    // Create preview angle
                                    editingAnglePreview = AngleMeasurement(
                                        centerPoint: newCenterPoint,
                                        firstLineEnd: newFirstLineEnd,
                                        secondLineEnd: newSecondLineEnd,
                                        degrees: degrees
                                    )
                                    
                                    // Update magnifier position to snapped position
                                    magnifierPosition = snappedPosition
                                }
                            }
                            .onEnded { _ in
                                // Handle new line creation from endpoint
                                if isCreatingNewLineFromEndpoint, let dragLine = currentDragLine, dragLine.value > 0 {
                                    // Add line immediately with "?" placeholder - no popup
                                    let placeholderLine = MeasurementLine(
                                        startPoint: dragLine.startPoint,
                                        endPoint: dragLine.endPoint,
                                        value: dragLine.value, // Keep the actual value for calculations
                                        unit: dragLine.unit,
                                        label: "?" // Show "?" as placeholder
                                    )
                                    viewModel.addMeasurement(placeholderLine)
                                    
                                    // Haptic feedback for completing new line creation
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                                // Save the final changes if we were editing an existing endpoint
                                else if let editingMeasurement = editingMeasurement, let previewLine = editingPreviewLine {
                                    // Haptic feedback for finishing endpoint edit - like setting down a tape measure
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    
                                    viewModel.updateMeasurement(editingMeasurement, with: previewLine)
                                }
                                // Save the final changes if we were editing an angle
                                else if let editingAngle = editingAngle, let previewAngle = editingAnglePreview {
                                    // Haptic feedback for finishing angle edit
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    
                                    viewModel.updateAngleMeasurement(editingAngle, with: previewAngle)
                                }
                                
                                // Reset all editing states
                                editingMeasurement = nil
                                editingEndpoint = nil
                                editingPreviewLine = nil
                                editingAngle = nil
                                editingAnglePoint = nil
                                editingAnglePreview = nil
                                isCreatingNewLineFromEndpoint = false
                                currentDragLine = nil
                                showMagnifier = false
                                
                                // Clean up long press detection
                                longPressTimer?.invalidate()
                                longPressTimer = nil
                                waitingForLongPress = false
                                pendingEndpointEdit = nil
                                
                                // Reset snap state
                                isSnappedToEndpoint = false
                                snappedEndpointPosition = nil
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
                                            
                                            // Check for snapping to existing endpoints and get the final position
                                            let finalEndPoint = checkAndSnapToEndpoint(at: dragValue.location)
                                            
                                            // Recalculate distance with potentially snapped position
                                            let finalPixelLength = sqrt(
                                                pow(finalEndPoint.x - longPressStartPoint.x, 2) +
                                                pow(finalEndPoint.y - longPressStartPoint.y, 2)
                                            )
                                            let finalUnitValue = viewModel.convertPixelsToUnit(finalPixelLength)
                                            
                                            // Provide continuous haptic feedback during dragging
                                            provideContinuousHaptic(for: finalPixelLength)
                                            
                                            currentDragLine = MeasurementLine(
                                                startPoint: longPressStartPoint,
                                                endPoint: finalEndPoint,
                                                value: finalUnitValue,
                                                unit: viewModel.selectedUnit,
                                                label: "?" // Show "?" while drawing
                                            )
                                        }
                                        
                                        // Update magnifier position - use the final endpoint (potentially snapped)
                                        magnifierPosition = currentDragLine?.endPoint ?? dragValue.location
                                    }
                                default:
                                    break
                                }
                            }
                            .onEnded { _ in
                                // Gesture ended
                                if let dragLine = currentDragLine, dragLine.value > 0 {
                                    // Add line immediately with "?" placeholder - no popup
                                    let placeholderLine = MeasurementLine(
                                        startPoint: dragLine.startPoint,
                                        endPoint: dragLine.endPoint,
                                        value: dragLine.value, // Keep the actual value for calculations
                                        unit: dragLine.unit,
                                        label: "?" // Show "?" as placeholder
                                    )
                                    viewModel.addMeasurement(placeholderLine)
                                    
                                    // Haptic feedback for completing measurement - like locking a tape measure
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                                
                                // Reset states
                                isLongPressing = false
                                showMagnifier = false
                                currentDragLine = nil
                                
                                // Reset snap state
                                isSnappedToEndpoint = false
                                snappedEndpointPosition = nil
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
                
                // Angle measurements overlay
                ForEach(viewModel.angleMeasurements) { angle in
                    // Hide the angle being edited, show preview instead
                    if editingAngle?.id != angle.id {
                        AngleMeasurementView(
                            angle: angle,
                            onDelete: {
                                viewModel.removeAngleMeasurement(angle)
                            },
                            onEdit: { updatedAngle in
                                viewModel.updateAngleMeasurement(angle, with: updatedAngle)
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
                
                // Show preview of angle being edited
                if let previewAngle = editingAnglePreview {
                    AngleMeasurementView(
                        angle: previewAngle,
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
                        screenSize: geometry.size,
                        measurements: viewModel.measurements,
                        excludeMeasurement: editingMeasurement,
                        angleMeasurements: viewModel.angleMeasurements,
                        excludeAngle: editingAngle
                    )
                    .position(
                        x: geometry.size.width - 60,
                        y: 60
                    )
                }
            }
            .clipped()
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
    
    private func findNearestAnglePoint(at point: CGPoint, threshold: CGFloat = 30) -> (AngleMeasurement, AnglePointType)? {
        for angle in viewModel.angleMeasurements {
            // Check center point
            let centerDistance = sqrt(
                pow(point.x - angle.centerPoint.x, 2) +
                pow(point.y - angle.centerPoint.y, 2)
            )
            if centerDistance <= threshold {
                return (angle, .center)
            }
            
            // Check first line end
            let firstEndDistance = sqrt(
                pow(point.x - angle.firstLineEnd.x, 2) +
                pow(point.y - angle.firstLineEnd.y, 2)
            )
            if firstEndDistance <= threshold {
                return (angle, .firstEnd)
            }
            
            // Check second line end
            let secondEndDistance = sqrt(
                pow(point.x - angle.secondLineEnd.x, 2) +
                pow(point.y - angle.secondLineEnd.y, 2)
            )
            if secondEndDistance <= threshold {
                return (angle, .secondEnd)
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
    
    private func checkAndSnapToEndpoint(at point: CGPoint) -> CGPoint {
        let snapThreshold: CGFloat = 5 // pixels - very precise snapping zone
        
        // Find the closest endpoint within snap threshold
        var closestEndpoint: CGPoint?
        var closestDistance: CGFloat = snapThreshold
        
        for measurement in viewModel.measurements {
            let distanceToStart = sqrt(
                pow(point.x - measurement.startPoint.x, 2) +
                pow(point.y - measurement.startPoint.y, 2)
            )
            let distanceToEnd = sqrt(
                pow(point.x - measurement.endPoint.x, 2) +
                pow(point.y - measurement.endPoint.y, 2)
            )
            
            if distanceToStart < closestDistance {
                closestDistance = distanceToStart
                closestEndpoint = measurement.startPoint
            }
            
            if distanceToEnd < closestDistance {
                closestDistance = distanceToEnd
                closestEndpoint = measurement.endPoint
            }
        }
        
        // If we found a close endpoint
        if let snapPoint = closestEndpoint {
            // If we weren't already snapped, or we're snapping to a different point
            if !isSnappedToEndpoint || snappedEndpointPosition != snapPoint {
                // Snap to the endpoint and provide strong haptic feedback
                isSnappedToEndpoint = true
                snappedEndpointPosition = snapPoint
                
                // Strong single haptic for snap confirmation
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.prepare()
                notificationFeedback.notificationOccurred(.success)
            }
            
            return snapPoint // Return the snapped position
        } else {
            // No endpoint nearby - reset snap state and return original position
            if isSnappedToEndpoint {
                isSnappedToEndpoint = false
                snappedEndpointPosition = nil
            }
            return point // Return the original finger position
        }
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
            .stroke(Color.measurementLine, lineWidth: 3)
            
            // Start point indicator
            Circle()
                .fill(Color.measurementLine)
                .frame(width: 12, height: 12)
                .position(measurement.startPoint)
            
            // End point indicator
            Circle()
                .fill(Color.measurementLine)
                .frame(width: 12, height: 12)
                .position(measurement.endPoint)
            
            // Measurement label with edit/delete functionality
            HStack(spacing: 4) {
                // Main measurement label
            Text(measurement.label)
                    .font(.appMeasurementValue)
                    .foregroundColor(.appTextOnPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.measurementLabel)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
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
                            .font(.appLabelMedium)
                            .foregroundColor(.appTextOnPrimary)
                            .padding(AppSpacing.xs)
                            .background(Color.buttonDanger)
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
        }
    }
}

struct MagnifierView: View {
    let image: UIImage
    let position: CGPoint
    let imageSize: CGSize
    let screenSize: CGSize
    let measurements: [MeasurementLine]
    let excludeMeasurement: MeasurementLine?
    let angleMeasurements: [AngleMeasurement]
    let excludeAngle: AngleMeasurement?
    
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
                magnifierSize: magnifierSize,
                measurements: measurements,
                excludeMeasurement: excludeMeasurement,
                angleMeasurements: angleMeasurements,
                excludeAngle: excludeAngle
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
    let measurements: [MeasurementLine]
    let excludeMeasurement: MeasurementLine?
    let angleMeasurements: [AngleMeasurement]
    let excludeAngle: AngleMeasurement?
    
    func makeUIView(context: Context) -> MagnifyImageUIView {
        let view = MagnifyImageUIView()
        view.image = image
        view.imageSize = imageSize
        return view
    }
    
    func updateUIView(_ uiView: MagnifyImageUIView, context: Context) {
        uiView.touchPoint = touchPoint
        uiView.measurements = measurements
        uiView.excludeMeasurement = excludeMeasurement
        uiView.angleMeasurements = angleMeasurements
        uiView.excludeAngle = excludeAngle
        uiView.setNeedsDisplay()
    }
}

class MagnifyImageUIView: UIView {
    var image: UIImage!
    var touchPoint: CGPoint = .zero
    var imageSize: CGSize = .zero
    var measurements: [MeasurementLine] = []
    var excludeMeasurement: MeasurementLine?
    var angleMeasurements: [AngleMeasurement] = []
    var excludeAngle: AngleMeasurement?
    
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
        
        // Draw measurement lines in the magnifier
        drawMeasurementLines(in: context)
        drawAngleMeasurements(in: context)
        
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
    
    private func drawMeasurementLines(in context: CGContext) {
        // Draw existing measurement lines so they appear in the magnifier
        // Exclude the measurement currently being edited to avoid confusion
        for measurement in measurements {
            // Skip the measurement that's currently being edited
            if let excludeMeasurement = excludeMeasurement, measurement.id == excludeMeasurement.id {
                continue
            }
            // Set line appearance
            context.setStrokeColor(UIColor.systemRed.cgColor)
            context.setLineWidth(2.0)
            context.setLineCap(.round)
            
            // Draw the measurement line
            context.move(to: measurement.startPoint)
            context.addLine(to: measurement.endPoint)
            context.strokePath()
            
            // Draw endpoint circles (small dots to show precise endpoints)
            let endpointRadius: CGFloat = 3.0
            
            // Start point circle
            context.setFillColor(UIColor.systemRed.cgColor)
            context.fillEllipse(in: CGRect(
                x: measurement.startPoint.x - endpointRadius,
                y: measurement.startPoint.y - endpointRadius,
                width: endpointRadius * 2,
                height: endpointRadius * 2
            ))
            
            // End point circle
            context.fillEllipse(in: CGRect(
                x: measurement.endPoint.x - endpointRadius,
                y: measurement.endPoint.y - endpointRadius,
                width: endpointRadius * 2,
                height: endpointRadius * 2
            ))
        }
    }
    
    private func drawAngleMeasurements(in context: CGContext) {
        // Draw existing angle measurements so they appear in the magnifier
        // Exclude the angle currently being edited to avoid confusion
        for angle in angleMeasurements {
            // Skip the angle that's currently being edited
            if let excludeAngle = excludeAngle, angle.id == excludeAngle.id {
                continue
            }
            
            // Set line appearance for dashed white lines
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(2.0)
            context.setLineCap(.round)
            context.setLineDash(phase: 0, lengths: [6, 3]) // Dashed pattern
            
            // Draw first line from center to first end
            context.move(to: angle.centerPoint)
            context.addLine(to: angle.firstLineEnd)
            context.strokePath()
            
            // Draw second line from center to second end
            context.move(to: angle.centerPoint)
            context.addLine(to: angle.secondLineEnd)
            context.strokePath()
            
            // Reset line dash for the arc
            context.setLineDash(phase: 0, lengths: [])
            
            // Draw arc - simplified version for magnifier
            context.setStrokeColor(UIColor.yellow.cgColor)
            context.setLineWidth(2.0)
            
            let radius: CGFloat = 30
            let angle1 = atan2(angle.firstLineEnd.y - angle.centerPoint.y, angle.firstLineEnd.x - angle.centerPoint.x)
            let angle2 = atan2(angle.secondLineEnd.y - angle.centerPoint.y, angle.secondLineEnd.x - angle.centerPoint.x)
            
            // Draw arc from angle1 to angle2
            context.addArc(center: angle.centerPoint, radius: radius, startAngle: angle1, endAngle: angle2, clockwise: false)
            context.strokePath()
            
            // Draw center point
            context.setFillColor(UIColor.red.cgColor)
            let centerRadius: CGFloat = 2.0
            context.fillEllipse(in: CGRect(
                x: angle.centerPoint.x - centerRadius,
                y: angle.centerPoint.y - centerRadius,
                width: centerRadius * 2,
                height: centerRadius * 2
            ))
        }
    }
}

struct AngleMeasurementView: View {
    let angle: AngleMeasurement
    let onDelete: () -> Void
    let onEdit: (AngleMeasurement) -> Void
    
    @State private var showingDeleteButton = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditDialog = false
    @State private var editValue = ""
    
    var body: some View {
        ZStack {
            // First dashed line (white)
            Path { path in
                path.move(to: angle.centerPoint)
                path.addLine(to: angle.firstLineEnd)
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
            
            // Second dashed line (white)
            Path { path in
                path.move(to: angle.centerPoint)
                path.addLine(to: angle.secondLineEnd)
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
            
            // Arc showing the angle (make it more visible)
            AngleArcView(
                centerPoint: angle.centerPoint,
                firstLineEnd: angle.firstLineEnd,
                secondLineEnd: angle.secondLineEnd,
                radius: 50
            )
            .stroke(Color.yellow, lineWidth: 3) // Use yellow to make it more visible
            
            // Center point indicator (for debugging)
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .position(angle.centerPoint)
            
            // Angle label
            Text(angle.label)
                .font(.appLabelMedium)
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                .position(
                    x: angle.centerPoint.x + 35,
                    y: angle.centerPoint.y - 35
                )
                .onTapGesture {
                    editValue = String(format: "%.1f", angle.degrees)
                    showingEditDialog = true
                }
                .onLongPressGesture {
                    showingDeleteButton.toggle()
                }
            
            // Delete button (appears on long press)
            if showingDeleteButton {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash.fill")
                        .font(.appLabelMedium)
                        .foregroundColor(.white)
                        .padding(AppSpacing.xs)
                        .background(Color.buttonDanger)
                        .clipShape(Circle())
                }
                .transition(.scale.combined(with: .opacity))
                .position(
                    x: angle.centerPoint.x,
                    y: angle.centerPoint.y - 40
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingDeleteButton)
        .alert("Delete Angle", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this angle measurement?")
        }
        .alert("Edit Angle", isPresented: $showingEditDialog) {
            TextField("Degrees", text: $editValue)
                .keyboardType(.decimalPad)
            
            Button("Cancel") {
                editValue = ""
            }
            
            Button("Save") {
                if let degrees = Double(editValue) {
                    let updatedAngle = AngleMeasurement(
                        centerPoint: angle.centerPoint,
                        firstLineEnd: angle.firstLineEnd,
                        secondLineEnd: angle.secondLineEnd,
                        degrees: degrees
                    )
                    onEdit(updatedAngle)
                }
                editValue = ""
            }
        }
    }
    
    private func averageAngle(_ angle: AngleMeasurement) -> Double {
        let angle1 = atan2(angle.firstLineEnd.y - angle.centerPoint.y, angle.firstLineEnd.x - angle.centerPoint.x)
        let angle2 = atan2(angle.secondLineEnd.y - angle.centerPoint.y, angle.secondLineEnd.x - angle.centerPoint.x)
        return (angle1 + angle2) / 2
    }
}

struct AngleArcView: Shape {
    let centerPoint: CGPoint
    let firstLineEnd: CGPoint
    let secondLineEnd: CGPoint
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let angle1 = atan2(firstLineEnd.y - centerPoint.y, firstLineEnd.x - centerPoint.x)
        let angle2 = atan2(secondLineEnd.y - centerPoint.y, secondLineEnd.x - centerPoint.x)
        
        let startAngle = Angle(radians: angle1)
        let endAngle = Angle(radians: angle2)
        
        path.addArc(
            center: centerPoint,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        return path
    }
}

#Preview {
    // Create a sample image for preview
    let sampleImage = UIImage(systemName: "photo") ?? UIImage()
    let viewModel = MeasurementViewModel()
    
    ImageAnnotationView(image: sampleImage, viewModel: viewModel)
}
