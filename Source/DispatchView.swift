import SwiftUI
import Combine

func hd(_ key: String) -> String { NSLocalizedString(key, comment: "") }

extension DispatchDistrict {
    var title: String {
        switch self {
        case .farm: hd("Farm")
        case .market: hd("Market")
        case .mill: hd("Mill")
        case .station: hd("Station")
        }
    }
    var symbol: String {
        switch self {
        case .farm: "leaf.fill"
        case .market: "basket.fill"
        case .mill: "gearshape.2.fill"
        case .station: "tram.fill"
        }
    }
    var note: String {
        switch self {
        case .farm: hd("Guide your first flocks from the west bank.")
        case .market: hd("Expect flocks from both sides of the road.")
        case .mill: hd("Leave room for tractors and their trailers.")
        case .station: hd("Keep the tracks clear for scheduled trains.")
        }
    }
}

private let pine = Color(red: 0.078, green: 0.20, blue: 0.19)
private let paper = Color(red: 0.966, green: 0.942, blue: 0.86)
private let card = Color(red: 1, green: 0.985, blue: 0.931)
private let rust = Color(red: 0.59, green: 0.224, blue: 0.105)
private let gold = Color(red: 0.98, green: 0.78, blue: 0.34)
private let muted = Color(red: 0.25, green: 0.34, blue: 0.30)
private func clockText(_ seconds: Int) -> String { String(format: "%d:%02d", seconds / 60, seconds % 60) }
private enum Page { case desk, map, crossing, schedule, report, replay, guide }

private final class Desk: ObservableObject {
    let book: DispatchBook
    @Published var page: Page = .desk
    @Published var selected: DispatchDistrict = .farm
    @Published var pending: DispatchLevel?
    @Published var frame = 0
    @Published var play = false
    var demo = false
    init() {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        let args = ProcessInfo.processInfo.arguments
        demo = env["APPSTORE_SCREENSHOTS"] == "1" || args.contains("-AppStoreScreenshots")
        let isolated = demo || args.contains("-UITestCleanSession")
        book = DispatchBook(directory: isolated ? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) : nil)
        if demo {
            let index = Int(env["APPSTORE_SCREENSHOT_SCREEN"] ?? "") ?? (args.firstIndex(of: "-AppStoreScreenshotScreen").flatMap { args.indices.contains($0 + 1) ? Int(args[$0+1]) : nil } ?? 0)
            if index >= 2 {
                var sample = DispatchGame(level: DispatchLevel.campaign[index == 2 ? 12 : 30])
                let ticks = index >= 4 ? 205 : (index == 2 ? 34 : 38)
                for _ in 0..<ticks {
                    guard !sample.finished else { break }
                    for lane in DispatchLane.allCases {
                        let exit: DispatchDirection = lane == .west ? .west : .east
                        let entry: DispatchDirection = lane == .west ? .east : .west
                        let out = sample.onIsland(exit) > 0
                        let into = sample.waiting(entry) > 0 && sample.islandReserved < sample.level.capacity
                        sample.setSignal(lane, birds: out || into)
                        if out { sample.release(exit, fromIsland: true) }
                        else if into { sample.release(entry, fromIsland: false) }
                    }
                    sample.tick()
                }
                book.installPreview(sample)
            }
            page = [.desk, .map, .crossing, .schedule, .report, .replay][min(5,max(0,index))]
            if index == 1 { selected = .market }
            if index == 5 { frame = 3 }
        } else { book.pause() }
        #else
        book = DispatchBook()
        book.pause()
        #endif
    }
    func refresh(_ action: () -> Void) { objectWillChange.send(); action() }
    func request(_ level: DispatchLevel) {
        if let current = book.game, !current.finished, current.level != level { pending = level }
        else if let current = book.game, !current.finished, current.level == level { enter() }
        else { start(level) }
    }
    func start(_ level: DispatchLevel) { book.start(level); enter() }
    func enter() { book.resume(); page = .crossing }
    func leave(_ dest: Page) { book.pause(); play = false; page = dest }
    func tick() {
        guard !demo else { return }
        if page == .crossing, let g = book.game, !g.paused, !g.finished {
            refresh { book.tick() }
            if book.game?.finished == true { page = .report }
        } else if page == .replay && play, let frames = book.game?.result?.replay, !frames.isEmpty {
            if frame >= frames.count - 1 { play = false } else { frame += 1 }
        }
    }
    var next: DispatchLevel { DispatchLevel.campaign.first { book.campaignBest[$0.id]?.complete != true } ?? DispatchLevel.campaign[0] }
}

@main struct HenwayDispatchApp: App {
    var body: some Scene { WindowGroup { DispatchView() } }
}

struct DispatchView: View {
    @StateObject private var desk = Desk()
    @Environment(\.scenePhase) private var phase
    @Environment(\.layoutDirection) private var readingDirection
    @State private var guideFromGame = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 13) {
                    masthead
                    switch desk.page {
                    case .desk: home
                    case .map: shiftMap
                    case .crossing: if let game = desk.book.game { crossing(game) }
                    case .schedule: if let game = desk.book.game { timetable(game) }
                    case .report: if let game = desk.book.game, let result = game.result { report(game, result) }
                    case .replay: if let game = desk.book.game, let result = game.result { replay(game, result) }
                    case .guide: guide
                    }
                    if desk.book.saveError != nil { Text(hd("Progress could not be saved on this device.")).foregroundStyle(rust) }
                }
                .frame(maxWidth: 760)
                .padding(.horizontal, 18).padding(.top, 7).padding(.bottom, 25)
                .frame(maxWidth: .infinity)
            }.id(desk.page)
        }
        .foregroundStyle(pine).tint(rust).preferredColorScheme(.light)
        .onReceive(timer) { _ in desk.tick() }
        .onChange(of: phase) { _, newValue in
            if newValue != .active && desk.page == .crossing { desk.refresh { desk.book.pause() } }
        }
        .alert(hd("Replace the current shift?"), isPresented: Binding(get: { desk.pending != nil }, set: { if !$0 { desk.pending = nil } }), presenting: desk.pending) { level in
            Button(hd("Start shift")) { desk.pending = nil; desk.start(level) }
            Button(hd("Cancel"), role: .cancel) { desk.pending = nil }
        } message: { _ in Text(hd("Your finished shifts and records are saved.")) }
    }

    private var masthead: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.swap").font(.headline.weight(.black))
            Text(verbatim: "HENWAY DISPATCH").font(.caption.weight(.heavy)).tracking(2)
            Spacer()
            if desk.page != .desk {
                Button { desk.leave(.desk) } label: { Image(systemName: "house").frame(minWidth: 44,minHeight: 38) }
                    .accessibilityLabel(hd("Dispatch desk")).accessibilityIdentifier("home")
            } else {
                Button { guideFromGame = false; desk.page = .guide } label: { Image(systemName:"questionmark.circle").frame(minWidth:44,minHeight:38) }
                    .accessibilityLabel(hd("Field guide")).accessibilityIdentifier("guide")
            }
        }.foregroundStyle(pine).overlay(alignment: .bottom) { Rectangle().fill(pine.opacity(0.28)).frame(height: 1) }
    }

    private func headline(_ title: String) -> some View {
        Text(title).font(.system(.largeTitle, design: .serif, weight: .bold)).kerning(-0.8)
            .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
    }
    private func eyebrow(_ text: String, color: Color = muted) -> some View {
        Text(text.localizedUppercase).font(.caption2.weight(.heavy)).tracking(1.3).foregroundStyle(color)
    }
    private func action(_ text: String, _ icon: String, id: String, dark: Bool = true, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) { HStack { Image(systemName:icon); Text(text).fontWeight(.bold); Spacer(); Image(systemName:"chevron.forward").font(.caption.bold()) }
                .padding(.horizontal,14).padding(.vertical,12).frame(minHeight:46)
                .foregroundStyle(dark ? .white : pine).background(dark ? pine : card, in: RoundedRectangle(cornerRadius:13))
                .overlay { RoundedRectangle(cornerRadius:13).stroke(pine.opacity(dark ? 0 : 0.25)) }
        }.buttonStyle(.plain).accessibilityIdentifier(id)
    }
    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment:.leading,spacing:4) {
            Text(value).font(.system(.title2,design:.rounded,weight:.bold)).monospacedDigit()
            Text(label).font(.caption.weight(.semibold))
        }.frame(maxWidth:.infinity,alignment:.leading)
    }
    private var home: some View {
        let next = desk.next
        let current = desk.book.game
        let day = DispatchLevel.daily(on: Date())
        return VStack(alignment:.leading,spacing:13) {
            headline(hd("Dispatch desk"))
            Image("CrossingMorning").resizable().aspectRatio(1.95,contentMode:.fill)
                .frame(maxWidth:.infinity).aspectRatio(1.95,contentMode:.fit).clipShape(RoundedRectangle(cornerRadius:17))
                .accessibilityHidden(true)
            let active = current.flatMap { $0.finished ? nil : $0 }
            let featured = active?.level ?? next
            VStack(alignment:.leading,spacing:9) {
                eyebrow(active == nil ? hd("Next shift") : hd("Shift in progress"), color: gold)
                HStack { Image(systemName: featured.district.symbol); Text(featured.district.title).font(.title2.bold()); Spacer()
                    Text(clockText(active?.remaining ?? featured.duration)).monospacedDigit().font(.headline) }
                Text(featured.district.note).font(.subheadline)
                Button { if active != nil { desk.enter() } else { desk.request(next) } } label: {
                    HStack { Text(active == nil ? hd("Start shift") : hd("Resume shift")).bold(); Spacer(); Image(systemName:"arrow.forward") }
                        .padding(11).foregroundStyle(pine).background(gold,in:RoundedRectangle(cornerRadius:9))
                }.buttonStyle(.plain).accessibilityIdentifier("start")
            }.padding(16).foregroundStyle(.white).background(pine,in:RoundedRectangle(cornerRadius:15))
            action(hd("Shift map"),"map",id:"map",dark:false) { desk.page = .map }
            Button { desk.request(day) } label: {
                HStack { Image(systemName:"sunrise.fill").foregroundStyle(rust).font(.title2)
                    VStack(alignment:.leading) {Text(hd("Daily shift")).bold(); Text([day.district.title,day.dailyKey ?? ""].joined(separator:" · ")).font(.caption)}
                    Spacer()
                    if let best = desk.book.dailyBest[day.dailyKey ?? ""] { Text("★ \(best.stars)").font(.caption.bold()) }
                    Image(systemName:"chevron.forward").font(.caption.bold()) }
                    .padding(14).background(card,in:RoundedRectangle(cornerRadius:13))
            }.buttonStyle(.plain).accessibilityIdentifier("daily")
            if let current, current.finished { action(hd("Last shift report"),"doc.text",id:"last-report",dark:false) { desk.page = .report } }
        }
    }

    private var shiftMap: some View {
        let district = desk.selected
        return VStack(alignment:.leading,spacing:14) {
            headline(hd("Shift map"))
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:8) {
                ForEach(DispatchDistrict.allCases,id:\.self) { item in
                    Button { desk.selected = item } label: { HStack { Image(systemName:item.symbol); Text(item.title).bold(); Spacer() }.padding(12)
                        .foregroundStyle(item == district ? .white : pine).background(item == district ? pine : card,in:RoundedRectangle(cornerRadius:10)) }
                        .buttonStyle(.plain).accessibilityIdentifier("district-" + item.rawValue)
                }
            }
            VStack(alignment:.leading,spacing:7) { eyebrow(hd("District")); Text(district.title).font(.system(.title,design:.serif,weight:.bold)); Text(district.note).font(.subheadline) }
                .frame(maxWidth:.infinity,alignment:.leading).padding(16).background(gold.opacity(0.65),in:RoundedRectangle(cornerRadius:14))
            let levels = DispatchLevel.campaign.filter { $0.district == district }
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible())],spacing:9) {
                ForEach(levels) { level in
                    Button { desk.request(level) } label: {
                        VStack(alignment:.leading,spacing:5) {
                            eyebrow(hd("Shift")); Text(String(format:"%02d",level.number)).font(.system(.title,design:.serif,weight:.bold))
                            if let result = desk.book.campaignBest[level.id] { Text(String(repeating:"★",count:result.stars) + " " + String(result.score)).font(.caption2.bold()).foregroundStyle(rust) }
                            else { Text(clockText(level.duration)).font(.caption.monospacedDigit()).foregroundStyle(muted) }
                        }.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(card,in:RoundedRectangle(cornerRadius:12))
                    }.buttonStyle(.plain).accessibilityIdentifier("level-\(level.id)")
                }
            }
        }
    }

    private func crossing(_ game: DispatchGame) -> some View {
        VStack(alignment:.leading,spacing:10) {
            HStack { headline(game.level.district.title); Spacer()
                Button { desk.refresh { if game.paused { desk.book.resume() } else { desk.book.pause() } } } label: {
                    Image(systemName:game.paused ? "play.fill" : "pause.fill").frame(width:44,height:44).background(card,in:Circle())
                }.accessibilityLabel(game.paused ? hd("Resume shift") : hd("Pause shift")).accessibilityIdentifier("pause")
            }
            HStack { stat(hd("Time left"),clockText(game.remaining)); stat(hd("Delivered"),"\(game.delivered)/\(game.level.total)"); stat(hd("Island"),"\(game.islandCount)/\(game.level.capacity)") }.padding(11).foregroundStyle(.white).background(pine,in:RoundedRectangle(cornerRadius:12))
            CrossingField(game:game).aspectRatio(1.7,contentMode:.fit).clipShape(RoundedRectangle(cornerRadius:14))
            Text(game.paused ? hd("Shift paused. Resume when you are ready.") : hint(game))
                .font(.subheadline.weight(.medium)).foregroundStyle(pine).fixedSize(horizontal:false,vertical:true)
            HStack(alignment:.top,spacing:8) {
                laneCard(.west,game).environment(\.layoutDirection, readingDirection)
                laneCard(.east,game).environment(\.layoutDirection, readingDirection)
            }.environment(\.layoutDirection,.leftToRight)
            HStack { Button(hd("Timetable")) { desk.leave(.schedule) }.accessibilityIdentifier("timetable"); Spacer()
                Button(hd("Field guide")) { guideFromGame = true; desk.leave(.guide) } }.font(.subheadline.bold()).padding(.vertical,8)
        }
    }
    private func hint(_ g: DispatchGame) -> String {
        if g.lane(.west).blocked || g.lane(.east).blocked { return hd("Open the busiest road to traffic to clear the queue.") }
        if g.lane(.west).vehicle == .train || g.lane(.east).vehicle == .train { return hd("Hold the flock until the train clears.") }
        if g.islandCount > 0 { return hd("Open the exit lane for birds, then send the flock to the bank.") }
        if g.waiting(.east) + g.waiting(.west) > 0 { return hd("Set the waiting flock’s lane to birds, then send it to the island.") }
        return hd("Open idle lanes to traffic while the next flock approaches.")
    }
    private func laneCard(_ lane: DispatchLane, _ g: DispatchGame) -> some View {
        let state = g.lane(lane), west = lane == .west
        let entry: DispatchDirection = west ? .east : .west
        let exit: DispatchDirection = west ? .west : .east
        return VStack(alignment:.leading,spacing:8) {
            Text(west ? hd("West lane") : hd("East lane")).font(.headline)
            Button { desk.refresh { desk.book.setSignal(lane,birds:!state.birdsGreen) } } label:{
                Label(state.birdsGreen ? hd("Birds") : hd("Traffic"),systemImage:state.birdsGreen ? "bird.fill" : "car.fill")
                    .font(.subheadline.bold()).frame(maxWidth:.infinity,minHeight:40).foregroundStyle(state.birdsGreen ? pine : .white)
                    .background(state.birdsGreen ? gold : pine,in:RoundedRectangle(cornerRadius:8))
            }.buttonStyle(.plain).accessibilityIdentifier("signal-"+lane.rawValue).disabled(g.paused)
            ForEach([false,true],id:\.self) { fromIsland in
                let dir = fromIsland ? exit : entry
                let n = fromIsland ? g.onIsland(dir) : g.waiting(dir)
                let can = g.releasable(dir,fromIsland:fromIsland)>0 && !g.paused
                Button { desk.refresh { _ = desk.book.release(dir,fromIsland:fromIsland) } } label:{
                    HStack(spacing:3) { Text(fromIsland ? hd("To bank") : hd("To island")); Spacer(); Text(String(n)).monospacedDigit() }
                        .font(.caption.bold()).frame(minHeight:35).padding(.horizontal,7)
                        .foregroundStyle(can ? .white : muted).background(can ? rust : paper,in:RoundedRectangle(cornerRadius:7))
                }.buttonStyle(.plain).disabled(!can).accessibilityIdentifier((fromIsland ? "exit-" : "enter-")+lane.rawValue)
            }
            HStack { Image(systemName:"car.2.fill"); Text(String(state.queue)).monospacedDigit(); Text(hd("queued")).lineLimit(2) }.font(.caption2).foregroundStyle(muted)
        }.padding(10).frame(maxWidth:.infinity,alignment:.topLeading).background(card,in:RoundedRectangle(cornerRadius:12))
    }

    private func timetable(_ g: DispatchGame) -> some View {
        VStack(alignment:.leading,spacing:12) {
            headline(hd("Timetable"))
            HStack { Image(systemName:g.level.district.symbol); Text(g.level.district.title).bold(); Spacer(); Text(clockText(g.elapsed)).monospacedDigit() }
                .padding(12).foregroundStyle(.white).background(pine,in:RoundedRectangle(cornerRadius:12))
            if !g.trainSchedule.isEmpty {
                eyebrow(hd("Train reservations"),color:rust)
                ForEach(g.trainSchedule,id:\.self) { t in HStack { Image(systemName:"tram.fill"); Text(hd("Scheduled train")); Spacer(); Text(clockText(t)).monospacedDigit().bold() }.padding(12).background(gold.opacity(0.5),in:RoundedRectangle(cornerRadius:9)) }
            }
            eyebrow(hd("Flock arrivals"))
            ForEach(Array(g.birdSchedule.enumerated()),id:\.offset) { _, a in
                HStack { Text(clockText(a.time)).font(.subheadline.monospacedDigit().bold()).frame(minWidth:43,alignment:.leading)
                    Text(a.direction == .east ? hd("West bank") : hd("East bank")); Spacer()
                    Image(systemName:"bird.fill").foregroundStyle(rust); Text(String(a.count)) }.padding(10)
                    .background(card,in:RoundedRectangle(cornerRadius:8))
            }
            action(hd("Resume shift"),"play.fill",id:"timetable-resume") { desk.enter() }
        }
    }

    private func report(_ g: DispatchGame,_ r: DispatchResult) -> some View {
        VStack(alignment:.leading,spacing:14) {
            headline(hd("Shift report"))
            VStack(alignment:.leading,spacing:9) {
                eyebrow(g.level.district.title,color:gold)
                HStack { ForEach(0..<3,id:\.self) { i in Image(systemName:i < r.stars ? "star.fill" : "star").foregroundStyle(gold) } }.font(.title)
                Text(String(r.score)).font(.system(size:62,weight:.heavy,design:.rounded)).monospacedDigit()
                Text(r.complete ? hd("All flocks delivered") : hd("Shift ended")).font(.headline)
            }.padding(21).frame(maxWidth:.infinity,alignment:.leading).foregroundStyle(.white).background(pine,in:RoundedRectangle(cornerRadius:16))
            HStack { stat(hd("Delivered"),"\(r.delivered)/\(r.total)"); stat(hd("Shift time"),clockText(r.elapsed)) }.padding(14).background(card,in:RoundedRectangle(cornerRadius:12))
            metric(hd("Flock waiting time"),clockText(r.birdWait)); metric(hd("Traffic waiting time"),clockText(r.trafficWait)); metric(hd("Longest queue"),String(r.longestQueue))
            action(hd("Crossing replay"),"play.rectangle.fill",id:"replay") { desk.frame = 0; desk.play = false; desk.page = .replay }
            action(hd("Try this shift again"),"arrow.counterclockwise",id:"restart",dark:false) { desk.start(g.level) }
            action(hd("Shift map"),"map",id:"report-map",dark:false) { desk.page = .map }
        }
    }
    private func metric(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).fontWeight(.bold).monospacedDigit() }.font(.subheadline).padding(.horizontal,6)
    }
    private func replay(_ game: DispatchGame,_ result: DispatchResult) -> some View {
        VStack(alignment:.leading,spacing:15) {
            headline(hd("Crossing replay")); eyebrow(hd("Busiest moment"),color:rust)
            if !result.replay.isEmpty {
                let i = min(desk.frame,result.replay.count-1)
                let f = result.replay[i]
                CrossingReplayField(frame:f,district:game.level.district).aspectRatio(1.7,contentMode:.fit).clipShape(RoundedRectangle(cornerRadius:14))
                HStack { stat(hd("Shift time"),clockText(f.elapsed)); stat(hd("Island"),String(f.island)); stat(hd("Delivered"),String(f.delivered)) }.padding(14).foregroundStyle(.white).background(pine,in:RoundedRectangle(cornerRadius:12))
                HStack(spacing:5) { ForEach(result.replay.indices,id:\.self) { n in
                    Button { desk.frame = n; desk.play = false } label: { Rectangle().fill(n <= i ? rust : muted.opacity(0.25)).frame(height:7).frame(maxWidth:.infinity,minHeight:38) }
                        .accessibilityLabel(clockText(result.replay[n].elapsed)).accessibilityIdentifier("frame-\(n)")
                } }
                action(desk.play ? hd("Pause replay") : hd("Play replay"),desk.play ? "pause.fill" : "play.fill",id:"play-replay") {
                    if !desk.play && i == result.replay.count-1 { desk.frame = 0 }
                    desk.play.toggle()
                }
                metric(hd("West queue"),String(f.westQueue)); metric(hd("East queue"),String(f.eastQueue))
            }
            action(hd("Shift report"),"doc.text",id:"back-report",dark:false) { desk.leave(.report) }
        }
    }
    private var guide: some View {
        VStack(alignment:.leading,spacing:14) {
            headline(hd("Field guide"))
            ForEach(Array([(hd("Signals"),hd("Tap Traffic to give birds the signal. A vehicle already moving must clear first.")),(hd("Cross in two stages"),hd("Send up to three birds to the island. Open their exit lane, then tap To bank to deliver them.")),(hd("Traffic queues"),hd("Tap Birds to let cars pass. Long queues can block the neighbouring lane.")),(hd("Score"),hd("Deliver every flock before time runs out. Shorter waits for birds and traffic earn more stars."))].enumerated()),id:\.offset) { i, item in
                VStack(alignment:.leading,spacing:6) { Text(item.0).font(.headline); Text(item.1).font(.subheadline) }
                    .frame(maxWidth:.infinity,alignment:.leading).padding(16).background(i == 0 ? gold.opacity(0.6) : card,in:RoundedRectangle(cornerRadius:12))
            }
            action(guideFromGame ? hd("Resume shift") : hd("Dispatch desk"),"arrow.forward",id:"guide-done") { if guideFromGame { desk.enter() } else { desk.page = .desk } }
        }
    }
}
