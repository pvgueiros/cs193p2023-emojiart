//
//  EditablePaletteList.swift
//  EmojiArt
//
//  Created by Paula Vasconcelos Gueiros on 25/02/25.
//

import SwiftUI

struct EditablePaletteList: View {
    @ObservedObject var store: PaletteStore
    
    @State private var showCursorPalette: Bool = false
    
    var body: some View {
        List {
            ForEach(store.palettes) { palette in
                NavigationLink(value: palette.id) {
                    VStack (alignment: .leading) {
                        Text(palette.name)
                        Text(palette.emojis).lineLimit(1)
                    }
                }
            }
            .onDelete { indexSet in
                store.palettes.remove(atOffsets: indexSet)
            }
            .onMove { indexSet, offset in
                store.palettes.move(fromOffsets: indexSet, toOffset: offset)
            }
        }
        .toolbar {
            Button {
                store.insert(Palette(name: "", emojis: ""))
                showCursorPalette = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .navigationDestination(for: Palette.ID.self) { paletteId in
            if let index = store.palettes.firstIndex(where: { $0.id == paletteId }) {
                PaletteEditor(palette: $store.palettes[index])
            }
        }
        .navigationDestination(isPresented: $showCursorPalette) {
            PaletteEditor(palette: $store.palettes[store.cursorIndex])
        }
        .navigationTitle("\(store.name) Palettes")
    }
}

//#Preview {
//    EditablePaletteList()
//}
