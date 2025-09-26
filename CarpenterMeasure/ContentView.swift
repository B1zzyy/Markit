import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MeasurementViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top toolbar
                HStack {
                    // Left button - Camera or Home
                    Button(action: {
                        if viewModel.capturedImage != nil {
                            // Go back to home screen
                            viewModel.goToHomeScreen()
                        } else {
                            // Open camera
                            viewModel.showingCamera = true
                        }
                    }) {
                        Image(systemName: viewModel.capturedImage != nil ? "house.fill" : "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(viewModel.capturedImage != nil ? Color.orange : Color.blue)
                            .clipShape(Circle())
                    }
                    
                    // Camera button (when image is present)
                    if viewModel.capturedImage != nil {
                        Button(action: {
                            viewModel.showingCamera = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                    
                    Text("Carpenter Measure")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.showingUnitPicker = true
                    }) {
                        Text(viewModel.selectedUnit.symbol)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                
                // Main content area
                if let image = viewModel.capturedImage {
                    ImageAnnotationView(image: image, viewModel: viewModel)
                } else {
                    // Empty state
                    VStack(spacing: 30) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 10) {
                            Text("Take a Photo to Start")
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Text("Tap the camera button to capture an image, then press and drag to add measurements")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        Button(action: {
                            viewModel.showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
                }
                
                // Bottom toolbar (only show when image is present)
                if viewModel.capturedImage != nil {
                    HStack(spacing: 20) {
                        Button(action: {
                            viewModel.clearAllMeasurements()
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 40)
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Spacer()
                        
                        Text("\(viewModel.measurements.count) measurements")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            // Future: Export functionality
                        }) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 40)
                                .background(Color.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            CameraView(viewModel: viewModel)
        }
        .actionSheet(isPresented: $viewModel.showingUnitPicker) {
            ActionSheet(
                title: Text("Select Measurement Unit"),
                buttons: MeasurementUnit.allCases.map { unit in
                    .default(Text(unit.displayName)) {
                        viewModel.selectedUnit = unit
                    }
                } + [.cancel()]
            )
        }
    }
}

#Preview {
    ContentView()
}
