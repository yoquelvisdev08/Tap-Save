import SwiftUI
import Charts

struct ExpenseSummaryCard: View {
    let expenses: [Expense]
    let timeFrame: ExpenseListView.TimeFrame
    @State private var showingDetails = false
    @StateObject private var currencySettings = CurrencySettings.shared
    
    private var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var previousPeriodExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        let previousStartDate: Date
        let previousEndDate: Date
        
        switch timeFrame {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            previousStartDate = calendar.date(byAdding: .day, value: -14, to: now) ?? now
            previousEndDate = startDate
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            previousStartDate = calendar.date(byAdding: .month, value: -2, to: now) ?? now
            previousEndDate = startDate
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            previousStartDate = calendar.date(byAdding: .year, value: -2, to: now) ?? now
            previousEndDate = startDate
        case .custom:
            // Para el caso custom, usamos el mismo período que el actual
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            previousStartDate = calendar.date(byAdding: .month, value: -2, to: now) ?? now
            previousEndDate = startDate
        }
        
        return expenses.filter { expense in
            expense.date >= previousStartDate && expense.date < previousEndDate
        }
    }
    
    private var previousTotal: Double {
        previousPeriodExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var percentageChange: Double {
        guard previousTotal > 0 else { return 0 }
        return ((totalAmount - previousTotal) / previousTotal) * 100
    }
    
    private var trendIcon: String {
        if percentageChange > 0 {
            return "arrow.up.right"
        } else if percentageChange < 0 {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }
    
    private var trendColor: Color {
        if percentageChange > 0 {
            return .red
        } else if percentageChange < 0 {
            return .green
        } else {
            return .primary
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total \(timeFrame.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(currencySettings.formatAmount(totalAmount))
                        .font(.title.bold())
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        showingDetails.toggle()
                    }
                } label: {
                    Image(systemName: showingDetails ? "chart.bar.xaxis" : "chart.bar.xaxis.ascending")
                        .font(.title2)
                        .symbolEffect(.bounce, value: showingDetails)
                }
                .buttonStyle(.bordered)
            }
            
            if showingDetails {
                Divider()
                
                // Comparación con período anterior
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("\(timeFrame.name) anterior")
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
                            Image(systemName: trendIcon)
                                .foregroundStyle(trendColor)
                            Text(currencySettings.formatAmount(abs(totalAmount - previousTotal)))
                                .foregroundStyle(trendColor)
                                .font(.title3.bold())
                        }
                        Text("(\(abs(percentageChange), specifier: "%.1f")%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Mini gráfico de tendencia
                Chart {
                    ForEach(previousPeriodExpenses) { expense in
                        LineMark(
                            x: .value("Fecha", expense.date),
                            y: .value("Monto", expense.amount)
                        )
                        .foregroundStyle(.gray.opacity(0.5))
                        
                        AreaMark(
                            x: .value("Fecha", expense.date),
                            y: .value("Monto", expense.amount)
                        )
                        .foregroundStyle(.gray.opacity(0.1))
                    }
                    
                    ForEach(expenses) { expense in
                        LineMark(
                            x: .value("Fecha", expense.date),
                            y: .value("Monto", expense.amount)
                        )
                        .foregroundStyle(Color.accentColor)
                        
                        AreaMark(
                            x: .value("Fecha", expense.date),
                            y: .value("Monto", expense.amount)
                        )
                        .foregroundStyle(Color.accentColor.opacity(0.1))
                    }
                }
                .frame(height: 100)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
} 