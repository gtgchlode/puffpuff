import SwiftUI

struct ReefStopView: View {
    let onHome: () -> Void
    let onBloom: () -> Void
    let onPause: () -> Void
    var onOverlay: (Bool) -> Void = { _ in }
    @Environment(\.presentReefDiscovery) private var presentDiscovery
    @Environment(ReefStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.oceanTime) private var oceanTime
    @Environment(\.reefPaused) private var reefPaused
    @State private var journey: ReefJourney?
    @State private var questDeparture: FirstReefProgress?
    @State private var journeyBegan = Date()
    @State private var visible = false
    @State private var golf = false
    @State private var feedback: String?
    @State private var pathNotice: String?
    @State private var showHelp = false
    @State private var showRewards = false
    @State private var drag: ReefPoint?
    @State private var showExploredMap = false
    @State private var showQuestRewards = false
    @State private var selectedCurrent: Int?
    @State private var placingAid:ReefGolfAid?
    @State private var placementPoint:ReefPoint?
    @State private var showBonusIntro = false
    @State private var challengeID:String?
    @State private var replayTrial:ReefMiniTrial?
    @State private var replayLayout=0

    private var reef: FirstReefProgress { store.progress.firstReef }
    private var busy: Bool { journey != nil }
    private var bonusAvailable: Bool { reef.completed && reef.bonus?.claimed != true }
    private var fishPosition: ReefPoint { golf ? reef.bonus?.position ?? FirstReef.bonusTee(reef) : reef.position }
    private var canAdjustCurrent: Bool { golf && reef.bonus?.finished == false && reef.bonus?.claimed == false && !busy && !reefPaused && !store.isSaveBlocked }

    private var canPutt:Bool {canAdjustCurrent && store.progress.shots>0 && placingAid == nil}

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !visible || reefPaused || scenePhase != .active || !busy)) { clock in
                let elapsed = max(0, clock.date.timeIntervalSince(journeyBegan))
                Group {
                    VStack(spacing: 3) {
                        heading(elapsed: elapsed).zIndex(2)
                        if showHelp {
                            Text(golf ? "Reach home in \(FirstReef.unlockLimit) putts to unlock; lower scores earn more. Six per attempt, one shot each. Tap a current to spend one changer." : "Find 3 snacks and home to open Bonus putt. Chests can hide snacks or supplies. Extra chests and side paths are optional.")
                                .reefFont(size:12).foregroundStyle(ReefTheme.muted).multilineTextAlignment(.center).padding(.horizontal,20)
                        }
                        if golf && showRewards { rewardLadder }
                        if golf {
                            GeometryReader { course in
                                let scale = max(0.1, min((course.size.width-24)/BonusCourse.width, course.size.height/BonusCourse.height))
                                let width = BonusCourse.width*scale
                                let height = BonusCourse.height*scale
                                ZStack(alignment:.topLeading) {
                                    ReefPlayfield(progress:reef,journey:journey,elapsed:elapsed,golf:true,drag:drag,
                                                  time:reduceMotion ? 0:oceanTime,reduceMotion:reduceMotion)
                                        .frame(width:width,height:height).accessibilityHidden(true)
                                    ForEach(0..<BonusCourse.currents.count,id:\.self) { index in
                                        ReefCurrentButton(direction:BonusCourse.initialCurrents(reef)[index],time:reduceMotion ? 0:oceanTime) {
                                            selectedCurrent=index
                                        }.position(x:BonusCourse.currents[index].x*scale,y:BonusCourse.currents[index].y*scale)
                                            .disabled(!canAdjustCurrent).accessibilityLabel("Current \(index+1), \(ReefCurrentPicker.names[BonusCourse.initialCurrents(reef)[index]])")
                                    }
                                    ForEach(reef.bonus?.addedCurrents ?? []) {current in
                                        ReefCurrentButton(direction:current.direction,time:reduceMotion ? 0:oceanTime) {}
                                            .overlay(alignment:.bottomTrailing) {ReefIcon(.currentAdder,size:18)}
                                            .position(x:current.position.x*scale,y:current.position.y*scale)
                                            .allowsHitTesting(false)
                                            .accessibilityLabel("Added current, \(ReefCurrentPicker.names[current.direction])")
                                    }
                                    ForEach(reef.bonus?.bouncyBlocks ?? []) {block in
                                        ReefIcon(.bouncyBlock,size:50*scale)
                                            .position(x:block.position.x*scale,y:block.position.y*scale).allowsHitTesting(false)
                                    }
                                    if let aid=placingAid,canAdjustCurrent {
                                        Color.clear.frame(width:width,height:height).contentShape(Rectangle())
                                            .onTapGesture {point in
                                                let location=ReefPoint(x:point.x/scale,y:point.y/scale)
                                                if aid == .current ? BonusCourse.canPlaceCurrent(at:location,in:reef) :
                                                    (BonusCourse.canPlaceBlock(at:location,in:reef) && (location-fishPosition).length>=45) {placementPoint=location;feedback=nil}
                                                else {feedback="Choose open water away from home, obstacles and other currents."}
                                            }.accessibilityLabel("Choose a place for the \(aid.title.lowercased())")
                                    }
                                    if canPutt {
                                        Color.clear.frame(width:60,height:60).contentShape(Circle())
                                            .highPriorityGesture(DragGesture(minimumDistance:2)
                                                .onChanged { value in
                                                    drag = .init(x:-value.translation.width/scale,y:-value.translation.height/scale)
                                                }.onEnded { value in
                                                    let vector=ReefPoint(x:-value.translation.width/scale,y:-value.translation.height/scale)
                                                    drag=nil
                                                    if let result=store.puttFirstReef(drag:vector) { play(result) }
                                                })
                                            .position(x:fishPosition.x*scale,y:fishPosition.y*scale)
                                            .accessibilityLabel("Puff Puff. Pull back to aim and release to putt.")
                                    }
                                    ReefPuffOverlay(progress:reef,journey:journey,elapsed:elapsed,drag:drag,
                                                    time:reduceMotion ? 0:oceanTime,reduceMotion:reduceMotion)
                                        .frame(width:width,height:height).allowsHitTesting(false)
                                        .accessibilityHidden(true).zIndex(3)
                                }.frame(width:width,height:height)
                                    .position(x:course.size.width/2,y:course.size.height/2)
                            }
                        } else {
                            ReefCoveView(progress: reef, departure: questDeparture, journey: journey,
                                          elapsed: elapsed, time: reduceMotion ? 0 : oceanTime,
                                          reduceMotion: reduceMotion,
                                          enabled: !busy && !reefPaused && !store.isSaveBlocked && reef.bonus?.claimed != true,
                                          onVisit: visit, onUncover: uncover, onMap: { showExploredMap = true },
                                          onChallenge: {object in
                                              if store.beginCoveChallenge(object.id) {challengeID=object.id}
                                              else {pathNotice="Couldn't save. Please try again."}
                                          },
                                          onReplayChallenge: replayChallenge,
                                          testingToolsEnabled: store.testingToolsEnabled,
                                          bottomInset: geometry.safeAreaInsets.bottom)
                                .frame(maxWidth: 520, maxHeight: .infinity)
                        }
                        if golf { golfControls }
                    }.frame(width:geometry.size.width,
                            height:geometry.size.height+(golf ? 0:geometry.safeAreaInsets.bottom),alignment:.top)
                        .ignoresSafeArea(.container,edges:golf ? []:.bottom)
                }
            }
        }
        .onAppear { visible=true;golf=false }
        .onDisappear { visible=false;journey=nil;questDeparture=nil;drag=nil;onOverlay(false) }
        .alert("", isPresented: Binding(get: { pathNotice != nil }, set: { if !$0 { pathNotice=nil } })) {
            Button("OK", role: .cancel) { pathNotice=nil }
        } message: {
            Text(pathNotice ?? "")
        }
        .sheet(isPresented:Binding(get:{selectedCurrent != nil},set:{if !$0 {selectedCurrent=nil}})) {
            if let index=selectedCurrent {
                ReefCurrentPicker(index:index,direction:BonusCourse.initialCurrents(reef)[index],count:store.progress.currentChangers) { direction in
                    if store.redirectReefCurrent(index,to:direction) {selectedCurrent=nil;feedback="Current changed"}
                    else {feedback=store.isSaveBlocked ? "Couldn't save. Please try again.":"Find current changers on the Trail.";selectedCurrent=nil}
                }.presentationDetents([.height(430)]).presentationBackground(.clear)
            }
        }
        .sheet(isPresented:Binding(get:{placementPoint != nil},set:{if !$0 {placementPoint=nil}})) {
            if placingAid == .block {
                ReefBlockPicker(count:store.progress.bouncyBlocks) {
                    if let point=placementPoint,store.addReefBlock(at:point) {placementPoint=nil;placingAid=nil;feedback=nil}
                    else {placementPoint=nil;feedback="Couldn't place it. Your block is still in your treasure."}
                }.presentationDetents([.height(310)]).presentationBackground(.clear)
            } else {
                ReefCurrentPicker(index:0,direction:0,count:store.progress.currentAdders,onUse:{direction in
                    if let point=placementPoint,store.addReefCurrent(at:point,direction:direction) {
                        placementPoint=nil;placingAid=nil;feedback=nil
                    } else {placementPoint=nil;feedback="Couldn't place it. Your current adder is still in your treasure."}
                },placing:true).presentationDetents([.height(430)]).presentationBackground(.clear)
            }
        }
        .onChange(of:placementPoint) {_,point in onOverlay(point != nil)}
        .onChange(of:golf) {_,_ in placingAid=nil;placementPoint=nil}
        .onChange(of: selectedCurrent) { _, selection in onOverlay(selection != nil) }
        .onChange(of: showExploredMap) { _, shown in onOverlay(shown) }
        .onChange(of: showQuestRewards) { _, shown in onOverlay(shown) }
        .onChange(of: showBonusIntro) { _, shown in onOverlay(shown) }
        .sheet(isPresented:Binding(get:{challengeID != nil},set:{if !$0 {challengeID=nil}}),onDismiss:{onOverlay(false)}) {
            if let id=challengeID {
                ReefMiniChallengeView(objectID:id) {reveal in
                    challengeID=nil
                    if let reveal {questDeparture=reef;play(reveal)}
                }.environment(store).presentationDetents([.large]).presentationBackground(.clear)
                    .interactiveDismissDisabled()
            }
        }
        .onChange(of:challengeID) {_,id in onOverlay(id != nil)}
        .onChange(of:store.testingToolsEnabled) { _, enabled in if !enabled { replayTrial = nil } }
        .onChange(of:replayTrial) {_,trial in onOverlay(trial != nil)}
        .sheet(item:$replayTrial,onDismiss:{onOverlay(false)}) {trial in
            ReefMiniPractice(trial:trial,title:trial.kind == .kelp ? "Kelp run":"Scare enemies",layout:replayLayout)
                .presentationDetents([.large]).presentationBackground(.clear)
        }
        .sheet(isPresented: $showBonusIntro, onDismiss: { onOverlay(false) }) {
            OceanScene {
                ReefIntroView(kind: .bonus) {
                    guard store.finishIntro(.bonus), store.startReefBonus() else { return false }
                    golf=true;feedback=nil;showRewards=false;showHelp=false
                    showBonusIntro=false
                    return true
                }
            }
            .presentationDetents([.large]).presentationBackground(.clear)
            .interactiveDismissDisabled()
            #if os(macOS)
            .frame(width: 400, height: 730)
            #endif
        }
        .sheet(isPresented: $showQuestRewards, onDismiss: { onOverlay(false) }) {
            ReefQuestRewardsSheet(progress: reef)
                .presentationDetents([.large]).presentationBackground(.clear)
        }
        .sheet(isPresented: $showExploredMap, onDismiss: { onOverlay(false) }) {
            ReefExploredMapSheet(progress: reef)
                .presentationDetents([.large]).presentationBackground(.clear)
        }
        .onChange(of:scenePhase) { _,phase in if phase != .active { journey=nil;questDeparture=nil;drag=nil } }
        .onChange(of:reefPaused) { _,paused in if paused { journey=nil;questDeparture=nil;drag=nil } }
        .task(id:journey?.id) {
            guard let current=journey else { return }
            let receiptID=store.discoveryReceipt?.source == .trail ? store.discoveryReceipt?.id:nil
            do {
                let homecoming = golf ? current.outcome.bonus?.holed == true : current.coveDiscovery == nil && current.outcome.completed && current.outcome.location == "home"
                let duration = golf ? current.duration : ReefQuestView.duration(current)
                let object=ReefCove.objects(in:current.outcome.location ?? "start").first{$0.id==current.coveDiscovery}
                let giftEndsAt=current.lifeGift == nil ? 0:(object.map{CoveActionTiming($0).clearedAt} ?? 0)+1.55
                // Chest prizes have their own brief reveal, without a celebration hold.
                let finishAt = reduceMotion ? 0.15 : max(duration+(homecoming ? 1.5:0.1),giftEndsAt)
                var revealAt = 0.0
                if object?.isChest == true || object?.find == .treasure {
                    store.cancelDiscoveryReceipt()
                } else if let receiptID {
                    // Explain at the reveal, without the old global delay or reward-banner hold.
                    revealAt = reduceMotion ? 0 : min(finishAt,object.map{CoveActionTiming($0).clearedAt+0.1} ?? duration)
                    try await Task.sleep(for:.seconds(revealAt))
                    guard !Task.isCancelled else{return}
                    presentDiscovery(receiptID)
                }
                try await Task.sleep(for:.seconds(max(0,finishAt-revealAt)))
                guard !Task.isCancelled else { return }
                journey=nil;questDeparture=nil
            } catch { /* Destination and rewards are already saved atomically. */ }
        }
    }

    private func replayChallenge(_ object:ReefCove.Object) {
        guard store.testingToolsEnabled, let kind=object.challengeKind,(reef.coveSearches ?? []).contains(object.id) else{return}
        replayLayout=reef.miniChallenges?[object.id]?.layout ?? ReefMiniChallenge.layout(for:object.id)
        let timed=reef.miniChallenges?[object.id]?.timedEnemies ?? ReefMiniChallenge.timedEncounter(object.id)
        replayTrial=kind == .kelp ? .kelp:timed ? .movingEnemies:.enemyPutts
    }

    private func heading(elapsed: Double) -> some View {
      VStack(spacing: 0) {
        HStack(spacing: 9) {
            VStack(alignment: .leading, spacing: 2) {
                Text(golf ? "Bonus putt" : ReefQuestView.areaName(questDeparture?.location ?? reef.location ?? "start"))
                    .reefFont(size:20,weight:.semibold,display:true).lineLimit(1).minimumScaleFactor(0.8)
                if !golf {
                    ReefIconLabel("\(store.progress.glow)", .glow, size: 24)
                        .reefFont(size: 16, weight: .semibold).monospacedDigit().fixedSize()
                        .accessibilityLabel("\(store.progress.glow) Glow available")
                }
            }
            Spacer(minLength:0)
            Button(action: onBloom) { ReefIconLabel("Bloom", .taps, size: 32).fixedSize() }
                .buttonStyle(ReefButtonStyle(kind: .action)).disabled(busy)
            ReefPauseButton(action: onPause)
        }
        HStack(spacing:6) {
            if golf {
                Text("\(reef.bonus?.strokes ?? 0)/\(FirstReef.turnLimit)").reefFont(size:14,weight:.semibold)
                    .accessibilityLabel("\(reef.bonus?.strokes ?? 0) of \(FirstReef.turnLimit) putts used")
                ReefIconLabel("\(store.progress.shots)",.shot,size:25).accessibilityLabel("\(store.progress.shots) shots available")
                ReefIconLabel("\(store.progress.currentChangers)",.current,size:25)
                    .accessibilityLabel("\(store.progress.currentChangers) current changers")
                Button { showRewards.toggle() } label: { Image(systemName:"gift.fill") }
                    .buttonStyle(ReefButtonStyle(kind:.quiet)).accessibilityLabel("Bonus rewards")
            } else {
                ReefQuestProgress(progress: reef, departure: questDeparture, journey: journey,
                                  elapsed: elapsed, reduceMotion: reduceMotion, compact: bonusAvailable) { showQuestRewards = true }
            }
            Spacer(minLength: 0)
            if !golf && bonusAvailable {
                Button {
                    if !store.progress.hasSeenBonusIntro { showBonusIntro=true }
                    else if store.startReefBonus() { golf=true;feedback=nil;showRewards=false;showHelp=false }
                } label: {
                    Image(systemName:"flag.checkered").font(.system(size:19,weight:.semibold))
                        .frame(width:44,height:44)
                }.buttonStyle(ReefButtonStyle(kind:.orb))
                    .disabled(busy || reefPaused || store.isSaveBlocked)
                    .accessibilityLabel("Bonus putt").help("Bonus putt")
            }
            ReefChestButton(onPresent:onOverlay)
            Button { showHelp.toggle() } label: { Image(systemName:"questionmark") }
                .buttonStyle(ReefButtonStyle(kind:.quiet)).accessibilityLabel("How to play")
        }.reefFont(size:12,weight:.semibold)
      }.padding(.horizontal,16).frame(maxWidth:470)
    }

    private func visit(_ destination:FirstReef.Destination) {
        guard !busy, !reefPaused, !store.isSaveBlocked, reef.bonus?.claimed != true else { return }
        feedback=nil
        let cost=FirstReef.cost(to:destination,from:reef)
        guard FirstReef.route(to:destination.id,state:reef) != nil else { pathNotice="Clear the blockage or take another path.";return }
        guard store.progress.glow >= cost else { openBloomForGlow(); return }
        let departure = reef
        guard let result=store.visitFirstReef(destination.id) else { pathNotice="Couldn't save. Please try again.";return }
        questDeparture = departure
        play(result)
    }
    private func uncover(_ object:ReefCove.Object) {
        guard !busy,!reefPaused,!store.isSaveBlocked,reef.bonus?.claimed != true else{return}
        feedback=nil
        guard store.progress.glow>=object.cost else { openBloomForGlow(); return }
        let departure=reef
        guard let result=store.uncoverCove(object.id) else {pathNotice="Couldn't save. Please try again.";return}
        questDeparture=departure;play(result)
    }
    private func openBloomForGlow() {
        pathNotice = nil
        if store.playBloomForGlow() { onOverlay(false) }
        else { pathNotice = "Couldn't save. Please try again." }
    }
    private func play(_ result:ReefJourney) { journeyBegan=Date();journey=result }

    private var golfControls: some View {
        VStack(spacing:5) {
            if reef.bonus?.claimed == true {
                Text("Bonuses collected").reefFont(size:17,weight:.semibold)
                Text("Next reef unlocked · coming soon").reefFont(size:12).foregroundStyle(ReefTheme.muted)
                Button("Home",action:onHome).buttonStyle(ReefButtonStyle(kind:.action))
            } else if let bonus=reef.bonus {
                if !busy && placingAid == nil {
                    Text(bonusStatus(bonus)).reefFont(size:13,weight:.medium).foregroundStyle(ReefTheme.ink)
                    if bonus.canCollect, let best=bonus.bestStrokes {
                        let reward=FirstReef.reward(for:best)
                        HStack(spacing:12) {
                            Text("Best: \(best)").reefFont(size:12,weight:.semibold)
                            rewardAmounts(reward)
                        }
                    }
                }
                if !bonus.finished && !busy {
                    ReefAidControls(currents:store.progress.currentAdders,blocks:store.progress.bouncyBlocks,
                                    placing:$placingAid,enabled:canAdjustCurrent)
                }
                HStack(spacing:8) {
                    Button("Explore") { golf=false;feedback=nil }
                        .buttonStyle(ReefButtonStyle(kind:.quiet)).disabled(busy)
                    Button("Retry") { if store.startReefBonus(retry:true) { feedback=nil;journey=nil;placingAid=nil;placementPoint=nil } }
                        .buttonStyle(ReefButtonStyle(kind:.quiet)).disabled(busy || store.isSaveBlocked)
                    if bonus.canCollect {
                        Button("Collect") { if !store.collectReefBonus() { feedback="Couldn't save. Please try again." } }
                            .buttonStyle(ReefButtonStyle(kind:.action)).disabled(busy || store.isSaveBlocked)
                    }
                }
                if let feedback { Text(feedback).reefFont(size:11).foregroundStyle(ReefTheme.muted) }
            }
        }.frame(maxWidth:430).frame(minHeight:64).padding(.horizontal,18).padding(.bottom,5)
    }

    private func rewardAmounts(_ reward:FirstReef.BonusReward) -> some View {
        HStack(spacing:9) {
            ReefIconLabel("\(reward.glow)", .glow, size: 23)
            ReefIconLabel("\(reward.shots)", .shot, size: 23)
            if reward.hints > 0 { ReefIconLabel("\(reward.hints)", .hint, size: 23) }
        }.reefFont(size:11,weight:.semibold).foregroundStyle(ReefTheme.gold)
            .accessibilityLabel("\(reward.glow) Glow, \(reward.shots) shots, \(reward.hints) hints")
    }
    private func bonusStatus(_ bonus:ReefBonusProgress)->String {
        if bonus.holed {
            return bonus.strokes <= FirstReef.unlockLimit
                ? FirstReef.reward(for:bonus.strokes).title
                : "Home in \(bonus.strokes) · need \(FirstReef.unlockLimit) or fewer to unlock"
        }
        if bonus.finished {return "Out of putts · no unlock"}
        if store.progress.shots == 0 {return "Win Bloom games or find unopened shot chests."}
        return "Pull back. Release to putt."
    }
    private var rewardLadder: some View {
        VStack(spacing:4) {
            ForEach(1...5,id:\.self) { strokes in
                HStack {
                    Text(strokes == 5 ? "5–6 · No unlock" : "\(strokes) · \(FirstReef.reward(for:strokes).title)\(strokes == FirstReef.unlockLimit ? " · unlock" : "")")
                        .reefFont(size:11,weight:.medium)
                    Spacer()
                    if strokes == 5 {
                        Text("No reward").reefFont(size:11).foregroundStyle(ReefTheme.muted)
                    } else {
                        rewardAmounts(FirstReef.reward(for:strokes))
                    }
                }
            }
            Text("Reach home in \(FirstReef.unlockLimit) putts or fewer to unlock. Lower scores earn more.")
                .reefFont(size:11).foregroundStyle(ReefTheme.muted)
        }.frame(maxWidth:300).padding(.vertical,4)
    }
}

struct ReefPlayfield: View {
    let progress:FirstReefProgress
    let journey:ReefJourney?
    let elapsed:Double
    let golf:Bool
    let drag:ReefPoint?
    let time:Double
    let reduceMotion:Bool

    var body: some View {
        Canvas { context,size in
            var c=context
            let scale=size.width/FirstReef.width
            c.scaleBy(x:scale,y:scale)
            let playTime=reduceMotion ? journey?.duration ?? elapsed:elapsed
            let frame=journey?.frame(at:playTime)
            let visited=progress.visited ?? ["start"]
            if golf {
                ReefBayArt.puttingWater(in:c,state:progress,time:time)
                for current in BonusCourse.activeCurrents(progress) {
                    let point=current.position
                    let direction=BonusCourse.currentDirection(current.direction)
                    for lane in -1...1 {
                        let side=ReefPoint(x:-direction.y,y:direction.x)*Double(lane)*9
                        let offset=reduceMotion ? 0 : sin(time/1600+Double(lane))*3
                        var flow=Path();flow.move(to:(point-direction*24+side).cg)
                        flow.addQuadCurve(to:(point+direction*24+side).cg,control:(point+side+ReefPoint(x:direction.y,y:-direction.x)*offset).cg)
                        c.stroke(flow,with:.color(ReefTheme.glint.opacity(0.6)),style:.init(lineWidth:2,lineCap:.round))
                    }
                }
                for bumper in BonusCourse.bumpers where !progress.cleared.contains(bumper.clearance ?? "") {
                    ReefBayArt.bumper(bumper,in:c,time:time,size:bumper.radius*3)
                }
            } else {
                ReefBayArt.water(in:c,state:progress,golf:false,time:time)
                for bumper in FirstReef.bumpers where visited.contains(bumper.clearance ?? "") && !progress.cleared.contains(bumper.clearance ?? "") {
                    ReefBayArt.bumper(bumper,in:c,time:time)
                }
            }
            if golf || visited.contains("home") {
                ReefBayArt.home(in:c,at:golf ? BonusCourse.home:FirstReef.home,open:progress.food.count == 3,time:time)
            }
            let position=frame?.position ?? (golf ? progress.bonus?.position ?? FirstReef.bonusTee(progress):progress.position)
            let arrived=golf ? progress.bonus?.holed == true : progress.completed && progress.location == "home"
            let landing=journey.map { max(0,playTime-$0.duration) } ?? (arrived ? 2.0:0)
            if let drag,drag.length > 2 {
                let unit=drag*(1/drag.length),end=position+unit*min(110,drag.length)
                var aim=Path();aim.move(to:position.cg);aim.addLine(to:end.cg)
                c.stroke(aim,with:.color(ReefTheme.gold),style:.init(lineWidth:2,lineCap:.round,dash:[2,5]))
                c.fill(ReefBayArt.circle(end,3),with:.color(ReefTheme.gold))
                c.stroke(ReefBayArt.circle(position,24+min(10,drag.length/11)),with:.color(ReefTheme.glint.opacity(0.6)),lineWidth:1)
            }
            if let journey,!reduceMotion,elapsed < journey.duration {
                for i in 1...4 {
                    let past=journey.frame(at:max(0,elapsed-Double(i)*0.06)).position
                    c.stroke(ReefBayArt.circle(past,Double(5-i)*0.8),with:.color(ReefTheme.glint.opacity(0.55)),lineWidth:0.8)
                }
            }
            if arrived && landing > 0 { ReefBayArt.doorLip(in:c,at:golf ? BonusCourse.home:FirstReef.home) }
        }
    }
}

/// Draw Puff Puff after the course art and controls so his official artwork stays in front.
private struct ReefPuffOverlay: View {
    let progress:FirstReefProgress
    let journey:ReefJourney?
    let elapsed:Double
    let drag:ReefPoint?
    let time:Double
    let reduceMotion:Bool

    var body: some View {
        Canvas { context,size in
            var c=context
            let scale=size.width/BonusCourse.width
            c.scaleBy(x:scale,y:scale)
            let playTime=reduceMotion ? journey?.duration ?? elapsed:elapsed
            let frame=journey?.frame(at:playTime)
            var position=frame?.position ?? progress.bonus?.position ?? FirstReef.bonusTee(progress)
            let arrived=progress.bonus?.holed == true
            let landing=journey.map { max(0,playTime-$0.duration) } ?? (arrived ? 2.0:0)
            let release=journey.map { _ in min(1,playTime/0.18) } ?? 1
            let charge=drag.map { min(1,$0.length/110) } ?? (journey?.launchCharge ?? 0)*(1-release)
            var inflation=0.05+charge*0.95
            var fishScale=0.62+charge*0.55
            if arrived && landing > 0 {
                inflation=max(0,0.05*(1-landing/0.65))
                let enter=ReefMotion.segment(landing*1000,from:550,to:1400)
                fishScale *= 1-enter*0.78
                position=position+ReefPoint(x:0,y:-3)*enter
            }
            var fish=c
            fish.translateBy(x:position.x,y:position.y)
            fish.scaleBy(x:fishScale,y:fishScale)
            fish.translateBy(x:-173.0/320*64,y:-144.0/270*54)
            PipRenderer.drawPose(in:fish,size:CGSize(width:64,height:54),time:time.truncatingRemainder(dividingBy:8000),inflation:inflation,joy:arrived ? 1:0)
        }
    }
}

private extension ReefPoint { var cg:CGPoint { CGPoint(x:x,y:y) } }

enum ReefBayArt {
    static func puttingWater(in c:GraphicsContext,state:FirstReefProgress,time:Double) {
        var center=Path();center.move(to:BonusCourse.fairway[0].cg)
        for point in BonusCourse.fairway.dropFirst() {center.addLine(to:point.cg)}
        var mask=center.strokedPath(.init(lineWidth:BonusCourse.laneRadius*2,lineCap:.round,lineJoin:.round))
        if state.cleared.contains("fin-school") { mask=mask.union(circle(BonusCourse.home,72)) }
        c.stroke(mask,with:.color(ReefTheme.bone.opacity(0.55)),lineWidth:13)
        c.stroke(mask,with:.color(ReefTheme.sand),lineWidth:6)
        c.fill(mask,with:.linearGradient(Gradient(colors:[ReefTheme.deep,ReefTheme.glass,ReefTheme.deep]),
            startPoint:BonusCourse.home.cg,endPoint:BonusCourse.tee.cg))
        var water=c;water.clip(to:mask)
        WaterDrawing.caustics(in:water,size:CGSize(width:BonusCourse.width,height:BonusCourse.height),time:time,strength:0.65)
        water.stroke(center,with:.color(ReefTheme.glint.opacity(0.09)),style:.init(lineWidth:72,lineCap:.round))
        // The small sand tee is a position cue, never a second hole.
        let tee=Path(ellipseIn:CGRect(x:BonusCourse.tee.x-22,y:BonusCourse.tee.y-9,width:44,height:18))
        water.fill(tee,with:.color(ReefTheme.sand.opacity(0.6)))
        for i in 0..<24 {
            let point=ReefPoint(x:20+WaterDrawing.seed(i,salt:21)*300,y:WaterDrawing.seed(i,salt:37)*570)
            water.fill(circle(point,i % 4 == 0 ? 1.2:0.7),with:.color(ReefTheme.glint.opacity(0.6)))
        }
    }
    static func circle(_ point:ReefPoint,_ radius:Double) -> Path {
        Path(ellipseIn:CGRect(x:point.x-radius,y:point.y-radius,width:radius*2,height:radius*2))
    }
    static func lanePath(_ lane:FirstReef.Lane) -> Path {
        var p=Path();p.move(to:lane.points[0].cg)
        for point in lane.points.dropFirst() { p.addLine(to:point.cg) }
        return p
    }
    static func water(in c:GraphicsContext,state:FirstReefProgress,golf:Bool,time:Double) {
        let visible=FirstReef.visibleIDs(state),visited=state.visited ?? ["start"]
        let lanes=FirstReef.activeLanes(state).filter { golf || (visible.contains($0.a) && visible.contains($0.b) && (visited.contains($0.a) || visited.contains($0.b))) }
        for lane in lanes {
            c.stroke(lanePath(lane),with:.color(ReefTheme.bone.opacity(0.3)),style:.init(lineWidth:lane.radius*2+16,lineCap:.round,lineJoin:.round))
        }
        for lane in lanes {
            c.stroke(lanePath(lane),with:.color(ReefTheme.sand),style:.init(lineWidth:lane.radius*2+8,lineCap:.round,lineJoin:.round))
        }
        var mask=Path()
        for lane in lanes { mask = mask.union(lanePath(lane).strokedPath(.init(lineWidth:lane.radius*2,lineCap:.round,lineJoin:.round))) }
        // The start cove remains visible before the first fork is revealed.
        mask = mask.union(circle(FirstReef.start,32))
        if state.cleared.contains("fin-school") { mask = mask.union(circle(FirstReef.home,44)) }
        c.fill(mask,with:.linearGradient(Gradient(colors:[ReefTheme.deep,ReefTheme.glass,ReefTheme.deep]),startPoint:.zero,endPoint:CGPoint(x:320,y:780)))
        var water=c;water.clip(to:mask)
        WaterDrawing.caustics(in:water,size:CGSize(width:340,height:780),time:time,strength:0.7)
        for lane in lanes {
            water.stroke(lanePath(lane),with:.color(ReefTheme.glint.opacity(0.12)),style:.init(lineWidth:lane.radius,lineCap:.round,lineJoin:.round))
            water.stroke(lanePath(lane),with:.color(ReefTheme.gold.opacity(0.35)),style:.init(lineWidth:1.5,lineCap:.round,dash:[1,11]))
            if !golf {
                for id in [lane.a,lane.b] where !visited.contains(id) {
                    let p=FirstReef.node(id).point
                    water.fill(circle(p,39),with:.radialGradient(Gradient(colors:[ReefTheme.deep.opacity(0.9),ReefTheme.deep.opacity(0)]),center:p.cg,startRadius:10,endRadius:41))
                }
            }
        }
        for i in 0..<40 {
            let x=20+WaterDrawing.seed(i,salt:21)*300
            var y=(WaterDrawing.seed(i,salt:37)*780-time/900).truncatingRemainder(dividingBy:780)
            if y < 0 { y += 780 }
            water.fill(circle(.init(x:x,y:y),i % 4 == 0 ? 1.2:0.7),with:.color(ReefTheme.glint.opacity(0.6)))
        }
    }
    static func bumper(_ b:ReefBumper,in c:GraphicsContext,time:Double,size:Double = 80) {
        switch b.kind {
        case .kelp: TrailArt.draw(.kelpForest,in:c,at:b.point.cg,size:size,time:time)
        case .sand: TrailArt.draw(.sandpit,in:c,at:b.point.cg,size:size,time:time)
        case .enemy: TrailArt.draw(.enemySchool,in:c,at:b.point.cg,size:size,time:time)
        case .stone:
            let shape=SeaGlassShape(seed:b.point.x).path(in:CGRect(x:b.point.x-b.radius,y:b.point.y-b.radius,width:b.radius*2,height:b.radius*2))
            c.fill(shape,with:.color(ReefTheme.bone));c.stroke(shape,with:.color(ReefTheme.muted.opacity(0.5)),lineWidth:1)
        }
    }
    static func home(in c:GraphicsContext,at p:ReefPoint,open:Bool,time:Double) {
        let pulse=0.5+0.5*sin(time/2400 * .pi*2)
        // The target is the cottage doorway; light and flag point to that exact
        // physics position, rather than suggesting a second hole nearby.
        if open {
            c.fill(circle(p,38),with:.radialGradient(Gradient(colors:[
                Color(hex:0xFFE898).opacity(0.45+0.12*pulse),.clear]),
                center:p.cg,startRadius:8,endRadius:38))
        }
        CoralHomeArt.draw(in:c,at:p.cg,scale:0.46,open:open)
        if open {
            var entrance=Path()
            entrance.move(to:CGPoint(x:p.x-8,y:p.y+10))
            entrance.addLine(to:CGPoint(x:p.x-8,y:p.y-4))
            entrance.addCurve(to:CGPoint(x:p.x,y:p.y-16),
                control1:CGPoint(x:p.x-8,y:p.y-12),control2:CGPoint(x:p.x-4,y:p.y-16))
            entrance.addCurve(to:CGPoint(x:p.x+8,y:p.y-4),
                control1:CGPoint(x:p.x+4,y:p.y-16),control2:CGPoint(x:p.x+8,y:p.y-12))
            entrance.addLine(to:CGPoint(x:p.x+8,y:p.y+10));entrance.closeSubpath()
            c.fill(entrance,with:.color(Color(hex:0x062A31)))
            var glow=c;glow.addFilter(.shadow(color:Color(hex:0xFFD16B).opacity(0.8),radius:5))
            glow.stroke(entrance,with:.color(Color(hex:0xFFF0B0)),style:.init(lineWidth:2.3,lineCap:.round,lineJoin:.round))
            let landing=Path(ellipseIn:CGRect(x:p.x-19,y:p.y+10,width:38,height:10))
            c.stroke(landing,with:.color(Color(hex:0xFFE898).opacity(0.65+0.25*pulse)),lineWidth:1.5)
        }
        var pole=Path();pole.move(to:CGPoint(x:p.x+31,y:p.y+14));pole.addLine(to:CGPoint(x:p.x+31,y:p.y-48))
        c.stroke(pole,with:.color(Color(hex:0x80501F)),style:.init(lineWidth:3.5,lineCap:.round))
        c.stroke(pole,with:.color(Color(hex:0xFFE6A3)),style:.init(lineWidth:1.6,lineCap:.round))
        var flag=Path();flag.move(to:CGPoint(x:p.x+31,y:p.y-48))
        flag.addQuadCurve(to:CGPoint(x:p.x+57,y:p.y-39),control:CGPoint(x:p.x+44,y:p.y-48))
        flag.addQuadCurve(to:CGPoint(x:p.x+31,y:p.y-28),control:CGPoint(x:p.x+45,y:p.y-35));flag.closeSubpath()
        c.fill(flag,with:.color(Color(hex:0xF69F84)))
        c.stroke(flag,with:.color(Color(hex:0x80501F)),lineWidth:1.3)
        c.draw(Text("Home").font(ReefTypography.font(size:12,weight:.bold)).foregroundColor(ReefTheme.ink),
               at:CGPoint(x:p.x,y:p.y+33))
    }
    static func doorLip(in c:GraphicsContext,at p:ReefPoint) {
        var lip=Path();lip.move(to:CGPoint(x:p.x-8,y:p.y+9));lip.addQuadCurve(to:CGPoint(x:p.x+9,y:p.y+9),control:CGPoint(x:p.x,y:p.y+13))
        c.stroke(lip,with:.color(ReefTheme.honey),style:.init(lineWidth:3,lineCap:.round))
    }
}

/// Saved progress drives the bars; the finite journey clock only animates the pickup.
struct ReefQuestProgress: View {
    let progress: FirstReefProgress
    var departure: FirstReefProgress?
    var journey: ReefJourney?
    var elapsed = 0.0
    var reduceMotion = false
    var compact = false
    var onDetails: () -> Void = {}

    private var pickup: Double {
        guard let journey, !reduceMotion else { return 1 }
        return min(1, max(0, (elapsed - ReefQuestView.duration(journey) + 0.15) / 0.9))
    }
    var body: some View {
        Button(action: onDetails) {
            HStack(spacing: 18) {
                meter(symbol: "leaf.fill", count: progress.food.count, before: departure?.food.count,
                      total: FirstReef.food.count, tint: ReefTheme.coral, gained: journey?.newFood.isEmpty == false, food: true)
                VStack(spacing: 3) {
                    Image(systemName: progress.hasFoundHome ? "house.fill" : "house")
                        .font(.system(size: 22, weight: .medium))
                    if progress.hasFoundHome { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)) }
                    else { Text("Home").reefFont(size: 12, weight: .semibold) }
                }.foregroundStyle(progress.hasFoundHome ? ReefTheme.gold : ReefTheme.muted)
                    .frame(width: compact ? 48 : 60, height: 44)
            }.padding(.vertical, 7)
        }
        .buttonStyle(ReefButtonStyle(kind: .navigation))
        .accessibilityLabel("Path goals")
        .accessibilityValue("\(progress.food.count) of 3 snacks. \(progress.hasFoundHome ? "Home found" : "Find home").")
        .sensoryFeedback(.success, trigger: progress.food.count)
    }

    private func meter(symbol: String, count: Int, before: Int?, total: Int, tint: Color, gained: Bool, food: Bool) -> some View {
        let old = before ?? count
        let arrival = reduceMotion || !gained ? 1 : min(1, max(0, (pickup - 0.65) / 0.35))
        let shown = gained && arrival == 0 ? old : count
        let fraction = (Double(old) + Double(count - old) * arrival) / Double(total)
        let pulse = gained && !reduceMotion ? sin(arrival * .pi) : 0
        return VStack(alignment: .leading, spacing: 5) {
            Label("\(shown)/\(total)", systemImage: symbol)
                .reefFont(size: 16, weight: .semibold)
                .contentTransition(.numericText())
                .scaleEffect(1 + pulse * 0.12)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    MembraneShape().fill(tint.opacity(0.16))
                    MembraneShape().fill(tint).frame(width: max(0, g.size.width * fraction))
                        .shadow(color: tint.opacity(0.8 * pulse), radius: 8)
                }
            }.frame(height: 8)
        }.foregroundStyle(tint).frame(width: compact ? 72 : 88)
            .overlay {
                if gained && !reduceMotion && pickup > 0 && pickup < 1 {
                    let travel = min(1, pickup / 0.7)
                    let eased = 1 - pow(1 - travel, 3)
                    VStack(spacing: 0) {
                        if food {
                            Canvas { c, size in
                                TrailArt.draw(.food, in: c, at: CGPoint(x: size.width / 2, y: size.height / 2), size: 42)
                            }.frame(width: 42, height: 42)
                        } else {
                            ReefIcon(.glow, size: 42)
                        }
                        Text("+1").reefFont(size: 15, weight: .semibold)
                    }
                    .offset(x: sin(travel * .pi) * 22, y: (1 - eased) * 135 - 6)
                    .scaleEffect(1 - travel * 0.2)
                    .opacity(pickup > 0.8 ? (1 - pickup) / 0.2 : 1)
                    .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
    }
}

struct ReefQuestRewardsSheet: View {
    let progress: FirstReefProgress
    @Environment(\.dismiss) private var dismiss
    @Environment(ReefStore.self) private var store

    var body: some View {
        OceanScene {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Path goals").reefFont(size: 25, weight: .semibold, display: true)
                        Spacer()
                        Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                            .buttonStyle(ReefButtonStyle(kind: .orb)).accessibilityLabel("Close path goals")
                    }
                    Label("\(progress.food.count)/3 snacks", systemImage: "leaf.fill")
                        .reefFont(size: 18, weight: .semibold).foregroundStyle(ReefTheme.coral)
                    Label(progress.hasFoundHome ? "Home found" : "Find home", systemImage: progress.hasFoundHome ? "checkmark.circle.fill" : "house")
                        .reefFont(size: 18, weight: .semibold).foregroundStyle(ReefTheme.gold)
                    Text("Find 3 snacks and home to open Bonus putt. Chests can hide snacks. After that, extra chests are optional.")
                        .reefFont(size: 13).foregroundStyle(ReefTheme.muted)
                    TideDivider(tint: ReefTheme.gold)
                    ForEach(FirstReef.destinations.filter { $0.kind == .treasure && progress.visited?.contains($0.id) == true }) { chest in
                        HStack(spacing: 14) {
                            let opened = progress.treasures.contains(chest.id)
                            Canvas { c, size in
                                let asset = chest.chestArt(open: opened)
                                TrailArt.draw(asset, in: c, at: CGPoint(x: size.width / 2, y: size.height / 2), size: 66)
                            }.frame(width: 66, height: 66).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 10) {
                                    if opened {
                                        let loot=chest.loot
                                        if loot.hints > 0 { ReefIconLabel("\(loot.hints)", .hint) }
                                        if loot.lives > 0 { ReefIconLabel("\(loot.lives)", .life) }
                                        if loot.shots > 0 { ReefIconLabel("\(loot.shots)", .shot) }
                                        if loot.lighters > 0 { ReefIconLabel("\(loot.lighters)", .lighter) }
                                        if loot.instantBoost { ReefIconLabel("15 min", .boostLive) }
                                    } else {
                                        Text("Hidden find").reefFont(size:15,weight:.semibold)
                                    }
                                }.reefFont(size: 15, weight: .semibold)
                                    .accessibilityElement(children: .ignore).accessibilityLabel(opened ? chest.treasureReward : "Hidden find")
                                Text(opened ? "Collected" : "\(chest.actionLabel) · \(chest.glowCost) Glow")
                                    .reefFont(size: 12).foregroundStyle(ReefTheme.muted)
                            }.fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text("Optional side paths can open easier putting lines.")
                        .reefFont(size: 13).foregroundStyle(ReefTheme.muted)
                    TideDivider(tint: ReefTheme.gold)
                }.padding(24).frame(maxWidth: 450)
            }.scrollIndicators(.hidden)
        }.foregroundStyle(ReefTheme.ink)
    }
}


extension FirstReef.Destination {
    func chestArt(open:Bool) -> TrailArt.Asset {
        switch chestAccent {
        case .mint: open ? .chestMintOpen : .chestMint
        case .coral: open ? .chestCoralOpen : .chestCoral
        case .gold: open ? .chestGoldOpen : .chestGold
        }
    }
}
