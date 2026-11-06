import SwiftUI

struct ReefSaveView: View {
    @Environment(ReefStore.self) private var store
    @Environment(ReefPurchases.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        OceanScene {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        SectionHeading(title: "Saved reef")
                        Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                            .buttonStyle(ReefButtonStyle(kind: .orb)).accessibilityLabel("Close saved reef")
                    }
                    OceanMembrane {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(store.lastSaveFailed ? "Save needs attention" : "Saved on this device", systemImage: store.lastSaveFailed ? "exclamationmark.circle" : "checkmark.circle")
                                .reefFont(.headline).foregroundStyle(ReefTheme.gold)
                            if let saved = store.progress.savedAt {
                                Text(saved, format: .dateTime.month().day().hour().minute()).reefFont(.caption).foregroundStyle(ReefTheme.muted)
                            }
                            Text("Your coral pattern, taps, hints, Glow, shots, and treasure trail save as you play. From Home, choose Bloom, then start from the prefilled level to resume your current board.")
                                .reefFont(.subheadline)
                            Button("Save again") { store.checkpoint() }.buttonStyle(ReefButtonStyle(kind: .quiet))
                        }
                    }
                    HStack {
                        Label("\(store.puzzle.level)", systemImage: "camera.macro")
                        Spacer()
                        Text("\(store.progress.completedBloomLevels.count) / 100 bloomed")
                    }.reefFont(.subheadline)
                    HStack {
                        Label("Treasure trail", systemImage: "water.waves")
                        Spacer()
                        Text("\(store.progress.firstReef.treasures.count) / 2 treasures")
                    }.reefFont(.subheadline)
                    ReefIconLabel("\(store.progress.hints) hints", .hint)
                        .reefFont(.subheadline)
                    TideDivider()
                    Text("Across your devices").reefFont(.title3, weight: .medium)
                    Text("iCloud sync isn't enabled yet. Your iPhone simulator and Mac preview each keep their own reef. Deleting the app can remove its local save.")
                        .reefFont(.subheadline).foregroundStyle(ReefTheme.muted)
                    TideDivider()
                    Text("Purchases & power-ups").reefFont(.title3, weight: .medium)
                    Text("Purchase and ad buttons are free previews. Unused hints stay in your collection. Added taps stay with the current patch, including after you close the app.")
                        .reefFont(.subheadline).foregroundStyle(ReefTheme.muted)
                    Button {
                        Task { await purchases.restore(store: store) }
                    } label: {
                        Text(purchases.isRestoring ? "Restoring…" : "Restore purchases").frame(maxWidth: .infinity)
                    }.buttonStyle(ReefButtonStyle()).disabled(purchases.isRestoring)
                    if let message = purchases.message {
                        Text(message).reefFont(.subheadline).foregroundStyle(ReefTheme.gold)
                    }
                }.padding(24).frame(maxWidth: 520)
            }.scrollIndicators(.hidden).foregroundStyle(ReefTheme.ink).fontDesign(.rounded)
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 700)
        #endif
    }
}
