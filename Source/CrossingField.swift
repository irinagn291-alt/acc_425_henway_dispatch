import SwiftUI

struct CrossingField: View {
    let game: DispatchGame
    var body: some View { CrossingMap(state: MapState(game)) }
}

struct CrossingReplayField: View {
    let frame: DispatchFrame
    let district: DispatchDistrict
    var body: some View { CrossingMap(state: MapState(frame, district)) }
}

private struct MapLane {
    let green: Bool, blocked: Bool
    let birds: Int, queue: Int, birdSeconds: Int, vehicleSeconds: Int
    let vehicle: DispatchVehicle?
    let direction: DispatchDirection?

    init(_ lane: DispatchLaneState) {
        green = lane.birdsGreen; blocked = lane.blocked
        birds = lane.crossingBirds; queue = lane.queue; vehicle = lane.vehicle
        direction = lane.crossingDirection; birdSeconds = lane.crossingSeconds; vehicleSeconds = lane.vehicleSeconds
    }

    init(_ frame: DispatchFrame, west: Bool) {
        green = west ? frame.westGreen : frame.eastGreen
        blocked = (west ? frame.westBlocked : frame.eastBlocked) ?? false
        birds = west ? frame.westCrossing : frame.eastCrossing
        queue = west ? frame.westQueue : frame.eastQueue
        vehicle = west ? frame.westVehicle : frame.eastVehicle
        direction = west ? frame.westDirection : frame.eastDirection
        birdSeconds = (west ? frame.westBirdSeconds : frame.eastBirdSeconds) ?? 2
        vehicleSeconds = (west ? frame.westVehicleSeconds : frame.eastVehicleSeconds) ?? 1
    }
}

private struct MapState {
    let district: DispatchDistrict, west: MapLane, east: MapLane
    let westBank: Int, eastBank: Int, eastboundIsland: Int, westboundIsland: Int, capacity: Int
    init(_ game: DispatchGame) {
        district = game.level.district; west = MapLane(game.lane(.west)); east = MapLane(game.lane(.east))
        westBank = game.waiting(.east); eastBank = game.waiting(.west)
        eastboundIsland = game.onIsland(.east); westboundIsland = game.onIsland(.west)
        capacity = game.level.capacity
    }
    init(_ frame: DispatchFrame, _ district: DispatchDistrict) {
        self.district = district; west = MapLane(frame, west: true); east = MapLane(frame, west: false)
        westBank = frame.westWaiting; eastBank = frame.eastWaiting
        eastboundIsland = frame.eastboundIsland ?? frame.island
        westboundIsland = frame.westboundIsland ?? 0
        capacity = frame.islandCapacity ?? frame.island
    }
}

private struct CrossingMap: View {
    let state: MapState

    var body: some View {
        Canvas { context, size in
            var painter = MapPainter(context)
            painter.c.scaleBy(x: size.width / 510, y: size.height / 300)
            painter.paint(state)
        }
        .aspectRatio(1.7, contentMode: .fit)
        .accessibilityHidden(true)
        .environment(\.layoutDirection, .leftToRight)
    }
}

// An overhead map in fixed physical west/east coordinates, including when text runs RTL.
private struct MapPainter {
    var c: GraphicsContext
    init(_ context: GraphicsContext) { c = context }

    private let ink = Color(red: 0.12, green: 0.24, blue: 0.22)
    private let road = Color(red: 0.26, green: 0.36, blue: 0.34)
    private let cream = Color(red: 1.0, green: 0.94, blue: 0.75)
    private let yellow = Color(red: 0.98, green: 0.76, blue: 0.30)
    private let red = Color(red: 0.72, green: 0.32, blue: 0.21)
    private let leaf = Color(red: 0.39, green: 0.56, blue: 0.42)
    private let mint = Color(red: 0.69, green: 0.76, blue: 0.58)
    private let sky = Color(red: 0.56, green: 0.75, blue: 0.72)
    private let timber = Color(red: 0.67, green: 0.49, blue: 0.30)
    private let path = Color(red: 0.88, green: 0.78, blue: 0.57)

    private func rect(_ x: CGFloat,_ y: CGFloat,_ w: CGFloat,_ h: CGFloat,_ fill: Color, radius: CGFloat = 0) {
        c.fill(Path(roundedRect: CGRect(x:x,y:y,width:w,height:h),cornerRadius:radius), with:.color(fill))
    }
    private func circle(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat,_ color:Color) {
        c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:w,height:h)),with:.color(color))
    }
    private func line(_ points:[CGPoint], _ color:Color, _ width:CGFloat = 1) {
        guard let first=points.first else { return }
        var shape=Path();shape.move(to:first);for pt in points.dropFirst() { shape.addLine(to:pt) }
        c.stroke(shape,with:.color(color),style:StrokeStyle(lineWidth:width,lineCap:.round,lineJoin:.round))
    }
    private func polygon(_ points:[CGPoint],_ fill:Color) {
        var shape=Path();shape.addLines(points);shape.closeSubpath();c.fill(shape,with:.color(fill))
    }
    private func pt(_ x:CGFloat,_ y:CGFloat)->CGPoint { CGPoint(x:x,y:y) }

    func paint(_ state:MapState) {
        let ground: Color
        switch state.district {
        case .farm: ground = mint
        case .market: ground = Color(red:0.89,green:0.76,blue:0.59)
        case .mill: ground = Color(red:0.66,green:0.72,blue:0.61)
        case .station: ground = Color(red:0.72,green:0.76,blue:0.67)
        }
        rect(0,0,510,300,ground)
        for row in 0..<12 {
            for col in 0..<17 where (row*17 + col*7).isMultiple(of:4) {
                let x=CGFloat(col*31 + (row%2)*8), y=CGFloat(row*26)
                line([pt(x,y),pt(x+3,y-2)],ink.opacity(0.17),1.3)
            }
        }
        districtDetails(state.district)
        for x in [CGFloat(156),354] {
            rect(x-39,-2,78,304,ink.opacity(0.40))
            rect(x-35,-2,70,304,road)
            line([pt(x-31,0),pt(x-31,300)],cream.opacity(0.62),1.4)
            line([pt(x+31,0),pt(x+31,300)],cream.opacity(0.62),1.4)
            for y in stride(from: 4, through: 302, by: 24) where !(120...187).contains(y) {
                rect(x-1,CGFloat(y),2,13,cream.opacity(0.5),radius:1)
            }
        }
        if state.district == .station {
            for y in stride(from: 0, through: 300, by: 11) {
                rect(335,CGFloat(y),38,3,ink.opacity(0.65),radius:1)
            }
            for x in [CGFloat(342),365] {
                rect(x,0,2.2,300,cream.opacity(0.74));rect(x+2.2,0,1,300,ink)
            }
        }

        // An uninterrupted walking path links the banks and zebra crossings.
        rect(-2,127,119,50,path,radius:5);rect(394,127,119,50,path,radius:5)
        for x in [CGFloat(156),354] {
            for stripe in 0..<6 { rect(x-30+CGFloat(stripe)*10.2,129,5.6,47,cream.opacity(0.84),radius:1.4) }
        }
        rect(198,104,114,99,ink.opacity(0.23),radius:22)
        rect(198,100,112,99,cream,radius:22)
        rect(202,104,104,91,mint,radius:18)
        for spot in 0..<min(9,state.capacity) {
            let pos=islandSpot(spot)
            circle(pos.x-7,pos.y-4,15,10,leaf.opacity(0.33))
        }
        drawBank(state.westBank, left:true)
        drawBank(state.eastBank, left:false)
        for spot in 0..<min(9,state.eastboundIsland+state.westboundIsland) {
            let pos=islandSpot(spot)
            bird(pos.x,pos.y,face:spot < state.eastboundIsland ? .east : .west,scale:0.91)
        }
        laneDetails(state.west,x:156,west:true)
        laneDetails(state.east,x:354,west:false)
    }

    private func islandSpot(_ index:Int)->CGPoint {
        pt(224+CGFloat(index%3)*27,125+CGFloat(index/3)*23)
    }

    private func districtDetails(_ district:DispatchDistrict) {
        switch district {
        case .farm:
            for row in 0..<5 {
                let y=CGFloat(19+row*15)
                line([pt(-6,y+9),pt(76,y-12)],timber.opacity(0.6),4.5)
                for sprout in 0..<5 {
                    let x=CGFloat(9+sprout*13),sy=y+6-x/5
                    line([pt(x,sy),pt(x-2,sy-3),pt(x,sy-1),pt(x+3,sy-4)],leaf,1.6)
                }
            }
            building(421,22,54,53,roof:red,door:true)
            silo(482,35);fence(25,208,78);fence(405,211,70)
            hay(12,264);hay(40,259);tree(483,261,15);tree(446,266,12)
        case .market:
            for x in [CGFloat(10),59,414,463] { stall(x,30,roof:x < 25 || x > 460 ? red : leaf) }
            for x in [CGFloat(12),43,73,420,456] {
                crate(x,223);crate(x+3,246)
                for i in 0..<3 {circle(x+3+CGFloat(i)*4,225,3.5,3.5,i.isMultiple(of:2) ? red : yellow)}
            }
            tree(248,53,15);tree(282,68,11);fence(216,243,70)
        case .mill:
            building(9,18,83,56,roof:leaf,door:true);wheel(97,63)
            for row in 0..<3 {
                for col in 0..<3 { log(414+CGFloat(col)*24,218+CGFloat(row)*15) }
            }
            silo(439,40);silo(470,44);tree(37,247,17);tree(77,271,12)
        case .station:
            platform(5,33,95);platform(407,41,101)
            building(216,9,68,53,roof:red,door:true)
            for x in [CGFloat(26),67,420,468] { bench(x,231) }
            clock(61,84);clock(448,88);fence(217,240,68)
        }
        if district != .market { tree(227,267,11);tree(276,279,8) }
    }

    private func building(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat,roof:Color,door:Bool) {
        rect(x+4,y+7,w,h,ink.opacity(0.23),radius:4)
        rect(x,y+9,w,h-8,cream,radius:4)
        rect(x-3,y,w+6,h*0.64,roof,radius:3)
        line([pt(x-2,y+h*0.29),pt(x+w+2,y+h*0.29)],ink.opacity(0.4),2)
        for i in 1..<6 {
            let xx=x+w*CGFloat(i)/6
            line([pt(xx,y+3),pt(xx,y+h*0.29-2)],cream.opacity(0.25),1.3)
        }
        rect(x+6,y+h*0.70,9,8,sky,radius:1)
        if door { rect(x+w*0.55,y+h*0.65,w*0.18,h*0.34,timber,radius:1.6) }
    }
    private func fence(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat) {
        line([pt(x,y),pt(x+w,y)],cream,3);line([pt(x,y+6),pt(x+w,y+6)],cream,2)
        for n in 0...5 {rect(x+w*CGFloat(n)/5-1.5,y-4,3.4,14,timber,radius:1)}
    }
    private func tree(_ x:CGFloat,_ y:CGFloat,_ radius:CGFloat) {
        circle(x-radius+3,y-radius+4,radius*2,radius*2,ink.opacity(0.20))
        circle(x-radius,y-radius,radius*2,radius*2,leaf)
        circle(x-radius*0.8,y-radius*0.85,radius*1.25,radius*1.25,mint.opacity(0.68))
        line([pt(x-2,y+3),pt(x+2,y+9),pt(x+5,y+5)],ink.opacity(0.35),1.4)
    }
    private func hay(_ x:CGFloat,_ y:CGFloat) {
        rect(x+2,y+3,23,14,ink.opacity(0.2),radius:4)
        rect(x,y,23,14,yellow,radius:4)
        for dx in [CGFloat(6),17] {line([pt(x+dx,y+1),pt(x+dx,y+13)],timber,2)}
    }
    private func silo(_ x:CGFloat,_ y:CGFloat) {
        rect(x,y,21,41,sky,radius:4);circle(x,y-5,21,10,cream)
        for dy in [CGFloat(9),21,33] {line([pt(x+1,y+dy),pt(x+20,y+dy)],ink.opacity(0.38),1.3)}
    }
    private func stall(_ x:CGFloat,_ y:CGFloat,roof:Color) {
        rect(x+3,y+7,38,44,ink.opacity(0.2),radius:3)
        rect(x+2,y+9,34,39,timber,radius:2)
        rect(x,y,39,24,cream,radius:3)
        for i in 0..<4 {rect(x+CGFloat(i)*10,y,5,24,roof,radius:1)}
        rect(x+4,y+30,30,9,cream,radius:2)
        for n in 0..<5 {circle(x+5+CGFloat(n)*5.5,y+30,4.7,5,n.isMultiple(of:2) ? red : yellow)}
    }
    private func crate(_ x:CGFloat,_ y:CGFloat) {
        rect(x,y,18,11,timber,radius:2)
        line([pt(x+2,y+7),pt(x+16,y+7)],cream.opacity(0.65),1)
    }
    private func wheel(_ x:CGFloat,_ y:CGFloat) {
        circle(x-13,y-13,26,26,timber);circle(x-9,y-9,18,18,ink)
        for i in 0..<8 {
            let angle=CGFloat(i) * CGFloat.pi / 4
            line([pt(x,y),pt(x+cos(angle)*10,y+sin(angle)*10)],cream,1.5)
        }
        circle(x-2,y-2,4,4,yellow)
    }
    private func log(_ x:CGFloat,_ y:CGFloat) {
        rect(x,y,22,10,timber,radius:4);circle(x+15,y+1,6,8,cream)
        circle(x+17,y+3,2.5,4,timber)
    }
    private func platform(_ x:CGFloat,_ y:CGFloat,_ width:CGFloat) {
        rect(x,y,width,41,cream,radius:5);rect(x+2,y+35,width-4,4,yellow)
        for i in 1..<5 { line([pt(x+width*CGFloat(i)/5,y+3),pt(x+width*CGFloat(i)/5,y+31)],ink.opacity(0.18),1) }
    }
    private func bench(_ x:CGFloat,_ y:CGFloat) {
        rect(x,y+4,24,12,ink.opacity(0.22),radius:2)
        for offset in [CGFloat(0),5,10] {rect(x,y+offset,24,3,timber,radius:1)}
    }
    private func clock(_ x:CGFloat,_ y:CGFloat) {
        rect(x-1,y+3,2,15,ink)
        circle(x-7,y-7,14,14,ink);circle(x-5.4,y-5.4,10.8,10.8,cream)
        line([pt(x,y-3),pt(x,y),pt(x+3,y+1)],ink,1)
    }

    private func drawBank(_ count:Int,left:Bool) {
        let visible=min(8,count)
        let dir:DispatchDirection=left ? .east : .west
        for i in 0..<visible {
            let index=CGFloat(i%4),row=CGFloat(i/4)
            let x=left ? 99-index*23 : 411+index*23
            bird(x,141+row*23+CGFloat(i%2)*6,face:dir,scale:0.91)
        }
        if count>8 { badge(count,at:pt(left ? 88 : 422,191)) }
    }

    private func bird(_ x:CGFloat,_ y:CGFloat,face:DispatchDirection,scale:CGFloat) {
        var local=self
        local.c.translateBy(x:x,y:y)
        local.c.scaleBy(x:face == .east ? scale : -scale,y:scale)
        local.circle(-10,4,18,6,ink.opacity(0.25))
        local.polygon([pt(-7,-1),pt(-14,-5),pt(-12,1),pt(-8,4)],timber)
        local.circle(-10,-5,17,12,cream)
        local.circle(-6,-4,9,6,yellow.opacity(0.77))
        local.circle(0,-10,10,10,cream)
        local.circle(1,-12,3.8,4.5,red);local.circle(4,-12.5,3.8,4.5,red)
        local.polygon([pt(8,-6),pt(14,-4.6),pt(8,-3)],yellow)
        local.circle(5.5,-7.5,2,2,ink)
        local.line([pt(-4,5),pt(-5,8),pt(-2,8)],timber,1.3)
        local.line([pt(3,5),pt(3,7),pt(6,7)],timber,1.3)
    }

    private func laneDetails(_ lane:MapLane,x:CGFloat,west:Bool) {
        for i in 0..<min(3,lane.queue) {
            let y=west ? 68-CGFloat(i)*25 : 224+CGFloat(i)*25
            // Queued shapes are neutral bumpers; the active vehicle has its actual type.
            rect(x-8,y-8,16,18,cream.opacity(0.78),radius:4)
            rect(x-5,y-5,10,5,road,radius:1.5)
        }
        if lane.queue>3 { badge(lane.queue,at:pt(x+22,west ? 57 : 248)) }
        if lane.blocked {
            for offset in 0..<4 {
                let xx=x-17+CGFloat(offset)*8
                line([pt(xx,west ? 87 : 209),pt(xx+6,west ? 91 : 205)],yellow,2.4)
            }
        }
        if let vehicle=lane.vehicle {
            let ticks:CGFloat=vehicle == .train ? 6 : vehicle == .tractor ? 3 : 2
            let progress=1-CGFloat(lane.vehicleSeconds)/ticks
            let y=west ? 125+progress*61 : 177-progress*61
            drawVehicle(vehicle,x:x,y:y,facingSouth:west)
        }
        if lane.birds>0 {
            let dir=lane.direction
            let progress=(3.0-CGFloat(lane.birdSeconds)+0.5)/3.0
            let centre=x+(dir == .west ? 1 : -1)*(30-progress*60)
            for i in 0..<min(3,lane.birds) {
                bird(centre+CGFloat(i%2)*9,145+CGFloat(i)*8,face:dir ?? .east,scale:0.87)
            }
        }
        signal(x+(west ? -46 : 44),west ? 116 : 181,birds:lane.green)
    }
    private func signal(_ x:CGFloat,_ y:CGFloat,birds:Bool) {
        rect(x-1,y+4,3,14,ink,radius:1)
        rect(x-9,y-10,20,18,ink,radius:4)
        circle(x-6,y-5,7,7,birds ? yellow : ink.opacity(0.9))
        circle(x+2,y-5,7,7,birds ? leaf.opacity(0.55) : sky)
        if birds { line([pt(x-5,y-2),pt(x-3,y),pt(x-1,y-3)],ink,1.2) }
        else { rect(x+3,y-2,5,2,ink,radius:1) }
    }
    private func drawVehicle(_ vehicle:DispatchVehicle,x:CGFloat,y:CGFloat,facingSouth:Bool) {
        var local=self;local.c.translateBy(x:x,y:y)
        if !facingSouth {local.c.rotate(by:.degrees(180))}
        switch vehicle {
        case .car:
            local.rect(-10,-14,22,33,ink.opacity(0.45),radius:5)
            local.rect(-10,-16,20,32,red,radius:5)
            local.rect(-7,-10,14,7,sky,radius:2);local.rect(-7,3,14,5,cream.opacity(0.7),radius:1.5)
            for xx in [CGFloat(-7),4] { local.rect(xx,12,3,2,cream,radius:1) }
        case .tractor:
            for xx in [CGFloat(-14),8] {
                local.rect(xx,-14,6,14,ink,radius:2)
                local.rect(xx+1,7,5,9,ink,radius:2)
            }
            local.rect(-9,-14,18,32,leaf,radius:4)
            local.rect(-8,-13,16,12,cream,radius:2);local.rect(-5,-10,10,6,sky,radius:1)
            local.rect(-4,1,8,13,yellow,radius:2);local.rect(5,-1,2,11,ink)
        case .trailer:
            local.rect(-13,-12,5,13,ink,radius:2);local.rect(8,-12,5,13,ink,radius:2)
            local.rect(-11,-16,22,29,timber,radius:3)
            for i in 0..<4 {local.rect(-8,CGFloat(-13+i*6),16,3,cream.opacity(0.68),radius:1)}
            local.line([pt(-5,13),pt(0,19),pt(5,13)],ink,2)
        case .train:
            local.rect(-15,-42,31,84,ink.opacity(0.5),radius:5)
            local.rect(-15,-45,30,85,red,radius:5)
            local.rect(-13,-43,26,54,cream,radius:3)
            for i in 0..<5 {local.rect(-9,CGFloat(-38+i*9),18,4,sky,radius:1.5)}
            local.rect(-10,16,20,12,sky,radius:3)
            local.rect(-7,33,14,3,yellow,radius:1)
        }
    }
    private func badge(_ count:Int,at point:CGPoint) {
        rect(point.x-10,point.y-7,20,14,ink,radius:5)
        c.draw(Text(verbatim:String(count)).font(.system(size:9,weight:.bold,design:.rounded)).foregroundStyle(cream),at:point)
    }
}
