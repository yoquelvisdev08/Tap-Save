import Foundation
import SwiftData

@Model
class SavingGoal {
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var icon: String
    var color: String
    var notes: String?
    var createdAt: Date
    var isCompleted: Bool
    
    init(
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        deadline: Date? = nil,
        icon: String = "star.fill",
        color: String = "#4ECDC4",
        notes: String? = nil,
        isCompleted: Bool = false
    ) {
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.icon = icon
        self.color = color
        self.notes = notes
        self.createdAt = Date()
        self.isCompleted = isCompleted
    }
    
    var progress: Double {
        if targetAmount <= 0 {
            return 0
        }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var remainingAmount: Double {
        max(targetAmount - currentAmount, 0)
    }
    
    var isOverdue: Bool {
        guard let deadline = deadline else { return false }
        return !isCompleted && Date() > deadline
    }
    
    var daysRemaining: Int? {
        guard let deadline = deadline else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: deadline)
        return components.day
    }
} 