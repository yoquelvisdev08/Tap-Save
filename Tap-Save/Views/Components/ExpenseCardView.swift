import SwiftUI

struct ExpenseCardView: View {
    let expense: Expense
    @State private var isPressed = false
    @State private var isEditing = false
    @StateObject private var currencySettings = CurrencySettings.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Icono de categoría
            ZStack {
                // Eliminamos todos los círculos de fondo
                
                if let iconName = expense.category?.icon {
                    if iconName.count <= 2 || iconName.unicodeScalars.allSatisfy({ $0.properties.isEmoji }) {
                        Text(iconName)
                            .font(.system(size: 22))
                            .symbolEffect(.bounce, value: isPressed)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary) // Default to primary color for SF Symbols
                            .symbolEffect(.bounce, value: isPressed)
                    }
                } else {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.gray)
                        .symbolEffect(.bounce, value: isPressed)
                }
            }
            .frame(width: 42, height: 42)
            
            // Detalles
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category?.name ?? "Sin categoría")
                    .font(.headline)
                
                if let notes = expense.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Text(expense.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Monto
            Text(currencySettings.formatAmount(expense.amount))
                .font(.headline)
                .foregroundStyle(expense.amount > 100 ? .red : .primary)
        }
        .padding()
        .background(.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(duration: 0.2)) {
                isPressed.toggle()
                isEditing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPressed = false
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                ExpenseFormView(expense: expense)
            }
        }
    }
}
