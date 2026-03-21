import SwiftUI

@main
struct MinesweepApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var currentViewModel: GameViewModel?

    var body: some View {
        if let vm = currentViewModel {
            GameView(viewModel: vm, onMenu: {
                currentViewModel = nil
            })
        } else {
            MenuView { difficulty in
                currentViewModel = GameViewModel(difficulty: difficulty)
            }
        }
    }
}
