import Foundation

struct CheckError: Error, CustomStringConvertible {
    let description: String
    init(_ value: String) { description = value }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw CheckError(message) }
}

// Operates the same two signals and the same four dispatch buttons available to a player.
// Favour birds already on the island, and open an empty lane to motor traffic each turn.
func playTurn(_ game: inout DispatchGame) {
    for lane in DispatchLane.allCases {
        let exiting: DispatchDirection = lane == .west ? .west : .east
        let entering: DispatchDirection = lane == .west ? .east : .west
        let wantsExit = game.onIsland(exiting) > 0
        let wantsEntry = game.waiting(entering) > 0 && game.islandReserved < game.level.capacity
        game.setSignal(lane, birds: wantsExit || wantsEntry)
        if wantsExit { game.release(exiting, fromIsland: true) }
        else if wantsEntry { game.release(entering, fromIsland: false) }
    }
}

func validate(_ game: DispatchGame) throws {
    let west = game.lane(.west), east = game.lane(.east)
    let accounted = game.delivered + game.islandCount + game.waiting(.east) + game.waiting(.west)
        + west.crossingBirds + east.crossingBirds + game.birdsYetToArrive
    try check(accounted == game.level.total, "Lost or duplicated bird at \(game.level.id), t=\(game.elapsed)")
    try check(game.islandReserved <= game.level.capacity, "Island over capacity")
    for state in [west, east] {
        try check(state.vehicle == nil || state.crossingBirds == 0, "Unsafe simultaneous crossing")
    }
}

struct Witness {
    var cars = false
    var tractors = false
    var trailers = false
    var trains = false
    var westbound = false
}

func solve(_ level: DispatchLevel, witness: inout Witness) throws -> DispatchResult {
    var game = DispatchGame(level: level)
    var walked = [Int: (westQueue: Int, eastQueue: Int, island: Int, delivered: Int)]()
    func remember() {
        walked[game.elapsed] = (game.lane(.west).queue, game.lane(.east).queue, game.islandCount, game.delivered)
    }
    remember()
    while !game.finished {
        try validate(game)
        playTurn(&game)
        for lane in DispatchLane.allCases {
            let state = game.lane(lane)
            switch state.vehicle {
            case .car: witness.cars = true
            case .tractor: witness.tractors = true
            case .trailer: witness.trailers = true
            case .train: witness.trains = true
            case nil: break
            }
            if state.crossingDirection == .west { witness.westbound = true }
        }
        game.tick()
        remember()
    }
    try validate(game)
    guard let result = game.result else { throw CheckError("Missing result") }
    try check(result.complete && (1...3).contains(result.stars), "Unreachable shift \(level.id) \(level.dailyKey ?? ""): \(result.delivered)/\(level.total)")
    try check(level.duration - 45 <= result.elapsed && result.elapsed <= level.duration, "Bad pacing")
    try check(result.replay.count == 7, "Incomplete replay")
    for (index, frame) in result.replay.enumerated() {
        let original = walked[frame.elapsed]
        try check(original?.westQueue == frame.westQueue && original?.eastQueue == frame.eastQueue &&
                  original?.island == frame.island && original?.delivered == frame.delivered, "Replay disagrees with live shift")
        if index > 0 { try check(frame.elapsed == result.replay[index-1].elapsed + 1, "Replay skips time") }
    }
    return result
}

func exerciseMechanics() throws {
    var game = DispatchGame(level: DispatchLevel.campaign[0])
    try check(game.release(.east, fromIsland: false) == 0, "Signal should protect the road")
    game.setSignal(.west, birds: true)
    try check(game.release(.east, fromIsland: false) == 3, "Initial group must enter")
    try check(game.islandCount == 0 && game.islandReserved == 3, "Island should reserve space in transit")
    game.setPaused(true)
    let paused = game
    game.tick(20)
    game.setSignal(.east, birds: true)
    try check(paused == game && game.release(.west, fromIsland: false) == 0, "Pause modified the shift")
    game.setPaused(false)
    game.tick(3)
    try check(game.islandCount == 3 && game.delivered == 0, "A crossing must stop on the island")
    game.setSignal(.east, birds: true)
    for _ in 0..<5 {
        if game.release(.east, fromIsland: true) > 0 { break }
        game.tick()
    }
    game.tick(3)
    try check(game.delivered == 3, "Outbound crossing did not deliver the chicks")

    var spill = DispatchGame(level: DispatchLevel.campaign[26])
    spill.setSignal(.west, birds: true)
    spill.tick(50)
    try check(spill.lane(.east).blocked, "Queue overflow should reach the neighbouring road")
    spill.setSignal(.west, birds: false)
    let westBacklog = spill.lane(.west).queue
    var openSeen = false
    for _ in 0..<40 {
        spill.tick()
        if !spill.lane(.east).blocked { openSeen = true }
    }
    try check(openSeen && spill.lane(.west).queue < westBacklog, "Traffic must recover when roads reopen")

    var expiry = DispatchGame(level: DispatchLevel.campaign[35])
    expiry.tick(Int.max)
    try check(expiry.finished && expiry.remaining == 0 && expiry.result?.stars == 0, "Idle shift must expire")
    let ended = expiry
    expiry.tick(); expiry.setSignal(.west, birds: true)
    try check(ended == expiry, "Completed shift changed")
}

func exerciseScoring() throws {
    let level = DispatchLevel.campaign[25]
    var previousScore = Int.max
    for (delay, expectedStars) in [(0, 3), (40, 2), (70, 1)] {
        var shift = DispatchGame(level: level)
        shift.tick(delay)
        while !shift.finished {
            playTurn(&shift)
            shift.tick()
        }
        guard let result = shift.result else { throw CheckError("Missing graded result") }
        try check(result.complete && result.stars == expectedStars, "Waiting must affect stars")
        try check(result.score < previousScore, "Lower quality dispatch should earn a lower score")
        previousScore = result.score
    }
}

func exerciseBook() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("henway-check-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let level = DispatchLevel.campaign[18]
    let book = DispatchBook(directory: directory)
    book.start(level)
    book.setSignal(.west, birds: true)
    try check(book.release(.east, fromIsland: false) == 3, "Book discarded action")
    book.tick(1)
    let midpoint = book.game
    let resumed = DispatchBook(directory: directory)
    try check(resumed.game == midpoint, "Mid-crossing resume diverged")
    resumed.pause()
    resumed.tick(20)
    try check(resumed.game?.elapsed == midpoint?.elapsed, "Paused book advanced")
    try check(DispatchBook(directory: directory).game?.paused == true, "Pause lost on relaunch")
    resumed.resume()
    book.tick(1)
    try check(book.game?.paused == false && book.game?.elapsed == 2, "A second handle overwrote new state")

    while let current = book.game, !current.finished {
        for lane in DispatchLane.allCases {
            let exit: DispatchDirection = lane == .west ? .west : .east
            let entry: DispatchDirection = lane == .west ? .east : .west
            guard let latest = book.game else { throw CheckError("Missing current shift") }
            let outbound = latest.onIsland(exit) > 0
            let inbound = latest.waiting(entry) > 0 && latest.islandReserved < level.capacity
            book.setSignal(lane, birds: outbound || inbound)
            if outbound { book.release(exit, fromIsland: true) }
            else if inbound { book.release(entry, fromIsland: false) }
        }
        book.tick()
    }
    let best = book.campaignBest[level.id]
    try check(best?.complete == true && book.saveError == nil, "Missing campaign record")
    book.restart()
    book.tick(level.duration)
    try check(book.campaignBest[level.id] == best, "Loss replaced a completed record")
    let daily = DispatchLevel.daily(on: Date(timeIntervalSince1970: 1_794_000_000))
    book.start(daily); book.tick(daily.duration)
    try check(DispatchBook(directory: directory).dailyBest[daily.dailyKey!] != nil, "Daily record lost")

    book.start(level)
    book.tick(6)
    let previous = book.game
    book.tick(1)
    try Data("interrupted save".utf8).write(to: directory.appendingPathComponent("dispatch-book.json"), options: .atomic)
    let recovered = DispatchBook(directory: directory)
    try check(recovered.game == previous && recovered.campaignBest[level.id] == best, "Backup could not restore the shift")
    recovered.clearCurrent()
    try check(recovered.game == nil && recovered.campaignBest[level.id] == best, "Clear-current erased history")
    recovered.clearAll()
    try Data("damaged primary".utf8).write(to: directory.appendingPathComponent("dispatch-book.json"), options: .atomic)
    let erased = DispatchBook(directory: directory)
    try check(erased.game == nil && erased.campaignBest.isEmpty && erased.dailyBest.isEmpty, "Reset resurrected backup")
}

do {
    let campaign = DispatchLevel.campaign
    try check(campaign.count == 36 && Set(campaign.map(\.id)).count == 36, "Campaign requires 36 unique shifts")
    var completionTimes = [Int]()
    var stars = [Int: Int]()
    for level in campaign {
        var witness = Witness()
        let finish = try solve(level, witness: &witness)
        completionTimes.append(finish.elapsed); stars[finish.stars, default: 0] += 1
        try check(witness.cars, "No road traffic")
        try check(witness.westbound == (level.district != .farm), "Directional progression missing")
        if level.district == .mill || level.district == .station {
            try check(witness.tractors && witness.trailers, "Missing tractor-and-trailer convoy")
        }
        try check(witness.trains == (level.district == .station), "Unexpected train timetable")
    }
    let parser = ISO8601DateFormatter()
    let utc = parser.date(from: "2026-11-27T00:00:00Z")!
    let local = parser.date(from: "2026-11-26T19:00:00-05:00")!
    try check(DispatchLevel.daily(on: utc) == DispatchLevel.daily(on: local), "Daily seed depends on timezone")
    try check(DispatchLevel.daily(on: utc).dailyKey == "2026-11-27", "Incorrect UTC key")
    for days in [-1000, -31, -1, 0, 1, 36, 150, 365] {
        let date = utc.addingTimeInterval(TimeInterval(days * 86_400))
        let level = DispatchLevel.daily(on: date)
        try check(DispatchGame(level: level) == DispatchGame(level: DispatchLevel.daily(on: date)), "Daily schedules differ")
        var witness = Witness()
        _ = try solve(level, witness: &witness)
    }
    try exerciseMechanics()
    try exerciseScoring()
    try exerciseBook()
    print("36 campaign and 8 UTC daily shifts solved. Completion \(completionTimes.min()!)–\(completionTimes.max()!) s. Stars \(stars).")
    print("Conservation, road safety, spillback, replay, pause, convoy, train schedules and atomic persistence passed.")
} catch {
    FileHandle.standardError.write(Data("FAILED: \(error)\n".utf8))
    exit(1)
}
