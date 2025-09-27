import Foundation
import SwiftUI
import UIKit

// MARK: - Measurement Units
enum MeasurementUnit: String, CaseIterable, Codable {
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

// MARK: - Saved Annotation
struct SavedAnnotation: Identifiable, Codable {
    let id: UUID
    let image: Data
    let measurements: [MeasurementLine]
    let angleMeasurements: [AngleMeasurement]
    let createdAt: Date
    let title: String
    
    init(image: UIImage, measurements: [MeasurementLine], angleMeasurements: [AngleMeasurement] = [], title: String = "") {
        self.id = UUID()
        self.image = image.jpegData(compressionQuality: 0.8) ?? Data()
        self.measurements = measurements
        self.angleMeasurements = angleMeasurements
        self.createdAt = Date()
        self.title = title.isEmpty ? "Annotation \(DateFormatter.shortDate.string(from: Date()))" : title
    }
    
    // Initializer for updating existing annotations
    init(id: UUID, image: UIImage, measurements: [MeasurementLine], angleMeasurements: [AngleMeasurement], createdAt: Date, title: String) {
        self.id = id
        self.image = image.jpegData(compressionQuality: 0.8) ?? Data()
        self.measurements = measurements
        self.angleMeasurements = angleMeasurements
        self.createdAt = createdAt
        self.title = title
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}


// MARK: - Measurement Line
struct MeasurementLine: Identifiable, Codable {
    let id: UUID
    var startPoint: CGPoint
    var endPoint: CGPoint
    var value: Double
    var unit: MeasurementUnit
    var label: String
    
    init(startPoint: CGPoint, endPoint: CGPoint, value: Double, unit: MeasurementUnit, label: String) {
        self.id = UUID()
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.value = value
        self.unit = unit
        self.label = label
    }
    
    // MARK: - Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case id, startPoint, endPoint, value, unit, label
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startPoint = try container.decode(CGPoint.self, forKey: .startPoint)
        endPoint = try container.decode(CGPoint.self, forKey: .endPoint)
        value = try container.decode(Double.self, forKey: .value)
        unit = try container.decode(MeasurementUnit.self, forKey: .unit)
        label = try container.decode(String.self, forKey: .label)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startPoint, forKey: .startPoint)
        try container.encode(endPoint, forKey: .endPoint)
        try container.encode(value, forKey: .value)
        try container.encode(unit, forKey: .unit)
        try container.encode(label, forKey: .label)
    }
    
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

// MARK: - Angle Measurement
struct AngleMeasurement: Identifiable, Codable {
    let id: UUID
    let centerPoint: CGPoint
    let firstLineEnd: CGPoint
    let secondLineEnd: CGPoint
    let degrees: Double
    let label: String
    
    init(centerPoint: CGPoint, firstLineEnd: CGPoint, secondLineEnd: CGPoint, degrees: Double) {
        self.id = UUID()
        self.centerPoint = centerPoint
        self.firstLineEnd = firstLineEnd
        self.secondLineEnd = secondLineEnd
        self.degrees = degrees
        self.label = String(format: "%.1f°", degrees)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        let centerX = try container.decode(CGFloat.self, forKey: .centerX)
        let centerY = try container.decode(CGFloat.self, forKey: .centerY)
        centerPoint = CGPoint(x: centerX, y: centerY)
        
        let firstX = try container.decode(CGFloat.self, forKey: .firstX)
        let firstY = try container.decode(CGFloat.self, forKey: .firstY)
        firstLineEnd = CGPoint(x: firstX, y: firstY)
        
        let secondX = try container.decode(CGFloat.self, forKey: .secondX)
        let secondY = try container.decode(CGFloat.self, forKey: .secondY)
        secondLineEnd = CGPoint(x: secondX, y: secondY)
        
        degrees = try container.decode(Double.self, forKey: .degrees)
        label = try container.decode(String.self, forKey: .label)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(centerPoint.x, forKey: .centerX)
        try container.encode(centerPoint.y, forKey: .centerY)
        try container.encode(firstLineEnd.x, forKey: .firstX)
        try container.encode(firstLineEnd.y, forKey: .firstY)
        try container.encode(secondLineEnd.x, forKey: .secondX)
        try container.encode(secondLineEnd.y, forKey: .secondY)
        try container.encode(degrees, forKey: .degrees)
        try container.encode(label, forKey: .label)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, centerX, centerY, firstX, firstY, secondX, secondY, degrees, label
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
    @Published var angleMeasurements: [AngleMeasurement] = []
    @Published var selectedUnit: MeasurementUnit = .millimeters
    @Published var drawingState: DrawingState = .idle
    @Published var showingCamera = false
    @Published var showingUnitPicker = false
    @Published var savedAnnotations: [SavedAnnotation] = []
    @Published var currentEditingAnnotation: SavedAnnotation? = nil
    
    // Scale factor for converting pixels to real-world measurements
    // This would need calibration in a real app
    @Published var pixelsPerUnit: Double = 10.0 // 10 pixels = 1 unit
    
    init() {
        loadSavedAnnotations()
    }
    
    func addMeasurement(_ line: MeasurementLine) {
        measurements.append(line)
    }
    
    func removeMeasurement(_ line: MeasurementLine) {
        measurements.removeAll { $0.id == line.id }
    }
    
    func updateMeasurement(_ oldMeasurement: MeasurementLine, with newMeasurement: MeasurementLine) {
        if let index = measurements.firstIndex(where: { $0.id == oldMeasurement.id }) {
            // Create a new measurement with the same ID by copying all properties
            let updatedMeasurement = MeasurementLine(
                startPoint: newMeasurement.startPoint,
                endPoint: newMeasurement.endPoint,
                value: newMeasurement.value,
                unit: newMeasurement.unit,
                label: newMeasurement.label
            )
            measurements[index] = updatedMeasurement
        }
    }
    
    func clearAllMeasurements() {
        measurements.removeAll()
        angleMeasurements.removeAll()
    }
    
    func addAngleMeasurement(_ angle: AngleMeasurement) {
        angleMeasurements.append(angle)
    }
    
    func removeAngleMeasurement(_ angle: AngleMeasurement) {
        angleMeasurements.removeAll { $0.id == angle.id }
    }
    
    func updateAngleMeasurement(_ oldAngle: AngleMeasurement, with newAngle: AngleMeasurement) {
        if let index = angleMeasurements.firstIndex(where: { $0.id == oldAngle.id }) {
            angleMeasurements[index] = newAngle
        }
    }
    
    func goToHomeScreen() {
        capturedImage = nil
        measurements.removeAll()
        angleMeasurements.removeAll()
        currentEditingAnnotation = nil
    }
    
    func convertPixelsToUnit(_ pixels: CGFloat) -> Double {
        return Double(pixels) / pixelsPerUnit
    }
    
    func setImage(_ image: UIImage) {
        // Fix image orientation to avoid coordinate issues
        capturedImage = image.fixedOrientation()
        clearAllMeasurements()
    }
    
    func setImageFromCamera(_ image: UIImage) {
        // When taking a new photo, clear editing state
        setImage(image)
        currentEditingAnnotation = nil
    }
    
    func changeUnit(to newUnit: MeasurementUnit) {
        let oldUnit = selectedUnit
        selectedUnit = newUnit
        
        // Convert existing measurements to new unit
        for i in 0..<measurements.count {
            let oldValue = measurements[i].value
            let convertedValue = convertValue(oldValue, from: oldUnit, to: newUnit)
            
            measurements[i] = MeasurementLine(
                startPoint: measurements[i].startPoint,
                endPoint: measurements[i].endPoint,
                value: convertedValue,
                unit: newUnit,
                label: String(format: "%.1f %@", convertedValue, newUnit.symbol)
            )
        }
    }
    
    private func convertValue(_ value: Double, from fromUnit: MeasurementUnit, to toUnit: MeasurementUnit) -> Double {
        // Convert to millimeters first (base unit)
        let valueInMM: Double
        switch fromUnit {
        case .millimeters:
            valueInMM = value
        case .centimeters:
            valueInMM = value * 10.0
        case .inches:
            valueInMM = value * 25.4
        }
        
        // Convert from millimeters to target unit
        switch toUnit {
        case .millimeters:
            return valueInMM
        case .centimeters:
            return valueInMM / 10.0
        case .inches:
            return valueInMM / 25.4
        }
    }
    
    // MARK: - Save/Load Annotations
    func saveCurrentAnnotation() {
        guard let image = capturedImage else { return }
        
        if let editingAnnotation = currentEditingAnnotation {
            // Update existing annotation
            if let index = savedAnnotations.firstIndex(where: { $0.id == editingAnnotation.id }) {
                // Create updated annotation with same ID and creation date but new measurements
                let updatedAnnotation = SavedAnnotation(
                    id: editingAnnotation.id,
                    image: image,
                    measurements: measurements,
                    angleMeasurements: angleMeasurements,
                    createdAt: editingAnnotation.createdAt,
                    title: editingAnnotation.title
                )
                savedAnnotations[index] = updatedAnnotation
            }
        } else {
            // Create new annotation (only if there are measurements or angle measurements)
            guard !measurements.isEmpty || !angleMeasurements.isEmpty else { return }
            let annotation = SavedAnnotation(image: image, measurements: measurements, angleMeasurements: angleMeasurements)
            savedAnnotations.append(annotation)
        }
        
        saveToDisk()
    }
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(savedAnnotations)
            let url = getDocumentsDirectory().appendingPathComponent("savedAnnotations.json")
            try data.write(to: url)
        } catch {
            print("Failed to save annotations: \(error)")
        }
    }
    
    private func loadSavedAnnotations() {
        do {
            let url = getDocumentsDirectory().appendingPathComponent("savedAnnotations.json")
            let data = try Data(contentsOf: url)
            savedAnnotations = try JSONDecoder().decode([SavedAnnotation].self, from: data)
        } catch {
            print("Failed to load annotations: \(error)")
            savedAnnotations = []
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func deleteSavedAnnotation(_ annotation: SavedAnnotation) {
        savedAnnotations.removeAll { $0.id == annotation.id }
        saveToDisk()
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
