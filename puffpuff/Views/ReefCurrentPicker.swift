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
    @Environment(\.dismiss) private var dismiss
    @State private var choice:Int?
    private let positions=[7,0,1,6,-1,2,5,4,3]
    var body:some View {
        VStack(spacing:14) {
            HStack {
                Text("Current \(index+1)").reefFont(size:23,weight:.semibold)
                Spacer()
                Button("Done") {dismiss()}.buttonStyle(ReefButtonStyle(kind:.quiet))
            }
            LazyVGrid(columns:Array(repeating:GridItem(.fixed(58)),count:3),spacing:6) {
                ForEach(positions,id:\.self) { value in
                    if value<0 {ReefIcon(.current,size:49)}
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
            ReefIconLabel("\(count) left",.current,size:25).reefFont(size:14)
            Text(count == 0 ? "Find changers while exploring the Trail.":"One changer. Lasts through retries.")
                .reefFont(size:13).foregroundStyle(ReefTheme.muted)
            Button("Use 1 changer") {if let choice {onUse(choice)}}
                .buttonStyle(ReefButtonStyle(kind:.action))
                .disabled(count == 0 || choice == nil || choice == direction)
        }.padding(24).frame(maxWidth:420)
            .background(MembraneShape().fill(ReefTheme.glass))
            .padding(16).frame(maxWidth:.infinity,maxHeight:.infinity)
            .background(ReefTheme.deep.opacity(0.95))
    }
}
