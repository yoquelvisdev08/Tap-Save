import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var isShowingAddCategory = false
    @State private var newCategoryName = ""
    @State private var selectedEmoji = "🏷️"
    @State private var editingCategory: Category?
    
    let emojis = ["🏠", "🚗", "✈️", "🍽️", "🛒", "💊", "🎮", "🎭", "👕", "📚", "🎓", "✂️", "🎨", "🔧", "🌿", "🐾", "🏃", "💪", "👥", "🎵", "📺", "📱"]
    
    var body: some View {
        List {
            ForEach(categories) { category in
                HStack {
                    Text(category.icon)
                        .font(.title2)
                    
                    Text(category.name)
                    
                    Spacer()
                    
                    Button {
                        editingCategory = category
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("Categorías")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { isShowingAddCategory = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $isShowingAddCategory) {
            NavigationStack {
                CategoryFormView(category: nil)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingCategory) { category in
            NavigationStack {
                CategoryFormView(category: category)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            modelContext.delete(category)
        }
    }
}

struct CategoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let category: Category?
    
    @State private var name: String
    @State private var selectedEmoji: String
    
    let emojis = ["🏠", "🚗", "✈️", "🍽️", "🛒", "💊", "🎮", "🎭", "👕", "📚", "🎓", "✂️", "🎨", "🔧", "🌿", "🐾", "🏃", "💪", "👥", "🎵", "📺", "📱"]
    
    init(category: Category?) {
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _selectedEmoji = State(initialValue: category?.icon ?? "🏷️")
    }
    
    var body: some View {
        Form {
            Section("Nombre") {
                TextField("Nombre de la categoría", text: $name)
            }
            
            Section("Emoji") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(emojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.title2)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.clear)
                            )
                            .onTapGesture {
                                selectedEmoji = emoji
                            }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(category == nil ? "Nueva Categoría" : "Editar Categoría")
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
            category.icon = selectedEmoji
        } else {
            // Crear nueva categoría
            let newCategory = Category(name: name, icon: selectedEmoji)
            modelContext.insert(newCategory)
        }
    }
}

#Preview {
    NavigationStack {
        CategoryListView()
            .modelContainer(for: Category.self, inMemory: true)
    }
} 