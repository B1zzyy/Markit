import SwiftUI
import Pow

struct ContentView: View {
    @StateObject private var viewModel = MeasurementViewModel()
    @State private var showingClearAllConfirmation = false
    @State private var showingUnitDropdown = false
    @State private var isAnimatingSave = false
    @State private var isSelectMode = false
    @State private var selectedAnnotations: Set<UUID> = []
    @State private var showingBulkDeleteConfirmation = false
    
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
                    
                    // Unit dropdown button (only show when annotating an image)
                    if viewModel.capturedImage != nil {
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
                    } else {
                        // Select button for multi-select mode on home screen
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSelectMode.toggle()
                                if !isSelectMode {
                                    selectedAnnotations.removeAll()
                                }
                            }
                        }) {
                            Text(isSelectMode ? "Done" : "Select")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.appPrimary)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.vertical, AppSpacing.md)
                .background(Color.appBackground)
                
                // Main content area
                if let image = viewModel.capturedImage {
                    ImageAnnotationView(image: image, viewModel: viewModel)
                        .scaleEffect(isAnimatingSave ? 0.95 : 1.0)
                        .opacity(isAnimatingSave ? 0.7 : 1.0)
                        .animation(.easeInOut(duration: 0.8), value: isAnimatingSave)
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
                                    // Saved annotations
                                    ForEach(viewModel.savedAnnotations.sorted(by: { $0.createdAt > $1.createdAt })) { annotation in
                                        SavedAnnotationCard(
                                            annotation: annotation,
                                            viewModel: viewModel,
                                            isSelectMode: isSelectMode,
                                            isSelected: selectedAnnotations.contains(annotation.id)
                                        ) {
                                            if selectedAnnotations.contains(annotation.id) {
                                                selectedAnnotations.remove(annotation.id)
                                            } else {
                                                selectedAnnotations.insert(annotation.id)
                                            }
                                        }
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
                            // Start save animation
                            isAnimatingSave = true
                            
                            // Save the annotation
                            viewModel.saveCurrentAnnotation()
                            
                            // Animate transition to home screen
                            withAnimation(.easeInOut(duration: 0.8)) {
                                viewModel.capturedImage = nil
                                viewModel.measurements.removeAll()
                            }
                            
                            // Hide success overlay after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                isAnimatingSave = false
                            }
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
            
            // Floating camera button (only on home screen when not in select mode)
            if viewModel.capturedImage == nil && !isSelectMode {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.showingCamera = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                                .frame(width: 56, height: 56)
                                .background(Color.appPrimary)
                                .clipShape(Circle())
                                .appShadowMedium()
                        }
                        .padding(.trailing, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                    }
                }
                .zIndex(1500)
            }
            
            // Floating delete button (when items are selected)
            if isSelectMode && !selectedAnnotations.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingBulkDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.red)
                                .clipShape(Circle())
                                .appShadowMedium()
                        }
                        .padding(.trailing, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                    }
                }
                .zIndex(1500)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Save animation overlay
            if isAnimatingSave {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.appSuccess)
                            .scaleEffect(isAnimatingSave ? 1.2 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimatingSave)
                        
                        Text("Annotation Saved!")
                            .font(.appHeadlineMedium)
                            .foregroundColor(.appTextPrimary)
                            .opacity(isAnimatingSave ? 1 : 0)
                            .animation(.easeInOut(duration: 0.4).delay(0.2), value: isAnimatingSave)
                    }
                    .padding(32)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .appShadowLarge()
                    .scaleEffect(isAnimatingSave ? 1 : 0.8)
                    .opacity(isAnimatingSave ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isAnimatingSave)
                }
                .zIndex(2000)
                .transition(.opacity)
            }
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
        .alert("Delete Selected Annotations", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete \(selectedAnnotations.count) Items", role: .destructive) {
                // Delete selected annotations
                for annotationId in selectedAnnotations {
                    if let annotation = viewModel.savedAnnotations.first(where: { $0.id == annotationId }) {
                        viewModel.deleteSavedAnnotation(annotation)
                    }
                }
                // Exit select mode
                selectedAnnotations.removeAll()
                isSelectMode = false
            }
        } message: {
            Text("This will permanently delete \(selectedAnnotations.count) selected annotation\(selectedAnnotations.count == 1 ? "" : "s"). This action cannot be undone.")
        }
    }
}

struct SavedAnnotationCard: View {
    let annotation: SavedAnnotation
    let viewModel: MeasurementViewModel
    let isSelectMode: Bool
    let isSelected: Bool
    let onSelectionToggle: () -> Void
    
    var body: some View {
        // Simple image thumbnail like camera roll
        if let uiImage = UIImage(data: annotation.image) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(Color.appCard)
                    .aspectRatio(1, contentMode: .fit)
                
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(isSelected ? Color.appPrimary.opacity(0.3) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 3)
                    )
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                // Selection overlay
                if isSelectMode {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.appPrimary : Color.white)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.appPrimary, lineWidth: 2)
                                    )
                                
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .onTapGesture {
                if isSelectMode {
                    onSelectionToggle()
                } else {
                    // Load the saved annotation for editing
                    viewModel.setImage(uiImage)
                    viewModel.measurements = annotation.measurements
                    viewModel.currentEditingAnnotation = annotation
                }
            }
            .contextMenu {
                if !isSelectMode {
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
}

#Preview {
    ContentView()
}
