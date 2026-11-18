// Renders Assets/AppIcon.icns from Assets/AppIcon.svg. Run from the Portside folder: swift scripts/make-icon.swift
import AppKit
import WebKit

// WebKit draws the SVG because it supports the blur filters the artwork uses.
@MainActor
func renderArtwork(_ svg: URL) async throws -> NSImage {
    let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1024, height: 1024))
    webView.setValue(false, forKey: "drawsBackground")
    webView.loadFileURL(svg, allowingReadAccessTo: svg.deletingLastPathComponent())
    while webView.isLoading {
        try await Task.sleep(for: .milliseconds(50))
    }
    let config = WKSnapshotConfiguration()
    config.rect = webView.bounds
    return try await webView.takeSnapshot(configuration: config)
}

func png(_ artwork: NSImage, pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    context.imageInterpolation = .high
    NSGraphicsContext.current = context
    artwork.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let svg = URL(fileURLWithPath: "Assets/AppIcon.svg").absoluteURL
let artwork = try await renderArtwork(svg)

let iconset = fm.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? fm.removeItem(at: iconset)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    try png(artwork, pixels: points).write(to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    try png(artwork, pixels: points * 2).write(to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", "Assets/AppIcon.icns"]
try iconutil.run()
iconutil.waitUntilExit()
try? fm.removeItem(at: iconset)
exit(iconutil.terminationStatus)
