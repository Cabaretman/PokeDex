import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var viewModel = PokedexViewModel()
    @State private var selectedPokemon: PokemonEntry?
    private let pokedexRed = Color(red: 0.6, green: 0.15, blue: 0.15)
    
    var body: some View {
        NavigationStack {
            ZStack {
                pokedexRed.ignoresSafeArea()
                VStack(spacing: 0) {
                    LCDScreen(
                        selectedPokemon: selectedPokemon,
                        loadedImages: viewModel.loadedImages,
                        pokemonDetails: viewModel.pokemonDetails
                    )
                    
                    PokemonSearchBar(text: $viewModel.searchText)
                    
                    PokemonDataGrid(
                        viewModel: viewModel,
                        selectedPokemon: $selectedPokemon
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { brandingHeader }
            }
        }
        .task {
            await viewModel.fetchInitialPokemon()
        }
    }
    
    private var brandingHeader: some View {
        VStack(spacing: 0) {
            Text("DEXOS")
                .font(.system(size: 25, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .tracking(2)
            Rectangle()
                .fill(Color.yellow.opacity(0.6))
                .frame(width: 40, height: 2)
                .cornerRadius(1)
                .padding(.top, 2)
        }
    }
}
#Preview {
    ContentView()
}
