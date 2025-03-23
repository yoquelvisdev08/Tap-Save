import SwiftUI

struct CustomCurrency: Codable, Identifiable, Equatable {
    var id: String { code }
    let name: String
    let code: String
    let symbol: String
}

enum Currency: Identifiable, CaseIterable, Equatable {
    case usd, eur, dop, mxn
    case custom(CustomCurrency)
    
    var id: String { 
        switch self {
        case .usd, .eur, .dop, .mxn:
            return rawValue
        case .custom(let currency):
            return currency.code
        }
    }
    
    var rawValue: String {
        switch self {
        case .usd: return "USD"
        case .eur: return "EUR"
        case .dop: return "DOP"
        case .mxn: return "MXN"
        case .custom(let currency): return currency.code
        }
    }
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .dop: return "RD$"
        case .mxn: return "MX$"
        case .custom(let currency): return currency.symbol
        }
    }
    
    var name: String {
        switch self {
        case .usd: return "Dólar estadounidense"
        case .eur: return "Euro"
        case .dop: return "Peso dominicano"
        case .mxn: return "Peso mexicano"
        case .custom(let currency): return currency.name
        }
    }
    
    static var allCases: [Currency] {
        let defaults: [Currency] = [.usd, .eur, .dop, .mxn]
        if let settings = CurrencySettings.sharedInstance {
            let customs = settings.customCurrencies.map { Currency.custom($0) }
            return defaults + customs
        }
        return defaults
    }
    
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        switch (lhs, rhs) {
        case (.usd, .usd), (.eur, .eur), (.dop, .dop), (.mxn, .mxn):
            return true
        case (.custom(let lhsCurrency), .custom(let rhsCurrency)):
            return lhsCurrency == rhsCurrency
        default:
            return false
        }
    }
}

@propertyWrapper
struct UserDefault<T: Codable> {
    let key: String
    let defaultValue: T
    
    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            if let data = UserDefaults.standard.object(forKey: key) as? Data {
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    print("Error decodificando \(key): \(error)")
                    return defaultValue
                }
            }
            return defaultValue
        }
        set {
            do {
                let encoded = try JSONEncoder().encode(newValue)
                UserDefaults.standard.set(encoded, forKey: key)
            } catch {
                print("Error codificando \(key): \(error)")
            }
        }
    }
}

class CurrencySettings: ObservableObject {
    internal static var sharedInstance: CurrencySettings?
    
    static var shared: CurrencySettings {
        if sharedInstance == nil {
            sharedInstance = CurrencySettings()
        }
        return sharedInstance!
    }
    
    @Published private(set) var selectedCurrency: Currency = .usd {
        didSet {
            objectWillChange.send()
        }
    }
    @Published private(set) var customCurrencies: [CustomCurrency] = []
    
    @UserDefault("selectedCurrency", defaultValue: "USD")
    private var selectedCurrencyCode: String {
        didSet {
            updateSelectedCurrency()
        }
    }
    
    @UserDefault("customCurrencies", defaultValue: [CustomCurrency]())
    private var storedCustomCurrencies: [CustomCurrency] {
        didSet {
            customCurrencies = storedCustomCurrencies
            objectWillChange.send()
        }
    }
    
    private init() {
        customCurrencies = storedCustomCurrencies
        updateSelectedCurrency()
    }
    
    private func updateSelectedCurrency() {
        let newCurrency: Currency
        if let customCurrency = customCurrencies.first(where: { $0.code == selectedCurrencyCode }) {
            newCurrency = .custom(customCurrency)
        } else if let currency = Currency.allCases.first(where: { $0.rawValue == selectedCurrencyCode }) {
            newCurrency = currency
        } else {
            newCurrency = .usd
        }
        
        if selectedCurrency != newCurrency {
            selectedCurrency = newCurrency
            objectWillChange.send()
        }
    }
    
    func updateCurrency(_ currency: Currency) {
        selectedCurrencyCode = currency.rawValue
        objectWillChange.send()
    }
    
    func addCustomCurrency(name: String, code: String, symbol: String) {
        let newCurrency = CustomCurrency(name: name, code: code, symbol: symbol)
        storedCustomCurrencies.append(newCurrency)
    }
    
    func removeCustomCurrency(_ currency: CustomCurrency) {
        storedCustomCurrencies.removeAll { $0.code == currency.code }
        if case .custom(let selectedCustom) = selectedCurrency, selectedCustom.code == currency.code {
            updateCurrency(.usd)
        }
    }
    
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = selectedCurrency.symbol
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(selectedCurrency.symbol)\(amount)"
    }
} 