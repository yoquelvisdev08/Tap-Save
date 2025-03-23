import SwiftUI
import SwiftData

struct ExpenseFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilter: ExpenseListView.ExpenseFilter
    @Query private var categories: [Category]
    @StateObject private var currencySettings = CurrencySettings.shared
    
    // Rangos predefinidos de montos
    var amountRanges: [(String, ClosedRange<Double>)] {
        [
            ("\(currencySettings.selectedCurrency.symbol)0 - \(currencySettings.selectedCurrency.symbol)50", 0...50),
            ("\(currencySettings.selectedCurrency.symbol)51 - \(currencySettings.selectedCurrency.symbol)100", 51...100),
            ("\(currencySettings.selectedCurrency.symbol)101 - \(currencySettings.selectedCurrency.symbol)500", 101...500),
            ("\(currencySettings.selectedCurrency.symbol)501+", 501...10000)
        ]
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Categorías") {
                    Button {
                        selectedFilter = .all
                        dismiss()
                    } label: {
                        HStack {
                            Label("Todas", systemImage: "list.bullet")
                            Spacer()
                            if case .all = selectedFilter {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    ForEach(categories) { category in
                        Button {
                            selectedFilter = .category(category)
                            dismiss()
                        } label: {
                            HStack {
                                if category.icon.count <= 2 || category.icon.unicodeScalars.allSatisfy({ $0.properties.isEmoji }) {
                                    Label {
                                        Text(category.name)
                                    } icon: {
                                        Text(category.icon)
                                            .font(.system(size: 18))
                                    }
                                } else {
                                    Label {
                                        Text(category.name)
                                    } icon: {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.primary)
                                    }
                                }
                                
                                Spacer()
                                
                                if case .category(let selectedCategory) = selectedFilter,
                                   selectedCategory.id == category.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Rango de Monto") {
                    ForEach(amountRanges, id: \.0) { name, range in
                        Button {
                            selectedFilter = .amount(range)
                            dismiss()
                        } label: {
                            HStack {
                                Text(name)
                                Spacer()
                                if case .amount(let selectedRange) = selectedFilter,
                                   selectedRange == range {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Category.self, configurations: config)
    
    // Crear y configurar las categorías
    let category1 = Category(name: "Comida", icon: "fork.knife", color: "#FF6B6B")
    let category2 = Category(name: "Transporte", icon: "car.fill", color: "#4ECDC4")
    container.mainContext.insert(category1)
    container.mainContext.insert(category2)
    
    return NavigationStack {
        ExpenseFilterView(selectedFilter: .constant(.all))
    }
    .modelContainer(container)
} 