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
        Group {
            if let vm = currentViewModel {
                GameView(viewModel: vm, onMenu: {
                    currentViewModel = nil
                })
                .transition(.move(edge: .trailing))
            } else {
                MenuView { difficulty in
                    currentViewModel = GameViewModel(difficulty: difficulty)
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentViewModel != nil)
    }
}
