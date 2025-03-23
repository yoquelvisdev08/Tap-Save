//
//  ExpenseRowView.swift
//  Tap-Save
//
//  Created by Yoquelvis abreu on 21/3/25.
//

import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            // Icono de categoría
            if let category = expense.category {
                Image(systemName: category.icon)
                    .foregroundStyle(category.categoryColor)
                    .font(.title2)
                    .frame(width: 32)
            } else {
                Image(systemName: "tag")
                    .foregroundStyle(.gray)
                    .font(.title2)
                    .frame(width: 32)
            }
            
            // Detalles del gasto
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category?.name ?? "Sin categoría")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let notes = expense.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Monto y fecha
            VStack(alignment: .trailing, spacing: 4) {
                Text(expense.formattedAmount)
                    .font(.headline)
                Text(expense.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let category = Category(name: "Comida", icon: "fork.knife", color: "red")
    let expense = Expense(amount: 25.50, notes: "Almuerzo", category: category)
    
    return ExpenseRowView(expense: expense)
        .padding()
}

