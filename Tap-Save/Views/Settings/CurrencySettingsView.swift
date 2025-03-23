import SwiftUI

struct CurrencySettingsView: View {
    @StateObject private var settings = CurrencySettings.shared
    @State private var showingAddCurrency = false
    @State private var newCurrencyName = ""
    @State private var newCurrencyCode = ""
    @State private var newCurrencySymbol = ""
    @State private var showingDeleteAlert = false
    @State private var currencyToDelete: CustomCurrency?
    
    var body: some View {
        List {
            Section {
                ForEach(Currency.allCases) { currency in
                    CurrencyRow(currency: currency, isSelected: settings.selectedCurrency == currency)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                settings.updateCurrency(currency)
                            }
                        }
                }
            } header: {
                Text("Moneda predeterminada")
            } footer: {
                Text("La moneda seleccionada se utilizará en toda la aplicación para mostrar los montos.")
            }
            
            if !settings.customCurrencies.isEmpty {
                Section("Monedas personalizadas") {
                    ForEach(settings.customCurrencies) { currency in
                        CurrencyRow(currency: .custom(currency), isSelected: settings.selectedCurrency == .custom(currency))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    settings.updateCurrency(.custom(currency))
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if case .custom(let selectedCustom) = settings.selectedCurrency, selectedCustom == currency {
                                    Text("No se puede eliminar la moneda seleccionada")
                                        .tint(.gray)
                                } else {
                                    Button(role: .destructive) {
                                        currencyToDelete = currency
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Moneda")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddCurrency = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCurrency) {
            NavigationView {
                Form {
                    TextField("Nombre (ej: Peso argentino)", text: $newCurrencyName)
                    TextField("Código (ej: ARS)", text: $newCurrencyCode)
                        .textInputAutocapitalization(.characters)
                    TextField("Símbolo (ej: $)", text: $newCurrencySymbol)
                }
                .navigationTitle("Nueva moneda")
                .navigationBarItems(
                    leading: Button("Cancelar") {
                        showingAddCurrency = false
                    },
                    trailing: Button("Guardar") {
                        if !newCurrencyName.isEmpty && !newCurrencyCode.isEmpty && !newCurrencySymbol.isEmpty {
                            settings.addCustomCurrency(
                                name: newCurrencyName,
                                code: newCurrencyCode.uppercased(),
                                symbol: newCurrencySymbol
                            )
                            newCurrencyName = ""
                            newCurrencyCode = ""
                            newCurrencySymbol = ""
                            showingAddCurrency = false
                        }
                    }
                    .disabled(newCurrencyName.isEmpty || newCurrencyCode.isEmpty || newCurrencySymbol.isEmpty)
                )
            }
        }
        .alert("Eliminar moneda", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                if let currency = currencyToDelete {
                    settings.removeCustomCurrency(currency)
                }
            }
        } message: {
            Text("¿Estás seguro de que deseas eliminar esta moneda? Esta acción no se puede deshacer.")
        }
    }
}

struct CurrencyRow: View {
    let currency: Currency
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(currency.name)
                Text("\(currency.symbol) \(currency.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
            }
        }
    }
} 