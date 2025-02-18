//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Paula Vasconcelos Gueiros on 07/02/25.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    typealias Emoji = EmojiArt.Emoji
    
    @ObservedObject var document: EmojiArtDocument
    
    private let paletteEmojiSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooser()
                .font(.system(size: paletteEmojiSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
    }
    
    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                documentContents(in: geometry)
                    .scaleEffect(zoom * gestureZoomDocument)
                    .offset(pan + gesturePan)
            }
            .onTapGesture {
                deselectAllEmoji()
            }
            .gesture(documentPanGesture.simultaneously(with: zoomGesture))
            .dropDestination(for: Sturldata.self) { items, location in
                drop(items, at: location, in: geometry)
            }
        }
    }
    
    @ViewBuilder
    private func documentContents(in geometry: GeometryProxy) -> some View {
        AsyncImage(url: document.background)
            .position(Emoji.Position.zero.in(geometry))
        ForEach(document.emojis) { emoji in
            EmojiView(emoji, isSelected: isSelected(emoji), zoomInProgress: emojiZoomInProgress)
                .scaleEffect(selectedEmoji.contains(emoji.id) ? gestureZoomSelectedEmoji : 1)
                .position(emoji.position.in(geometry))
                .onTapGesture {
                    toggleSelected(emoji)
                }
        }
    }
    
    // MARK: - User Gestures
    
    @State private var zoom: CGFloat = 1
    @GestureState private var gestureZoomDocument: CGFloat = 1
    
    @State private var emojiZoomInProgress: Bool = false
    @GestureState private var gestureZoomSelectedEmoji: CGFloat = 1
    
    @State private var pan: CGOffset = .zero
    @GestureState private var gesturePan: CGOffset = .zero
    
    private var zoomGesture: some Gesture {
        let objectGestureZoom = selectedEmoji.isEmpty ? $gestureZoomDocument : $gestureZoomSelectedEmoji
        
        return MagnificationGesture()
            .updating(objectGestureZoom, body: { inMotionPinchScale, objectGestureZoom, _ in
                emojiZoomInProgress = true
                objectGestureZoom = inMotionPinchScale
            })
            .onEnded { endingPinchScale in
                if selectedEmoji.isEmpty { zoom *= endingPinchScale }
                else {
                    emojiZoomInProgress = false
                    for emojiID in selectedEmoji {
                        document.resize(emojiWithId: emojiID, by: endingPinchScale)
                    }
                }
            }
    }
                     
    private var documentPanGesture: some Gesture {
        DragGesture()
            .updating($gesturePan, body: { inMotionDragOffset, gesturePan, _ in
                gesturePan = inMotionDragOffset.translation
            })
            .onEnded { dragOffset in
                pan += dragOffset.translation
            }
    }
    
    // MARK: - Emoji Positioning
    
    private func drop(_ sturldatas: [Sturldata], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        for strurldata in sturldatas {
            switch strurldata {
            case .url(let url):
                document.setBackground(url)
                return true
            case .string(let emoji):
                document.addEmoji(
                    emoji,
                    at: emojiPosition(at: location, in: geometry),
                    size: paletteEmojiSize / zoom
                )
                return true
            default: break
            }
        }
        return false
    }
    
    private func emojiPosition(at location: CGPoint, in geometry: GeometryProxy) -> Emoji.Position {
        let center = geometry.frame(in: .local).center
        return Emoji.Position(
            x: Int((location.x - center.x - pan.width) / zoom),
            y: Int(-(location.y - center.y - pan.height) / zoom)
        )
    }
    
    // MARK: - Selection
    
    @State var selectedEmoji = Set<Emoji.ID>()
    
    func toggleSelected(_ emoji: Emoji) {
        if isSelected(emoji) {
            selectedEmoji.remove(emoji.id)
        } else {
            selectedEmoji.insert(emoji.id)
        }
    }
    
    func isSelected(_ emoji: Emoji) -> Bool {
        selectedEmoji.contains(emoji.id)
    }
    
    func deselectAllEmoji() {
        selectedEmoji.removeAll()
    }
}

#Preview {
    EmojiArtDocumentView(document: EmojiArtDocument())
        .environmentObject(PaletteStore(named: "Preview"))
}
