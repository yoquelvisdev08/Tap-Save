import Foundation
import SwiftUI
import UniformTypeIdentifiers

class CSVExportService {
    static let shared = CSVExportService()
    
    private init() {}
    
    func exportExpensesToCSV(expenses: [Expense]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        // Formato de número para cantidades
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        
        // Header con formato profesional
        var csvString = "sep=,\n" // Especifica el separador para Excel
        csvString.append("\"Fecha\",\"Monto\",\"Categoría\",\"Notas\"\n")
        
        // Ordenar gastos por fecha (más reciente primero)
        let sortedExpenses = expenses.sorted { $0.date > $1.date }
        
        // Datos de gastos
        for expense in sortedExpenses {
            let categoryName = expense.category?.name ?? "Sin categoría"
            // Escapar comillas duplicándolas para evitar problemas con CSV
            let notes = expense.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            let formattedDate = dateFormatter.string(from: expense.date)
            
            // Formatear monto con dos decimales
            let formattedAmount = numberFormatter.string(from: NSNumber(value: expense.amount)) ?? "\(expense.amount)"
            
            // Encapsular cada campo entre comillas dobles para manejar correctamente comas y saltos de línea
            let row = "\"\(formattedDate)\",\"\(formattedAmount)\",\"\(categoryName)\",\"\(notes)\"\n"
            csvString.append(row)
        }
        
        // Añadir fila de totales al final
        let totalAmount = expenses.reduce(0) { $0 + $1.amount }
        let formattedTotal = numberFormatter.string(from: NSNumber(value: totalAmount)) ?? "\(totalAmount)"
        csvString.append("\"\",\"\(formattedTotal)\",\"TOTAL\",\"\"\n")
        
        return csvString
    }
    
    func saveCSVToDocuments(csvString: String) -> URL? {
        // Crear nombre de archivo con fecha
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "TapSave_Gastos_\(dateString).csv"
        
        // Obtener la URL del directorio de documentos
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        // Guardar el archivo con BOM (Byte Order Mark) para Excel
        do {
            // Añadir BOM para UTF-8 que ayuda a Excel a reconocer el encoding
            let bom = "\u{FEFF}"
            let csvWithBOM = bom + csvString
            
            try csvWithBOM.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error al guardar el archivo CSV: \(error.localizedDescription)")
            return nil
        }
    }
    
    func shareCSV(csvString: String, from viewController: UIViewController? = nil, completion: ((Bool) -> Void)? = nil) {
        // Feedback háptico para indicar que empieza el proceso
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        // Guardar primero el archivo
        guard let fileURL = saveCSVToDocuments(csvString: csvString) else {
            completion?(false)
            return
        }
        
        // Crear un CSV wrapper con el tipo correcto
        let csvItem = CSVFileWrapper(fileURL: fileURL)
        
        // Crear el controlador para compartir
        let activityViewController = UIActivityViewController(
            activityItems: [csvItem],
            applicationActivities: nil
        )
        
        // Configurar callback de finalización
        activityViewController.completionWithItemsHandler = { _, completed, _, _ in
            completion?(completed)
        }
        
        // Presentar el controlador
        if let vc = viewController {
            vc.present(activityViewController, animated: true)
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        } else {
            completion?(false)
        }
    }
    
    // Función para guardar directamente en Files
    func saveToFiles(csvString: String, from viewController: UIViewController? = nil, completion: ((Bool) -> Void)? = nil) {
        // Feedback háptico
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        // Crear nombre de archivo con fecha
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let dateString = dateFormatter.string(from: Date())
        let filename = "Gastos_\(dateString).csv"
        
        // Guardar temporalmente
        guard let tempDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            completion?(false)
            return
        }
        
        let fileURL = tempDirectory.appendingPathComponent(filename)
        
        do {
            // Añadir BOM para UTF-8 que ayuda a Excel a reconocer el encoding
            let bom = "\u{FEFF}"
            let csvWithBOM = bom + csvString
            
            try csvWithBOM.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Mostrar interfaz para guardar archivo
            let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
            documentPicker.shouldShowFileExtensions = true
            
            // Presentar el picker
            if let vc = viewController {
                vc.present(documentPicker, animated: true)
            } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(documentPicker, animated: true)
            } else {
                completion?(false)
                return
            }
            
            completion?(true)
        } catch {
            print("Error al guardar el archivo CSV: \(error.localizedDescription)")
            completion?(false)
        }
    }
}

// Wrapper para el archivo CSV que incluye el tipo UTI correcto
class CSVFileWrapper: NSObject, UIActivityItemSource {
    let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return fileURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return fileURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Exportación de gastos Tap-Save"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.commaSeparatedText.identifier
    }
}

// Extensión de View para facilitar el uso desde SwiftUI
extension View {
    func shareCSV(csvString: String, completion: ((Bool) -> Void)? = nil) {
        CSVExportService.shared.shareCSV(csvString: csvString, completion: completion)
    }
    
    func saveCSVToFiles(csvString: String, completion: ((Bool) -> Void)? = nil) {
        CSVExportService.shared.saveToFiles(csvString: csvString, completion: completion)
    }
} 