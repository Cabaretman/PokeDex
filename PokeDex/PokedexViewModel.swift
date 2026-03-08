import SwiftUI
import Combine

@MainActor
class PokedexViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var pokemonList: [PokemonEntry] = []
    @Published var loadedImages: [String: UIImage] = [:]
    @Published var pokemonDetails: [String: PokemonDetail] = [:]
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasMorePages: Bool = true
    
    // MARK: - Private Properties
    
    private var nextURL: String?
    private let service = PokemonService.shared
    
    // MARK: - Computed Properties
    
    var filteredPokemonList: [PokemonEntry] {
        if searchText.isEmpty {
            return pokemonList
        }
        return pokemonList.filter { pokemon in
            pokemon.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var displayedPokemonCount: Int {
        filteredPokemonList.count
    }
    
    // MARK: - Initialization
    
    init() {
        Task {
            await fetchInitialPokemon()
        }
    }
    
    
    // MARK: - Public Methods
    
    func fetchInitialPokemon() async {
        guard pokemonList.isEmpty else { return }
        await fetchPokemon()
    }
    
    func fetchPokemon() async {
        guard !isLoading, hasMorePages else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await service.fetchPokemonList(url: nextURL, limit: 20)
            
            nextURL = response.next
            hasMorePages = response.next != nil
            
            let newEntries = response.results
            pokemonList.append(contentsOf: newEntries)
            
            await prefetchImages(for: newEntries)
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func refresh() async {
        pokemonList.removeAll()
        loadedImages.removeAll()
        pokemonDetails.removeAll()
        nextURL = nil
        hasMorePages = true
        
        await fetchPokemon()
    }
    
    func loadImage(for pokemon: PokemonEntry) {
        guard loadedImages[pokemon.name] == nil else { return }
        Task {
            do {
                let image = try await service.fetchSprite(for: pokemon)
                loadedImages[pokemon.name] = image
            } catch {
                print("Failed to load image for \(pokemon.name): \(error)")
            }
        }
    }
    
    func loadDetails(for pokemon: PokemonEntry) {
        guard pokemonDetails[pokemon.name] == nil else { return }
        Task {
            do {
                let details = try await service.fetchPokemonDetail(url: pokemon.url)
                pokemonDetails[pokemon.name] = details
            } catch {
                print("Failed to load details for \(pokemon.name): \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func prefetchImages(for entries: [PokemonEntry]) async {
        for pokemon in entries {
            loadImage(for: pokemon)
        }
    }
    
    // MARK: - Search
    
    func clearSearch() {
        searchText = ""
    }
}
