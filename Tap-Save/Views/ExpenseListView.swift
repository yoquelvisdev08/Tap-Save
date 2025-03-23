//
//  ExpenseListView.swift
//  Tap-Save
//
//  Created by Yoquelvis abreu on 21/3/25.
//

import SwiftUI
import SwiftData

// MARK: - Main View
struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [Expense]
    @State private var selectedFilter: ExpenseFilter = .all
    @State private var selectedTimeFrame: TimeFrame = .month
    @State private var searchText = ""
    @State private var isShowingFilters = false
    
    // MARK: - Enums
    enum ExpenseFilter: Equatable {
        case all
        case category(Category)
        case amount(ClosedRange<Double>)
        
        var name: String {
            switch self {
            case .all: return "Todos"
            case .category(let cat): return cat.name
            case .amount(let range): return "💰 \(range.lowerBound) - \(range.upperBound)"
            }
        }
        
        static func == (lhs: ExpenseFilter, rhs: ExpenseFilter) -> Bool {
            switch (lhs, rhs) {
            case (.all, .all):
                return true
            case let (.category(c1), .category(c2)):
                return c1.id == c2.id
            case let (.amount(r1), .amount(r2)):
                return r1.lowerBound == r2.lowerBound && r1.upperBound == r2.upperBound
            default:
                return false
            }
        }
    }
    
    enum TimeFrame: CaseIterable, Equatable {
        case week, month, year, custom
        
        var name: String {
            switch self {
            case .week: return "Semana"
            case .month: return "Mes"
            case .year: return "Año"
            case .custom: return "Personalizado"
            }
        }
        
        var icon: String {
            switch self {
            case .week: return "calendar.badge.clock"
            case .month: return "calendar"
            case .year: return "calendar.badge.plus"
            case .custom: return "calendar.day.timeline.left"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                FilterBar(selectedFilter: $selectedFilter,
                         selectedTimeFrame: $selectedTimeFrame,
                         isShowingFilters: $isShowingFilters)
                
                ExpenseSummaryCard(expenses: filteredExpenses,
                                 timeFrame: selectedTimeFrame)
                    .padding(.horizontal)
                
                ExpensesList(expenses: groupedExpenses)
            }
            .padding(.vertical)
        }
        .navigationTitle("Gastos")
        .searchable(text: $searchText, prompt: "Buscar gastos...")
        .sheet(isPresented: $isShowingFilters) {
            ExpenseFilterView(selectedFilter: $selectedFilter)
                .presentationDetents([.medium])
        }
    }
    
    // MARK: - Helper Views
    private struct FilterBar: View {
        @Binding var selectedFilter: ExpenseFilter
        @Binding var selectedTimeFrame: TimeFrame
        @Binding var isShowingFilters: Bool
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        isSelected: selectedFilter == .all,
                        label: "Todos",
                        icon: "list.bullet"
                    ) {
                        selectedFilter = .all
                    }
                    
                    Divider()
                        .frame(height: 24)
                    
                    ForEach(TimeFrame.allCases, id: \.name) { timeFrame in
                        FilterChip(
                            isSelected: selectedTimeFrame == timeFrame,
                            label: timeFrame.name,
                            icon: timeFrame.icon
                        ) {
                            selectedTimeFrame = timeFrame
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle\(isShowingFilters ? ".fill" : "")")
                    }
                }
            }
        }
    }
    
    private struct ExpensesList: View {
        let expenses: [(String, [Expense])]
        
        var body: some View {
            ForEach(expenses, id: \.0) { dateString, expenses in
                ExpenseGroupView(
                    dateString: dateString,
                    expenses: expenses
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredExpenses: [Expense] {
        expenses.filter { expense in
            switch selectedFilter {
            case .all:
                return true
            case .category(let cat):
                return expense.category?.id == cat.id
            case .amount(let range):
                return range.contains(expense.amount)
            }
        }
    }
    
    private var groupedExpenses: [(String, [Expense])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        
        return grouped.map { (date, expenses) in
            let dateString = formatDate(date)
            return (dateString, expenses.sorted { $0.date > $1.date })
        }.sorted { date1, date2 in
            if let date1 = parseDate(date1.0),
               let date2 = parseDate(date2.0) {
                return date1 > date2
            }
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hoy"
        } else if calendar.isDateInYesterday(date) {
            return "Ayer"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter.string(from: date)
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        if dateString == "Hoy" {
            return Date()
        } else if dateString == "Ayer" {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date())
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter.date(from: dateString)
        }
    }
}

// MARK: - Supporting Views
struct FilterChip: View {
    let isSelected: Bool
    let label: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : .gray.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    do {
        let schema = Schema([Expense.self, Category.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        
        return NavigationStack {
            ExpenseListView()
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview container")
    }
}

