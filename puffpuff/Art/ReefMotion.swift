import SwiftUI

// Adapted from rossark0/rossark-motion-skill, templates/swiftui/Motion.swift.
// MIT license and attribution are included in THIRD_PARTY_NOTICES.txt.
// One clock supplies every animated part. Added scene/visibility pausing and a
// cancellable completion task so a finished one-shot stops requesting frames.
enum ReefMotion {
    struct Key {
        let time: Double
        let value: Double
        var arriving = false
        init(_ time: Double, _ value: Double, arriving: Bool = false) {
            self.time = time; self.value = value; self.arriving = arriving
        }
    }

    static let travel = UnitCurve.bezier(startControlPoint: .init(x: 0.77, y: 0), endControlPoint: .init(x: 0.175, y: 1))
    static let arrive = UnitCurve.bezier(startControlPoint: .init(x: 0.23, y: 1), endControlPoint: .init(x: 0.32, y: 1))
    static let response = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.22)

    static func wave(_ t: Double, period: Double, phase: Double = 0) -> Double {
        sin((t / period + phase) * .pi * 2)
    }

    static func track(_ t: Double, _ keys: [Key]) -> Double {
        guard let first = keys.first else { return 0 }
        if t <= first.time { return first.value }
        for i in 1..<keys.count where t <= keys[i].time {
            let a = keys[i - 1], b = keys[i]
            let fraction = min(1, max(0, (t - a.time) / max(1, b.time - a.time)))
            let ease = (b.arriving ? arrive : travel).value(at: fraction)
            return a.value + (b.value - a.value) * ease
        }
        return keys.last!.value
    }

    static func segment(_ t: Double, from: Double, to: Double) -> Double {
        arrive.value(at: min(1, max(0, (t - from) / (to - from))))
    }
}

private struct ReefPausedKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var reefPaused: Bool {
        get { self[ReefPausedKey.self] }
        set { self[ReefPausedKey.self] = newValue }
    }
}

struct ReefClock<Content: View>: View {
    var period: Double = 8000
    var duration: Double? = nil
    var paused = false
    var frameInterval = 1.0 / 60
    @ViewBuilder var content: (Double) -> Content
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.reefPaused) private var reefPaused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var finished = false
    @State private var elapsed = 0.0
    @State private var began = Date()

    private var running: Bool { appeared && !paused && !reefPaused && !reduceMotion && scenePhase == .active && !finished }

    var body: some View {
        TimelineView(.animation(minimumInterval: frameInterval, paused: !running)) { context in
            let raw = elapsed + (running ? context.date.timeIntervalSince(began) * 1000 : 0)
            let time = reduceMotion ? (duration ?? 0) : duration.map { min($0, raw) } ?? raw.truncatingRemainder(dividingBy: period)
            content(time)
        }
        .onAppear { began = Date(); appeared = true }
        .onDisappear { appeared = false }
        .onChange(of: running) { wasRunning, isRunning in
            if wasRunning { elapsed += Date().timeIntervalSince(began) * 1000 }
            if isRunning { began = Date() }
        }
        .task(id: running) {
            guard running, let duration else { return }
            do {
                try await Task.sleep(for: .milliseconds(max(0, duration - elapsed)))
                guard !Task.isCancelled else { return }
                finished = true
            } catch { /* Visibility and scene changes cancel this completion task. */ }
        }
    }
}

enum PipChoreography {
    // All idle periods divide 8 seconds, so the loop's pose AND velocity match.
    static let period = 8000.0
    static let breathPeriod = 4000.0
    static let finPeriod = 2000.0
    static let floatAmount = 1.8
    static let tailDegrees = 5.0
    static let tailDelay = 110.0
    static let blink: [ReefMotion.Key] = [
        .init(0, 0), .init(2900, 0), .init(3010, 1), .init(3050, 1),
        .init(3240, 0, arriving: true), .init(6600, 0), .init(6710, 1),
        .init(6750, 1), .init(6940, 0, arriving: true), .init(8000, 0)
    ]
    static let look: [ReefMotion.Key] = [
        .init(0, 2), .init(2300, 2), .init(2850, -3), .init(4400, -3),
        .init(5000, 2), .init(8000, 2)
    ]
    static let puff: [ReefMotion.Key] = [
        .init(0, 0), .init(240, 1), .init(360, 1), .init(850, 0, arriving: true), .init(2200, 0)
    ]
}
