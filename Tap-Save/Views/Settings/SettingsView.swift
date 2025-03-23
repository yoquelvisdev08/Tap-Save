import SwiftUI
import SwiftData

// Estructura para manejar los colores de la aplicación
struct AppColors {
    static let colors: [Color] = [
        Color(hex: "#FF6B6B"),
        Color(hex: "#4ECDC4"),
        Color(hex: "#45B7D1"),
        Color(hex: "#96CEB4"),
        Color(hex: "#FFEEAD"),
        Color(hex: "#D4A5A5"),
        Color(hex: "#9B5DE5"),
        Color(hex: "#00BBF9"),
        Color(hex: "#00F5D4"),
        Color(hex: "#FEE440")
    ]
    
    static let descriptions = [
        "Coral",
        "Turquesa",
        "Azul cielo",
        "Verde menta",
        "Amarillo pastel",
        "Rosa antiguo",
        "Púrpura",
        "Azul brillante",
        "Turquesa brillante",
        "Amarillo brillante"
    ]
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var currencySettings = CurrencySettings.shared
    
    var body: some View {
        NavigationStack {
            List {
                generalSection
                exportSection
                aboutSection
            }
            .navigationTitle("Ajustes")
        }
    }
    
    private var generalSection: some View {
        Section {
            NavigationLink {
                CurrencySettingsView()
            } label: {
                HStack {
                    Label("Moneda", systemImage: "dollarsign.circle")
                    Spacer()
                    Text(currencySettings.selectedCurrency.symbol)
                        .foregroundStyle(.secondary)
                }
            }
            
            NavigationLink {
                CategoriesView()
            } label: {
                Label("Categorías", systemImage: "folder")
            }
        } header: {
            Text("General")
        }
    }
    
    private var exportSection: some View {
        Section("Exportar Datos") {
            Button(action: {
                // TODO: Implementar exportación
            }) {
                Label("Exportar a CSV", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    private var aboutSection: some View {
        Section("Acerca de") {
            LabeledContent("Versión", value: "1.0.0")
            Link(destination: URL(string: "https://github.com/yourusername/TapAndSave")!) {
                Label("Código Fuente", systemImage: "swift")
            }
        }
    }
}

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var isShowingAddCategory = false
    @State private var newCategoryName = ""
    @State private var selectedIcon = "folder"
    @State private var editingCategory: Category? = nil
    
    // Separar categorías por defecto y personalizadas
    private var defaultCategories: [Category] {
        let cats = categories.filter { $0.isDefault }
        print("Categorías por defecto: \(cats.count)")
        for cat in cats {
            print("Defecto: \(cat.name), isDefault: \(cat.isDefault)")
        }
        return cats
    }
    
    private var customCategories: [Category] {
        let cats = categories.filter { !$0.isDefault }
        print("Categorías personalizadas: \(cats.count)")
        for cat in cats {
            print("Personalizada: \(cat.name), isDefault: \(cat.isDefault)")
        }
        return cats
    }
    
    var body: some View {
        List {
            Section(header: Text("Categorías por defecto")) {
                ForEach(defaultCategories) { category in
                    CategoryRow(category: category)
                        .contextMenu {
                            Text("No se puede eliminar")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            
            Section(header: Text("Categorías personalizadas")) {
                if customCategories.isEmpty {
                    Text("No hay categorías personalizadas")
                        .foregroundStyle(.secondary)
                        .italic()
                }
                
                ForEach(customCategories) { category in
                    CategoryRow(category: category)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = category
                        }
                        .contextMenu {
                            Button {
                                editingCategory = category
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                        }
                }
                .onDelete(perform: deleteCustomCategories)
            }
        }
        .navigationTitle("Categorías")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isShowingAddCategory = true }) {
                    Label("Agregar", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddCategory) {
            NavigationStack {
                CategoryEditorView(isNewCategory: true)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingCategory) { category in
            NavigationStack {
                CategoryEditorView(category: category)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // Eliminación solo para categorías personalizadas
    private func deleteCustomCategories(at offsets: IndexSet) {
        withAnimation {
            let categoriesToDelete = offsets.map { customCategories[$0] }
            for category in categoriesToDelete {
                modelContext.delete(category)
            }
        }
    }
}

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let category: Category?
    let isNewCategory: Bool
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "folder"
    
    init(category: Category? = nil, isNewCategory: Bool = false) {
        self.category = category
        self.isNewCategory = isNewCategory
        
        // Inicializar los valores de estado
        if let category = category {
            _name = State(initialValue: category.name)
            _selectedIcon = State(initialValue: category.icon)
        }
    }
    
    var body: some View {
        Form {
            Section("Información") {
                TextField("Nombre", text: $name)
                SFSymbolsPicker(selectedIcon: $selectedIcon)
            }
        }
        .navigationTitle(isNewCategory ? "Nueva Categoría" : "Editar Categoría")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    saveCategory()
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
    
    private func saveCategory() {
        if let category = category {
            // Editar categoría existente
            category.name = name
            category.icon = selectedIcon
        } else {
            // Crear nueva categoría
            let newCategory = Category(name: name, icon: selectedIcon, isDefault: false)
            modelContext.insert(newCategory)
        }
    }
}

struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        HStack {
            if category.icon.count <= 2 || category.icon.unicodeScalars.allSatisfy({ $0.properties.isEmoji }) {
                Text(category.icon)
                    .font(.system(size: 18))
                    .frame(width: 30)
            } else {
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 30)
            }
            
            Text(category.name)
            
            Spacer()
            Text("\(category.expenses.count)")
                .foregroundStyle(.secondary)
        }
    }
}

struct SFSymbolsPicker: View {
    @Binding var selectedIcon: String
    
    private let commonSymbols = [
        "house", "car", "cart", "fork.knife", "heart",
        "gamecontroller", "bag", "creditcard", "gift",
        "airplane", "bus", "tram", "bicycle", "figure.walk",
        "pills", "cross", "bandage", "stethoscope",
        "book", "graduationcap", "pencil", "folder",
        "wrench.and.screwdriver", "hammer", "screwdriver",
        "phone", "envelope", "wifi", "network",
        "music.note", "theatermasks.fill", "ticket", "film",
        "dog", "cat", "leaf", "tree", "mountain.2"
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                ForEach(commonSymbols, id: \.self) { symbol in
                    Image(systemName: symbol)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background {
                            if symbol == selectedIcon {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor.opacity(0.2))
                            }
                        }
                        .onTapGesture {
                            selectedIcon = symbol
                        }
                }
            }
            .padding(.vertical)
        }
        .frame(maxHeight: 200)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Category.self, inMemory: true)
} 