//
//  PaletteStore.swift
//  EmojiArt
//
//  Created by Paula Vasconcelos Gueiros on 10/02/25.
//

import Foundation

class PaletteStore: ObservableObject {
    let name: String
    
    @Published var palettes: [Palette] = [] {
        didSet {
            if palettes.isEmpty && !oldValue.isEmpty {
                palettes = oldValue
            }
        }
    }
    
    init(named name: String) {
        self.name = name
        palettes = Palette.builtins
        
        if palettes.isEmpty {
            palettes = [Palette(name: "Warning", emojis: "⚠️")]
        }
    }
    
    @Published var cursorIndex = 0
}
