//
//  ContentView.swift
//  Tap-Save
//
//  Created by Yoquelvis Abreu on 21/3/25.
//

import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [Expense]
    @Query private var categories: [Category]
    @State private var isShowingAddExpense = false
    @State private var newExpenseAmount: Double = 0
    @State private var selectedCategory: Category?
    @State private var notes: String = ""
    @State private var editingExpense: Expense?
    @State private var editExpenseAmount: Double = 0
    @State private var editCategory: Category?
    @State private var editNotes: String = ""
    @State private var isShowingEditExpense = false
    @State private var isShowingAddCategory = false
    @State private var isShowingDeleteConfirmation = false
    @State private var newCategoryName = ""
    @State private var selectedIcon = "tag"
    @State private var selectedColor = Color.blue
    @State private var hasSeenOnboarding = false
    @State private var selectedTab = 0
    
    // Paleta de colores moderna
    private let appColors = [
        Color(hex: "#FF6B6B"), // Coral
        Color(hex: "#4ECDC4"), // Turquesa
        Color(hex: "#45B7D1"), // Azul cielo
        Color(hex: "#96CEB4"), // Verde menta
        Color(hex: "#FFEEAD"), // Amarillo pastel
        Color(hex: "#D4A5A5"), // Rosa antiguo
        Color(hex: "#9B5DE5"), // Púrpura
        Color(hex: "#00BBF9"), // Azul brillante
        Color(hex: "#00F5D4"), // Turquesa brillante
        Color(hex: "#FEE440")  // Amarillo brillante
    ]
    
    // Iconos modernos y significativos
    private let availableIcons = [
        "banknote", "cart.fill", "house.fill", "car.fill", "airplane.departure",
        "tram.fill", "fork.knife", "cup.and.saucer.fill", "gift.fill", "heart.fill",
        "cross.case.fill", "pills.fill", "creditcard.fill", "gamecontroller.fill",
        "theatermasks.fill", "bag.fill", "books.vertical.fill", "graduationcap.fill",
        "scissors", "paintbrush.fill", "hammer.fill", "wrench.and.screwdriver.fill",
        "leaf.fill", "pawprint.fill", "figure.run", "dumbbell.fill",
        "person.2.fill", "music.note", "tv.fill", "iphone"
    ]

    var body: some View {
        Group {
            if hasSeenOnboarding {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        List {
                            ForEach(expenses) { expense in
                                ExpenseRow(expense: expense)
                                    .transition(.asymmetric(
                                        insertion: .push(from: .trailing).combined(with: .opacity),
                                        removal: .push(from: .leading).combined(with: .opacity)
                                    ))
                            }
                            .onDelete { indexSet in
                                withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                                    deleteExpenses(at: indexSet)
                                }
                            }
                        }
                        .navigationTitle("Gastos")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    withAnimation(.spring(duration: 0.3)) {
                                        isShowingAddExpense = true
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .symbolEffect(.bounce, value: isShowingAddExpense)
                                }
                            }
                        }
                    }
                    .tabItem {
                        Label("Gastos", systemImage: "list.bullet")
                            .symbolEffect(.bounce, value: selectedTab == 0)
                    }
                    .tag(0)
                    
                    NavigationStack {
                        SavingGoalsView()
                            .transition(.move(edge: .trailing))
                    }
                    .tabItem {
                        Label("Metas", systemImage: "star.fill")
                            .symbolEffect(.bounce, value: selectedTab == 1)
                    }
                    .tag(1)
                    
                    NavigationStack {
                        StatisticsView(expenses: expenses)
                            .transition(.move(edge: .trailing))
                    }
                    .tabItem {
                        Label("Estadísticas", systemImage: "chart.pie.fill")
                            .symbolEffect(.bounce, value: selectedTab == 2)
                    }
                    .tag(2)
                    
                    NavigationStack {
                        BudgetView()
                            .transition(.move(edge: .trailing))
                    }
                    .tabItem {
                        Label("Presupuestos", systemImage: "chart.bar.fill")
                            .symbolEffect(.bounce, value: selectedTab == 3)
                    }
                    .tag(3)
                    
                    NavigationStack {
                        SettingsView()
                            .transition(.move(edge: .trailing))
                    }
                    .tabItem {
                        Label("Ajustes", systemImage: "gear")
                            .symbolEffect(.bounce, value: selectedTab == 4)
                    }
                    .tag(4)
                }
                .sheet(isPresented: $isShowingAddExpense) {
                    NavigationStack {
                        ExpenseFormView(expense: nil)
                            .transition(.move(edge: .bottom))
                    }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled()
                }
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(duration: 0.3), value: hasSeenOnboarding)
    }
    
    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            let expense = expenses[index]
            modelContext.delete(expense)
        }
    }
}

// MARK: - ExpenseRow
struct ExpenseRow: View {
    let expense: Expense
    @StateObject private var currencySettings = CurrencySettings.shared
    @State private var isEditing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono de categoría
            ZStack {
                // Eliminamos todos los círculos de fondo
                
                if let iconName = expense.category?.icon {
                    // Verificar si es un emoji (generalmente solo 1-2 caracteres) o nombre de SF Symbol
                    if iconName.count <= 2 || iconName.unicodeScalars.allSatisfy({ $0.properties.isEmoji }) {
                        Text(iconName)
                            .font(.system(size: 22))
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                } else {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.gray)
                }
            }
            .frame(width: 42, height: 42)
            
            // Detalles del gasto
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category?.name ?? "Sin categoría")
                    .font(.headline)
                
                if let notes = expense.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Monto y fecha
            VStack(alignment: .trailing, spacing: 4) {
                Text(currencySettings.formatAmount(expense.amount))
                    .font(.headline)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            isEditing = true
        }
        .contextMenu {
            Button {
                isEditing = true
            } label: {
                Label("Editar", systemImage: "pencil")
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                ExpenseFormView(expense: expense)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

struct ExpenseFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let expense: Expense?
    
    @State private var amount: Double = 0
    @State private var category: Category?
    @State private var notes: String = ""
    @Query private var categories: [Category]
    @StateObject private var currencySettings = CurrencySettings.shared
    
    var title: String {
        expense == nil ? "Nuevo Gasto" : "Editar Gasto"
    }

    var body: some View {
        Form {
            Section("Monto") {
                HStack {
                    Text(currencySettings.selectedCurrency.symbol)
                        .foregroundStyle(.secondary)
                    TextField("Monto", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            
            Section("Categoría") {
                if categories.isEmpty {
                    Text("No hay categorías disponibles")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Seleccionar categoría", selection: $category) {
                        Text("Sin categoría").tag(nil as Category?)
                        ForEach(categories) { category in
                            HStack {
                                ZStack {
                                    // Eliminamos todos los círculos de fondo
                                    
                                    if category.icon.count <= 2 || category.icon.unicodeScalars.allSatisfy({ $0.properties.isEmoji }) {
                                        Text(category.icon)
                                            .font(.system(size: 16))
                                    } else {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .frame(width: 30, height: 30)
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                }
            }
            
            Section("Notas") {
                TextField("Notas (opcional)", text: $notes)
                    .onChange(of: notes) { oldValue, newValue in
                        if newValue.count > 100 {
                            notes = String(newValue.prefix(100))
                        }
                    }
                Text("\(notes.count)/100 caracteres")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
            .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    withAnimation {
                        saveExpense()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let expense = expense {
                amount = expense.amount
                category = expense.category
                notes = expense.notes ?? ""
            }
        }
    }
    
    private func saveExpense() {
        if let expense = expense {
            // Editar gasto existente
            expense.amount = amount
            expense.category = category
            expense.notes = notes.isEmpty ? nil : notes
        } else {
            // Crear nuevo gasto
            let newExpense = Expense(
                amount: amount,
                notes: notes.isEmpty ? nil : notes,
                category: category
            )
            modelContext.insert(newExpense)
        }
    }
}

// Vista de onboarding
struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    
    var body: some View {
        TabView {
            OnboardingPage(
                title: "Bienvenido a Tap-Save",
                subtitle: "La forma más fácil de controlar tus gastos",
                image: "banknote.fill",
                color: Color(hex: "#4ECDC4")
            )
            
            OnboardingPage(
                title: "Organiza tus Gastos",
                subtitle: "Crea categorías personalizadas para clasificar tus gastos",
                image: "folder.fill.badge.plus",
                color: Color(hex: "#9B5DE5")
            )
            
            OnboardingPage(
                title: "Visualiza tus Datos",
                subtitle: "Obtén insights valiosos con gráficos y estadísticas",
                image: "chart.pie.fill",
                color: Color(hex: "#FF6B6B")
            ) {
                VStack(spacing: 16) {
                    Button("Comenzar") {
        withAnimation {
                            hasSeenOnboarding = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#4ECDC4"))
                    .font(.headline)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .shadow(radius: 5)
                }
                .padding(.bottom, 40)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
    }
}

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let image: String
    let color: Color
    let content: (() -> AnyView)?
    
    init(
        title: String,
        subtitle: String,
        image: String,
        color: Color
    ) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.color = color
        self.content = nil
    }
    
    init(
        title: String,
        subtitle: String,
        image: String,
        color: Color,
        @ViewBuilder content: @escaping () -> some View
    ) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.color = color
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        ZStack {
            color.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: image)
                    .font(.system(size: 80))
                    .foregroundStyle(color)
                    .symbolEffect(.bounce.byLayer, options: .speed(0.5), value: title)
                    .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 16) {
                    Text(title)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                }
                
                if let content {
                    content()
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

// Tarjeta de estadísticas
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

// Extensión para crear colores desde hexadecimal
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    do {
        let schema = Schema([
            Expense.self,
            Category.self,
            Budget.self,
            SavingGoal.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        return ContentView()
            .modelContainer(container)
    } catch {
        return Text("Error al cargar preview: \(error.localizedDescription)")
    }
}
