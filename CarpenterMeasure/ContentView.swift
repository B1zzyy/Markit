import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MeasurementViewModel()
    @State private var showingClearAllConfirmation = false
    @State private var showingSaveConfirmation = false
    @State private var showingUnitDropdown = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                // Top toolbar
                HStack {
                    // Left button - Back arrow (only when image is present)
                    if viewModel.capturedImage != nil {
                        Button(action: {
                            viewModel.goToHomeScreen()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(.appPrimary)
                                .frame(width: 44, height: 44)
                        }
                        
                        // Camera button (when image is present)
                        Button(action: {
                            viewModel.showingCamera = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                                .foregroundColor(.appPrimary)
                                .frame(width: 44, height: 44)
                        }
                    } else {
                        // Empty space when on home screen
                        Spacer()
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    // Only show app title when no image is present
                    if viewModel.capturedImage == nil {
                        Text("Markit")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.appTextPrimary)
                    }
                    
                    Spacer()
                    
                    // Unit dropdown button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingUnitDropdown.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedUnit.symbol)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appPrimary)
                            Image(systemName: showingUnitDropdown ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.appPrimary)
                        }
                        .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.vertical, AppSpacing.md)
                .background(Color.appBackground)
                
                // Main content area
                if let image = viewModel.capturedImage {
                    ImageAnnotationView(image: image, viewModel: viewModel)
                } else {
                    // Home screen with saved annotations
                    VStack(spacing: 0) {
                        if viewModel.savedAnnotations.isEmpty {
                            // Empty state
                            VStack(spacing: 30) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 80))
                                    .foregroundColor(.appMutedForeground)
                                
                                VStack(spacing: 10) {
                                    Text("Take a Photo to Start")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.appTextPrimary)
                                    
                                    Text("Tap the camera button to capture an image, then press and drag to add measurements")
                                        .font(.body)
                                        .foregroundColor(.appTextSecondary)
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
                                    .foregroundColor(.appPrimaryForeground)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 15)
                                    .background(Color.buttonPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                                    .appShadowSmall()
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // Saved annotations grid (camera roll style)
                            ScrollView {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2)
                                ], spacing: 2) {
                                    // Camera button as first item
                                    Button(action: {
                                        viewModel.showingCamera = true
                                    }) {
                                        RoundedRectangle(cornerRadius: AppRadius.sm)
                                            .fill(Color.buttonPrimary.opacity(0.3))
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay(
                                                Image(systemName: "camera.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.appPrimary)
                                            )
                                    }
                                    
                                    // Saved annotations
                                    ForEach(viewModel.savedAnnotations.sorted(by: { $0.createdAt > $1.createdAt })) { annotation in
                                        SavedAnnotationCard(annotation: annotation, viewModel: viewModel)
                                    }
                                }
                                .padding(2)
                            }
                        }
                    }
                    .background(Color.appBackground)
                }
                
                // Bottom toolbar (only show when image is present)
                if viewModel.capturedImage != nil {
                    HStack(spacing: 20) {
                        Button(action: {
                            showingClearAllConfirmation = true
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(.appDestructiveForeground)
                                .frame(width: 50, height: 40)
                                .background(Color.buttonDanger)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                                .appShadowSmall()
                        }
                        
                        Spacer()
                        
                        Text("\(viewModel.measurements.count) measurements")
                            .font(.appCaptionText)
                            .foregroundColor(.appTextSecondary)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.saveCurrentAnnotation()
                            showingSaveConfirmation = true
                        }) {
                            Image(systemName: "checkmark")
                                .font(.title3)
                                .foregroundColor(.appTextOnPrimary)
                                .frame(width: 50, height: 40)
                                .background(Color.appSuccess)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                                .appShadowSmall()
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.appBackground)
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                if showingUnitDropdown {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingUnitDropdown = false
                    }
                }
            }
            
            // Unit dropdown overlay (positioned above all content)
            VStack {
                HStack {
                    Spacer()
                    if showingUnitDropdown {
                        VStack(spacing: 0) {
                            ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                                Button(action: {
                                    viewModel.changeUnit(to: unit)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showingUnitDropdown = false
                                    }
                                }) {
                                    HStack {
                                        Text(unit.displayName)
                                            .font(.appBodyMedium)
                                            .foregroundColor(.appTextPrimary)
                                        Spacer()
                                        Text(unit.symbol)
                                            .font(.appCaptionText)
                                            .foregroundColor(.appTextSecondary)
                                        if unit == viewModel.selectedUnit {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12))
                                                .foregroundColor(.appPrimary)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                                .background(unit == viewModel.selectedUnit ? Color.appPrimary.opacity(0.1) : Color.clear)
                                
                                if unit != MeasurementUnit.allCases.last {
                                    Divider()
                                        .background(Color.appBorder)
                                }
                            }
                        }
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                        .appShadowMedium()
                        .frame(width: 150)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, 60)
                Spacer()
            }
            .zIndex(1000)
            .allowsHitTesting(showingUnitDropdown)
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            CameraView(viewModel: viewModel)
        }
        .alert("Clear All Measurements", isPresented: $showingClearAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                viewModel.clearAllMeasurements()
            }
        } message: {
            Text("This will delete all measurement lines from the image. This action cannot be undone.")
        }
        .alert("Annotation Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your annotated image has been saved and can be accessed from the home page.")
        }
    }
}

struct SavedAnnotationCard: View {
    let annotation: SavedAnnotation
    let viewModel: MeasurementViewModel
    
    var body: some View {
        // Simple image thumbnail like camera roll
        if let uiImage = UIImage(data: annotation.image) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                .onTapGesture {
                    // Load the saved annotation
                    viewModel.setImage(uiImage)
                    viewModel.measurements = annotation.measurements
                }
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.deleteSavedAnnotation(annotation)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }
    }
}

#Preview {
    ContentView()
}
