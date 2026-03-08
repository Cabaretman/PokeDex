import SwiftUI

struct PokemonSearchBar: View {
    @Binding var text: String
    private let lcdGreen = Color(red: 0.44, green: 0.58, blue: 0.36)

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.black.opacity(0.4))
            TextField("SEARCH", text: $text)
                .font(.system(.body, design: .monospaced))
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
        }
        .padding(10)
        .background(lcdGreen)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 2))
        .padding(.horizontal)
        .padding(.bottom, 6)
    }
}
#Preview("Search Bar") {
    ZStack {
        Color(red: 0.6, green: 0.15, blue: 0.15).ignoresSafeArea()
        PokemonSearchBar(text: .constant("PIKACHU"))
    }
}
