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
    private let deleteButtonTitleSize: CGFloat = 24
    private let defaultInset: CGFloat = 10
    
    var body: some View {
        VStack(spacing: defaultInset) {
            documentBody
            if !selectedEmojiIDs.isEmpty {
                deleteSelectedView
            }
            PaletteChooser()
                .font(.system(size: paletteEmojiSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
        .onChange(of: document.emojis) { oldValue, newValue in
            cleanUpSelection(newValue)
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
            EmojiView(emoji, isSelected: isSelected(emoji), gestureInProgress: gestureInProgress)
                .scaleEffect(selectedEmojiIDs.contains(emoji.id) ? gestureZoomSelectedEmoji : 1)
                .position(emoji.position.in(geometry))
                .offset(selectedEmojiIDs.contains(emoji.id) ? gesturePanSelectedEmoji : .zero)
                .gesture(emojiPanGesture)
                .onTapGesture {
                    toggleSelected(emoji)
                }
        }
    }
    
    private var deleteSelectedView: some View {
        HStack {
            Spacer()
            Button(role: .destructive) {
                document.deleteAllEmoji(selectedEmojiIDs)
            } label: {
                HStack {
                    Image(systemName: "trash").foregroundColor(.red)
                    Text("Delete selected (\(selectedEmojiIDs.count))")
                }
            }
        }
        .font(.system(size: deleteButtonTitleSize))
        .padding(.horizontal)
    }
    
    // MARK: - User Gestures
    
    @State private var zoom: CGFloat = 1
    @GestureState private var gestureZoomDocument: CGFloat = 1
    @GestureState private var gestureZoomSelectedEmoji: CGFloat = 1
    
    @State private var pan: CGOffset = .zero
    @GestureState private var gesturePan: CGOffset = .zero
    @GestureState private var gesturePanSelectedEmoji: CGOffset = .zero
    
    @State private var gestureInProgress: Bool = false
    
    private var zoomGesture: some Gesture {
        let objectGestureZoom = selectedEmojiIDs.isEmpty ? $gestureZoomDocument : $gestureZoomSelectedEmoji
        
        return MagnificationGesture()
            .updating(objectGestureZoom, body: { inMotionPinchScale, objectGestureZoom, _ in
                gestureInProgress = true
                objectGestureZoom = inMotionPinchScale
            })
            .onEnded { endingPinchScale in
                gestureInProgress = false
                if selectedEmojiIDs.isEmpty { zoom *= endingPinchScale }
                else {
                    for emojiID in selectedEmojiIDs {
                        document.resize(emojiWithId: emojiID, by: endingPinchScale)
                    }
                }
            }
    }
                     
    private var documentPanGesture: some Gesture {
        DragGesture()
            .updating($gesturePan, body: { inMotionDragOffset, gesturePan, _ in
                gestureInProgress = true
                gesturePan = inMotionDragOffset.translation
            })
            .onEnded { dragOffset in
                gestureInProgress = false
                pan += dragOffset.translation
            }
    }
    
    private var emojiPanGesture: some Gesture {
        DragGesture()
            .updating($gesturePanSelectedEmoji, body: { inMotionDragOffset, gesturePanSelectedEmoji, _ in
                gestureInProgress = true
                gesturePanSelectedEmoji = inMotionDragOffset.translation
            })
            .onEnded { dragOffset in
                gestureInProgress = false
                for emojiID in selectedEmojiIDs {
                    document.move(emojiWithId: emojiID, by: dragOffset.translation)
                }
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
    
    @State var selectedEmojiIDs = Set<Emoji.ID>()
    
    private func toggleSelected(_ emoji: Emoji) {
        if isSelected(emoji) {
            selectedEmojiIDs.remove(emoji.id)
        } else {
            selectedEmojiIDs.insert(emoji.id)
        }
    }
    
    private func isSelected(_ emoji: Emoji) -> Bool {
        selectedEmojiIDs.contains(emoji.id)
    }
    
    private func deselectAllEmoji() {
        selectedEmojiIDs.removeAll()
    }
    
    private func cleanUpSelection(_ updatedEmojis: [Emoji]) {
        let existingIDs = Set(updatedEmojis.map { $0.id })
        selectedEmojiIDs.formIntersection(existingIDs)
    }
}

#Preview {
    EmojiArtDocumentView(document: EmojiArtDocument())
        .environmentObject(PaletteStore(named: "Preview"))
}
