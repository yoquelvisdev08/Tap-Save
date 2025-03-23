//
//  Category.swift
//  Tap-Save
//
//  Created by Yoquelvis abreu on 21/3/25.
//

import SwiftUI
import SwiftData

@Model
final class Category {
    var name: String
    var icon: String
    var color: String
    var isDefault: Bool = false
    @Relationship(deleteRule: .cascade) var expenses: [Expense] = []
    
    init(name: String, icon: String, color: String = "#4ECDC4", isDefault: Bool = false) {
        self.name = name
        self.icon = icon
        self.color = color
        self.isDefault = isDefault
        self.expenses = []
    }
    
    var categoryColor: Color {
        Color(hex: color)
    }
    
    static var defaultCategories: [Category] {
        [
            Category(name: "Entretenimiento", icon: "🎮", isDefault: true),
            Category(name: "Otros", icon: "⚙️", isDefault: true),
            Category(name: "Comida", icon: "🍽️", isDefault: true),
            Category(name: "Salud", icon: "❤️", isDefault: true),
            Category(name: "Transporte", icon: "🚗", isDefault: true),
            Category(name: "Casa", icon: "🏠", isDefault: true),
            Category(name: "Compras", icon: "🛒", isDefault: true),
            Category(name: "Servicios", icon: "🔧", isDefault: true)
        ]
    }
}

// Extensión para manejar el color
extension Category {
    // Aquí puedes agregar más funcionalidad relacionada con colores si es necesario
}

