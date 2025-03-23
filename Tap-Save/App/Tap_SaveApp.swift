//
//  Tap_SaveApp.swift
//  Tap-Save
//
//  Created by Yoquelvis abreu on 21/3/25.
//

import SwiftUI
import SwiftData

@main
struct Tap_SaveApp: App {
    let container: ModelContainer
    
    init() {
        // Configurar el contenedor de SwiftData
        let schema = Schema([
            Expense.self,
            Category.self,
            Budget.self,
            SavingGoal.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Inicializar categorías por defecto directamente
            initializeDefaultCategories()
        } catch {
            fatalError("Could not configure container: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
    
    private func initializeDefaultCategories() {
        let context = container.mainContext
        
        print("Iniciando verificación de categorías por defecto...")
        
        // Primero, verificamos si hay categorías existentes con el mismo nombre para evitar duplicados
        let allCategoriesDescriptor = FetchDescriptor<Category>()
        if let allCategories = try? context.fetch(allCategoriesDescriptor) {
            // Agrupar categorías por nombre
            var categoriesByName = [String: [Category]]()
            for category in allCategories {
                if categoriesByName[category.name] == nil {
                    categoriesByName[category.name] = []
                }
                categoriesByName[category.name]?.append(category)
            }
            
            // Eliminar duplicados (mantener solo uno de cada nombre)
            for (name, categories) in categoriesByName {
                if categories.count > 1 {
                    print("Encontrados \(categories.count) duplicados para la categoría: \(name)")
                    
                    // Mantener solo la primera categoría, eliminar el resto
                    let toKeep = categories.first!
                    toKeep.isDefault = Category.defaultCategories.contains { $0.name == name }
                    
                    for category in categories.dropFirst() {
                        print("Eliminando duplicado: \(category.name)")
                        context.delete(category)
                    }
                }
            }
            
            // Guardar cambios después de eliminar duplicados
            try? context.save()
            
            // Los nombres de las categorías por defecto
            let defaultNames = Set(Category.defaultCategories.map { $0.name })
            
            // Verificar cada categoría y corregir si necesario
            for category in allCategories {
                // Si el nombre coincide con una categoría por defecto pero no está marcada como tal
                if defaultNames.contains(category.name) && !category.isDefault {
                    print("Corrigiendo categoría que debería ser por defecto: \(category.name)")
                    category.isDefault = true
                }
                
                // Depuración
                print("Categoría en DB: \(category.name), isDefault: \(category.isDefault)")
            }
            
            // Guardar cambios
            try? context.save()
        }
        
        // Verificar si ya existen categorías por defecto
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.isDefault == true })
        let existingDefaultCategories = try? context.fetch(descriptor)
        
        print("Categorías por defecto existentes: \(existingDefaultCategories?.count ?? 0)")
        
        // Crear un conjunto de nombres de categorías por defecto existentes
        let existingDefaultNames = Set(existingDefaultCategories?.map { $0.name } ?? [])
        
        // Crear solo las categorías por defecto que faltan
        for defaultCategory in Category.defaultCategories {
            if !existingDefaultNames.contains(defaultCategory.name) {
                print("Agregando categoría por defecto faltante: \(defaultCategory.name)")
                context.insert(defaultCategory)
            }
        }
        
        // Guardar cambios
        do {
            try context.save()
            print("Categorías por defecto verificadas y actualizadas correctamente")
        } catch {
            print("Error al guardar categorías por defecto: \(error.localizedDescription)")
        }
    }
}
