import Foundation
import UIKit

// MARK: - Network Errors

enum PokemonAPIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case imageDownloadFailed
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .imageDownloadFailed:
            return "Failed to download image"
        case .noData:
            return "No data received"
        }
    }
}

// MARK: - Pokemon Service

@MainActor
class PokemonService {
    static let shared = PokemonService()
    
    private let baseURL = "https://pokeapi.co/api/v2"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 100_000_000)
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Fetch Pokemon List
    
    func fetchPokemonList(url: String? = nil, limit: Int = 20) async throws -> PokemonListResponse {
        let urlString = url ?? "\(baseURL)/pokemon?limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            throw PokemonAPIError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(PokemonListResponse.self, from: data)
            return response
        } catch let error as DecodingError {
            throw PokemonAPIError.decodingError(error)
        } catch {
            throw PokemonAPIError.networkError(error)
        }
    }
    
    // MARK: - Fetch Pokemon Detail
    //Note: Right now this is redundant at MVP. However, a real Pokedex should display the details of the pokemon, not just the name and sprite. This function will fetch details fort hat.
    func fetchPokemonDetail(url: String) async throws -> PokemonDetail {
        guard let url = URL(string: url) else {
            throw PokemonAPIError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let detail = try JSONDecoder().decode(PokemonDetail.self, from: data)
            return detail
        } catch let error as DecodingError {
            throw PokemonAPIError.decodingError(error)
        } catch {
            throw PokemonAPIError.networkError(error)
        }
    }
    
    // MARK: - Fetch Pokemon Image
    
    func fetchPokemonImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw PokemonAPIError.invalidURL
        }
        
        if let cachedImage = ImageCacheService.shared.get(for: urlString) {
            return cachedImage
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            
            guard let image = UIImage(data: data) else {
                throw PokemonAPIError.imageDownloadFailed
            }
            
            ImageCacheService.shared.set(image, for: urlString)
            return image
        } catch {
            throw PokemonAPIError.networkError(error)
        }
    }
    
    // MARK: - Convenience method for fetching sprite
    
    func fetchSprite(for pokemon: PokemonEntry) async throws -> UIImage {
        guard let spriteURL = pokemon.spriteURL else {
            throw PokemonAPIError.invalidURL
        }
        
        return try await fetchPokemonImage(from: spriteURL.absoluteString)
    }
}
