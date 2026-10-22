import DashboardCore
import DashboardUI
import SwiftUI

/// Edits the Monday–Sunday meal plan through the allowlisted API.
struct MealPlanView: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dashboardTheme) private var theme

    let meals: [WeeklyMeal]
    @State private var values: [String]

    init(meals: [WeeklyMeal]) {
        self.meals = meals
        _values = State(initialValue: meals.map(\.meal) + Array(repeating: "", count: max(0, 7 - meals.count)))
    }

    var body: some View {
        NavigationStack {
            Form {
                ForEach(0..<7, id: \.self) { index in
                    TextField(dayName(index), text: $values[index])
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .foregroundStyle(index < meals.count && meals[index].isToday ? theme.accentColor : theme.body)
                }
            }
            .navigationTitle("Weekly meals")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.run(.mealWeek(values.map { String($0.prefix(120)) }))
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func dayName(_ index: Int) -> String {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][index]
    }
}
