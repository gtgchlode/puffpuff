import SwiftUI

@main
struct PuffPuffApp: App {
    @State private var store = ReefStore()
    @State private var purchases = ReefPurchases()
    var body: some Scene {
        WindowGroup {
            ReefRootView().environment(store).environment(purchases)
                #if os(macOS)
                .frame(minWidth: 420, idealWidth: 480, maxWidth: 700, minHeight: 740, idealHeight: 900)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 480, height: 900)
        .windowResizability(.contentSize)
        #endif
    }
}

struct ReefRootView: View {
    @Environment(ReefStore.self) private var store
    @Environment(ReefPurchases.self) private var purchases
    @Environment(\.scenePhase) private var scenePhase
    @State private var overlayVisible = false
    @State private var showSave = false
    @State private var showSettings = false
    @State private var openedTrail = false
    @State private var homeVisit = 0
    @State private var showPause = false
    @State private var discovery:ReefDiscovery?
    @AppStorage("puffpuff.appearance") private var appearance = ReefAppearance.lagoon
    @State private var discoveryItems: [ReefDiscovery] = []
    var body: some View {
        OceanScene(paused: overlayVisible || showSave || showSettings || showPause || discovery != nil) {
          if store.isSaveBlocked {
            VStack(spacing: 20) {
                Text("Your reef is safe").reefFont(.title2)
                Text("We couldn't open your save. Your existing files are kept, and a new game won't replace them.").multilineTextAlignment(.center)
                Button("Try loading again") { store.reloadSavedProgress() }.buttonStyle(ReefButtonStyle(filled: true))
            }.padding(30)
          } else if !store.progress.hasSeenTrailIntro {
            ReefIntroView(kind: .trail) { store.finishIntro(.trail) }
          } else {
            ZStack {
                gameplay
                    .allowsHitTesting(!showPause)
                    .accessibilityHidden(showPause)
                    .blur(radius: showPause ? 8 : 0)
                    .opacity(showPause ? 0.15 : 1)
                if showPause {
                    ReefPauseView(onResume: { showPause = false }, onHome: goHome,
                                  onSave: { showSave = true }, onSettings: { showSettings = true })
                }
            }.environment(\.reefPaused, showPause || showSave || showSettings || overlayVisible || discovery != nil)
          }
        }
        .foregroundStyle(ReefTheme.ink)
        .reefFont(size: 15)
        .task {
            if !openedTrail { openedTrail = true; store.navigate(to: .trail) }
            await purchases.observe(store: store)
        }
        .onChange(of:store.discoveryReceipt?.id) { _,_ in
            if let receipt=store.discoveryReceipt,receipt.source == .bonus {presentDiscovery(receipt.id)}
        }
        .sheet(item:$discovery,onDismiss:{discoveryItems=[]}) {item in
            ReefDiscoverySheet(item:item) {
                if store.acknowledgeDiscovery(item) {
                    discoveryItems.removeAll{$0==item}
                    discovery=discoveryItems.first
                }
            }.presentationDetents([.medium]).presentationBackground(.clear)
        }
        .onChange(of:store.progress.activeScreen) { _,_ in cancelDiscovery() }
        .onChange(of:store.puzzle.level) { _,_ in cancelDiscovery() }
        .onChange(of:showPause || showSettings || showSave || overlayVisible) { _,covered in
            if covered {cancelDiscovery()}
        }
        .onChange(of: store.progress.lifeGiftSeed) { _, _ in
            homeVisit += 1
            cancelDiscovery()
            overlayVisible = false
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.reloadSavedProgress() }
            else { cancelDiscovery(); if phase == .background { store.checkpoint() } }
        }
        .sheet(isPresented: $showSave) {
            ReefSaveView().environment(store).environment(purchases)
                .presentationDetents([.large]).presentationBackground(.clear)
        }
        .sheet(isPresented: $showSettings) {
            ReefSettingsView(appearance: $appearance).environment(store)
                .presentationDetents([.large]).presentationBackground(.clear)
        }
        .alert("Reef", isPresented: Binding(get: { store.notice != nil }, set: { if !$0 { store.notice = nil } })) {
            Button("Okay") { store.notice = nil }
        } message: { Text(store.notice ?? "") }
        .environment(\.presentReefDiscovery, presentDiscovery)
        .environment(\.colorScheme, appearance.colorScheme)
        .preferredColorScheme(appearance.colorScheme)
    }

    private func presentDiscovery(_ receiptID: UUID) {
        guard store.progress.hasSeenTrailIntro,scenePhase == .active,!overlayVisible,!showSave,!showSettings,!showPause,
              discovery == nil,!store.isSaveBlocked,let receipt=store.discoveryReceipt,
              receipt.id==receiptID else{return}
        switch receipt.source {
        case .bloom(let level): guard store.progress.activeScreen == .bloom,store.puzzle.level==level,store.isComplete else{return}
        case .trail,.bonus: guard store.progress.activeScreen == .trail else{return}
        }
        discoveryItems=store.discoveryItems(for:receiptID)
        store.cancelDiscoveryReceipt()
        discovery=discoveryItems.first
    }
    private func cancelDiscovery() {
        store.cancelDiscoveryReceipt()
        discoveryItems=[]
        discovery=nil
    }

    private func goHome() {
        store.checkpoint()
        showPause = false
        overlayVisible = false
        store.navigate(to: .trail)
        homeVisit += 1
    }

    private var gameplay: some View {
        VStack(spacing: 0) {
            if store.lastSaveFailed {
                Button { showSave = true } label: {
                    Label("Save needs attention", systemImage: "exclamationmark.circle")
                        .reefFont(size: 12).foregroundStyle(ReefTheme.gold)
                }.buttonStyle(ReefButtonStyle(kind: .quiet))
            }
            if store.progress.activeScreen == .bloom {
                BloomView(onHome: goHome, onPause: pauseGame, onOverlay: { overlayVisible = $0 })
            } else {
                ReefTrailView(onHome: goHome, onBloom: { _ = store.startFromLevel(min(store.puzzle.level, ReefStore.levelLimit)) }, onPause: pauseGame, onOverlay: { overlayVisible = $0 }).id(homeVisit)
            }
        }.frame(maxWidth: 560)
    }

    private func pauseGame() {
        store.checkpoint()
        showPause = true
    }
}

private struct ReefPauseView: View {
    let onResume: () -> Void
    let onHome: () -> Void
    let onSave: () -> Void
    let onSettings: () -> Void
    @Environment(ReefStore.self) private var store
    var body: some View {
        VStack(spacing: 22) {
            PipView(paused: true, happy: true).frame(width: 150, height: 127)
            Text("puffpuff").reefFont(size: 32, weight: .semibold, display: true)
            HStack(spacing: 24) {
                ResourceOrb(kind: .glow, count: store.progress.glow, label: "Glow")
                ResourceOrb(kind: .shot, count: store.progress.shots, label: "shots")
            }
            ReefChestButton(labelled:true)
            Button("Resume", action: onResume).buttonStyle(ReefButtonStyle(filled: true))
            Button { onHome() } label: { Label("Home", systemImage: "house.fill") }
                .buttonStyle(ReefButtonStyle())
            HStack(spacing: 24) {
                Button(action: onSave) { Image(systemName: "checkmark.seal") }.accessibilityLabel("Saved reef")
                Button(action: onSettings) { Label("Settings", systemImage: "gearshape") }
            }.buttonStyle(ReefButtonStyle(kind: .quiet))
        }.frame(maxWidth: 320).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Temporary debug navigation lives in Settings; Trail is the real home screen.
struct ReefBloomStartOptions: View {
    @Environment(ReefStore.self) private var store
    let onStart: () -> Void
    @State private var levelText = ""
    @State private var expanded = false
    private var chosenLevel: Int? {
        guard let level = Int(levelText), (1...ReefStore.levelLimit).contains(level) else { return nil }
        return level
    }
    var body: some View {
        VStack(spacing: 12) {
            Button("Debug levels") { expanded.toggle(); levelText = String(min(store.puzzle.level, ReefStore.levelLimit)) }
                .buttonStyle(ReefButtonStyle(kind: .quiet))
            if expanded {
                Button("Start from beginning") { if store.startFromBeginning() { onStart() } }
                    .buttonStyle(ReefButtonStyle())
                HStack {
                    TextField("1–\(ReefStore.levelLimit)", text: $levelText).textFieldStyle(.plain)
                        .multilineTextAlignment(.center).frame(width: 60, height: 44)
                        .background(MembraneSurface(tint: ReefTheme.honey, round: true))
                        .accessibilityLabel("Starting Bloom level")
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    Button("Start from level") {
                        if let level = chosenLevel, store.startFromLevel(level) { onStart() }
                    }.buttonStyle(ReefButtonStyle(filled: true)).disabled(chosenLevel == nil)
                }
                if chosenLevel == nil { Text("Choose 1–\(ReefStore.levelLimit)").reefFont(size: 12) }
                if store.latestBloomLevel != store.puzzle.level {
                    Text("Saved level \(store.latestBloomLevel)").reefFont(size: 12)
                }
            }
        }
    }
}
