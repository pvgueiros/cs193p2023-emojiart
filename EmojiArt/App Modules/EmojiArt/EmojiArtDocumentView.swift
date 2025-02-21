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
            deleteView
            paletteView
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
                    .offset(pan + gesturePanDocument)
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
                .scaleEffect(scaleEffectFor(emoji))
                .position(emoji.position.in(geometry))
                .offset(offsetFor(emoji))
                .gesture(panGestureFor(emoji))
                .onTapGesture {
                    toggleSelected(emoji)
                }
        }
    }
    
    private var deleteView: some View {
        HStack {
            Spacer()
            Button(role: .destructive) {
                document.deleteAll(emojisWithIdIn: selectedEmojiIds)
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete (\(selectedEmojiIds.count))")
                }
            }
            .padding(defaultInset)
            .background(.white)
            .cornerRadius(.infinity)
            .opacity(selectedEmojiIds.isEmpty ? 0 : 1)
        }
        .font(.system(size: deleteButtonTitleSize))
        .padding(.horizontal)
    }
    
    private var paletteView: some View {
        PaletteChooser()
            .font(.system(size: paletteEmojiSize))
            .padding(.horizontal)
            .scrollIndicators(.hidden)
    }
    
    // MARK: - User Gestures
    
    @State private var gestureInProgress: Bool = false
    
    @State private var zoom: CGFloat = 1
    @GestureState private var gestureZoomDocument: CGFloat = 1
    @GestureState private var gestureZoomSelectedEmoji: CGFloat = 1
    
    private var zoomGesture: some Gesture {
        let objectGestureZoom = selectedEmojiIds.isEmpty ? $gestureZoomDocument : $gestureZoomSelectedEmoji
        
        return MagnificationGesture()
            .updating(objectGestureZoom) { inMotionPinchScale, objectGestureZoom, _ in
                gestureInProgress = true
                objectGestureZoom = inMotionPinchScale
            }
            .onEnded { endingPinchScale in
                gestureInProgress = false
                
                if selectedEmojiIds.isEmpty { zoom *= endingPinchScale }
                else {
                    document.resizeAll(emojisWithIdIn: selectedEmojiIds, by: endingPinchScale)
                }
            }
    }
    
    @State private var pan: CGOffset = .zero
    @GestureState private var gesturePanDocument: CGOffset = .zero
                     
    private var documentPanGesture: some Gesture {
        DragGesture()
            .updating($gesturePanDocument) { inMotionDragOffset, gesturePanDocument, _ in
                gestureInProgress = true
                gesturePanDocument = inMotionDragOffset.translation
            }
            .onEnded { dragOffset in
                gestureInProgress = false
                pan += dragOffset.translation
            }
    }
    
    @GestureState private var gesturePanSelectedEmoji: CGOffset = .zero
    @GestureState private var gesturePanSingleEmoji: CGOffset = .zero
    
    @State private var singleEmojiBeingDraggedId: Emoji.ID? = nil
    private var isDraggingSingleEmoji: Bool { singleEmojiBeingDraggedId != nil }
    
    private func panGestureFor(_ emoji: Emoji) -> some Gesture {
        let objectGesturePan = selectedEmojiIds.contains(emoji.id)
            ? $gesturePanSelectedEmoji
            : $gesturePanSingleEmoji
        
        return DragGesture()
            .updating(objectGesturePan) { inMotionDragOffset, objectGesturePan, _ in
                gestureInProgress = true
                singleEmojiBeingDraggedId = selectedEmojiIds.contains(emoji.id) ? nil : emoji.id
                objectGesturePan = inMotionDragOffset.translation
            }
            .onEnded { dragOffset in
                gestureInProgress = false
                
                if isDraggingSingleEmoji {
                    document.move(emoji, by: dragOffset.translation)
                    singleEmojiBeingDraggedId = nil
                } else {
                    document.moveAll(emojisWithIdIn: selectedEmojiIds, by: dragOffset.translation)
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
    
    private func offsetFor(_ emoji: Emoji) -> CGOffset {
        if selectedEmojiIds.contains(emoji.id) { return gesturePanSelectedEmoji }
        if singleEmojiBeingDraggedId == emoji.id { return gesturePanSingleEmoji }
        return .zero
    }
    
    private func scaleEffectFor(_ emoji: Emoji) -> CGFloat {
        selectedEmojiIds.contains(emoji.id) ? gestureZoomSelectedEmoji : 1
    }
    
    // MARK: - Selection
    
    @State var selectedEmojiIds = Set<Emoji.ID>()
    
    private func toggleSelected(_ emoji: Emoji) {
        if isSelected(emoji) {
            selectedEmojiIds.remove(emoji.id)
        } else {
            selectedEmojiIds.insert(emoji.id)
        }
    }
    
    private func isSelected(_ emoji: Emoji) -> Bool {
        selectedEmojiIds.contains(emoji.id)
    }
    
    private func deselectAllEmoji() {
        selectedEmojiIds.removeAll()
    }
    
    private func cleanUpSelection(_ updatedEmojis: [Emoji]) {
        let existingIds = Set(updatedEmojis.map { $0.id })
        selectedEmojiIds.formIntersection(existingIds)
    }
}

#Preview {
    EmojiArtDocumentView(document: EmojiArtDocument())
        .environmentObject(PaletteStore(named: "Preview"))
}
