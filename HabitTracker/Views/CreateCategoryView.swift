//
//  CreateCategoryView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 19/11/24.
//

import SwiftUI

struct CreateCategoryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var categoryName: String = ""
    @State private var selectedColorHex: String = "#a8e6cf"
    var onCategoryCreated: (Int64) -> Void  // Callback to send the new category ID

    private let colors: [String] = [
        "#a8e6cf", "#dcedc1", "#ffd670", "#ffb36c", "#f08080",
        "#bae1ff", "#abc4ff", "#ffafcc", "#eecbff", "#cdb4db"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Category Name", text: $categoryName)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pick a Color")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                            ForEach(colors, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColorHex == colorHex ? Color.black : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColorHex = colorHex
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }

                Section {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(categoryName.isEmpty)  // Disable save if the name is empty
                }
            }
            .navigationTitle("Create Category")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func saveCategory() {
        guard !categoryName.isEmpty else { return }

        do {
            try DatabaseManager.shared.addCategory(name: categoryName, colorHex: selectedColorHex)

            if let newCategory = try DatabaseManager.shared.fetchCategories().last {
                onCategoryCreated(newCategory.id!)  // Pass the new category's ID
            }
            dismiss()
        } catch {
            print("Error creating category: \(error)")
        }
    }
}
