//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Paula Vasconcelos Gueiros on 07/02/25.
//

import SwiftUI

@MainActor
class EmojiArtDocument: ObservableObject {
    
    // MARK: - Properties
    
    typealias Emoji = EmojiArt.Emoji
    
    @Published private var emojiArt = EmojiArt() {
        didSet {
            autoSave()
            if emojiArt.background != oldValue.background {
                Task {
                    await fetchBackgroundImage()
                }
            }
        }
    }
    
    var emojis: [Emoji] {
        emojiArt.emojis
    }
    
    var bbox: CGRect {
        var bbox = CGRect.zero
        for emoji in emojiArt.emojis {
            bbox = bbox.union(emoji.bbox)
        }
        if let backgroundSize = background.uiImage?.size {
            bbox = bbox.union(CGRect(center: .zero, size: backgroundSize))
        }
        return bbox
    }
    
    // MARK: - Initialization
    
    init() {
        if let data = try? Data(contentsOf: autosaveURL),
           let autosavedEmojiArt = try? EmojiArt(json: data) {
            emojiArt = autosavedEmojiArt
        }
    }
    
    // MARK: - Persistence
    
    private let autosaveURL: URL = URL.documentsDirectory.appendingPathComponent("Autosaved.emojiart")
    
    private func autoSave() {
        save(to: autosaveURL)
        print("autosaved to \(autosaveURL)")
    }
    
    private func save(to url: URL) {
        do {
            let data = try emojiArt.json()
            try data.write(to: url)
        } catch {
            print("EmojiArtDocument: Failed to save to \(url): \(error)")
        }
    }
    
    // MARK: - Background Image
    
    @Published var background: Background = .none
    
    enum Background {
        case none
        case fetching(URL)
        case found(UIImage)
        case failed(String)
        
        var urlBeingFetched: URL? {
            switch self {
            case .fetching(let url): return url
            default: return nil
            }
        }
        
        var isFetching: Bool { urlBeingFetched != nil }
        
        var uiImage: UIImage? {
            switch self {
            case .found(let uiImage): return uiImage
            default: return nil
            }
        }
        
        var failureReason: String? {
            switch self {
            case .failed(let reason): return reason
            default: return nil
            }
        }
    }
    
    private func fetchBackgroundImage() async {
        if let url = emojiArt.background {
            background = .fetching(url)
            do {
                let image = try await fetchUIImage(from: url)
                if url == emojiArt.background {
                    background = .found(image)
                }
            } catch {
                if url == emojiArt.background {
                    background = .failed("Couldn't set background image: \(error.localizedDescription)")
                }
            }
        } else {
            background = .none
        }
    }
    
    private func fetchUIImage(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        if let uiImage = UIImage(data: data) {
            return uiImage
        } else {
            throw FetchError.badImageData
        }
    }
    
    enum FetchError: Error {
        case badImageData
    }
    
    // MARK: - Intent
    
    func setBackground(_ url: URL?) {
        emojiArt.background = url
    }
    
    func addEmoji(_ emoji: String, at position: Emoji.Position, size: CGFloat) {
        emojiArt.addEmoji(emoji, at: position, size: Int(size))
    }
    
    func move(_ emoji: Emoji, by offset: CGOffset) {
        let existingPosition = emojiArt[emoji].position
        emojiArt[emoji].position = Emoji.Position(
            x: existingPosition.x + Int(offset.width),
            y: existingPosition.y - Int(offset.height)
        )
    }
    
    func move(emojiWithId id: Emoji.ID, by offset: CGOffset) {
        if let emoji = emojiArt[id] {
            move(emoji, by: offset)
        }
    }
    
    func moveAll(emojisWithIdIn emojiIds: Set<Emoji.ID>, by offset: CGOffset) {
        for id in emojiIds {
            move(emojiWithId: id, by: offset)
        }
    }
    
    func resize(_ emoji: Emoji, by scale: CGFloat) {
        emojiArt[emoji].size = Int(CGFloat(emojiArt[emoji].size) * scale)
    }
    
    func resize(emojiWithId id: Emoji.ID, by scale: CGFloat) {
        if let emoji = emojiArt[id] {
            resize(emoji, by: scale)
        }
    }
    
    func resizeAll(emojisWithIdIn emojiIds: Set<Emoji.ID>, by scale: CGFloat) {
        for id in emojiIds {
            resize(emojiWithId: id, by: scale)
        }
    }
    
    func deleteAll(emojisWithIdIn emojiIds: Set<Emoji.ID>) {
        for id in emojiIds {
            emojiArt.deleteEmoji(id: id)
        }
    }
}

extension EmojiArt.Emoji {
    var font: Font {
        .system(size: CGFloat(size))
    }
    
    var bbox: CGRect {
        CGRect(center: position.in(nil), size: CGSize(width: CGFloat(size), height: CGFloat(size)))
    }
}

extension EmojiArt.Emoji.Position {
    func `in`(_ geometry: GeometryProxy?) -> CGPoint {
        let center = geometry?.frame(in: .local).center ?? .zero
        return CGPoint(x: center.x + CGFloat(x), y: center.y - CGFloat(y))
    }
}
