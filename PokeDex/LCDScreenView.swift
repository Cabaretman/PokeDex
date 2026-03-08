import SwiftUI
import Combine

struct LCDScreen: View {
    let selectedPokemon: PokemonEntry?
    let loadedImages: [String: UIImage]
    let pokemonDetails: [String: PokemonDetail]
    
    @State private var showCursor = true
    @State private var currentPage = 0
    private let lcdGreen = Color(red: 0.44, green: 0.58, blue: 0.36)
    private let bezelGray = Color(red: 0.22, green: 0.22, blue: 0.25)
    private let cursorTimer = Timer.publish(every: 0.7, on: .main, in: .common).autoconnect()
    
    private var totalPages: Int {
        guard selectedPokemon != nil else { return 1 }
        return pokemonDetails[selectedPokemon!.name] != nil ? 3 : 1
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(bezelGray)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.black.opacity(0.5), lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 0) {
                batteryIndicator
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(lcdGreen)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 3))
                    
                    screenEffects
                    
                    if let selected = selectedPokemon {
                        VStack {
                            if currentPage == 0 {
                                VStack(spacing: 8) {
                                    spriteDisplay(for: selected, size: 150)
                                    nameDisplay(name: selected.name)
                                }
                            } else if let details = pokemonDetails[selected.name] {
                                if currentPage == 1 {
                                    basicInfoView(for: selected, details: details)
                                } else if currentPage == 2 {
                                    statsView(for: selected, details: details)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        if totalPages > 1 {
                            navigationControls
                        }
                    } else {
                        Text("AWAITING INPUT...")
                            .font(.system(.title3, design: .monospaced))
                            .foregroundColor(.black.opacity(0.4))
                    }
                }
                .padding(25)
            }
        }
        .frame(height: 280)
        .padding()
        .onChange(of: selectedPokemon?.id) { _, _ in
            currentPage = 0
        }
    }

    // MARK: - Subviews
    
    private var batteryIndicator: some View {
        HStack(spacing: 6) {
            Circle().fill(Color.red).frame(width: 8, height: 8).shadow(color: .red, radius: 3)
            Text("BATTERY").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundColor(.white.opacity(0.5))
        }
        .padding(.leading, 15).padding(.top, 10)
    }

    private var screenEffects: some View {
        ZStack {
            ScanlineOverlay()
            RadialGradient(
                gradient: Gradient(colors: [.black.opacity(0.2), .clear]),
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .allowsHitTesting(false)
    }
    
    private var navigationControls: some View {
        VStack {
            Spacer()
            HStack {
                navButton(systemName: "chevron.left", enabled: currentPage > 0) {
                    withAnimation(.easeInOut(duration: 0.2)) { currentPage -= 1 }
                }
                Spacer()
                navButton(systemName: "chevron.right", enabled: currentPage < totalPages - 1) {
                    withAnimation(.easeInOut(duration: 0.2)) { currentPage += 1 }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
    }
    
    private func navButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(enabled ? .black.opacity(0.7) : .black.opacity(0.15))
                .frame(width: 28, height: 28)
                .background(Color.black.opacity(0.05))
                .cornerRadius(4)
        }
        .disabled(!enabled)
    }

    private func spriteDisplay(for pokemon: PokemonEntry, size: CGFloat) -> some View {
        Group {
            if let img = loadedImages[pokemon.name] {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                ProgressView().frame(width: size, height: size)
            }
        }
    }

    private func nameDisplay(name: String) -> some View {
        HStack(spacing: 0) {
            Text(name.uppercased()).font(.system(.title3, design: .monospaced)).foregroundColor(.black)
            Rectangle().frame(width: 10, height: 22).foregroundColor(showCursor ? .black : .clear).padding(.leading, 4)
        }
        .onReceive(cursorTimer) { _ in showCursor.toggle() }
    }
    
    // MARK: - Different Info Pages
    
    private func basicInfoView(for pokemon: PokemonEntry, details: PokemonDetail) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 15) {
                spriteDisplay(for: pokemon, size: 85)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("ID: #\(String(format: "%03d", details.id))")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                    
                    HStack(spacing: 4) {
                        ForEach(details.types.sorted(by: { $0.slot < $1.slot }), id: \.slot) { typeEntry in
                            Text(typeEntry.type.name.uppercased())
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(typeColor(for: typeEntry.type.name))
                                .cornerRadius(3)
                        }
                    }
                }
            }
            
            HStack(spacing: 0) {
                measurementColumn(label: "HEIGHT", value: String(format: "%.1f m", Double(details.height) / 10.0))
                Rectangle().fill(Color.black.opacity(0.2)).frame(width: 2, height: 30)
                measurementColumn(label: "WEIGHT", value: String(format: "%.1f kg", Double(details.weight) / 10.0))
            }
            .padding(.top, 5)
        }
        .padding(.horizontal, 10)
    }
    
    private func measurementColumn(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.black.opacity(0.6))
            Text(value).font(.system(size: 16, weight: .black, design: .monospaced))
        }
        .frame(maxWidth: .infinity)
    }
    
    private func statsView(for pokemon: PokemonEntry, details: PokemonDetail) -> some View {
        VStack(spacing: 4) {
            Text("BASE STATS")
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .padding(.bottom, 2)
            
            ForEach(details.stats, id: \.stat.name) { stat in
                HStack(spacing: 8) {
                    Text(formatStatName(stat.stat.name))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .frame(width: 55, alignment: .leading)
                    
                    StatSegmentBar(value: stat.base_stat, maxValue: 160)
                        .frame(height: 10)
                    
                    Text("\(stat.base_stat)")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .frame(width: 30, alignment: .trailing)
                }
            }
            .padding(.horizontal, 10)
        }
    }
    
    // MARK: - Helpers
    
    private func formatStatName(_ name: String) -> String {
        let mapping = ["hp": "HP", "attack": "ATK", "defense": "DEF", "special-attack": "S.ATK", "special-defense": "S.DEF", "speed": "SPD"]
        return mapping[name] ?? name.uppercased()
    }
    
    private func typeColor(for type: String) -> Color {
        let colors: [String: Color] = [
            "fire": .orange, "water": .blue, "grass": .green, "electric": .yellow,
            "psychic": .pink, "ice": .cyan, "dragon": .purple, "fighting": .red,
            "bug": Color(red: 0.6, green: 0.7, blue: 0.2), "rock": .brown, "ghost": .indigo,
            "poison": .purple, "ground": .orange, "flying": .blue.opacity(0.7)
        ]
        return colors[type.lowercased()] ?? .gray
    }
}

// MARK: - Retro Components

struct StatSegmentBar: View {
    let value: Int
    let maxValue: Int
    private let segmentCount = 15 // Number of "blocks" in the bar
    
    var body: some View {
        GeometryReader { geo in
            let segmentWidth = (geo.size.width - CGFloat(segmentCount - 1)) / CGFloat(segmentCount)
            let activeSegments = Int(Double(value) / Double(maxValue) * Double(segmentCount))
            
            HStack(spacing: 1) {
                ForEach(0..<segmentCount, id: \.self) { index in
                    Rectangle()
                        .fill(index < activeSegments ? Color.black.opacity(0.7) : Color.black.opacity(0.08))
                        .frame(width: segmentWidth)
                }
            }
        }
    }
}

struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                for y in stride(from: 0, to: geo.size.height, by: 4) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
    }
}
