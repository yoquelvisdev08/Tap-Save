//
//  Expense.swift
//  Tap-Save
//
//  Created by Yoquelvis abreu on 21/3/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Expense {
    var id: String
    var amount: Double
    var date: Date
    var notes: String?
    var category: Category?
    
    init(amount: Double, date: Date = Date(), notes: String? = nil, category: Category? = nil) {
        self.id = UUID().uuidString
        self.amount = amount
        self.date = date
        self.notes = notes
        self.category = category
    }
}

// Extensión para funcionalidad adicional
extension Expense {
    // Formateo de fecha
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
    
    // Formateo de monto
    var formattedAmount: String {
        CurrencySettings.shared.formatAmount(amount)
    }
}

