import SwiftUI
import SwiftData
import Charts

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var categories: [Category]
    @Query private var expenses: [Expense]
    @State private var isShowingAddBudget = false
    @State private var selectedCategory: Category?
    @State private var budgetAmount: Double = 0
    @State private var selectedPeriod: BudgetPeriod = .monthly
    
    var body: some View {
        List {
            if budgets.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Sin Presupuestos",
                        systemImage: "chart.bar.fill",
                        description: Text("Agrega un presupuesto para comenzar a controlar tus gastos")
                    )
                }
            } else {
                ForEach(budgets) { budget in
                    BudgetCard(budget: budget, expenses: expenses)
                }
                .onDelete(perform: deleteBudgets)
            }
        }
        .navigationTitle("Presupuestos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isShowingAddBudget = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .symbolEffect(.bounce, value: isShowingAddBudget)
                }
            }
        }
        .sheet(isPresented: $isShowingAddBudget) {
            NavigationStack {
                BudgetFormView(budget: nil)
            }
        }
    }
    
    private func deleteBudgets(at offsets: IndexSet) {
        for index in offsets {
            let budget = budgets[index]
            modelContext.delete(budget)
        }
    }
}

struct BudgetCard: View {
    let budget: Budget
    let expenses: [Expense]
    @State private var showAlert = false
    @State private var isEditing = false
    @StateObject private var currencySettings = CurrencySettings.shared
    @Environment(\.modelContext) private var modelContext
    
    var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch budget.period {
        case .weekly:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .yearly:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return expenses.filter { expense in
            if let category = budget.category {
                return expense.date >= startDate && expense.category?.id == category.id
            } else {
                return expense.date >= startDate
            }
        }
    }
    
    var totalSpent: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var progress: Double {
        min(totalSpent / budget.amount, 1.0)
    }
    
    var progressColor: Color {
        switch progress {
        case 0..<0.5:
            return .green
        case 0.5..<0.8:
            return .yellow
        default:
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Categoría
                if let category = budget.category {
                    Label {
                        Text(category.name)
                    } icon: {
                        Image(systemName: category.icon)
                            .foregroundStyle(category.categoryColor)
                    }
                } else {
                    Label("General", systemImage: "chart.pie.fill")
                }
                
                Spacer()
                
                // Período
                Text(budget.period.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Botón de editar
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            
            // Barra de progreso
            ProgressView(value: progress) {
                HStack {
                    Text(currencySettings.formatAmount(totalSpent))
                    Text("de")
                    Text(currencySettings.formatAmount(budget.amount))
                }
                .font(.caption)
            }
            .tint(progressColor)
            
            // Porcentaje
            HStack {
                Text("\(Int((progress * 100).rounded()))% utilizado")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if progress >= 1.0 {
                    Label("Límite excedido", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                BudgetFormView(budget: budget)
            }
        }
    }
}

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let budget: Budget?
    
    @State private var amount: Double
    @State private var category: Category?
    @State private var period: BudgetPeriod
    @Query private var categories: [Category]
    @StateObject private var currencySettings = CurrencySettings.shared
    
    init(budget: Budget?) {
        self.budget = budget
        _amount = State(initialValue: budget?.amount ?? 0)
        _category = State(initialValue: budget?.category)
        _period = State(initialValue: budget?.period ?? .monthly)
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
                Picker("Seleccionar categoría", selection: $category) {
                    Text("General").tag(nil as Category?)
                    ForEach(categories) { category in
                        Label(category.name, systemImage: category.icon)
                            .tag(category as Category?)
                    }
                }
            }
            
            Section("Período") {
                Picker("Seleccionar período", selection: $period) {
                    ForEach(BudgetPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
            }
        }
        .navigationTitle(budget == nil ? "Nuevo Presupuesto" : "Editar Presupuesto")
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
                        saveBudget()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveBudget() {
        if let budget = budget {
            // Editar presupuesto existente
            budget.amount = amount
            budget.category = category
            budget.period = period
        } else {
            // Crear nuevo presupuesto
            let newBudget = Budget(amount: amount, period: period, category: category)
            modelContext.insert(newBudget)
        }
    }
}

#Preview {
    NavigationStack {
        BudgetView()
            .modelContainer(for: [Budget.self, Category.self, Expense.self], inMemory: true)
    }
} 