import SwiftUI

struct PokemonChip: View {
    let pokemon: PokemonEntry
    let isSelected: Bool
    let image: UIImage?
    let action: () -> Void
    let onAppearAction: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 6) {
                imagePreview
                nameLabel
            }
            .padding(10)
            .background(chipBackground)
            .cornerRadius(12)
            .overlay(borderOverlay)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
        }
        .buttonStyle(PressEffectButtonStyle(isPressed: $isPressed))
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onAppear(perform: onAppearAction)
    }
    
    // MARK: - Sub-components
    
    private var imagePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.black.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .transition(.scale.combined(with: .opacity))
            } else {
                VStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white.opacity(0.6))
                    
                    Text("...")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .frame(height: 80)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0.3),
                            .black.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
    
    private var nameLabel: some View {
        Text(pokemon.name.uppercased())
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(nameLabelBackground)
            .cornerRadius(6)
    }
    
    // MARK: - Styling
    
    private var chipBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.08)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var nameLabelBackground: some View {
        Group {
            if isSelected {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.8),
                        Color.blue.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.black.opacity(0.7)
            }
        }
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isSelected ?
                    LinearGradient(
                        gradient: Gradient(colors: [.yellow, .orange]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0.3),
                            .black.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                lineWidth: isSelected ? 3 : 1.5
            )
    }
    
    private var shadowColor: Color {
        isSelected ? .yellow.opacity(0.5) : .black.opacity(0.3)
    }
    
    private var shadowRadius: CGFloat {
        isSelected ? 8 : 3
    }
    
    private var shadowOffset: CGFloat {
        isSelected ? 4 : 2
    }
}

// MARK: - Press Effect Button Style

struct PressEffectButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            PokemonChip(
                pokemon: PokemonEntry.mock,
                isSelected: false,
                image: nil,
                action: {},
                onAppearAction: {}
            )
            
            PokemonChip(
                pokemon: PokemonEntry.mock,
                isSelected: true,
                image: nil,
                action: {},
                onAppearAction: {}
            )
        }
    }
    .padding()
    .background(Color(red: 0.6, green: 0.15, blue: 0.15))
}
