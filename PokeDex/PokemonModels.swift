import Foundation

// MARK: - API Response Models

struct PokemonListResponse: Codable {
    let count: Int?
    let next: String?
    let previous: String?
    let results: [PokemonEntry]
}

struct PokemonEntry: Codable, Identifiable, Hashable {
    let name: String
    let url: String
    
    var id: String { name }
    
    var pokemonId: Int? {
        let cleanedUrl = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = cleanedUrl.split(separator: "/")
        guard let idString = components.last else { return nil }
        return Int(idString)
    }
    
    var spriteURL: URL? {
        guard let id = pokemonId else { return nil }
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }
}

struct PokemonDetail: Codable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let sprites: PokemonSprites
    let types: [PokemonTypeEntry]
    let abilities: [PokemonAbilityEntry]
    let stats: [PokemonStat]
}

struct PokemonSprites: Codable {
    let front_default: String?
    let front_shiny: String?
    let other: OtherSprites?
    
    struct OtherSprites: Codable {
        let officialArtwork: OfficialArtwork?
        
        enum CodingKeys: String, CodingKey {
            case officialArtwork = "official-artwork"
        }
    }
    
    struct OfficialArtwork: Codable {
        let front_default: String?
    }
}

struct PokemonTypeEntry: Codable {
    let slot: Int
    let type: PokemonType
}

struct PokemonType: Codable {
    let name: String
    let url: String
}

struct PokemonAbilityEntry: Codable {
    let ability: PokemonAbility
    let is_hidden: Bool
}

struct PokemonAbility: Codable {
    let name: String
    let url: String
}

struct PokemonStat: Codable {
    let base_stat: Int
    let effort: Int
    let stat: Stat
    
    struct Stat: Codable {
        let name: String
    }
}

// MARK: - Helper Extensions

//Note: These are helpful for previews and testing but are not currently in use in the final codebase
extension PokemonEntry {
    static let mock = PokemonEntry(
        name: "bulbasaur",
        url: "https://pokeapi.co/api/v2/pokemon/1/"
    )
    
    static let mockList = [
        PokemonEntry(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/"),
        PokemonEntry(name: "ivysaur", url: "https://pokeapi.co/api/v2/pokemon/2/"),
        PokemonEntry(name: "venusaur", url: "https://pokeapi.co/api/v2/pokemon/3/"),
    ]
}
