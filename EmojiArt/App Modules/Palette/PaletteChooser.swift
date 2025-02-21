//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Paula Vasconcelos Gueiros on 10/02/25.
//

import SwiftUI

struct PaletteChooser: View {
    @EnvironmentObject var store: PaletteStore
    
    var body: some View {
        HStack {
            chooserButton
            view(for: store.palettes[store.cursorIndex])
        }
        .clipped()
    }
    
    var chooserButton: some View {
        AnimatedActionButton(systemImage: "paintpalette") {
            store.cursorIndex += 1
        }
        .contextMenu {
            AnimatedActionButton("New", systemImage: "plus") {
                store.insert(Palette(name: "Fruit", emojis: "🍎🍐🍊🍋🍋‍🟩🍌🍉🍇🥑🥥🥭🫐"))
            }
            AnimatedActionButton("Delete", systemImage: "minus.circle", role: .destructive) {
                store.palettes.remove(at: store.cursorIndex)
            }
        }
    }
    
    func view(for palette: Palette) -> some View {
        HStack {
            Text("\(palette.name)")
            ScrollingEmojis(palette.emojis)
        }
        .id(palette.id)
        .transition(.rollUp)
    }
}

struct ScrollingEmojis: View {
    let emojis: [String]
    
    init(_ emojis: String) {
        self.emojis = emojis.uniqued.map(String.init)
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                        .draggable(emoji)
                }
            }
        }
    }
}

#Preview {
    PaletteChooser()
        .environmentObject(PaletteStore(named: "Preview"))
}
