import SwiftUI

struct ImageAnnotationView: View {
    let image: UIImage
    @ObservedObject var viewModel: MeasurementViewModel
    @State private var imageSize: CGSize = .zero
    @State private var showingValueInput = false
    @State private var tempMeasurementValue = ""
    @State private var pendingMeasurement: MeasurementLine?
    
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
                
                // Drawing overlay for current line being drawn
                if case .drawing(let startPoint) = viewModel.drawingState {
                    Path { path in
                        path.move(to: startPoint)
                        path.addLine(to: startPoint) // Will be updated in drag gesture
                    }
                    .stroke(Color.blue, lineWidth: 2)
                }
            }
            .clipped()
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        switch viewModel.drawingState {
                        case .idle:
                            viewModel.drawingState = .drawing(startPoint: value.startLocation)
                        case .drawing:
                            break // Continue drawing
                        case .editing:
                            break // Don't interfere with editing
                        }
                    }
                    .onEnded { value in
                        if case .drawing(let startPoint) = viewModel.drawingState {
                            let pixelLength = sqrt(
                                pow(value.location.x - startPoint.x, 2) +
                                pow(value.location.y - startPoint.y, 2)
                            )
                            let realWorldLength = viewModel.convertPixelsToUnit(pixelLength)
                            
                            pendingMeasurement = MeasurementLine(
                                startPoint: startPoint,
                                endPoint: value.location,
                                value: realWorldLength,
                                unit: viewModel.selectedUnit,
                                label: String(format: "%.1f %@", realWorldLength, viewModel.selectedUnit.symbol)
                            )
                            
                            tempMeasurementValue = String(format: "%.1f", realWorldLength)
                            showingValueInput = true
                        }
                        viewModel.drawingState = .idle
                    }
            )
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

#Preview {
    // Create a sample image for preview
    let sampleImage = UIImage(systemName: "photo") ?? UIImage()
    let viewModel = MeasurementViewModel()
    
    ImageAnnotationView(image: sampleImage, viewModel: viewModel)
}
