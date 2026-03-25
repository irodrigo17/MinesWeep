import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings = .shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Long Press Duration")
                            Spacer()
                            Text(String(format: "%.2fs", settings.longPressDuration))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $settings.longPressDuration, in: 0.1...0.5, step: 0.05)
                    }
                } header: {
                    Text("Gestures")
                } footer: {
                    Text("How long you need to hold a cell to place or remove a flag.")
                }

                Section {
                    Toggle("Solvable Boards", isOn: $settings.solvableBoards)
                } header: {
                    Text("Gameplay")
                } footer: {
                    Text("When enabled, boards are generated to be solvable through logic alone, without guessing. Disabling allows classic random mine placement.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
