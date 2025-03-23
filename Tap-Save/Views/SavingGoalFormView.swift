import SwiftUI
import SwiftData

struct SavingGoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let goal: SavingGoal?
    var onSave: ((SavingGoal) -> Void)?
    
    @State private var name: String = ""
    @State private var targetAmountString: String = ""
    @State private var currentAmountString: String = ""
    @State private var notes: String = ""
    @State private var showDeadline: Bool = false
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedColor: String = "#4ECDC4"
    @State private var isCompleted: Bool = false
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    @StateObject private var currencySettings = CurrencySettings.shared
    
    private var targetAmount: Double {
        return Double(targetAmountString) ?? 0
    }
    
    private var currentAmount: Double {
        return Double(currentAmountString) ?? 0
    }
    
    // Colores predefinidos
    private let colorOptions = [
        "#4ECDC4", "#FF6B6B", "#9B5DE5", "#45B7D1", "#96CEB4", 
        "#FFEEAD", "#D4A5A5", "#00BBF9", "#00F5D4", "#FEE440"
    ]
    
    // Iconos predefinidos para metas
    private let iconOptions = [
        "star.fill", "house.fill", "car.fill", "airplane.departure", "graduationcap.fill",
        "gift.fill", "heart.fill", "bag.fill", "beach.umbrella.fill", "gamecontroller.fill",
        "laptopcomputer", "trophy.fill", "figure.walk", "person.2.fill", "train.side.front.car",
        "camera.fill", "microphone.fill", "bicycle", "globe.americas.fill", "paintbrush.fill",
        "dollarsign.circle.fill", "creditcard.fill", "banknote.fill", "sparkles", "wand.and.stars"
    ]
    
    var title: String {
        goal == nil ? "Nueva Meta" : "Editar Meta"
    }
    
    var progress: Double {
        if targetAmount <= 0 { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var body: some View {
        Form {
            Section("Información básica") {
                TextField("Nombre", text: $name)
                
                // Monto objetivo
                HStack {
                    Text(currencySettings.selectedCurrency.symbol)
                        .foregroundStyle(.secondary)
                    TextField("Monto objetivo", text: $targetAmountString)
                        .keyboardType(.decimalPad)
                }
                
                // Monto actual
                HStack {
                    Text(currencySettings.selectedCurrency.symbol)
                        .foregroundStyle(.secondary)
                    TextField("Monto actual", text: $currentAmountString)
                        .keyboardType(.decimalPad)
                        .onChange(of: currentAmountString) { _, newValue in
                            // Actualizar automáticamente el estado de completado
                            let newAmount = Double(newValue) ?? 0
                            if newAmount >= targetAmount && targetAmount > 0 {
                                isCompleted = true
                            } else {
                                isCompleted = false
                            }
                        }
                }
                
                // Progreso visual
                HStack {
                    Text("Progreso")
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .foregroundStyle(.secondary)
                }
                
                ProgressView(value: progress)
                    .tint(Color(hex: selectedColor))
                    .padding(.vertical, 4)
            }
            
            Section("Estilo") {
                // Selección de icono
                Button(action: {
                    showingIconPicker = true
                }) {
                    HStack {
                        Text("Icono")
                        
                        Spacer()
                        
                        if selectedIcon.count <= 2 || selectedIcon.unicodeScalars.allSatisfy({ $0.properties.isEmoji }) {
                            Text(selectedIcon)
                                .font(.title3)
                                .foregroundStyle(.primary)
                        } else {
                            Image(systemName: selectedIcon)
                                .font(.title3)
                                .foregroundStyle(Color(hex: selectedColor))
                        }
                    }
                }
                
                // Selección de color
                Button(action: {
                    showingColorPicker = true
                }) {
                    HStack {
                        Text("Color")
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color(hex: selectedColor))
                            .frame(width: 24, height: 24)
                    }
                }
            }
            
            Section("Fecha límite (opcional)") {
                Toggle("Establecer fecha límite", isOn: $showDeadline)
                
                if showDeadline {
                    DatePicker(
                        "Fecha límite",
                        selection: $deadline,
                        in: Date()...,
                        displayedComponents: .date
                    )
                }
            }
            
            Section("Notas (opcional)") {
                TextField("Notas", text: $notes, axis: .vertical)
                    .lineLimit(2...3)
                    .frame(height: 70)
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
            
            Section {
                if goal != nil {
                    Toggle("Meta completada", isOn: $isCompleted)
                        .tint(.green)
                }
                
                Button(action: saveGoal) {
                    Text("Guardar")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .disabled(name.isEmpty || targetAmount <= 0)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: selectedColor))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(title)
        .sheet(isPresented: $showingIconPicker) {
            NavigationStack {
                IconPickerView(selectedIcon: $selectedIcon)
                    .navigationTitle("Seleccionar Icono")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Listo") {
                                showingIconPicker = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingColorPicker) {
            NavigationStack {
                ColorPickerView(selectedColor: $selectedColor)
                    .navigationTitle("Seleccionar Color")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Listo") {
                                showingColorPicker = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Cargar datos si estamos editando
            if let goal = goal {
                name = goal.name
                targetAmountString = goal.targetAmount > 0 ? String(format: "%.2f", goal.targetAmount) : ""
                currentAmountString = goal.currentAmount > 0 ? String(format: "%.2f", goal.currentAmount) : ""
                notes = goal.notes ?? ""
                selectedIcon = goal.icon
                selectedColor = goal.color
                isCompleted = goal.isCompleted
                
                if let deadline = goal.deadline {
                    self.deadline = deadline
                    showDeadline = true
                }
            }
        }
    }
    
    private func saveGoal() {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        // Crear o actualizar la meta
        let savedGoal: SavingGoal
        
        if let existingGoal = goal {
            // Actualizar meta existente
            existingGoal.name = name
            existingGoal.targetAmount = targetAmount
            existingGoal.currentAmount = currentAmount
            existingGoal.notes = notes.isEmpty ? nil : notes
            existingGoal.icon = selectedIcon
            existingGoal.color = selectedColor
            existingGoal.deadline = showDeadline ? deadline : nil
            existingGoal.isCompleted = isCompleted
            savedGoal = existingGoal
        } else {
            // Crear nueva meta
            let newGoal = SavingGoal(
                name: name,
                targetAmount: targetAmount,
                currentAmount: currentAmount,
                deadline: showDeadline ? deadline : nil,
                icon: selectedIcon,
                color: selectedColor,
                notes: notes.isEmpty ? nil : notes,
                isCompleted: isCompleted
            )
            modelContext.insert(newGoal)
            savedGoal = newGoal
        }
        
        // Llamar al callback si existe
        onSave?(savedGoal)
        
        dismiss()
    }
}

// MARK: - Vistas auxiliares
struct IconPickerView: View {
    @Binding var selectedIcon: String
    @State private var searchText = ""
    
    // Iconos predefinidos para metas
    private let iconOptions = [
        "star.fill", "house.fill", "car.fill", "airplane.departure", "graduationcap.fill",
        "gift.fill", "heart.fill", "bag.fill", "beach.umbrella.fill", "gamecontroller.fill",
        "laptopcomputer", "trophy.fill", "figure.walk", "person.2.fill", "train.side.front.car",
        "camera.fill", "microphone.fill", "bicycle", "globe.americas.fill", "paintbrush.fill",
        "dollarsign.circle.fill", "creditcard.fill", "banknote.fill", "sparkles", "wand.and.stars",
        "phone", "message.fill", "music.note", "play.circle.fill", "book.fill",
        "calendar", "map.fill", "building.2.fill", "leaf.fill", "mountain.2.fill",
        "drop.fill", "flame.fill", "bolt.fill", "tag.fill", "key.fill",
        "lock.fill", "bell.fill", "hammer.fill", "screwdriver.fill", "pills.fill",
        "cross.case.fill", "fork.knife", "cup.and.saucer.fill", "birthday.cake.fill", "tent.fill",
        "backpack.fill", "figure.hiking", "figure.fishing", "pawprint.fill", "menucard.fill"
    ]
    
    // Emojis populares para metas
    private let emojiOptions = [
        "💰", "💵", "💸", "🏠", "🚗", "✈️", "🎓", "🎁", "💝", "👜",
        "🏖️", "🎮", "💻", "🏆", "🚶", "👫", "🚆", "📷", "🎤", "🚲",
        "🌎", "🖌️", "💲", "💳", "🌟", "✨", "🔮", "📱", "💬", "🎵",
        "📺", "📚", "📅", "🗺️", "🏢", "🍀", "⛰️", "💧", "🔥", "⚡",
        "🏷️", "🔑", "🔒", "🔔", "🛠️", "💊", "🩺", "🍴", "☕", "🎂",
        "⛺", "🎒", "🥾", "🎣", "🐾", "🍽️", "💍", "👶", "🏡", "🚢"
    ]
    
    var filteredIcons: [String] {
        if searchText.isEmpty {
            return iconOptions
        } else {
            return iconOptions.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            // Barra de búsqueda
            TextField("Buscar icono", text: $searchText)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Sección de emojis
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 16) {
                    ForEach(emojiOptions, id: \.self) { emoji in
                        Button(action: {
                            selectedIcon = emoji
                        }) {
                            Text(emoji)
                                .font(.title)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == emoji ? Color.blue.opacity(0.3) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            } header: {
                Text("Emojis")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            
            Divider()
            
            // Sección de iconos SF Symbols
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(filteredIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                        }) {
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 50, height: 50)
                                .background(selectedIcon == icon ? Color.blue.opacity(0.3) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct ColorPickerView: View {
    @Binding var selectedColor: String
    
    // Colores predefinidos
    private let colorOptions = [
        "#4ECDC4", "#FF6B6B", "#9B5DE5", "#45B7D1", "#96CEB4", 
        "#FFEEAD", "#D4A5A5", "#00BBF9", "#00F5D4", "#FEE440",
        "#F72585", "#7209B7", "#3A0CA3", "#4361EE", "#4CC9F0",
        "#F94144", "#F3722C", "#F8961E", "#F9C74F", "#90BE6D",
        "#43AA8B", "#577590", "#277DA1", "#DC2F02", "#E85D04"
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(colorOptions, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                    }) {
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .opacity(selectedColor == color ? 1 : 0)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    SavingGoalFormView(goal: nil)
} 