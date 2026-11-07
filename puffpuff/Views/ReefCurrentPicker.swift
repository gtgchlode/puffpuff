import SwiftUI

struct ReefCurrentButton:View {
    let direction:Int
    let time:Double
    let action:()->Void
    var body:some View {
        Button(action:action) {
            Image(systemName:"arrow.up").font(.system(size:19,weight:.bold))
                .rotationEffect(.degrees(Double(direction)*45))
                .foregroundStyle(ReefTheme.ink)
                .frame(width:44,height:44)
                .background(SeaGlassShape(seed:Double(direction)).fill(ReefTheme.glass.opacity(0.82)))
                .overlay(SeaGlassShape(seed:Double(direction)).stroke(ReefTheme.glint.opacity(0.6),lineWidth:1.5))
                .shadow(color:ReefTheme.glint.opacity(0.3),radius:5+sin(time/2000)*2)
        }.buttonStyle(.plain)
    }
}

struct ReefCurrentPicker:View {
    static let names=["up","up and right","right","down and right","down","down and left","left","up and left"]
    let index:Int
    let direction:Int
    let count:Int
    let onUse:(Int)->Void
    var placing=false
    @Environment(\.dismiss) private var dismiss
    @State private var choice:Int?
    private let positions=[7,0,1,6,-1,2,5,4,3]
    var body:some View {
        VStack(spacing:14) {
            HStack {
                Text(placing ? "Add current":"Current \(index+1)").reefFont(size:23,weight:.semibold)
                Spacer()
                Button("Done") {dismiss()}.buttonStyle(ReefButtonStyle(kind:.quiet))
            }
            LazyVGrid(columns:Array(repeating:GridItem(.fixed(58)),count:3),spacing:6) {
                ForEach(positions,id:\.self) { value in
                    if value<0 {ReefIcon(placing ? .currentAdder:.current,size:49)}
                    else {
                        ReefCurrentButton(direction:value,time:0) {choice=value}
                            .overlay {
                                if (choice ?? direction) == value {
                                    SeaGlassShape().stroke(ReefTheme.gold,lineWidth:3).frame(width:50,height:50).allowsHitTesting(false)
                                }
                            }
                            .accessibilityLabel(Self.names[value])
                            .accessibilityAddTraits((choice ?? direction) == value ? .isSelected:[])
                    }
                }
            }
            ReefIconLabel("\(count) left",placing ? .currentAdder:.current,size:25).reefFont(size:14)
            Text(placing ? "Gone on Retry.":count == 0 ? "Find changers while exploring the Trail.":"Uses one current changer.")
                .reefFont(size:13).foregroundStyle(ReefTheme.muted)
            Button(placing ? "Use 1 adder":"Use 1 changer") {if placing {onUse(choice ?? direction)} else if let choice {onUse(choice)}}
                .buttonStyle(ReefButtonStyle(kind:.action))
                .disabled(count == 0 || (!placing && (choice == nil || choice == direction)))
        }.padding(24).frame(maxWidth:420)
            .background(MembraneShape().fill(ReefTheme.glass))
            .padding(16).frame(maxWidth:.infinity,maxHeight:.infinity)
            .background(ReefTheme.deep.opacity(0.95))
    }
}


extension ReefGolfAid {
    var icon:ReefIconKind {self == .current ? .currentAdder:.bouncyBlock}
    var title:String {self == .current ? "Current":"Block"}
}

struct ReefAidControls:View {
    let currents:Int
    let blocks:Int
    @Binding var placing:ReefGolfAid?
    var enabled=true
    var body:some View {
        HStack(spacing:12) {
            if placing != nil {
                Text("Tap open water").reefFont(size:13)
                Button("Cancel") {placing=nil}.buttonStyle(ReefButtonStyle(kind:.quiet))
            } else {
                ForEach(ReefGolfAid.allCases) {aid in
                    let count=aid == .current ? currents:blocks
                    Button {placing=aid} label: {
                        ReefIconLabel("\(aid.title) · \(count)",aid.icon,size:26)
                    }.buttonStyle(ReefButtonStyle(kind:.quiet)).disabled(!enabled || count==0)
                        .accessibilityLabel("Add \(aid.title.lowercased()), \(count) available")
                }
            }
        }.reefFont(size:14).frame(minHeight:44)
    }
}

struct ReefBlockPicker:View {
    let count:Int
    let onUse:()->Void
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        VStack(spacing:16) {
            HStack {
                Text("Add bouncy block").reefFont(size:23,weight:.semibold)
                Spacer()
                Button("Done") {dismiss()}.buttonStyle(ReefButtonStyle(kind:.quiet))
            }
            ReefIcon(.bouncyBlock,size:70)
            Text("Bank off it. Gone on Retry.").reefFont(size:14)
            Button("Use 1 block") {onUse()}.buttonStyle(ReefButtonStyle(kind:.action)).disabled(count==0)
        }.padding(24).background(MembraneShape().fill(ReefTheme.glass))
            .padding(16).frame(maxWidth:420,maxHeight:.infinity)
            .frame(maxWidth:.infinity).background(ReefTheme.deep.opacity(0.95))
            .foregroundStyle(ReefTheme.ink)
    }
}
