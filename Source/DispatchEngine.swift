import Foundation

enum DispatchDistrict: String, CaseIterable, Codable {
    case farm, market, mill, station
}

enum DispatchDirection: String, CaseIterable, Codable {
    case east, west

    var entry: DispatchLane { self == .east ? .west : .east }
    var exit: DispatchLane { self == .east ? .east : .west }
}

enum DispatchLane: String, CaseIterable, Codable {
    case west, east

    var opposite: DispatchLane { self == .west ? .east : .west }
}

enum DispatchVehicle: String, Codable {
    case car, tractor, trailer, train
}

struct DispatchLevel: Codable, Identifiable, Equatable {
    let id: Int
    let district: DispatchDistrict
    let number: Int
    let duration: Int
    let capacity: Int
    let total: Int
    let seed: UInt64
    let dailyKey: String?
    var isDaily: Bool { dailyKey != nil }

    static let campaign: [Self] = (0..<36).map { index in
        let district = DispatchDistrict.allCases[index / 9]
        return make(id: index + 1, district: district, number: index % 9 + 1,
                    seed: UInt64(index + 1) * 7919 + 4157, dailyKey: nil)
    }

    static func daily(on date: Date) -> Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        let year = day.year ?? 2001, month = day.month ?? 1, dayOfMonth = day.day ?? 1
        let key = String(format: "%04d-%02d-%02d", year, month, dayOfMonth)
        let seed = UInt64(max(1, year * 10_000 + month * 100 + dayOfMonth))
        var random = DispatchRandom(seed: seed)
        let district = DispatchDistrict.allCases[random.take(4)]
        return make(id: 0, district: district, number: 3 + random.take(7), seed: seed, dailyKey: key)
    }

    private static func make(id: Int, district: DispatchDistrict, number: Int,
                             seed: UInt64, dailyKey: String?) -> Self {
        Self(id: id, district: district, number: number, duration: 148 + number * 3,
             capacity: max(4, 7 - (number - 1) / 3), total: 21 + number * 2,
             seed: seed, dailyKey: dailyKey)
    }
}

private struct DispatchRandom {
    var seed: UInt64
    mutating func take(_ bound: Int) -> Int {
        seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int((seed >> 33) % UInt64(bound))
    }
}

struct DispatchArrival: Codable, Equatable {
    let time: Int
    let direction: DispatchDirection
    let count: Int
}

private struct DispatchRoadArrival: Codable, Equatable {
    let time: Int
    let lane: DispatchLane
    let vehicle: DispatchVehicle
}

private struct DispatchTimetable: Codable, Equatable {
    let birds: [DispatchArrival]
    let vehicles: [DispatchRoadArrival]
    let trains: [Int]

    init(level: DispatchLevel) {
        var generator = DispatchRandom(seed: level.seed)
        var birds: [DispatchArrival] = []
        var birdsLeft = level.total
        let groups = (level.total + 2) / 3
        for i in 0..<groups {
            let count = min(3, birdsLeft)
            let time = i == 0 ? 0 : 2 + i * (level.duration - 35) / max(1, groups - 1) + generator.take(3)
            let direction: DispatchDirection = level.district == .farm ? .east : (i.isMultiple(of: 2) ? .east : .west)
            birds.append(DispatchArrival(time: time, direction: direction, count: count))
            birdsLeft -= count
        }
        self.birds = birds

        var roads: [DispatchRoadArrival] = []
        for side in DispatchLane.allCases {
            var time = 2 + generator.take(4)
            var entry = 0
            while time < level.duration {
                let isTractor = (level.district == .mill || level.district == .station) && (entry + (side == .east ? 1 : 0)).isMultiple(of: 3)
                roads.append(DispatchRoadArrival(time: time, lane: side, vehicle: isTractor ? .tractor : .car))
                let interval = level.district == .farm ? 9 : 7
                time += max(4, interval + generator.take(5) - level.number / 4)
                entry += 1
            }
        }
        self.vehicles = roads.sorted { $0.time != $1.time ? $0.time < $1.time : $0.lane.rawValue < $1.lane.rawValue }
        self.trains = level.district == .station ? [32 + generator.take(7), 74 + generator.take(9), 111 + generator.take(8)] : []
    }
}

private struct DispatchCrossing: Codable, Equatable {
    let direction: DispatchDirection
    let fromIsland: Bool
    let count: Int
    var seconds: Int
}

private struct DispatchRoad: Codable, Equatable {
    var birdsGreen = false
    var queue: [DispatchVehicle] = []
    var vehicle: DispatchVehicle?
    var vehicleSeconds = 0
    var birds: DispatchCrossing?
}

struct DispatchLaneState: Equatable {
    let birdsGreen: Bool
    let queue: Int
    let blocked: Bool
    let vehicle: DispatchVehicle?
    let crossingBirds: Int
    let crossingDirection: DispatchDirection?
    let fromIsland: Bool?
    let crossingSeconds: Int
    let vehicleSeconds: Int
    let trainIn: Int?
}

struct DispatchFrame: Codable, Equatable {
    let elapsed: Int
    let westQueue: Int
    let eastQueue: Int
    let island: Int
    let delivered: Int
    let westWaiting: Int
    let eastWaiting: Int
    let westGreen: Bool
    let eastGreen: Bool
    let westCrossing: Int
    let eastCrossing: Int
    let westVehicle: DispatchVehicle?
    let eastVehicle: DispatchVehicle?
    var eastboundIsland: Int?
    var westboundIsland: Int?
    var islandCapacity: Int?
    var westDirection: DispatchDirection?
    var eastDirection: DispatchDirection?
    var westBirdSeconds: Int?
    var eastBirdSeconds: Int?
    var westVehicleSeconds: Int?
    var eastVehicleSeconds: Int?
    var westBlocked: Bool?
    var eastBlocked: Bool?

    fileprivate var activity: Int {
        3 * (westCrossing + eastCrossing) + 2 * (westQueue + eastQueue) + island +
            westWaiting + eastWaiting + (westVehicle == nil ? 0 : 2) + (eastVehicle == nil ? 0 : 2)
    }
}

struct DispatchResult: Codable, Equatable {
    let stars: Int
    let score: Int
    let delivered: Int
    let total: Int
    let elapsed: Int
    let replay: [DispatchFrame]
    let birdWait: Int
    let trafficWait: Int
    let longestQueue: Int
    var complete: Bool { delivered == total }
}

struct DispatchGame: Codable, Equatable {
    let level: DispatchLevel
    private(set) var elapsed = 0
    private(set) var delivered = 0
    private(set) var paused = false
    private(set) var result: DispatchResult?
    private(set) var birdWait = 0
    private(set) var trafficWait = 0
    private(set) var longestQueue = 0

    private var westRoad = DispatchRoad(), eastRoad = DispatchRoad()
    private var eastboundWaiting = 0, westboundWaiting = 0
    private var eastboundIsland = 0, westboundIsland = 0
    private let timetable: DispatchTimetable
    private var birdIndex = 0, vehicleIndex = 0
    private var frames: [DispatchFrame] = []
    private static let crossingDuration = 3
    private static let trainDuration = 6

    init(level: DispatchLevel) {
        self.level = level
        timetable = DispatchTimetable(level: level)
        applyArrivals()
        recordFrame()
    }

    var remaining: Int { max(0, level.duration - elapsed) }
    var finished: Bool { result != nil }
    var islandCount: Int { eastboundIsland + westboundIsland }
    var islandReserved: Int { islandCount + [westRoad, eastRoad].compactMap(\.birds).filter { !$0.fromIsland }.reduce(0) { $0 + $1.count } }
    var upcomingTrains: [Int] { timetable.trains.filter { $0 >= elapsed } }
    var trainSchedule: [Int] { timetable.trains }
    var nextArrival: DispatchArrival? { birdIndex < timetable.birds.count ? timetable.birds[birdIndex] : nil }
    var birdSchedule: [DispatchArrival] { timetable.birds }
    var queueLimit: Int { level.district == .farm ? 5 : 4 }
    var birdsYetToArrive: Int { timetable.birds.dropFirst(birdIndex).reduce(0) { $0 + $1.count } }

    func waiting(_ direction: DispatchDirection) -> Int {
        direction == .east ? eastboundWaiting : westboundWaiting
    }

    func onIsland(_ direction: DispatchDirection) -> Int {
        direction == .east ? eastboundIsland : westboundIsland
    }

    func lane(_ side: DispatchLane) -> DispatchLaneState {
        let road = road(side)
        let trainSeconds = trainRemaining(on: side)
        return DispatchLaneState(birdsGreen: road.birdsGreen, queue: road.queue.count, blocked: spillback(on: side),
                                 vehicle: trainSeconds > 0 ? .train : road.vehicle, crossingBirds: road.birds?.count ?? 0,
                                 crossingDirection: road.birds?.direction, fromIsland: road.birds?.fromIsland,
                                 crossingSeconds: road.birds?.seconds ?? 0, vehicleSeconds: trainSeconds > 0 ? trainSeconds : road.vehicleSeconds,
                                 trainIn: side == .east ? upcomingTrains.first.map { $0 - elapsed } : nil)
    }

    mutating func setPaused(_ value: Bool) {
        if !finished { paused = value }
    }

    mutating func setSignal(_ side: DispatchLane, birds: Bool) {
        guard !paused, !finished else { return }
        if side == .west { westRoad.birdsGreen = birds } else { eastRoad.birdsGreen = birds }
    }

    func releasable(_ direction: DispatchDirection, fromIsland: Bool) -> Int {
        let side = fromIsland ? direction.exit : direction.entry
        let road = road(side)
        guard !paused, !finished, road.birdsGreen, road.birds == nil, road.vehicle == nil,
              !trackReserved(side, for: Self.crossingDuration) else { return 0 }
        let available = fromIsland ? onIsland(direction) : min(waiting(direction), level.capacity - islandReserved)
        return min(3, max(0, available))
    }

    @discardableResult
    mutating func release(_ direction: DispatchDirection, fromIsland: Bool) -> Int {
        let count = releasable(direction, fromIsland: fromIsland)
        guard count > 0 else { return 0 }
        let side = fromIsland ? direction.exit : direction.entry
        switch (direction, fromIsland) {
        case (.east, false): eastboundWaiting -= count
        case (.west, false): westboundWaiting -= count
        case (.east, true): eastboundIsland -= count
        case (.west, true): westboundIsland -= count
        }
        let crossing = DispatchCrossing(direction: direction, fromIsland: fromIsland, count: count, seconds: Self.crossingDuration)
        if side == .west { westRoad.birds = crossing } else { eastRoad.birds = crossing }
        return count
    }

    mutating func tick(_ seconds: Int = 1) {
        guard !paused, !finished, seconds > 0 else { return }
        for _ in 0..<min(seconds, remaining) {
            birdWait += eastboundWaiting + westboundWaiting + islandCount
            trafficWait += westRoad.queue.count + eastRoad.queue.count
            elapsed += 1
            finishMovement(on: .west)
            finishMovement(on: .east)
            applyArrivals()
            longestQueue = max(longestQueue, max(westRoad.queue.count, eastRoad.queue.count))
            dispatchTraffic(on: .west)
            dispatchTraffic(on: .east)
            recordFrame()
            if delivered == level.total || remaining == 0 {
                finish()
                break
            }
        }
    }

    private func road(_ side: DispatchLane) -> DispatchRoad { side == .west ? westRoad : eastRoad }
    private mutating func put(_ road: DispatchRoad, on side: DispatchLane) {
        if side == .west { westRoad = road } else { eastRoad = road }
    }

    private func trainRemaining(on side: DispatchLane) -> Int {
        guard side == .east, let start = timetable.trains.first(where: { elapsed >= $0 && elapsed < $0 + Self.trainDuration }) else { return 0 }
        return start + Self.trainDuration - elapsed
    }

    private func trackReserved(_ side: DispatchLane, for seconds: Int) -> Bool {
        side == .east && timetable.trains.contains { elapsed < $0 + Self.trainDuration && elapsed + seconds > $0 }
    }

    // A saturated feeder spills into its neighbour. Resolve a two-sided spill in favour
    // of the longer queue so opening both roads will always drain the junction.
    private func spillback(on side: DispatchLane) -> Bool {
        let other = road(side.opposite).queue.count, local = road(side).queue.count
        return other >= queueLimit && (other > local || (other == local && side == .east))
    }

    private mutating func finishMovement(on side: DispatchLane) {
        var road = road(side)
        if var crossing = road.birds {
            crossing.seconds -= 1
            if crossing.seconds == 0 {
                if crossing.fromIsland { delivered += crossing.count }
                else if crossing.direction == .east { eastboundIsland += crossing.count }
                else { westboundIsland += crossing.count }
                road.birds = nil
            } else { road.birds = crossing }
        }
        if let vehicle = road.vehicle {
            road.vehicleSeconds -= 1
            if road.vehicleSeconds == 0 {
                if vehicle == .tractor { road.vehicle = .trailer; road.vehicleSeconds = 2 }
                else { road.vehicle = nil }
            }
        }
        put(road, on: side)
    }

    private mutating func applyArrivals() {
        while birdIndex < timetable.birds.count, timetable.birds[birdIndex].time <= elapsed {
            let arrival = timetable.birds[birdIndex]
            if arrival.direction == .east { eastboundWaiting += arrival.count }
            else { westboundWaiting += arrival.count }
            birdIndex += 1
        }
        while vehicleIndex < timetable.vehicles.count, timetable.vehicles[vehicleIndex].time <= elapsed {
            let arrival = timetable.vehicles[vehicleIndex]
            if arrival.lane == .west { westRoad.queue.append(arrival.vehicle) }
            else { eastRoad.queue.append(arrival.vehicle) }
            vehicleIndex += 1
        }
    }

    private mutating func dispatchTraffic(on side: DispatchLane) {
        var road = road(side)
        guard !road.birdsGreen, road.birds == nil, road.vehicle == nil, let next = road.queue.first,
              !spillback(on: side), !trackReserved(side, for: next == .tractor ? 5 : 2) else { return }
        road.vehicle = road.queue.removeFirst()
        road.vehicleSeconds = next == .tractor ? 3 : 2
        put(road, on: side)
    }

    private mutating func recordFrame() {
        let west = lane(.west), east = lane(.east)
        frames.append(DispatchFrame(elapsed: elapsed, westQueue: west.queue, eastQueue: east.queue,
                                    island: islandCount, delivered: delivered, westWaiting: eastboundWaiting,
                                    eastWaiting: westboundWaiting, westGreen: west.birdsGreen, eastGreen: east.birdsGreen,
                                    westCrossing: west.crossingBirds, eastCrossing: east.crossingBirds,
                                    westVehicle: west.vehicle, eastVehicle: east.vehicle,
                                    eastboundIsland: eastboundIsland, westboundIsland: westboundIsland, islandCapacity: level.capacity,
                                    westDirection: west.crossingDirection, eastDirection: east.crossingDirection,
                                    westBirdSeconds: west.crossingSeconds, eastBirdSeconds: east.crossingSeconds,
                                    westVehicleSeconds: west.vehicleSeconds, eastVehicleSeconds: east.vehicleSeconds,
                                    westBlocked: west.blocked, eastBlocked: east.blocked))
    }

    private mutating func finish() {
        let all = delivered == level.total
        let congestion = birdWait + trafficWait * 2
        let score = max(0, delivered * 120 + (all ? 600 : 0) + remaining * 5 - congestion / 4)
        let stars = all ? (congestion <= level.total * 14 ? 3 : congestion <= level.total * 33 ? 2 : 1) : (delivered == 0 ? 0 : 1)
        let peak = frames.indices.max { frames[$0].activity < frames[$1].activity } ?? 0
        let start = max(0, min(peak - 3, frames.count - 7))
        result = DispatchResult(stars: stars, score: score, delivered: delivered, total: level.total,
                                elapsed: elapsed, replay: Array(frames[start..<min(start + 7, frames.count)]),
                                birdWait: birdWait, trafficWait: trafficWait, longestQueue: longestQueue)
        paused = false
    }
}
