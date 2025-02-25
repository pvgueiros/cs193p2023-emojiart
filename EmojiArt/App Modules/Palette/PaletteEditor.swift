//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by Paula Vasconcelos Gueiros on 24/02/25.
//

import SwiftUI

struct PaletteEditor: View {
    
    enum Focused {
        case name
        case addEmojis
    }
    @FocusState private var focused: Focused?
    
    private let emojiFont = Font.system(size: 40)
    
    @Binding var palette: Palette
    @State private var emojisToAdd: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Name", text: $palette.name)
                    .focused($focused, equals: .name)
            }
            Section(header: Text("Emojis")) {
                TextField("Add Emojis Here", text: $emojisToAdd)
                    .focused($focused, equals: .addEmojis)
                    .font(emojiFont)
                    .onChange(of: emojisToAdd) { oldValue, newValue in
                        palette.emojis = (emojisToAdd + palette.emojis)
                            .filter { $0.isEmoji }
                            .uniqued
                    }
                emojiListView
            }
        }
        .frame(minWidth: 300, minHeight: 350)
        .onAppear {
            if palette.name.isEmpty {
                focused = .name
            } else {
                focused = .addEmojis
            }
        }
    }
    
    private var emojiListView: some View {
        VStack(alignment: .trailing) {
            Text("Tap to Remove Emojis").font(.caption).foregroundColor(.gray)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                let uniqueEmojis = palette.emojis.uniqued.map(String.init)
                ForEach (uniqueEmojis, id: \.self) { emoji in
                    Text(emoji)
                        .onTapGesture {
                            withAnimation {
                                palette.emojis.remove(emoji.first!)
                                emojisToAdd.remove(emoji.first!)
                            }
                        }
                }
            }
        }
        .font(emojiFont)
    }
}

#Preview {
    @Previewable @State var palette = PaletteStore(named: "Preview").palettes.first!
    PaletteEditor(palette: $palette)
}
