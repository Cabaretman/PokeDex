import SwiftUI

struct PokemonDataGrid: View {
    @ObservedObject var viewModel: PokedexViewModel
    @Binding var selectedPokemon: PokemonEntry?
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredPokemonList) { pokemon in
                    PokemonChip(
                        pokemon: pokemon,
                        isSelected: selectedPokemon == pokemon,
                        image: viewModel.loadedImages[pokemon.name],
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPokemon = pokemon
                                viewModel.loadDetails(for: pokemon)
                            }
                        },
                        onAppearAction: {
                            if pokemon == viewModel.pokemonList.last {
                                Task { await viewModel.fetchPokemon() }
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}
#Preview {
    let vm = PokedexViewModel()
    
    return PokemonDataGrid(
        viewModel: vm,
        selectedPokemon: .constant(nil)
    )
    .background(Color(red: 0.6, green: 0.15, blue: 0.15))
}
