import UIKit

class ImageCacheService {
    static let shared = ImageCacheService()
    
    private let cache: NSCache<NSString, UIImage>
    private let fileManager = FileManager.default
    private let cacheDirectory: URL?
    
    private init() {
        self.cache = NSCache<NSString, UIImage>()
        cache.countLimit = 150
        cache.totalCostLimit = 1024 * 1024 * 100 // 100 MB
        
        if let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            self.cacheDirectory = cacheDir.appendingPathComponent("PokemonImages")
            try? fileManager.createDirectory(at: self.cacheDirectory!, withIntermediateDirectories: true)
        } else {
            self.cacheDirectory = nil
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Memory Cache
    
    func set(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale)
        cache.setObject(image, forKey: key as NSString, cost: cost)
        
        saveToDisk(image, for: key)
    }
    func get(for key: String) -> UIImage? {
        if let image = cache.object(forKey: key as NSString) {
            return image
        }
        if let image = loadFromDisk(for: key) {
            let cost = Int(image.size.width * image.size.height * image.scale * image.scale)
            cache.setObject(image, forKey: key as NSString, cost: cost)
            return image
        }
        return nil
    }
    
    func remove(for key: String) {
        cache.removeObject(forKey: key as NSString)
        removeFromDisk(for: key)
    }
    
    @objc private func clearMemoryCache() {
        cache.removeAllObjects()
    }
    
    func clearAllCache() {
        clearMemoryCache()
        clearDiskCache()
    }
    
    // MARK: - Disk Cache
    
    private func saveToDisk(_ image: UIImage, for key: String) {
        guard let directory = cacheDirectory,
              let data = image.pngData() else { return }
        
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        let fileURL = directory.appendingPathComponent(filename)
        
        try? data.write(to: fileURL)
    }
    private func loadFromDisk(for key: String) -> UIImage? {
        guard let directory = cacheDirectory else { return nil }
        
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        let fileURL = directory.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return nil }
        return image
    }
    private func removeFromDisk(for key: String) {
        guard let directory = cacheDirectory else { return }
        
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        let fileURL = directory.appendingPathComponent(filename)
        
        try? fileManager.removeItem(at: fileURL)
    }
    private func clearDiskCache() {
        guard let directory = cacheDirectory else { return }
        try? fileManager.removeItem(at: directory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    // MARK: - Cache Statistics
    
    func getCacheSize() -> Int {
        guard let directory = cacheDirectory,
              let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        return contents.reduce(0) { size, url in
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return size + fileSize
        }
    }
}
