import Foundation

final class DispatchBook {
    private struct Snapshot: Codable, Equatable {
        var version = 1
        var revision: UInt64 = 0
        var game: DispatchGame?
        var campaignBest: [Int: DispatchResult] = [:]
        var dailyBest: [String: DispatchResult] = [:]
    }

    private static let fileLock = NSLock()
    private let directory: URL
    private let currentURL: URL
    private let backupURL: URL
    private var state = Snapshot()
    private(set) var saveError: Error?
    var game: DispatchGame? { state.game }
    var campaignBest: [Int: DispatchResult] { state.campaignBest }
    var dailyBest: [String: DispatchResult] { state.dailyBest }

    init(directory: URL? = nil) {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.directory = directory ?? appSupport.appendingPathComponent("HenwayDispatch", isDirectory: true)
        currentURL = self.directory.appendingPathComponent("dispatch-book.json")
        backupURL = self.directory.appendingPathComponent("dispatch-book.previous.json")
        Self.fileLock.lock()
        defer { Self.fileLock.unlock() }
        state = readNewest() ?? Snapshot()
    }

    #if DEBUG
    func installPreview(_ game: DispatchGame) {
        update { $0.game = game }
    }
    #endif

    func start(_ level: DispatchLevel) {
        update { $0.game = DispatchGame(level: level) }
    }

    func restart() {
        update { snapshot in
            guard let level = snapshot.game?.level else { return }
            snapshot.game = DispatchGame(level: level)
        }
    }

    func pause() { update { $0.game?.setPaused(true) } }
    func resume() { update { $0.game?.setPaused(false) } }

    func setSignal(_ lane: DispatchLane, birds: Bool) {
        update { $0.game?.setSignal(lane, birds: birds) }
    }

    @discardableResult
    func release(_ direction: DispatchDirection, fromIsland: Bool) -> Int {
        var moved = 0
        update { moved = $0.game?.release(direction, fromIsland: fromIsland) ?? 0 }
        return moved
    }

    func tick(_ seconds: Int = 1) {
        update { snapshot in
            guard let game = snapshot.game, !game.finished, !game.paused, seconds > 0 else { return }
            snapshot.game?.tick(seconds)
            guard let end = snapshot.game?.result else { return }
            if let day = game.level.dailyKey {
                snapshot.dailyBest[day] = Self.best(snapshot.dailyBest[day], end)
            } else {
                snapshot.campaignBest[game.level.id] = Self.best(snapshot.campaignBest[game.level.id], end)
            }
        }
    }

    func clearCurrent() { update { $0.game = nil } }

    func clearAll() {
        update { snapshot in
            snapshot.game = nil
            snapshot.campaignBest = [:]
            snapshot.dailyBest = [:]
        }
        // A confirmed reset must also replace the recoverable previous copy.
        Self.fileLock.lock()
        defer { Self.fileLock.unlock() }
        if saveError == nil, let data = try? Data(contentsOf: currentURL) {
            do { try data.write(to: backupURL, options: .atomic) }
            catch { saveError = error }
        }
    }

    private static func best(_ previous: DispatchResult?, _ candidate: DispatchResult) -> DispatchResult {
        guard let previous else { return candidate }
        if previous.complete != candidate.complete { return candidate.complete ? candidate : previous }
        if previous.stars != candidate.stars { return candidate.stars > previous.stars ? candidate : previous }
        if previous.score != candidate.score { return candidate.score > previous.score ? candidate : previous }
        return candidate.elapsed < previous.elapsed ? candidate : previous
    }

    private func decode(_ url: URL) -> Snapshot? {
        guard let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data),
              snapshot.version == 1 else { return nil }
        return snapshot
    }

    private func readNewest() -> Snapshot? {
        if let current = decode(currentURL) { return current }
        return decode(backupURL)
    }

    private func update(_ action: (inout Snapshot) -> Void) {
        Self.fileLock.lock()
        defer { Self.fileLock.unlock() }
        if let latest = readNewest(), latest.revision > state.revision { state = latest }
        let before = state
        action(&state)
        guard state != before || saveError != nil else { return }
        state.revision &+= 1
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(state)
            if decode(currentURL) != nil {
                let previous = try Data(contentsOf: currentURL)
                try previous.write(to: backupURL, options: .atomic)
            }
            try data.write(to: currentURL, options: .atomic)
            saveError = nil
        } catch {
            saveError = error
        }
    }
}
