import SwiftUI

extension ReefDiscovery {
    var title:String {
        switch self {
        case .glow:"Lumes"
        case .snack:"Coral gardens"
        case .hint:"Hints"
        case .futureTeller:"Future Teller"
        case .life:"Lives"
        case .lighter:"Lighters"
        case .instantBoost:"Unlimited lives"
        case .storedBoost:"Saved unlimited lives"
        case .shot:"Shots"
        case .current:"Current changers"
        case .currentAdder:"Current adders"
        case .bouncyBlock:"Bouncy blocks"
        }
    }
    var explanation:String {
        switch self {
        case .glow:"Spend Lumes to uncover the Trail and collect supplies. Earn more by playing Glow."
        case .snack:"Relight three coral gardens and your home to restore The Faded Garden."
        case .hint:"Reveal one useful coral to tap in Glow. Uses one hint, with no tap cost."
        case .futureTeller:"Glimpse one possible board just before the winning tap. Work toward that arrangement, then tap the marked coral. Reopen your glimpse freely this attempt."
        case .life:"Lose one if a Glow attempt fails or you restart. One refills every five minutes, up to five. Winning costs nothing."
        case .lighter:"Light one coral and keep it glowing for that Glow attempt. Uses no taps."
        case .instantBoost:"Starts immediately: fifteen minutes of unlimited Glow lives, with your lives refilled."
        case .storedBoost:"Keep this gold boost until you need it. Activate it for fifteen minutes of unlimited Glow lives and a refill."
        case .shot:"Each putt or Trail challenge move uses one shot. Collect more in Glow and while exploring."
        case .bouncyBlock:"Place a bouncy coral block to bank PuffPuff or an enemy fish. Uses one block in any golf challenge. It disappears on Retry."
        case .current:"Use one to redirect a current in bonus golf."
        case .currentAdder:"Place an extra current and choose its direction. Uses one adder. Use it in bonus golf, kelp runs or enemy challenges. It disappears on Retry."
        }
    }
    var icon:ReefIconKind {
        switch self {
        case .glow,.snack:.glow
        case .hint:.hint
        case .futureTeller:.futureTeller
        case .life:.life
        case .lighter:.lighter
        case .instantBoost:.boostLive
        case .storedBoost:.boostStored
        case .shot:.shot
        case .current:.current
        case .currentAdder:.currentAdder
        case .bouncyBlock:.bouncyBlock
        }
    }
    func balance(_ p:ReefProgress,at now:Date)->String {
        let s=p.supplies.refreshed(at:now)
        switch self {
        case .glow:return "\(p.glow)"
        case .snack:return "\(p.firstReef.food.count)/3"
        case .hint:return "\(p.hints)"
        case .futureTeller:return "\(p.futureTellers)"
        case .life:return "\(s.lives)"
        case .lighter:return "\(s.lighters)"
        case .instantBoost:return s.unlimited(at:now) ? BloomLivesStatus.countdown(s.unlimitedUntil!,at:now):"Inactive"
        case .storedBoost:return "\(s.unlimitedBoosts)"
        case .shot:return "\(p.shots)"
        case .current:return "\(p.currentChangers)"
        case .currentAdder:return "\(p.currentAdders)"
        case .bouncyBlock:return "\(p.bouncyBlocks)"
        }
    }
}

struct ReefDiscoveryArt:View {
    let item:ReefDiscovery
    var size:Double=48
    var body:some View {
        if item == .snack {
            Canvas {c,s in ReefQuestArt.coral(.rosyFan,in:c,at:.init(x:s.width/2,y:s.height/2),size:size,time:0,seed:0,moving:false,light:1)}.frame(width:size,height:size)
        } else {ReefIcon(item.icon,size:size)}
    }
}

struct ReefChestButton:View {
    var labelled=false
    var onPresent:(Bool)->Void = {_ in}
    @State private var shown=false
    var body:some View {
        Button {shown=true} label:{
            HStack(spacing:8) {
                Canvas {c,s in TrailArt.draw(.chestMint,in:c,at:.init(x:s.width/2,y:s.height/2),size:39)}.frame(width:44,height:44)
                if labelled {Text("Your treasure").reefFont(size:17,weight:.semibold)}
            }
        }.buttonStyle(ReefButtonStyle(kind:.quiet)).accessibilityLabel("Your treasure")
            .onChange(of:shown) {_,value in onPresent(value)}
            .sheet(isPresented:$shown,onDismiss:{onPresent(false)}) {
                ReefInventoryView().presentationDetents([.large]).presentationBackground(.clear)
            }
    }
}

struct ReefInventoryView:View {
    @Environment(ReefStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        OceanScene {
            ScrollView(.vertical) {
                VStack(alignment:.leading,spacing:20) {
                    HStack {
                        Text("Your treasure").reefFont(size:27,weight:.semibold,display:true)
                        Spacer()
                        Button {dismiss()} label:{Image(systemName:"xmark").frame(width:44,height:44)}
                            .buttonStyle(ReefButtonStyle(kind:.quiet)).accessibilityLabel("Close treasure chest")
                    }
                    row(.glow)
                    section("Glow",items:[.life,.hint] + (store.progress.futureTellerUnlocked ? [.futureTeller]:[]) + [.lighter,.instantBoost,.storedBoost])
                }.padding(24).frame(maxWidth:480,alignment:.leading)
                    .frame(maxWidth:.infinity,alignment:.topLeading)
                    .clipped()
            }
            .scrollIndicators(.visible)
            .scrollBounceBehavior(.basedOnSize,axes:.vertical)
        }.foregroundStyle(ReefTheme.ink)
        #if os(macOS)
        .frame(minWidth:400,idealWidth:460,minHeight:650,idealHeight:760)
        #endif
    }
    private func section(_ title:String,items:[ReefDiscovery])->some View {
        VStack(alignment:.leading,spacing:16) {
            TideDivider(tint:ReefTheme.gold)
            Text(title).reefFont(size:22,weight:.semibold)
            ForEach(items) {row($0)}
        }
    }
    private func row(_ item:ReefDiscovery)->some View {
        HStack(alignment:.top,spacing:14) {
            ReefDiscoveryArt(item:item)
            VStack(alignment:.leading,spacing:5) {
                TimelineView(.periodic(from:.now,by:1)) {clock in
                    HStack(alignment:.firstTextBaseline,spacing:8) {
                        Text(item.title).reefFont(size:16,weight:.semibold)
                            .lineLimit(1).minimumScaleFactor(0.8)
                            .frame(maxWidth:.infinity,alignment:.leading)
                        Text(item.balance(store.progress,at:clock.date)).reefFont(size:16,weight:.semibold)
                            .monospacedDigit().lineLimit(1).fixedSize(horizontal:true,vertical:false)
                    }
                }
                Text(item.explanation).reefFont(size:13).foregroundStyle(ReefTheme.muted).fixedSize(horizontal:false,vertical:true)

                if item == .storedBoost,store.progress.supplies.unlimitedBoosts>0 {
                    Button("Use 15 min") {_ = store.activateUnlimitedLives()}
                        .buttonStyle(ReefButtonStyle(kind:.action)).disabled(store.isSaveBlocked)
                }
            }.frame(maxWidth:.infinity,alignment:.leading)
        }.frame(maxWidth:.infinity,alignment:.leading).accessibilityElement(children:.contain)
    }
}

struct ReefDiscoverySheet:View {
    let item:ReefDiscovery
    let onDone:()->Void
    var body:some View {
        OceanScene {
            VStack(spacing:20) {
                ReefDiscoveryArt(item:item,size:100)
                Text(item.title).reefFont(size:28,weight:.semibold,display:true)
                Text(item.explanation).reefFont(size:17).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
                Button("Got it",action:onDone).buttonStyle(ReefButtonStyle(kind:.action))
            }.padding(30).frame(maxWidth:400).frame(maxWidth:.infinity,maxHeight:.infinity)
        }.foregroundStyle(ReefTheme.ink).interactiveDismissDisabled()
        #if os(macOS)
        .frame(width:420,height:420)
        #endif
    }
}
