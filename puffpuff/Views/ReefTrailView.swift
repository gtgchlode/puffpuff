import SwiftUI

struct ReefTrailView: View {
    let onHome: () -> Void
    let onBloom: () -> Void
    let onPause: () -> Void
    var onOverlay: (Bool) -> Void = { _ in }

    var body: some View {
        ReefStopView(onHome: onHome, onBloom: onBloom, onPause: onPause, onOverlay: onOverlay)
            .onAppear { onOverlay(false) }
    }
}
