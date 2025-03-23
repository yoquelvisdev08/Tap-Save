import SwiftUI

struct ExpenseFilterBar: View {
    @Binding var selectedTimeFrame: ExpenseListView.TimeFrame
    @Binding var selectedCategories: Set<String>
    @Binding var searchText: String
    let categories: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            // Time frame selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    TimeFrameButtons(selectedTimeFrame: $selectedTimeFrame)
                }
                .padding(.horizontal)
            }
            
            // Search field
            SearchField(searchText: $searchText)
                .padding(.horizontal)
            
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryButtons(
                        categories: categories,
                        selectedCategories: $selectedCategories
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Subviews
private struct TimeFrameButtons: View {
    @Binding var selectedTimeFrame: ExpenseListView.TimeFrame
    
    var body: some View {
        ForEach([ExpenseListView.TimeFrame.week,
                 .month,
                 .year,
                 .custom], id: \.self) { timeFrame in
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    selectedTimeFrame = timeFrame
                }
            } label: {
                Text(timeFrame.name)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedTimeFrame == timeFrame ? Color.accentColor : Color.secondary.opacity(0.2))
                    .foregroundStyle(selectedTimeFrame == timeFrame ? .white : .primary)
                    .clipShape(Capsule())
            }
        }
    }
}

private struct SearchField: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Buscar gastos...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct CategoryButtons: View {
    let categories: [String]
    @Binding var selectedCategories: Set<String>
    
    var body: some View {
        ForEach(categories, id: \.self) { category in
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    if selectedCategories.contains(category) {
                        selectedCategories.remove(category)
                    } else {
                        selectedCategories.insert(category)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                    Text(category)
                        .font(.subheadline)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategories.contains(category) ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .foregroundStyle(selectedCategories.contains(category) ? Color.accentColor : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(selectedCategories.contains(category) ? Color.accentColor : Color.clear, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
} 