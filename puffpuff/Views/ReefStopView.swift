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
    @State private var pathNotice: String?
    @State private var insufficientLumes: (cost:Int,available:Int)?
    @State private var showHelp = false
    @State private var showHouse = false
    @State private var showExploredMap = false
    @State private var showQuestRewards = false

    private var reef: FirstReefProgress { store.progress.firstReef }
    private var busy: Bool { journey != nil }
    private var hasPatrollingEnemies:Bool {
        let cleared=Set(reef.coveSearches ?? [])
        return ReefCove.objects(in:reef.location ?? "start").contains { object in
            object.barrier == .enemy && !object.isChest && object.find != .food && object.find != .home
                && !cleared.contains(object.id)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !visible || reefPaused || scenePhase != .active || (!busy && (!hasPatrollingEnemies || reduceMotion)))) { clock in
                let elapsed = max(0, clock.date.timeIntervalSince(journeyBegan))
                VStack(spacing: 3) {
                    heading(elapsed: elapsed).zIndex(2)
                    if showHelp {
                        Text("A storm dimmed the reef. Relight 3 gardens and find your way home.")
                            .reefFont(size:12).foregroundStyle(ReefTheme.muted).multilineTextAlignment(.center).padding(.horizontal,20)
                    }
                    ReefCoveView(progress: reef, departure: questDeparture, journey: journey,
                                 elapsed: elapsed, time: reduceMotion ? 0 : oceanTime,
                                 reduceMotion: reduceMotion,
                                 enabled: !busy && !reefPaused && !store.isSaveBlocked,
                                 onVisit: visit, onUncover: uncover, onMap: { showExploredMap = true },
                                 bottomInset: geometry.safeAreaInsets.bottom)
                        .frame(maxWidth: 520, maxHeight: .infinity)
                }.frame(width:geometry.size.width,height:geometry.size.height+geometry.safeAreaInsets.bottom,alignment:.top)
                    .ignoresSafeArea(.container,edges:.bottom)
            }
        }
        .onAppear { visible=true }
        .onDisappear { visible=false;journey=nil;questDeparture=nil;onOverlay(false) }
        .alert("", isPresented: Binding(get: { pathNotice != nil },
                                         set: { if !$0 { pathNotice=nil } })) {
            Button("OK", role: .cancel) { pathNotice=nil }
        } message: { Text(pathNotice ?? "") }
        .overlay {
            if let need=insufficientLumes {
                ZStack {
                    ReefTheme.abyss.opacity(0.62).ignoresSafeArea()
                    ReefInsufficientLumesPopup(cost:need.cost,available:need.available,
                                               onGoToGlow:openBloomForGlow,
                                               onCancel:{ insufficientLumes=nil;onOverlay(false) })
                        .padding(.horizontal,24)
                }
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .transition(.opacity.combined(with:.scale(scale:0.96)))
                .zIndex(10)
            }
        }
        .sheet(isPresented: $showHouse, onDismiss: { onOverlay(false) }) { ReefHouseView().presentationDetents([.large]).presentationBackground(.clear) }
        .onChange(of: showHouse) { _, shown in onOverlay(shown) }
        .onChange(of: showExploredMap) { _, shown in onOverlay(shown) }
        .onChange(of: showQuestRewards) { _, shown in onOverlay(shown) }
        .sheet(isPresented: $showQuestRewards, onDismiss: { onOverlay(false) }) {
            ReefQuestRewardsSheet(progress: reef)
                .presentationDetents([.large]).presentationBackground(.clear)
        }
        .sheet(isPresented: $showExploredMap, onDismiss: { onOverlay(false) }) {
            ReefExploredMapSheet(progress: reef)
                .presentationDetents([.large]).presentationBackground(.clear)
        }
        .onChange(of:scenePhase) { _,phase in if phase != .active { journey=nil;questDeparture=nil } }
        .onChange(of:reefPaused) { _,paused in if paused { journey=nil;questDeparture=nil } }
        .task(id:journey?.id) {
            guard let current=journey else { return }
            let receiptID=store.discoveryReceipt?.source == .trail ? store.discoveryReceipt?.id:nil
            do {
                let homecoming = false
                let duration = ReefQuestView.duration(current)
                let object=ReefCove.objects(in:current.outcome.location ?? "start").first{$0.id==current.coveDiscovery}
                let giftEndsAt=current.lifeGift == nil ? 0:(object.map{CoveActionTiming($0).clearedAt} ?? 0)+1.55
                let finishAt = reduceMotion ? 0.15 : max(duration+(homecoming ? 1.5:0.1),giftEndsAt)
                var revealAt = 0.0
                if object?.isChest == true || object?.find == .treasure {
                    store.cancelDiscoveryReceipt()
                } else if let receiptID {
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

    private func heading(elapsed: Double) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ReefQuestView.areaName(questDeparture?.location ?? reef.location ?? "start"))
                        .reefFont(size:20,weight:.semibold,display:true).lineLimit(1).minimumScaleFactor(0.8)
                    ReefIconLabel("\(store.progress.glow)", .glow, size: 24)
                        .reefFont(size: 16, weight: .semibold).monospacedDigit().fixedSize()
                        .accessibilityLabel("\(store.progress.glow) Lumes available")
                }
                Spacer(minLength:0)
                Button(action: onBloom) { ReefIconLabel("Glow", .taps, size: 32).fixedSize() }
                    .buttonStyle(ReefButtonStyle(kind: .action)).disabled(busy)
                ReefPauseButton(action: onPause)
            }
            HStack(spacing:6) {
                ReefQuestProgress(progress: reef, departure: questDeparture, journey: journey,
                                  elapsed: elapsed, reduceMotion: reduceMotion) { showQuestRewards = true }
                Spacer(minLength: 0)
                if store.canVisitHome {
                    Button {showHouse=true} label: {
                        Canvas {c,s in CoralHomeArt.draw(in:c,at:.init(x:s.width/2,y:s.height/2+10),scale:0.16,open:true)}
                            .frame(width:40,height:40)
                    }.buttonStyle(ReefButtonStyle(kind:.quiet)).accessibilityLabel("PuffPuff’s house")
                }
                ReefChestButton(onPresent:onOverlay)
                Button { showHelp.toggle() } label: { Image(systemName:"questionmark") }
                    .buttonStyle(ReefButtonStyle(kind:.quiet)).accessibilityLabel("How to play")
            }.reefFont(size:12,weight:.semibold)
        }.padding(.horizontal,16).frame(maxWidth:470)
    }

    private func visit(_ destination:FirstReef.Destination) {
        guard !busy, !reefPaused, !store.isSaveBlocked else { return }
        let cost=FirstReef.cost(to:destination,from:reef)
        guard FirstReef.route(to:destination.id,state:reef) != nil else { pathNotice="Clear the blockage or take another path.";return }
        guard store.progress.glow >= cost else { promptForGlow(cost:cost); return }
        let departure = reef
        guard let result=store.visitFirstReef(destination.id) else { pathNotice="Couldn't save. Please try again.";return }
        questDeparture = departure;play(result)
    }
    private func uncover(_ object:ReefCove.Object) {
        guard !busy,!reefPaused,!store.isSaveBlocked else{return}
        guard store.progress.glow>=object.cost else { promptForGlow(cost:object.cost); return }
        let departure=reef
        guard let result=store.uncoverCove(object.id) else {pathNotice="Couldn't save. Please try again.";return}
        questDeparture=departure;play(result)
    }
    private func promptForGlow(cost:Int) {
        pathNotice=nil
        insufficientLumes=(cost,store.progress.glow)
        onOverlay(true)
    }
    private func openBloomForGlow() {
        pathNotice=nil;insufficientLumes=nil
        onOverlay(false)
        guard store.playBloomForGlow() else { pathNotice="Couldn't save. Please try again.";return }
    }
    private func play(_ result:ReefJourney) { journeyBegan=Date();journey=result }
}

private struct ReefInsufficientLumesPopup:View {
    let cost:Int
    let available:Int
    let onGoToGlow:()->Void
    let onCancel:()->Void

    private var shortfall:Int { max(0,cost-available) }

    var body:some View {
        VStack(spacing:16) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors:[ReefTheme.hintGold.opacity(0.28),.clear],
                                         center:.center,startRadius:8,endRadius:54))
                ReefIcon(.glow,size:78)
            }
            .frame(width:100,height:100)

            Text("Not enough Lumes")
                .reefFont(size:25,weight:.semibold,display:true)
                .multilineTextAlignment(.center)

            TideDivider(tint:ReefTheme.gold)

            VStack(spacing:8) {
                ReefIconLabel("\(cost) Lumes needed",.glow,size:27)
                    .reefFont(size:19,weight:.semibold)
                Text("You have \(available) Lumes.")
                    .reefFont(size:16,weight:.medium)
                Text("Play Glow to earn the \(shortfall) more you need, then return to this path.")
                    .reefFont(size:14)
                    .foregroundStyle(ReefTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal:false,vertical:true)
            }

            HStack(spacing:8) {
                Button("Not now",action:onCancel)
                    .buttonStyle(ReefButtonStyle(kind:.quiet))
                    .frame(maxWidth:.infinity)
                Button(action:onGoToGlow) {
                    ReefIconLabel("Go to Glow",.taps,size:23)
                        .fixedSize()
                }
                .buttonStyle(ReefButtonStyle(kind:.action))
                .frame(maxWidth:.infinity)
            }
            .padding(.top,4)
        }
        .padding(.horizontal,24)
        .padding(.vertical,28)
        .frame(maxWidth:380)
        .background {
            ZStack {
                MembraneShape().fill(ReefTheme.glass)
                MembraneSurface(tint:ReefTheme.gold,intensity:0.85)
            }
        }
        .overlay(MembraneShape().stroke(ReefTheme.glint.opacity(0.9),lineWidth:1.2))
        .shadow(color:ReefTheme.abyss.opacity(0.45),radius:28,y:12)
        .foregroundStyle(ReefTheme.ink)
        .accessibilityElement(children:.contain)
    }
}

// The doorway lip is shared with the existing swim-home animation.
enum ReefBayArt {
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
                meter(symbol: "sparkles", count: progress.food.count, before: departure?.food.count,
                      total: FirstReef.food.count, tint: ReefTheme.coral, gained: journey?.newFood.isEmpty == false, food: true)
                ReefMysteryHome(restored:progress.hasRestoredHome)
                    .frame(width:compact ? 44:52,height:44)
            }.padding(.vertical, 7)
        }
        .buttonStyle(ReefButtonStyle(kind: .navigation))
        .accessibilityLabel("Path goals")
        .accessibilityValue("\(progress.food.count) of 3 gardens glowing. \(progress.hasRestoredHome ? "Home restored" : "Find and relight your home").")
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
                                ReefQuestArt.coral(.rosyFan,in:c,at:.init(x:size.width/2,y:size.height/2),size:42,time:0,seed:0,moving:false,light:1)
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
                        Text("The Faded Garden").reefFont(size: 25, weight: .semibold, display: true)
                        Spacer()
                        Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                            .buttonStyle(ReefButtonStyle(kind: .orb)).accessibilityLabel("Close path goals")
                    }
                    Label("\(progress.food.count)/3 gardens glowing", systemImage: "sparkles")
                        .reefFont(size: 18, weight: .semibold).foregroundStyle(ReefTheme.coral)
                    Label(progress.hasRestoredHome ? "Home is glowing" : progress.hasFoundHome ? "Relight home" : "Find your home", systemImage: progress.hasRestoredHome ? "checkmark.circle.fill" : "house")
                        .reefFont(size: 18, weight: .semibold).foregroundStyle(ReefTheme.gold)
                    Text("A storm scattered the reef and put out its coral lights. Relight three gardens to find your way home. Treasure is optional.")
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
                                        if loot.lighters > 0 { ReefIconLabel("\(loot.lighters)", .lighter) }
                                        if loot.instantBoost { ReefIconLabel("15 min", .boostLive) }
                                    } else {
                                        Text("Hidden find").reefFont(size:15,weight:.semibold)
                                    }
                                }.reefFont(size: 15, weight: .semibold)
                                    .accessibilityElement(children: .ignore).accessibilityLabel(opened ? chest.treasureReward : "Hidden find")
                                Text(opened ? "Collected" : "\(chest.actionLabel) · \(chest.glowCost) Lumes")
                                    .reefFont(size: 12).foregroundStyle(ReefTheme.muted)
                            }.fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if progress.completed {
                        Text("Your home is ready. Make it your own, or keep exploring for treasure.").reefFont(size:14)
                    }
                    ForEach(ReefWorldPlan.worlds.dropFirst()) { world in
                        VStack(alignment:.leading,spacing:6) {
                            Label(world.title,systemImage:"lock.fill").reefFont(size:18,weight:.semibold)
                            Text(world.story).reefFont(size:13)
                            Text("Coming later").reefFont(size:12).foregroundStyle(ReefTheme.muted)
                        }.padding(.vertical,8)
                    }
                    Text(progress.completed ? "The Faded Garden is glowing again." : "Side paths hide extra Glow supplies.")
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
