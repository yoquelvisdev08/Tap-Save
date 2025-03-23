//
//  Budget.swift
//  Tap-Save
//
//  Created by Yoquelvis abreu on 21/3/25.
//

import Foundation
import SwiftData

@Model
final class Budget {
    @Attribute(.unique) var id: String
    var amount: Double
    var period: BudgetPeriod
    var category: Category?
    var startDate: Date
    
    init(amount: Double, period: BudgetPeriod = .monthly, category: Category? = nil, startDate: Date = Date()) {
        self.id = UUID().uuidString
        self.amount = amount
        self.period = period
        self.category = category
        self.startDate = startDate
    }
}

// Período del presupuesto
enum BudgetPeriod: String, Codable, CaseIterable {
    case weekly = "Semanal"
    case monthly = "Mensual"
    case yearly = "Anual"
}

