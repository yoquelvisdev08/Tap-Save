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
                    showingComparison: $showingComparison
                )
                
                if !gastosPorCategoria.isEmpty {
                    CategoryChartView(
                        gastosPorCategoria: gastosPorCategoria,
                        totalGastos: totalGastos
                    )
                }
                
                if !gastosPorDia.isEmpty {
                    TimelineChartView(
                        gastosPorDia: gastosPorDia,
                        selectedPeriod: selectedPeriod
                    )
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
                Button(action: { showingComparison.toggle() }) {
                    Image(systemName: showingComparison ? "chart.bar.xaxis" : "chart.bar.xaxis.ascending")
                        .font(.title2)
                        .symbolEffect(.bounce, value: showingComparison)
                }
                .buttonStyle(.bordered)
            }
            
            if showingComparison {
                ComparisonView(
                    totalGastos: totalGastos,
                    previousTotal: previousTotal,
                    selectedPeriod: selectedPeriod
                )
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
    }
}

struct CategoryChartView: View {
    let gastosPorCategoria: [(String, Double, Color)]
    let totalGastos: Double
    
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
                            Text(totalGastos, format: .currency(code: "USD"))
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
                            Text(amount, format: .currency(code: "USD"))
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

#Preview {
    NavigationStack {
        StatisticsView(expenses: [])
    }
}

