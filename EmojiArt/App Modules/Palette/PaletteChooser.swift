//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Paula Vasconcelos Gueiros on 10/02/25.
//

import SwiftUI

struct PaletteChooser: View {
    @EnvironmentObject var store: PaletteStore
    
    @State private var showPaletteEditor: Bool = false
    @State private var showPaletteList: Bool = false
    
    var body: some View {
        HStack {
            chooserButton
            view(for: store.palettes[store.cursorIndex])
        }
        .clipped()
        .sheet(isPresented: $showPaletteEditor) {
            PaletteEditor(palette: $store.palettes[store.cursorIndex])
                .font(nil)
        }
        .sheet(isPresented: $showPaletteList) {
            NavigationStack {
                EditablePaletteList(store: store)
                    .font(nil)
            }
        }
    }
    
    private var chooserButton: some View {
        AnimatedActionButton(systemImage: "paintpalette") {
            store.cursorIndex += 1
        }
        .contextMenu {
            goToMenu
            AnimatedActionButton("New", systemImage: "plus") {
                store.insert(Palette(name: "", emojis: ""))
                showPaletteEditor = true
            }
            AnimatedActionButton("Delete", systemImage: "minus.circle", role: .destructive) {
                store.palettes.remove(at: store.cursorIndex)
            }
            AnimatedActionButton("Edit", systemImage: "pencil") {
                showPaletteEditor = true
            }
            AnimatedActionButton("List", systemImage: "list.bullet.rectangle.portrait") {
                showPaletteList = true
            }
        }
    }
    
    private var goToMenu: some View {
        Menu {
            ForEach(store.palettes) { palette in
                AnimatedActionButton(palette.name) {
                    if let index = store.palettes.firstIndex(where: {$0.id == palette.id}) {
                        store.cursorIndex = index
                    }
                }
            }
        } label: {
            Label("Go To", systemImage: "text.insert")
        }
    }
    
    private func view(for palette: Palette) -> some View {
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
