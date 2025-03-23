import SwiftUI
import SwiftData

struct SavingGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [SavingGoal]
    @State private var isAddingGoal = false
    @State private var selectedGoal: SavingGoal?
    @State private var isEditingGoal = false
    @State private var showingConfetti = false
    @StateObject private var currencySettings = CurrencySettings.shared
    
    var body: some View {
        ScrollView {
            // Header con resumen
            VStack(spacing: 16) {
                // Tarjeta de resumen
                SavingsSummaryCard(goals: goals)
                    .padding(.horizontal)
                
                // Lista de metas
                LazyVStack(spacing: 16) {
                    if goals.isEmpty {
                        EmptyGoalsView()
                    } else {
                        ForEach(goals) { goal in
                            SavingGoalCard(goal: goal, onTap: {
                                selectedGoal = goal
                                isEditingGoal = true
                            })
                            .padding(.horizontal)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .padding(.top)
        }
        .overlay(alignment: .bottom) {
            Button(action: {
                isAddingGoal = true
            }) {
                Label("Nueva Meta", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#4ECDC4"))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 5, y: 3)
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationTitle("Metas de Ahorro")
        .confettiCelebration(isShowing: $showingConfetti)
        .sheet(isPresented: $isAddingGoal) {
            NavigationStack {
                SavingGoalFormView(goal: nil, onSave: { _ in
                    // Mostrar confetti cuando se crea una meta
                    withAnimation(.spring(duration: 0.5)) {
                        showingConfetti = true
                    }
                    
                    // Apagar confetti después de 3 segundos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showingConfetti = false
                    }
                })
            }
        }
        .sheet(isPresented: $isEditingGoal, onDismiss: {
            selectedGoal = nil
        }) {
            if let goal = selectedGoal {
                NavigationStack {
                    SavingGoalFormView(goal: goal, onSave: { updatedGoal in
                        // Si se completó, mostrar confetti
                        if updatedGoal.isCompleted && !goal.isCompleted {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    showingConfetti = true
                                }
                                
                                // Apagar confetti después de 3 segundos
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showingConfetti = false
                                }
                            }
                        }
                    })
                }
            }
        }
    }
}

// MARK: - Componentes de la vista

struct SavingsSummaryCard: View {
    let goals: [SavingGoal]
    @StateObject private var currencySettings = CurrencySettings.shared
    
    var totalSaved: Double {
        goals.reduce(0) { $0 + $1.currentAmount }
    }
    
    var totalGoals: Double {
        goals.reduce(0) { $0 + $1.targetAmount }
    }
    
    var overallProgress: Double {
        if totalGoals <= 0 { return 0 }
        return min(totalSaved / totalGoals, 1.0)
    }
    
    var completedGoals: Int {
        goals.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Título de la tarjeta
            Text("Resumen de ahorro")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            // Información de ahorro
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ahorrado")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(currencySettings.formatAmount(totalSaved))
                        .font(.title2.bold())
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Meta total")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(currencySettings.formatAmount(totalGoals))
                        .font(.title2.bold())
                }
            }
            
            // Barra de progreso
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: overallProgress)
                    .tint(Color(hex: "#4ECDC4"))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                
                HStack {
                    Text("\(Int(overallProgress * 100))% completado")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(completedGoals) de \(goals.count) metas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct SavingGoalCard: View {
    let goal: SavingGoal
    let onTap: () -> Void
    @StateObject private var currencySettings = CurrencySettings.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Icono con color personalizado
                    ZStack {
                        Circle()
                            .fill(Color(hex: goal.color).opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        if goal.icon.count <= 2 || goal.icon.unicodeScalars.allSatisfy({ $0.properties.isEmoji }) {
                            Text(goal.icon)
                                .font(.system(size: 18))
                        } else {
                            Image(systemName: goal.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color(hex: goal.color))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if let daysRemaining = goal.daysRemaining, daysRemaining >= 0 {
                            Text("\(daysRemaining) días restantes")
                                .font(.caption)
                                .foregroundStyle(daysRemaining < 7 ? .orange : .secondary)
                        } else if goal.isOverdue {
                            Text("Vencida")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    Spacer()
                    
                    // Badges para estado
                    if goal.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .symbolEffect(.pulse, options: .repeating, value: goal.isCompleted)
                    }
                }
                
                // Progreso y montos
                VStack(alignment: .leading, spacing: 8) {
                    // Barra de progreso con brillo cuando está completa
                    ProgressView(value: goal.progress)
                        .tint(goal.isCompleted ? .green : Color(hex: goal.color))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    
                    HStack {
                        Text("\(Int(goal.progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(currencySettings.formatAmount(goal.currentAmount)) de \(currencySettings.formatAmount(goal.targetAmount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Nota opcional
                if let notes = goal.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(LinearGradient(
                        colors: [
                            Color(hex: goal.color).opacity(0.5),
                            Color(hex: goal.color).opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyGoalsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "#4ECDC4"))
                .symbolEffect(.pulse, options: .repeating)
            
            Text("No tienes metas de ahorro")
                .font(.title3.bold())
            
            Text("Crea tu primera meta para comenzar a ahorrar")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
} 