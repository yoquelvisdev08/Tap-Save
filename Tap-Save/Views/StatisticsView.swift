//
//  StatisticsView.swift
//  Tap-Save
//
//  Created by Yoquelvis abreu on 21/3/25.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    let expenses: [Expense]
    @State private var selectedPeriod: Period = .month
    @State private var selectedDate = Date()
    @State private var showingComparison = false
    @State private var comparisonMode: ComparisonMode = .previousPeriod
    @State private var selectedChartType: ChartType = .all
    @State private var showingPredictions = false
    
    enum Period: String, CaseIterable {
        case week = "Semana"
        case month = "Mes"
        case year = "Año"
        
        var dateComponent: Calendar.Component {
            switch self {
            case .week: return .weekOfYear
            case .month: return .month
            case .year: return .year
            }
        }
    }
    
    enum ComparisonMode: String, CaseIterable {
        case previousPeriod = "Período anterior"
        case monthlyComparison = "Comparativa mensual"
        case yearlyComparison = "Comparativa anual"
    }
    
    enum ChartType: String, CaseIterable {
        case all = "Todos"
        case category = "Categorías"
        case timeline = "Temporal"
        case weekday = "Días de la semana"
        case trend = "Tendencia"
        case prediction = "Predicción"
    }
    
    var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        let startDate: Date
        
        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
        }
        
        return expenses.filter { $0.date >= startDate && $0.date <= selectedDate }
    }
    
    var previousPeriodExpenses: [Expense] {
        let calendar = Calendar.current
        let endDate: Date
        let startDate: Date
        
        switch selectedPeriod {
        case .week:
            endDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
            startDate = calendar.date(byAdding: .day, value: -14, to: selectedDate) ?? selectedDate
        case .month:
            endDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            startDate = calendar.date(byAdding: .month, value: -2, to: selectedDate) ?? selectedDate
        case .year:
            endDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
            startDate = calendar.date(byAdding: .year, value: -2, to: selectedDate) ?? selectedDate
        }
        
        return expenses.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    var totalGastos: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var gastosPorCategoria: [(String, Double, Color)] {
        // 1. Agrupar gastos por categoría
        let gastosPorCategoriaDict = Dictionary(grouping: filteredExpenses) { 
            $0.category?.name ?? "Sin categoría" 
        }
        
        // 2. Calcular el total por categoría
        let totalesPorCategoria = gastosPorCategoriaDict.mapValues { expenses in
            expenses.reduce(0) { $0 + $1.amount }
        }
        
        // 3. Crear el array final con nombre, monto y color
        let resultado = totalesPorCategoria.map { (nombre, monto) -> (String, Double, Color) in
            let color = gastosPorCategoriaDict[nombre]?.first?.category?.categoryColor ?? .gray
            return (nombre, monto, color)
        }
        
        // 4. Ordenar por monto descendente
        return resultado.sorted { $0.1 > $1.1 }
    }
    
    var gastosPorDia: [(Date, Double)] {
        let calendar = Calendar.current
        
        // 1. Agrupar gastos por día
        let gastosDiarios = Dictionary(grouping: filteredExpenses) { 
            calendar.startOfDay(for: $0.date)
        }
        
        // 2. Calcular el total por día
        let totalesPorDia = gastosDiarios.mapValues { expenses in
            expenses.reduce(0) { $0 + $1.amount }
        }
        
        // 3. Convertir a array de tuplas y ordenar por fecha
        let gastosPorDiaArray = totalesPorDia.map { (fecha, monto) in
            (fecha, monto)
        }
        
        return gastosPorDiaArray.sorted { $0.0 < $1.0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                FilterView(selectedPeriod: $selectedPeriod, selectedDate: $selectedDate)
                
                SummaryView(
                    totalGastos: totalGastos,
                    previousTotal: previousPeriodExpenses.reduce(0) { $0 + $1.amount },
                    selectedPeriod: selectedPeriod,
                    showingComparison: $showingComparison,
                    comparisonMode: $comparisonMode
                )
                
                if showingComparison {
                    switch comparisonMode {
                    case .previousPeriod:
                        ComparisonView(
                            totalGastos: totalGastos,
                            previousTotal: previousPeriodExpenses.reduce(0) { $0 + $1.amount },
                            selectedPeriod: selectedPeriod
                        )
                    case .monthlyComparison:
                        MonthlyComparisonView(expenses: expenses, selectedDate: selectedDate)
                    case .yearlyComparison:
                        YearlyComparisonView(expenses: expenses, selectedDate: selectedDate)
                    }
                }
                
                ChartTypePicker(selectedChartType: $selectedChartType)
                
                if selectedChartType == .all || selectedChartType == .category {
                    if !gastosPorCategoria.isEmpty {
                        CategoryChartView(
                            gastosPorCategoria: gastosPorCategoria,
                            totalGastos: totalGastos
                        )
                    }
                }
                
                if selectedChartType == .all || selectedChartType == .timeline {
                    if !gastosPorDia.isEmpty {
                        TimelineChartView(
                            gastosPorDia: gastosPorDia,
                            selectedPeriod: selectedPeriod
                        )
                    }
                }
                
                if selectedChartType == .all || selectedChartType == .weekday {
                    WeekdayChartView(expenses: filteredExpenses)
                }
                
                if selectedChartType == .all || selectedChartType == .trend {
                    TrendChartView(expenses: expenses, selectedDate: selectedDate)
                }
                
                if selectedChartType == .all || selectedChartType == .prediction {
                    PredictionView(expenses: expenses)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Estadísticas")
        .overlay {
            if expenses.isEmpty {
                ContentUnavailableView(
                    "No hay datos",
                    systemImage: "chart.pie",
                    description: Text("Agrega gastos para ver estadísticas")
                )
            }
        }
    }
}

// Componentes auxiliares
struct FilterView: View {
    @Binding var selectedPeriod: StatisticsView.Period
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: 12) {
            Picker("Período", selection: $selectedPeriod) {
                ForEach(StatisticsView.Period.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            DatePicker(
                "Fecha final",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
}

struct SummaryView: View {
    let totalGastos: Double
    let previousTotal: Double
    let selectedPeriod: StatisticsView.Period
    @Binding var showingComparison: Bool
    @Binding var comparisonMode: StatisticsView.ComparisonMode
    @StateObject private var currencySettings = CurrencySettings.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(currencySettings.formatAmount(totalGastos))
                        .font(.title.bold())
                }
                Spacer()
                Button(action: { 
                    withAnimation {
                        showingComparison.toggle() 
                    }
                }) {
                    Image(systemName: showingComparison ? "chart.bar.xaxis" : "chart.bar.xaxis.ascending")
                        .font(.title2)
                        .symbolEffect(.bounce, value: showingComparison)
                }
                .buttonStyle(.bordered)
            }
            
            if showingComparison {
                VStack {
                    Picker("Tipo de comparación", selection: $comparisonMode) {
                        ForEach(StatisticsView.ComparisonMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
}

struct ComparisonView: View {
    let totalGastos: Double
    let previousTotal: Double
    let selectedPeriod: StatisticsView.Period
    @StateObject private var currencySettings = CurrencySettings.shared
    
    private var difference: Double { totalGastos - previousTotal }
    private var percentChange: Double { previousTotal > 0 ? (difference / previousTotal) * 100 : 0 }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text("\(selectedPeriod.rawValue) anterior")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(currencySettings.formatAmount(previousTotal))
                    .font(.title3.bold())
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Diferencia")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: difference >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundStyle(difference >= 0 ? .red : .green)
                    Text(currencySettings.formatAmount(abs(difference)))
                        .foregroundStyle(difference >= 0 ? .red : .green)
                        .font(.title3.bold())
                }
                Text("(\(abs(percentChange), specifier: "%.1f")%)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct MonthlyComparisonView: View {
    let expenses: [Expense]
    let selectedDate: Date
    @StateObject private var currencySettings = CurrencySettings.shared
    
    // Obtener datos de los últimos 12 meses para comparativa
    var monthlyData: [(String, Double)] {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: selectedDate)
        let currentYear = calendar.component(.year, from: selectedDate)
        
        var result: [(String, Double)] = []
        
        // Generamos datos para los últimos 6 meses
        for i in 0..<6 {
            var dateComponents = DateComponents()
            dateComponents.year = currentYear
            dateComponents.month = currentMonth - i
            
            // Ajuste para meses anteriores que cruzan al año anterior
            if dateComponents.month ?? 0 <= 0 {
                dateComponents.year = currentYear - 1
                dateComponents.month = 12 + (dateComponents.month ?? 0)
            }
            
            guard let startOfMonth = calendar.date(from: dateComponents) else { continue }
            
            // Obtener el primer día del mes
            let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: startOfMonth)) ?? startOfMonth
            
            // Obtener el último día del mes
            var nextMonthComponents = DateComponents()
            nextMonthComponents.month = 1
            nextMonthComponents.day = -1
            let endDate = calendar.date(byAdding: nextMonthComponents, to: startDate) ?? startDate
            
            // Filtrar gastos para este mes
            let monthExpenses = expenses.filter { 
                $0.date >= startDate && $0.date <= endDate
            }
            
            // Calcular total para este mes
            let total = monthExpenses.reduce(0) { $0 + $1.amount }
            
            // Formatear nombre del mes
            let monthName = calendar.shortMonthSymbols[calendar.component(.month, from: startDate) - 1]
            let yearString = String(calendar.component(.year, from: startDate))
            let monthLabel = "\(monthName) \(yearString)"
            
            result.append((monthLabel, total))
        }
        
        return result.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comparativa Mensual")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(monthlyData, id: \.0) { month, amount in
                    BarMark(
                        x: .value("Mes", month),
                        y: .value("Gasto", amount)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 220)
            .chartYAxis {
                AxisMarks { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text(currencySettings.formatAmount(amount))
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Tabla de datos mensuales
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.fixed(120))
            ], spacing: 10) {
                Text("Mes").font(.caption.bold())
                Text("Total").font(.caption.bold())
                
                ForEach(monthlyData, id: \.0) { monthName, amount in
                    Text(monthName)
                        .font(.caption)
                    Text(currencySettings.formatAmount(amount))
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(amount > 0 ? .primary : .secondary)
                }
            }
            .padding()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
}

struct YearlyComparisonView: View {
    let expenses: [Expense]
    let selectedDate: Date
    @StateObject private var currencySettings = CurrencySettings.shared
    
    // Obtener datos de los últimos 3 años para comparativa
    var yearlyData: [(String, [MonthlyTotal])] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: selectedDate)
        
        var result: [(String, [MonthlyTotal])] = []
        
        // Generamos datos para los últimos 3 años
        for yearOffset in 0..<3 {
            let year = currentYear - yearOffset
            let yearString = String(year)
            
            var monthlyTotals: [MonthlyTotal] = []
            
            // Para cada mes del año
            for month in 1...12 {
                var dateComponents = DateComponents()
                dateComponents.year = year
                dateComponents.month = month
                
                guard let startOfMonth = calendar.date(from: dateComponents) else { continue }
                
                // Obtener el último día del mes
                var nextMonthComponents = DateComponents()
                nextMonthComponents.month = 1
                nextMonthComponents.day = -1
                let endDate = calendar.date(byAdding: nextMonthComponents, to: startOfMonth) ?? startOfMonth
                
                // Filtrar gastos para este mes
                let monthExpenses = expenses.filter { 
                    $0.date >= startOfMonth && $0.date <= endDate
                }
                
                // Calcular total para este mes
                let total = monthExpenses.reduce(0) { $0 + $1.amount }
                
                // Nombre abreviado del mes
                let monthName = calendar.shortMonthSymbols[month - 1]
                
                monthlyTotals.append(MonthlyTotal(month: month, name: monthName, total: total))
            }
            
            result.append((yearString, monthlyTotals))
        }
        
        return result.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparativa Anual")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(yearlyData, id: \.0) { year, monthlyData in
                    ForEach(monthlyData) { monthData in
                        LineMark(
                            x: .value("Mes", monthData.name),
                            y: .value("Gasto", monthData.total)
                        )
                        .foregroundStyle(by: .value("Año", year))
                        .symbol(by: .value("Año", year))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .frame(height: 250)
            .chartForegroundStyleScale([
                yearlyData[0].0: Color.blue,
                yearlyData.count > 1 ? yearlyData[1].0 : "": Color.green,
                yearlyData.count > 2 ? yearlyData[2].0 : "": Color.orange
            ])
            .chartYAxis {
                AxisMarks { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text(currencySettings.formatAmount(amount))
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Totales anuales
            VStack(spacing: 14) {
                ForEach(yearlyData, id: \.0) { year, monthlyData in
                    let yearTotal = monthlyData.reduce(0) { $0 + $1.total }
                    
                    HStack {
                        Circle()
                            .fill(year == yearlyData[0].0 ? Color.blue : 
                                  year == yearlyData[1].0 ? Color.green : Color.orange)
                            .frame(width: 12, height: 12)
                        
                        Text("\(year):")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(currencySettings.formatAmount(yearTotal))
                            .font(.subheadline.bold())
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
}

struct MonthlyTotal: Identifiable {
    var id: Int { month }
    let month: Int
    let name: String
    let total: Double
}

struct CategoryChartView: View {
    let gastosPorCategoria: [(String, Double, Color)]
    let totalGastos: Double
    @StateObject private var currencySettings = CurrencySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gastos por Categoría")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(gastosPorCategoria, id: \.0) { category, amount, color in
                SectorMark(
                    angle: .value("Monto", amount),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .cornerRadius(3)
                .foregroundStyle(color)
            }
            .frame(height: 200)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotFrame {
                        let frame = geometry[plotFrame]
                        VStack {
                            Text("Total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(currencySettings.formatAmount(totalGastos))
                                .font(.headline)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            
            CategoryLegendView(gastosPorCategoria: gastosPorCategoria, totalGastos: totalGastos)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
}

struct CategoryLegendView: View {
    let gastosPorCategoria: [(String, Double, Color)]
    let totalGastos: Double
    @StateObject private var currencySettings = CurrencySettings.shared
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(gastosPorCategoria, id: \.0) { categoria, monto, color in
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    Text(categoria)
                        .font(.subheadline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(currencySettings.formatAmount(monto))
                            .font(.subheadline.bold())
                        Text("\((monto/totalGastos)*100, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TimelineChartView: View {
    let gastosPorDia: [(Date, Double)]
    let selectedPeriod: StatisticsView.Period
    @StateObject private var currencySettings = CurrencySettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Evolución Temporal")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(gastosPorDia, id: \.0) { date, amount in
                LineMark(
                    x: .value("Fecha", date),
                    y: .value("Monto", amount)
                )
                .interpolationMethod(.catmullRom)
                .symbol(Circle().strokeBorder(lineWidth: 2))
                
                AreaMark(
                    x: .value("Fecha", date),
                    y: .value("Monto", amount)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Gradient(colors: [.blue.opacity(0.3), .blue.opacity(0.1)]))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: selectedPeriod == .week ? .day : .month)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date.formatted(selectedPeriod == .week ? .dateTime.day() : .dateTime.month()))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(currencySettings.formatAmount(amount))
                                .font(.caption)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
}

// Nuevo componente para el selector de tipo de gráfico
struct ChartTypePicker: View {
    @Binding var selectedChartType: StatisticsView.ChartType
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(StatisticsView.ChartType.allCases, id: \.self) { chartType in
                    Button(action: {
                        withAnimation {
                            selectedChartType = chartType
                        }
                    }) {
                        HStack {
                            Image(systemName: iconForChartType(chartType))
                            Text(chartType.rawValue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedChartType == chartType ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedChartType == chartType ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 5)
    }
    
    private func iconForChartType(_ chartType: StatisticsView.ChartType) -> String {
        switch chartType {
        case .all: return "chart.bar.doc.horizontal"
        case .category: return "chart.pie"
        case .timeline: return "chart.line.uptrend.xyaxis"
        case .weekday: return "calendar"
        case .trend: return "arrow.up.right"
        case .prediction: return "chart.line.uptrend.xyaxis"
        }
    }
}

// Gráfico de gastos por día de la semana
struct WeekdayChartView: View {
    let expenses: [Expense]
    @StateObject private var currencySettings = CurrencySettings.shared
    
    // Datos por día de la semana
    var weekdayData: [(String, Double)] {
        let calendar = Calendar.current
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE" // Nombre completo del día
        
        // Inicializar array con días de la semana
        var weekdayAmounts: [String: Double] = [
            "Lunes": 0,
            "Martes": 0,
            "Miércoles": 0,
            "Jueves": 0,
            "Viernes": 0,
            "Sábado": 0,
            "Domingo": 0
        ]
        
        // Nombres de días en español
        let weekdayNames = [
            1: "Domingo",
            2: "Lunes",
            3: "Martes",
            4: "Miércoles",
            5: "Jueves",
            6: "Viernes",
            7: "Sábado"
        ]
        
        // Calcular total por día de la semana
        for expense in expenses {
            let weekday = calendar.component(.weekday, from: expense.date)
            if let dayName = weekdayNames[weekday] {
                weekdayAmounts[dayName, default: 0] += expense.amount
            }
        }
        
        // Convertir a array de tuplas y ordenar por día de la semana
        let result = weekdayAmounts.map { (day, amount) in
            return (day, amount)
        }.sorted { (day1, day2) -> Bool in
            let order = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
            return order.firstIndex(of: day1.0)! < order.firstIndex(of: day2.0)!
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gastos por Día de la Semana")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(weekdayData, id: \.0) { day, amount in
                    BarMark(
                        x: .value("Día", day),
                        y: .value("Gasto", amount)
                    )
                    .foregroundStyle(Color.purple.gradient)
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        if amount > 0 {
                            Text(currencySettings.formatAmount(amount))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .rotationEffect(.degrees(-45))
                                .offset(y: -5)
                        }
                    }
                }
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks { value in
                    let day = value.as(String.self) ?? ""
                    AxisValueLabel {
                        Text(day.prefix(3)) // Abreviamos el nombre del día
                            .font(.caption)
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text(currencySettings.formatAmount(amount))
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Análisis
            VStack(alignment: .leading, spacing: 10) {
                if let maxDay = weekdayData.max(by: { $0.1 < $1.1 }), maxDay.1 > 0 {
                    Text("Mayor gasto: \(maxDay.0)")
                        .font(.subheadline)
                    
                    HStack {
                        Text(currencySettings.formatAmount(maxDay.1))
                            .font(.subheadline.bold())
                        
                        let average = weekdayData.map({ $0.1 }).reduce(0, +) / Double(weekdayData.count)
                        if average > 0 {
                            Text("(\(Int((maxDay.1 / average - 1) * 100))% sobre la media)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
}

// Gráfico de tendencia trimestral
struct TrendChartView: View {
    let expenses: [Expense]
    let selectedDate: Date
    @StateObject private var currencySettings = CurrencySettings.shared
    
    // Calcular datos trimestrales con línea de tendencia
    var quarterlyData: [(Date, Double, Double)] {
        let calendar = Calendar.current
        let endDate = selectedDate
        let startDate = calendar.date(byAdding: .month, value: -12, to: endDate) ?? endDate
        
        // Dividir en trimestres
        var quarterlyTotals: [(Date, Double)] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let quarterEndDate = min(
                calendar.date(byAdding: .month, value: 3, to: currentDate) ?? endDate,
                endDate
            )
            
            // Filtrar gastos para este trimestre
            let quarterExpenses = expenses.filter {
                $0.date >= currentDate && $0.date <= quarterEndDate
            }
            
            // Calcular total para este trimestre
            let total = quarterExpenses.reduce(0) { $0 + $1.amount }
            
            // Añadir al array
            quarterlyTotals.append((currentDate, total))
            
            // Avanzar al siguiente trimestre
            currentDate = calendar.date(byAdding: .month, value: 3, to: currentDate) ?? endDate
        }
        
        // Calcular línea de tendencia (regresión lineal simple)
        let count = Double(quarterlyTotals.count)
        let indices = Array(0..<quarterlyTotals.count).map(Double.init)
        let values = quarterlyTotals.map { $0.1 }
        
        // Cálculo de la pendiente y ordenada en el origen
        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map { $0 * $1 }.reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)
        
        let slope = (count * sumXY - sumX * sumY) / (count * sumX2 - sumX * sumX)
        let yIntercept = (sumY - slope * sumX) / count
        
        // Calcular valores de la tendencia
        let trendValues = indices.map { yIntercept + slope * $0 }
        
        // Combinar datos originales con la línea de tendencia
        return zip(quarterlyTotals, trendValues).map { (quarter, trend) in
            return (quarter.0, quarter.1, trend)
        }
    }
    
    // Formato para el título de trimestre
    func formatQuarterTitle(_ date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        // Determinar el trimestre según el mes
        let quarter: Int
        if month <= 3 {
            quarter = 1
        } else if month <= 6 {
            quarter = 2
        } else if month <= 9 {
            quarter = 3
        } else {
            quarter = 4
        }
        
        return "T\(quarter) \(year)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tendencia Trimestral")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(quarterlyData, id: \.0) { date, amount, trend in
                    BarMark(
                        x: .value("Trimestre", formatQuarterTitle(date)),
                        y: .value("Gasto", amount)
                    )
                    .foregroundStyle(Color.teal.gradient)
                    .cornerRadius(6)
                }
                
                ForEach(quarterlyData, id: \.0) { date, _, trend in
                    LineMark(
                        x: .value("Trimestre", formatQuarterTitle(date)),
                        y: .value("Tendencia", trend)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .foregroundStyle(.red)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    .symbolSize(30)
                }
            }
            .frame(height: 250)
            .chartYAxis {
                AxisMarks { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text(currencySettings.formatAmount(amount))
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Análisis de tendencia
            VStack(alignment: .leading, spacing: 10) {
                // Calcular si la tendencia es al alza o a la baja
                if quarterlyData.count >= 2 {
                    let firstTrend = quarterlyData.first?.2 ?? 0
                    let lastTrend = quarterlyData.last?.2 ?? 0
                    let change = lastTrend - firstTrend
                    
                    HStack {
                        Image(systemName: change > 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundStyle(change > 0 ? .red : .green)
                        
                        Text(change > 0 ? "Tendencia al alza" : "Tendencia a la baja")
                            .font(.subheadline.bold())
                            .foregroundStyle(change > 0 ? .red : .green)
                    }
                    
                    if abs(change) > 0 {
                        Text("Cambio estimado: \(currencySettings.formatAmount(abs(change)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
}

// Clase para almacenar predicciones por categoría
struct CategoryPrediction: Identifiable {
    var id: String { category }
    let category: String
    let color: Color
    let currentAmount: Double
    let predictedAmount: Double
    let confidence: Double
    
    // Extraer el cálculo del percentChange a un método para evitar expresiones complejas
    func getPercentChange() -> Double {
        if currentAmount > 0 {
            return (predictedAmount - currentAmount) / currentAmount
        } else {
            return 0
        }
    }
    
    // Determinar si hay un aumento o descenso
    func isIncrease() -> Bool {
        return getPercentChange() >= 0
    }
    
    // Obtener el color apropiado según la tendencia
    func getTrendColor() -> Color {
        return isIncrease() ? .red : .green
    }
}

// Vista de predicción de gastos
struct PredictionView: View {
    let expenses: [Expense]
    @StateObject private var currencySettings = CurrencySettings.shared
    
    // Calcula las predicciones por categoría
    var categoryPredictions: [CategoryPrediction] {
        guard !expenses.isEmpty else { return [] }
        
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Obtener el principio del mes actual
        let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        
        // Periodo para analizar (últimos 6 meses)
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: startOfCurrentMonth)!
        
        // Agrupar gastos por mes para cada categoría
        var categoryMonthlyExpenses: [String: [Date: Double]] = [:]
        
        // Obtener todas las categorías únicas
        let uniqueCategories = Set(expenses.compactMap { $0.category?.name ?? "Sin categoría" })
        
        // Inicializar el diccionario para cada categoría
        for category in uniqueCategories {
            categoryMonthlyExpenses[category] = [:]
        }
        
        // Agrupar gastos por mes y categoría
        for expense in expenses.filter({ $0.date >= sixMonthsAgo }) {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: expense.date))!
            let categoryName = expense.category?.name ?? "Sin categoría"
            
            categoryMonthlyExpenses[categoryName, default: [:]][monthStart, default: 0] += expense.amount
        }
        
        // Calcular gastos del mes actual por categoría
        let currentMonthExpenses = expenses.filter { 
            let date = $0.date
            return date >= startOfCurrentMonth && date < calendar.date(byAdding: .month, value: 1, to: startOfCurrentMonth)!
        }
        
        let currentByCategory = Dictionary(grouping: currentMonthExpenses) { 
            $0.category?.name ?? "Sin categoría" 
        }.mapValues { categoryExpenses in
            categoryExpenses.reduce(0) { $0 + $1.amount }
        }
        
        var predictions: [CategoryPrediction] = []
        
        // Realizar predicciones para cada categoría
        for category in uniqueCategories {
            let monthlyData = categoryMonthlyExpenses[category] ?? [:]
            
            // Si no hay suficientes datos para esta categoría, omitir
            if monthlyData.count < 3 {
                continue
            }
            
            // Ordenar los datos por mes
            let sortedMonthlyData = monthlyData.sorted { $0.key < $1.key }
            
            // Obtener valores para análisis de tendencia
            let months = sortedMonthlyData.map { calendar.dateComponents([.month], from: $0.key).month ?? 0 }
            let amounts = sortedMonthlyData.map { $0.value }
            
            // Solo predecir si tenemos al menos 3 meses de datos
            if amounts.count >= 3 {
                let predictedAmount = predictNextMonthAmount(months: months, amounts: amounts)
                let confidence = calculateConfidence(amounts: amounts)
                
                // Color de la categoría
                let color = expenses.first(where: { ($0.category?.name ?? "Sin categoría") == category })?.category?.categoryColor ?? .gray
                
                predictions.append(CategoryPrediction(
                    category: category,
                    color: color,
                    currentAmount: currentByCategory[category] ?? 0,
                    predictedAmount: predictedAmount,
                    confidence: confidence
                ))
            }
        }
        
        // Ordenar por mayor cambio porcentual (aumento o descenso)
        return predictions.sorted { abs($0.getPercentChange()) > abs($1.getPercentChange()) }
    }
    
    // Predicción para el siguiente mes usando regresión lineal
    private func predictNextMonthAmount(months: [Int], amounts: [Double]) -> Double {
        // Convertir meses a valores consecutivos para regresión
        let xValues = Array(0..<months.count).map(Double.init)
        let yValues = amounts
        
        // Cálculo de la regresión lineal
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map { $0 * $1 }.reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        let n = Double(xValues.count)
        
        // Calculamos pendiente y ordenada en el origen
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        // Predecir el siguiente valor (x = último índice + 1)
        let nextMonth = Double(xValues.count)
        let prediction = intercept + slope * nextMonth
        
        // Asegurar que la predicción no sea negativa
        return max(0, prediction)
    }
    
    // Calcula la confianza de la predicción (0.0 - 1.0)
    private func calculateConfidence(amounts: [Double]) -> Double {
        // Si hay poca variación, mayor confianza
        if amounts.count <= 1 { return 0.5 }
        
        // Paso 1: Calcular la media
        let sum = amounts.reduce(0, +)
        let count = Double(amounts.count)
        let mean = sum / count
        
        // Paso 2: Calcular la varianza en pasos separados
        var squaredDiffs = 0.0
        for amount in amounts {
            let diff = amount - mean
            squaredDiffs += diff * diff
        }
        let variance = squaredDiffs / count
        
        // Paso 3: Calcular la desviación estándar
        let stdDev = sqrt(variance)
        
        // Paso 4: Calcular el coeficiente de variación
        let cv: Double
        if mean > 0 {
            cv = stdDev / mean
        } else {
            cv = 1.0
        }
        
        // Paso 5: Calcular la confianza base
        let baseConfidence = 1.0 / (1.0 + cv)
        
        // Paso 6: Ajustar por cantidad de datos
        let countFactor = Double(amounts.count) * 0.02
        let dataBonus = min(0.2, countFactor)
        
        // Paso 7: Calcular confianza final
        let finalConfidence = baseConfidence + dataBonus
        return min(1.0, finalConfidence)
    }
    
    // Predicción total para el próximo mes
    var totalPrediction: Double {
        categoryPredictions.reduce(0) { $0 + $1.predictedAmount }
    }
    
    // Promedio de confianza en las predicciones
    var averageConfidence: Double {
        guard !categoryPredictions.isEmpty else { return 0 }
        return categoryPredictions.reduce(0) { $0 + $1.confidence } / Double(categoryPredictions.count)
    }
    
    // Total actual por periodo
    var currentTotal: Double {
        categoryPredictions.reduce(0) { $0 + $1.currentAmount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Predicción de Gastos para el Siguiente Mes")
                .font(.headline)
                .padding(.horizontal)
            
            if categoryPredictions.isEmpty {
                Text("Se necesitan al menos 3 meses de datos para hacer predicciones")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Resumen de predicción
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Estimado próximo mes:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Formato del monto de predicción total
                        let formattedTotalPrediction = currencySettings.formatAmount(totalPrediction)
                        Text(formattedTotalPrediction)
                            .font(.title2.bold())
                        
                        // Uso simplificado para el porcentaje de cambio
                        HStack {
                            // Determinar dirección del cambio
                            let calculatedChange = calculateTotalPercentChange()
                            let isIncrease = calculatedChange >= 0
                            
                            // Icono según dirección
                            Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                                .foregroundStyle(isIncrease ? Color.red : Color.green)
                            
                            // Texto de porcentaje formateado
                            let formattedPercent = String(format: "%.1f", abs(calculatedChange) * 100)
                            Text("\(formattedPercent)% que el mes actual")
                                .font(.caption)
                                .foregroundStyle(isIncrease ? Color.red : Color.green)
                        }
                    }
                    
                    Spacer()
                    
                    // Indicador de confianza
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Confianza:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Visualización de estrellas
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { i in
                                // Calcular si la estrella debe estar llena o vacía
                                let threshold = Double(i) / 5.0
                                let isFilled = threshold <= averageConfidence
                                let starColor = isFilled ? Color.yellow : Color.gray.opacity(0.3)
                                
                                Image(systemName: "star.fill")
                                    .foregroundStyle(starColor)
                            }
                        }
                        
                        // Porcentaje de confianza
                        let confidencePercent = Int(averageConfidence * 100)
                        Text("\(confidencePercent)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Predicciones por categoría
                VStack(alignment: .leading, spacing: 10) {
                    Text("Predicciones por Categoría")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Gráfico de predicciones por categoría
                    let topCategories = Array(categoryPredictions.prefix(5))
                    
                    // Crear un gráfico extremadamente simplificado
                    VStack(spacing: 12) {
                        Chart {
                            // Actual values only - simplificado al máximo
                            ForEach(0..<topCategories.count, id: \.self) { index in
                                let prediction = topCategories[index]
                                BarMark(
                                    x: .value("Categoría", prediction.category),
                                    y: .value("Actual", prediction.currentAmount)
                                )
                                .foregroundStyle(Color.blue.opacity(0.7))
                            }
                        }
                        .frame(height: 120)
                        .padding(.horizontal)
                        
                        Chart {
                            // Predicted values only - separado en otro gráfico
                            ForEach(0..<topCategories.count, id: \.self) { index in
                                let prediction = topCategories[index]
                                BarMark(
                                    x: .value("Categoría", prediction.category),
                                    y: .value("Predicción", prediction.predictedAmount)
                                )
                                .foregroundStyle(Color.green)
                            }
                        }
                        .frame(height: 120)
                        .padding(.horizontal)
                    }
                    
                    // Lista detallada de predicciones
                    VStack(spacing: 16) {
                        // Usar un ForEach basado en índice para simplificar
                        ForEach(0..<categoryPredictions.count, id: \.self) { index in
                            // Obtener la predicción actual
                            let prediction = categoryPredictions[index]
                            
                            // Elementos visuales simplificados
                            HStack {
                                // Indicador de color
                                Circle()
                                    .fill(prediction.color)
                                    .frame(width: 12, height: 12)
                                
                                // Nombre de categoría
                                Text(prediction.category)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                // Monto actual
                                Text("Actual: \(currencySettings.formatAmount(prediction.currentAmount))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                // Espacio entre los montos
                                Spacer()
                                    .frame(width: 20)
                                
                                // Monto predicho simplificado
                                Text("Próximo: \(currencySettings.formatAmount(prediction.predictedAmount))")
                                    .font(.caption.bold())
                                    .foregroundStyle(prediction.getTrendColor())
                            }
                            .padding(.horizontal)
                            
                            // Divider a menos que sea el último elemento
                            if index < categoryPredictions.count - 1 {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                
                // Explicación del análisis
                VStack(alignment: .leading, spacing: 10) {
                    Text("Acerca de este análisis")
                        .font(.subheadline.bold())
                    
                    Text("Las predicciones se basan en el análisis de tus patrones de gasto durante los últimos 6 meses, utilizando modelos de regresión lineal y análisis de tendencias.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("La confianza en la predicción aumenta con la consistencia de tus gastos mes a mes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
    
    private func calculateTotalPercentChange() -> Double {
        if currentTotal > 0 {
            return (totalPrediction - currentTotal) / currentTotal
        } else {
            return 0
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsView(expenses: [])
    }
}

