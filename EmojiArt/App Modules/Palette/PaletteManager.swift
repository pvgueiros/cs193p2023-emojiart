//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by Paula Vasconcelos Gueiros on 25/02/25.
//

import SwiftUI

struct PaletteManager: View {
    
    let stores: [PaletteStore]
    @State private var selectedStore: PaletteStore?
    
    var body: some View {
        NavigationSplitView {
            List(stores, selection: $selectedStore) { store in
                PaletteStoreView(store: store)
                    .tag(store)
            }
            .navigationTitle("Manager")
        } content: {
            if let selectedStore {
                EditablePaletteList(store: selectedStore)
            } else {
                Text("Choose a store")
            }
        } detail: {
            Text("Choose a palette")
        }
    }
}

struct PaletteStoreView: View {
    @ObservedObject var store: PaletteStore
    
    var body: some View {
        Text(store.name)
    }
}

//#Preview {
//    PaletteManager()
//}
