import SwiftUI

/// The real Trail challenge owns a saved attempt. Practice below never accesses ReefStore.
struct ReefMiniChallengeView:View {
    let objectID:String
    var onClose:(ReefJourney?)->Void
    @Environment(ReefStore.self) private var store
    @State private var moving=false
    @State private var reveal:ReefJourney?
    private var attempt:ReefMiniAttempt {
        store.progress.firstReef.miniChallenges?[objectID] ?? .fresh(.kelp)
    }
    var body:some View {
        ReefMiniShell(title:attempt.kind == .kelp ? "Kelp run":"Scare enemies",close:{onClose(reveal)}) {
            VStack(spacing:12) {
                Text(attempt.kind == .kelp ? "Reach the hole in 4 shots. Touch kelp and try again.":attempt.timedEnemies == true ? "Time one shot to get both fish into the hole.":"Get both fish into the hole. \(attempt.moveLimit) shots.")
                    .reefFont(size:15).multilineTextAlignment(.center)
                HStack {
                    Text("\(max(0,attempt.moveLimit-attempt.moves)) \(attempt.moveLimit-attempt.moves == 1 ? "shot":"shots") left").reefFont(size:16,weight:.semibold)
                    Spacer()
                    ReefIcon(.shot,size:26)
                    Text("\(store.progress.shots)").reefFont(size:16)
                }
                ReefMiniArena(attempt:attempt,moving:$moving,enabled:store.progress.shots>0 && !store.isSaveBlocked,patrol:attempt.timedEnemies == true,
                              currentCount:store.progress.currentAdders,blockCount:store.progress.bouncyBlocks,
                              onPlace:{aid,point,direction in store.addCoveAid(aid,to:objectID,at:point,direction:direction)}) {drag,phase in
                    guard let shot=store.shootCoveChallenge(objectID,drag:drag,patrolTime:phase) else{return nil}
                    reveal=shot.discovery;return shot.flight
                }
            }
        } actions: {
            VStack(spacing:6) {
                VStack(spacing:4) {
                  if !moving {
                    if attempt.result == .wall {Text("Caught in the kelp").reefFont(size:16,weight:.semibold)}
                    if attempt.result == .outOfShots {Text("Try again").reefFont(size:16,weight:.semibold)}
                    if store.progress.shots == 0,attempt.result != .won {
                        Text("Find more shots on the Trail or in Bloom.").reefFont(size:13).multilineTextAlignment(.center)
                    }
                }
                }.frame(minHeight:44)
                if attempt.result == .won {
                    Button("Continue") {onClose(reveal)}
                        .buttonStyle(ReefButtonStyle(kind:.action)).disabled(moving)
                } else {
                    Button("Retry") {_ = store.beginCoveChallenge(objectID,retry:true)}
                        .buttonStyle(ReefButtonStyle(kind:.action))
                        .disabled(moving || attempt.moves == 0 || store.isSaveBlocked)
                }
            }.frame(maxWidth:.infinity)
        }
    }
}

private struct ReefMiniOverlayKey:PreferenceKey {
    static var defaultValue=false
    static func reduce(value:inout Bool,nextValue:()->Bool) {value = value || nextValue()}
}
private struct ReefMiniBoardWidthKey:EnvironmentKey {static let defaultValue=360.0}
private extension EnvironmentValues {
    var reefMiniBoardWidth:Double {
        get {self[ReefMiniBoardWidthKey.self]}
        set {self[ReefMiniBoardWidthKey.self]=newValue}
    }
}

struct ReefMiniShell<Content:View,Actions:View>:View {
    let title:String
    let close:()->Void
    @ViewBuilder var content:Content
    @ViewBuilder var actions:Actions
    @Environment(\.scenePhase) private var scenePhase
    @State private var overlayOpen=false
    var body:some View {
        OceanScene(paused:scenePhase != .active || overlayOpen) {
            VStack(spacing:10) {
                HStack {
                    Text(title).reefFont(size:26,weight:.semibold,display:true)
                    Spacer()
                    Button("Done",action:close).buttonStyle(ReefButtonStyle(kind:.quiet))
                }
                GeometryReader {space in
                    ScrollView {content.padding(.bottom,12).frame(maxWidth:.infinity)}.scrollIndicators(.visible)
                        .environment(\.reefMiniBoardWidth,min(360,max(210,(space.size.height-154)*340/500)))
                }
                // Outside the scroll view: reachable even on small phones or large text.
                actions.padding(.top,4).fixedSize(horizontal:false,vertical:true)
            }.padding(18).frame(maxWidth:470).frame(maxWidth:.infinity)
        }.foregroundStyle(ReefTheme.ink).environment(\.reefPaused,false)
            .onPreferenceChange(ReefMiniOverlayKey.self) {overlayOpen=$0}
        #if os(macOS)
        .frame(minWidth:390,idealWidth:440,minHeight:680,idealHeight:820)
        #endif
    }
}

/// Input is confined to Puff Puff, so dragging the rest of the view still scrolls.
struct ReefMiniArena:View {
    let attempt:ReefMiniAttempt
    @Binding var moving:Bool
    var enabled=true
    var patrol=false
    var shells:[ReefPoint]=[]
    var moveShell:((Int,ReefPoint)->Void)?
    var currentCount=0
    var blockCount=0
    var onPlace:((ReefGolfAid,ReefPoint,Int)->Bool)?
    var onLaunch:(ReefPoint,Double?)->ReefMiniFlight?
    @Environment(\.oceanTime) private var oceanTime
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.reefMiniBoardWidth) private var boardWidth
    @State private var flight:ReefMiniFlight?
    @State private var returning:ReefMiniReturn?
    @State private var placingAid:ReefGolfAid?
    @State private var placementPoint:ReefPoint?
    @State private var placementError:String?
    @State private var started=Date()
    @State private var pull:ReefPoint?
    var body:some View {
      VStack(spacing:8) {
        GeometryReader {geometry in
            let scale=geometry.size.width/ReefMiniChallenge.width
            TimelineView(.animation(minimumInterval:1.0/60,paused:(flight == nil && returning == nil) || scenePhase != .active)) {clock in
                let elapsed=max(0,clock.date.timeIntervalSince(started))
                // Read the arena's clock, inside its OceanScene. The parent sheet
                // can have a different (or paused) clock and must never aim the shot.
                let phase:Double?=patrol ? (reduceMotion ? 0:oceanTime/1000):nil
                let resting=ReefMiniChallenge.restingFrame(attempt,patrolTime:phase)
                let frame=flight?.frame(at:elapsed) ?? returning?.frame(toward:resting,at:elapsed) ?? resting
                ZStack(alignment:.topLeading) {
                    Canvas {context,_ in
                        var c=context;c.scaleBy(x:scale,y:scale)
                        ReefMiniArt.draw(kind:attempt.kind,layout:attempt.layout ?? 0,frame:frame,in:c,time:reduceMotion ? 0:oceanTime,shells:shells,
                                         pull:pull,won:!moving && attempt.result == .won,
                                         releaseCharge:(flight?.launchCharge ?? 0)*(1-min(1,elapsed/0.22)),
                                         currents:attempt.addedCurrents ?? [],blocks:attempt.bouncyBlocks ?? [])
                    }.allowsHitTesting(false)
                    if !moving,!attempt.finished,let aid=placingAid {
                        Color.clear.contentShape(Rectangle()).onTapGesture {point in
                            let p=ReefPoint(x:point.x/scale,y:point.y/scale)
                            if ReefMiniChallenge.canPlace(aid,at:p,in:attempt),
                               ReefMiniChallenge.clearOfFish(p,in:attempt),
                               shells.allSatisfy({($0-p).length>=50}) {placementPoint=p}
                            else {placementError="Choose open water away from fish, the hole and other obstacles."}
                        }.accessibilityLabel("Choose a place for the \(aid.title.lowercased())")
                    }
                    if !moving,enabled,!attempt.finished,placingAid == nil {
                        Color.clear.frame(width:64,height:64).contentShape(Circle())
                            .position(x:frame.position.x*scale,y:frame.position.y*scale)
                            .gesture(DragGesture(minimumDistance:0,coordinateSpace:.named("mini-board"))
                                .onChanged {v in pull = .init(x:(v.startLocation.x-v.location.x)/scale,y:(v.startLocation.y-v.location.y)/scale)}
                                .onEnded {v in
                                    let drag=ReefPoint(x:(v.startLocation.x-v.location.x)/scale,y:(v.startLocation.y-v.location.y)/scale)
                                    pull=nil
                                    guard let next=onLaunch(drag,phase) else{return}
                                    if !reduceMotion {started=Date();flight=next;moving=true}
                                })
                            .accessibilityLabel("Puff Puff. Pull back and release to shoot.")
                    }
                    if !moving,placingAid == nil,let moveShell {
                        ForEach(shells.indices,id:\.self) {i in
                            Color.clear.frame(width:54,height:54).contentShape(Circle())
                                .position(x:shells[i].x*scale,y:shells[i].y*scale)
                                .gesture(DragGesture(minimumDistance:1,coordinateSpace:.named("mini-board")).onChanged {v in
                                    moveShell(i,.init(x:v.location.x/scale,y:v.location.y/scale))
                                }).accessibilityLabel("Move shell \(i+1)")
                        }
                    }
                }
            }
        }.aspectRatio(340.0/500,contentMode:.fit).frame(maxWidth:boardWidth)
            .coordinateSpace(name:"mini-board")
            .task(id:flight?.id ?? returning?.id) {
                guard let duration=flight?.duration ?? returning?.duration else{return}
                do {try await Task.sleep(for:.seconds(duration))} catch{return}
                flight=nil;returning=nil;moving=false
            }
            .onChange(of:attempt) {old,new in
                guard new.moves == 0,old.moves > 0 ||
                    (!(old.addedCurrents ?? []).isEmpty || !(old.bouncyBlocks ?? []).isEmpty) && new.addedCurrents == nil && new.bouncyBlocks == nil else{return}
                pull=nil;flight=nil;placingAid=nil;placementPoint=nil
                guard old.moves > 0 else{return}
                guard !reduceMotion,scenePhase == .active else{return}
                returning=ReefMiniReturn(from:ReefMiniChallenge.restingFrame(old))
                started=Date();moving=true
            }
            .onChange(of:scenePhase) {_,phase in if phase != .active {settle()}}
            .onChange(of:reduceMotion) {_,value in if value {settle()}}
            .onDisappear {settle()}
        if onPlace != nil {
            ReefAidControls(currents:currentCount,blocks:blockCount,placing:$placingAid,enabled:!moving && !attempt.finished)
                .opacity(attempt.finished ? 0:1).allowsHitTesting(!attempt.finished)
        }
      }
      .preference(key:ReefMiniOverlayKey.self,value:placementPoint != nil || placementError != nil)
      .sheet(isPresented:Binding(get:{placementPoint != nil},set:{if !$0 {placementPoint=nil}})) {
          if placingAid == .block {
              ReefBlockPicker(count:blockCount) {place(direction:0)}
                  .presentationDetents([.height(310)]).presentationBackground(.clear)
          } else {
              ReefCurrentPicker(index:0,direction:0,count:currentCount,onUse:{place(direction:$0)},placing:true)
                  .presentationDetents([.height(430)]).presentationBackground(.clear)
          }
      }
      .alert("",isPresented:Binding(get:{placementError != nil},set:{if !$0 {placementError=nil}})) {
          Button("OK",role:.cancel) {placementError=nil}
      } message: {Text(placementError ?? "")}
    }
    private func place(direction:Int) {
        guard let aid=placingAid,let point=placementPoint else{return}
        if onPlace?(aid,point,direction) == true {placementPoint=nil;placingAid=nil}
        else {placementPoint=nil;placementError="Couldn't place it. Your power-up is still in your treasure."}
    }
    private func settle() {flight=nil;returning=nil;moving=false;pull=nil;placingAid=nil;placementPoint=nil}
}

enum ReefMiniTrial:String,CaseIterable,Identifiable {
    case kelp,movingEnemies,enemyPutts,arrangeEnemies
    var id:String {rawValue}
    static var enemies:[Self] {[.movingEnemies,.enemyPutts,.arrangeEnemies]}
    var title:String {
        switch self {case .kelp:"Kelp run";case .movingEnemies:"1. Timed school";case .enemyPutts:"2. Scare enemies";case .arrangeEnemies:"3. Shell setup"}
    }
    var rule:String {
        switch self {
        case .kelp:"Reach the hole in 4 shots. Touch kelp and try again."
        case .movingEnemies:"Time one shot to send both moving fish into the hole."
        case .enemyPutts:"Get both fish into the hole in 8 shots."
        case .arrangeEnemies:"Arrange the shells. Bank off one and sink both fish in 3 shots."
        }
    }
    var limit:Int {self == .movingEnemies ? 1:self == .arrangeEnemies ? 3:self == .enemyPutts ? 8:4}
    var kind:ReefMiniKind {self == .kelp ? .kelp:.enemy}
}
struct ReefMiniPractice:View {
    let trial:ReefMiniTrial
    var title:String?=nil
    var layout=0
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        ReefMiniPracticeGame(trial:trial,title:title,layout:layout,close:{dismiss()}).id(trial)
    }
}
struct ReefMiniPracticeGame:View {
    let trial:ReefMiniTrial
    let title:String?
    let layout:Int
    let close:()->Void
    @State private var attempt:ReefMiniAttempt
    @State private var moving=false
    @State private var shells=[ReefPoint(x:80,y:355),ReefPoint(x:265,y:270)]
    @State private var banked=false
    @State private var currentStock=3
    @State private var blockStock=3
    init(trial:ReefMiniTrial,title:String?=nil,layout:Int=0,close:@escaping ()->Void) {
        self.trial=trial;self.title=title;self.layout=layout;self.close=close
        _attempt=State(initialValue:.fresh(trial.kind,layout:layout,timed:trial == .movingEnemies))
    }
    private var won:Bool {attempt.result == .won && (trial != .arrangeEnemies || banked)}
    private var ended:Bool {attempt.finished || attempt.moves>=trial.limit}
    var body:some View {
        ReefMiniShell(title:title ?? trial.title,close:close) {
          VStack(spacing:12) {
            Text(trial.rule).reefFont(size:15).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
            HStack {
                Text("\(max(0,trial.limit-attempt.moves)) \(trial.limit-attempt.moves == 1 ? "shot":"shots") left").reefFont(size:16,weight:.semibold)
                Spacer()
                Text("Free practice").reefFont(size:12).foregroundStyle(ReefTheme.muted)
            }
            ReefMiniArena(attempt:attempt,moving:$moving,enabled:!ended,patrol:trial == .movingEnemies,
                          shells:trial == .arrangeEnemies ? shells:[],
                          moveShell:trial == .arrangeEnemies && attempt.moves==0 ? {i,p in place(i,p)}:nil,
                          currentCount:currentStock,blockCount:blockStock,
                          onPlace:{aid,p,direction in add(aid,at:p,direction:direction)}) {drag,phase in
                guard let flight=ReefMiniChallenge.shoot(drag,from:attempt,patrolTime:phase,shells:trial == .arrangeEnemies ? shells:[]) else{return nil}
                attempt=flight.outcome;banked = banked || !flight.shellHits.isEmpty
                return flight
            }
          }
        } actions: {
            VStack(spacing:6) {
                Text(!moving && ended ? (won ? "Cleared!":attempt.result == .wall ? "Caught in the kelp":attempt.result == .won ? "Try a shell bank":"Try again"):" ")
                    .reefFont(size:18,weight:.semibold).foregroundStyle(ReefTheme.gold).frame(minHeight:26)
                Button(won ? "Replay":"Retry") {reset()}
                    .buttonStyle(ReefButtonStyle(kind:.action)).disabled(moving)
            }.frame(maxWidth:.infinity)
        }
    }
    private func reset() {attempt = .fresh(trial.kind,layout:layout,timed:trial == .movingEnemies);banked=false;currentStock=3;blockStock=3}
    private func add(_ aid:ReefGolfAid,at p:ReefPoint,direction:Int)->Bool {
        guard !ended,(0..<8).contains(direction),ReefMiniChallenge.canPlace(aid,at:p,in:attempt),
              ReefMiniChallenge.clearOfFish(p,in:attempt),
              trial != .arrangeEnemies || shells.allSatisfy({($0-p).length>=50}) else{return false}
        if aid == .current {
            guard currentStock>0 else{return false}
            attempt.addedCurrents=(attempt.addedCurrents ?? [])+[.init(position:p,direction:direction)];currentStock -= 1
        } else {
            guard blockStock>0 else{return false}
            attempt.bouncyBlocks=(attempt.bouncyBlocks ?? [])+[.init(position:p)];blockStock -= 1
        }
        return true
    }
    private func place(_ i:Int,_ p:ReefPoint) {
        let safe=ReefPoint(x:min(296,max(44,p.x)),y:min(375,max(145,p.y)))
        guard (safe-ReefMiniChallenge.enemyStart).length>58,
              attempt.enemies.allSatisfy({(safe-$0.position).length>50}),
              (attempt.bouncyBlocks ?? []).allSatisfy({(safe-$0.position).length>=50}),
              (attempt.addedCurrents ?? []).allSatisfy({(safe-$0.position).length>=50}),
              shells.indices.filter({$0 != i}).allSatisfy({(safe-shells[$0]).length>52}) else{return}
        shells[i]=safe
    }
}
