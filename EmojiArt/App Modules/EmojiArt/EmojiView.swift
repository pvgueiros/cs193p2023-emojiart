//
//  EmojiView.swift
//  EmojiArt
//
//  Created by Paula Vasconcelos Gueiros on 10/02/25.
//

import SwiftUI

struct EmojiView: View {
    typealias Emoji = EmojiArt.Emoji
    
    struct Constant {
        static let padding: CGFloat = 5
        static let selectionWidth: CGFloat = 3
        static let selectionColor: Color = .blue
    }
    
    let emoji: Emoji
    let isSelected: Bool
    let zoomInProgress: Bool
    
    init(_ emoji: Emoji, isSelected: Bool, zoomInProgress: Bool = false) {
        self.emoji = emoji
        self.isSelected = isSelected
        self.zoomInProgress = zoomInProgress
    }
    
    var body: some View {
        Text(emoji.string)
            .font(emoji.font)
            .padding(Constant.padding)
            .border(zoomInProgress ? .clear :
                        isSelected ? Constant.selectionColor :
                            .clear,
                    width: Constant.selectionWidth)
    }
}

#Preview {
    EmojiView(.init(string: "🍋", position: .zero, size: 40, id: 1), isSelected: true)
}
