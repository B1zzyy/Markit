import SwiftUI

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
                
                // Measurement lines overlay
                ForEach(viewModel.measurements) { measurement in
                    MeasurementLineView(
                        measurement: measurement,
                        onDelete: {
                            viewModel.removeMeasurement(measurement)
                        }
                    )
                }
                
                // Live drawing line (follows finger during drag)
                if let dragLine = currentDragLine {
                    MeasurementLineView(
                        measurement: dragLine,
                        onDelete: {}
                    )
                    .opacity(0.8)
                }
                
                // Magnifying glass - fixed in top right corner
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

                // Transparent overlay for gesture handling
                Color.clear
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        // Long press gesture to start measurement
                        LongPressGesture(minimumDuration: 0.5)
                            .sequenced(before: DragGesture(minimumDistance: 0))
                            .onChanged { value in
                                switch value {
                                case .first(true):
                                    // Long press started
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
                                            
                                            currentDragLine = MeasurementLine(
                                                startPoint: dragValue.startLocation,
                                                endPoint: dragValue.location,
                                                value: pixelLength,
                                                unit: viewModel.selectedUnit,
                                                label: String(format: "%.0f px", pixelLength)
                                            )
                                        } else {
                                            // Update existing line
                                            let pixelLength = sqrt(
                                                pow(dragValue.location.x - longPressStartPoint.x, 2) +
                                                pow(dragValue.location.y - longPressStartPoint.y, 2)
                                            )
                                            
                                            currentDragLine = MeasurementLine(
                                                startPoint: longPressStartPoint,
                                                endPoint: dragValue.location,
                                                value: pixelLength,
                                                unit: viewModel.selectedUnit,
                                                label: String(format: "%.0f px", pixelLength)
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
}

struct MeasurementLineView: View {
    let measurement: MeasurementLine
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
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
            
            // Measurement label
            Text(measurement.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .position(
                    x: measurement.midPoint.x,
                    y: measurement.midPoint.y - 20
                )
                .onTapGesture {
                    showingDeleteConfirmation = true
                }
        }
        .alert("Delete Measurement", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this measurement?")
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
