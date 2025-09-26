import Foundation
import SwiftUI
import UIKit

// MARK: - Measurement Units
enum MeasurementUnit: String, CaseIterable {
    case millimeters = "mm"
    case centimeters = "cm"
    case inches = "in"
    
    var displayName: String {
        switch self {
        case .millimeters: return "Millimeters"
        case .centimeters: return "Centimeters"
        case .inches: return "Inches"
        }
    }
    
    var symbol: String {
        return self.rawValue
    }
}

// MARK: - Measurement Line
struct MeasurementLine: Identifiable {
    let id = UUID()
    var startPoint: CGPoint
    var endPoint: CGPoint
    var value: Double
    var unit: MeasurementUnit
    var label: String
    
    var length: CGFloat {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        return sqrt(dx * dx + dy * dy)
    }
    
    var angle: Double {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        return atan2(dy, dx)
    }
    
    var midPoint: CGPoint {
        return CGPoint(
            x: (startPoint.x + endPoint.x) / 2,
            y: (startPoint.y + endPoint.y) / 2
        )
    }
}

// MARK: - Drawing State
enum DrawingState {
    case idle
    case drawing(startPoint: CGPoint)
    case editing(line: MeasurementLine)
}

// MARK: - App State
class MeasurementViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var measurements: [MeasurementLine] = []
    @Published var selectedUnit: MeasurementUnit = .centimeters
    @Published var drawingState: DrawingState = .idle
    @Published var showingCamera = false
    @Published var showingUnitPicker = false
    
    // Scale factor for converting pixels to real-world measurements
    // This would need calibration in a real app
    @Published var pixelsPerUnit: Double = 10.0 // 10 pixels = 1 unit
    
    func addMeasurement(_ line: MeasurementLine) {
        measurements.append(line)
    }
    
    func removeMeasurement(_ line: MeasurementLine) {
        measurements.removeAll { $0.id == line.id }
    }
    
    func clearAllMeasurements() {
        measurements.removeAll()
    }
    
    func convertPixelsToUnit(_ pixels: CGFloat) -> Double {
        return Double(pixels) / pixelsPerUnit
    }
    
    func setImage(_ image: UIImage) {
        // Fix image orientation to avoid coordinate issues
        capturedImage = image.fixedOrientation()
        clearAllMeasurements()
    }
    
    func goToHomeScreen() {
        capturedImage = nil
        clearAllMeasurements()
        drawingState = .idle
    }
}

// MARK: - UIImage Extension for Orientation Fix
extension UIImage {
    func fixedOrientation() -> UIImage {
        // If image is already in correct orientation, return as-is
        if imageOrientation == .up {
            return self
        }
        
        // Create graphics context
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        // Draw image with correct orientation
        draw(in: CGRect(origin: .zero, size: size))
        
        // Get the correctly oriented image
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
