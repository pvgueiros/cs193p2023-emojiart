//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Paula Vasconcelos Gueiros on 07/02/25.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    @StateObject var defaultDocument = EmojiArtDocument()
    @StateObject var paletteStore = PaletteStore(named: "Main")
    @StateObject var paletteStore2 = PaletteStore(named: "Alternate")
    @StateObject var paletteStore3 = PaletteStore(named: "Special")
    
    var body: some Scene {
        WindowGroup {
//            EmojiArtDocumentView(document: defaultDocument)
//                .environmentObject(paletteStore)
            PaletteManager(stores: [paletteStore, paletteStore2, paletteStore3])
        }
    }
}
