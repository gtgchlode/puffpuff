import Foundation
import Observation

struct SearchSpot:Identifiable {
    let id:Int
    var area:Int {id/4}
    var slot:Int {id%4}
    var barrier:Int {(area+slot)%3}
    var cost:Int {[2,4,1,3][slot]}
    var action:String {["Part kelp","Sweep sand","Scare fish"][barrier]}
    var reward:String {slot == 0 ? "Snack found!":slot == 1 ? ["Hint + golf advantage","Lives + golf advantage","Lighter + golf advantage"][area]:slot == 2 ? "Coral lit!":"Passage open"}
}

@Observable final class ReefSearchLab {
    let kind:LabPathKind
    var area=0
    var glow=24
    var cleared:Set<Int>=[]
    var scanned:Set<Int>=[]
    var opened:Set<Int>=[0]
    var won=false
    var message=""
    var lastSpot:Int?
    var loops=0
    init(_ kind:LabPathKind) {self.kind=kind;if kind == .hub {area = -1};if kind == .hub || kind == .hunt {opened=[0,1,2]}}
    let areaNames=["Kelp nook","Shell shallows","Coral passage"]
    var spots:[SearchSpot] {(0..<12).map(SearchSpot.init)}
    var foods:Int {cleared.filter{$0%4 == 0}.count}
    var finds:Int {cleared.filter{$0%4 == 1}.count}
    var instruction:String {[
        "Search each cove. Clear its passage when you’re ready to swim on.",
        "Tap the edge of the darkness. Each clearing reveals more reef.",
        "Search the scene, then swipe sideways to the next shore.",
        "Uncover neighboring patches. Grow a little garden of light.",
        "Search each shelf. Open its passage to dive deeper.",
        "Choose a reef from home. Search it, then return for another.",
        "Scan a dark hiding place, then decide whether to uncover it.",
        "Search a pocket, then ride onward. Loop around for anything you missed."
    ][kind.id]}
    func available(_ id:Int)->Bool {
        guard (0..<12).contains(id) else{return false}
        if cleared.contains(id) {return true}
        if kind == .fog || kind == .garden {
            if id == 0 {return true}
            let a=id/4,s=id%4
            if s == 0 {return cleared.contains((a-1)*4+3)}
            return cleared.contains(a*4) || s == 3 && (cleared.contains(a*4+1) || cleared.contains(a*4+2))
        }
        return opened.contains(id/4)
    }
    func uncover(_ id:Int) {
        guard available(id),!cleared.contains(id) else{return}
        let spot=SearchSpot(id:id)
        if kind == .hunt,!scanned.contains(id) {
            guard glow>=1 else{message="Need 1 Glow";return}
            glow -= 1;scanned.insert(id);message="\(spot.action) · \(spot.cost) Glow";return
        }
        guard glow>=spot.cost else{message="Need \(spot.cost) Glow";return}
        glow -= spot.cost;cleared.insert(id);lastSpot=id;message=spot.reward
        if spot.slot == 3,spot.area<2 {opened.insert(spot.area+1)}
        if kind == .fog || kind == .garden {area=spot.area}
    }
    func visit(_ destination:Int) {
        guard destination == -1 && kind == .hub || opened.contains(destination) else{return}
        area=destination;message="";lastSpot=nil
    }
    func flowOn() {
        guard kind == .current,cleared.contains(area*4+3) else{return}
        let next=(area+1)%3
        if next == 0 {loops += 1}
        visit(next)
    }
    func home() {
        guard foods == 3 else{message="Find \(3-foods) more snacks";return}
        won=true;message="Home!"
    }
    func refill() {glow += 8;message="8 trial Glow"}
    func reset() {
        area=kind == .hub ? -1:0;glow=24;cleared=[];scanned=[];won=false;message="";lastSpot=nil;loops=0
        opened=kind == .hub || kind == .hunt ? [0,1,2]:[0]
    }
}
