import SwiftUI
import AppKit

/// Uses the exact official Affinity contours already imported in PipPaths.swift.
/// Compile this file with Art/PipPaths.swift; no gameplay/store code is involved.
private struct PuffPuffIcon: View {
    let mac: Bool
    var body: some View {
        Canvas { context, size in
            let full = CGRect(origin: .zero, size: size)
            let inset = mac ? size.width * 0.078125 : 0
            let tile = full.insetBy(dx: inset, dy: inset)
            let outline = mac ? Path(roundedRect: tile, cornerRadius: tile.width * 0.22) : Path(tile)
            if mac {
                var shadow = context
                shadow.addFilter(.shadow(color: .black.opacity(0.18), radius: size.width * 0.012, y: size.width * 0.014))
                shadow.fill(outline, with: .color(rgb(0x448E91)))
            }
            context.clip(to: outline)
            context.translateBy(x: inset, y: inset)
            context.scaleBy(x: tile.width / 1024, y: tile.height / 1024)
            let square = Path(CGRect(x: 0, y: 0, width: 1024, height: 1024))
            context.fill(square, with: .linearGradient(Gradient(colors: [rgb(0x9BDCD1), rgb(0x60BAB4), rgb(0x287E8A)]),
                                                       startPoint: .zero, endPoint: CGPoint(x: 930, y: 1024)))
            context.fill(square, with: .radialGradient(Gradient(colors: [rgb(0xE4F8D8).opacity(0.42), .clear]),
                                                       center: CGPoint(x: 180, y: 70), startRadius: 30, endRadius: 690))
            var current = Path()
            current.move(to: CGPoint(x: -60, y: 830))
            current.addCurve(to: CGPoint(x: 1080, y: 710), control1: CGPoint(x: 320, y: 1040), control2: CGPoint(x: 660, y: 570))
            context.stroke(current, with: .color(rgb(0xB5E7D5).opacity(0.13)), style: .init(lineWidth: 16, lineCap: .round))
            for (x, y, radius) in [(115.0, 190.0, 20.0), (873, 167, 32), (926, 250, 13)] {
                let bubble = Path(ellipseIn: CGRect(x: x-radius, y: y-radius, width: radius*2, height: radius*2))
                context.fill(bubble, with: .color(rgb(0xD8F5E6).opacity(0.13)))
                context.stroke(bubble, with: .color(rgb(0xE2F8E8).opacity(0.52)), lineWidth: 5)
            }
            let parts = PipPaths.parts(inflation: 1).filter { $0.opacity > 0 }
            let bounds = parts.reduce(CGRect.null) { bounds, part in
                bounds.union(part.path.applying(part.transform).boundingRect.insetBy(dx: -part.width/2, dy: -part.width/2))
            }
            let scale = min(860 / bounds.width, 810 / bounds.height)
            var shadow = context
            shadow.addFilter(.blur(radius: 18))
            shadow.fill(Path(ellipseIn: CGRect(x: 278, y: 887, width: 468, height: 34)), with: .color(rgb(0x15545F).opacity(0.24)))
            context.translateBy(x: 512 - bounds.midX * scale, y: 507 - bounds.midY * scale)
            context.scaleBy(x: scale, y: scale)
            for part in parts {
                var layer = context
                layer.concatenate(part.transform)
                layer.opacity = part.opacity
                if let fill = part.fill { layer.fill(part.path, with: .color(rgb(fill))) }
                if let stroke = part.stroke {
                    layer.stroke(part.path, with: .color(rgb(stroke)), style: .init(lineWidth: part.width, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
    private func rgb(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 255)/255, green: Double((hex >> 8) & 255)/255, blue: Double(hex & 255)/255)
    }
}

@main struct ExportPuffPuffIcon {
    @MainActor static func main() throws {
        let project = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "outputs/puffpuff", isDirectory: true)
        let catalog = project.appendingPathComponent("puffpuff/Assets.xcassets")
        let icons = catalog.appendingPathComponent("AppIcon.appiconset")
        let design = project.appendingPathComponent("Design/AppIcon")
        try FileManager.default.createDirectory(at: icons, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: design, withIntermediateDirectories: true)
        var entries: [[String: String]] = []
        var rendered = Set<String>()
        func add(_ idiom: String, _ points: Double, _ scale: Int) throws {
            let pixels = Int(points * Double(scale)), mac = idiom == "mac"
            let filename = "AppIcon-\(mac ? "mac" : "ios")-\(pixels).png"
            let pointName = points == Double(Int(points)) ? String(Int(points)) : String(points)
            entries.append(["idiom":idiom, "size":"\(pointName)x\(pointName)", "scale":"\(scale)x", "filename":filename])
            if rendered.insert(filename).inserted { try export(pixels: pixels, mac: mac, to: icons.appendingPathComponent(filename)) }
        }
        for points in [20.0, 29, 40, 60] { for scale in [2, 3] { try add("iphone", points, scale) } }
        for points in [20.0, 29, 40, 76] { for scale in [1, 2] { try add("ipad", points, scale) } }
        try add("ipad", 83.5, 2)
        try add("ios-marketing", 1024, 1)
        for points in [16.0, 32, 128, 256, 512] { for scale in [1, 2] { try add("mac", points, scale) } }
        let info: [String: Any] = ["author":"xcode", "version":1]
        try JSONSerialization.data(withJSONObject: ["images":entries,"info":info], options: [.prettyPrinted,.sortedKeys])
            .write(to: icons.appendingPathComponent("Contents.json"))
        try JSONSerialization.data(withJSONObject: ["info":info], options: [.prettyPrinted,.sortedKeys])
            .write(to: catalog.appendingPathComponent("Contents.json"))
        try export(pixels: 1024, mac: false, to: design.appendingPathComponent("PuffPuff-App-Icon.png"))
        try export(pixels: 512, mac: true, to: design.appendingPathComponent("PuffPuff-Icon-Preview.png"))
        print("Rendered official puffed Puff Puff: \(entries.count) iPhone, iPad and Mac icon slots.")
    }
    @MainActor private static func export(pixels: Int, mac: Bool, to url: URL) throws {
        let renderer = ImageRenderer(content: PuffPuffIcon(mac: mac).frame(width: CGFloat(pixels), height: CGFloat(pixels)))
        renderer.scale = 1
        renderer.isOpaque = !mac
        guard let source = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
        // iOS/marketing assets have no alpha channel. macOS keeps its outer padding transparent.
        let bitmap: CGImage
        if mac { bitmap = source }
        else {
            let rgb = CGColorSpace(name: CGColorSpace.sRGB)!
            let context = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                                    space: rgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            context.draw(source, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
            bitmap = context.makeImage()!
        }
        let data = NSBitmapImageRep(cgImage: bitmap).representation(using: .png, properties: [:])!
        try data.write(to: url)
    }
}
