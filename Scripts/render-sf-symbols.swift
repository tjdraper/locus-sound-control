#!/usr/bin/env swift
//
// Renders SF Symbols at menu bar size so a candidate icon can be judged before it is committed to.
//
// The curated set in the Decisions section of Plans/HighLevelPlan.md was chosen this way. Reading a
// symbol in SF Symbols.app at 200pt says nothing about whether it survives 18pt as a flat template:
// the hierarchical symbols in particular — homepod, the Beats ones — draw their main shape as a
// light grey stroke that flattens to something much fainter than its neighbours.
//
//   Scripts/render-sf-symbols.swift out.png headphones airpods.pro hifispeaker
//
// Each row is the name, the symbol at 72pt, and the symbol drawn at 18pt then blown up without
// smoothing, which is what the menu bar actually shows. An unavailable name is reported rather than
// skipped, since the spellings are easy to get wrong (`airpods.max` and `airpodsmax` are both real).

import AppKit

guard CommandLine.arguments.count > 2 else {
    print("usage: render-sf-symbols.swift <output.png> <symbol-name> [symbol-name ...]")
    exit(1)
}

let outputPath = CommandLine.arguments[1]
let names: [String] = Array(CommandLine.arguments.dropFirst(2))

let rowHeight: CGFloat = 130
let labelWidth: CGFloat = 360
let columnWidth: CGFloat = 130
let gap: CGFloat = 24
let menuBarPointSize: CGFloat = 15
let menuBarBox: CGFloat = 18

let width = labelWidth + columnWidth * 2 + gap * 4
let height = rowHeight * CGFloat(names.count) + gap

let nameAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 22, weight: .regular),
    .foregroundColor: NSColor.black,
]
let unavailableAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .regular),
    .foregroundColor: NSColor.systemRed,
]

/// Drawn into an 18pt box first, so the blow-up shows the pixels the menu bar would show.
func menuBarPixels(of symbol: NSImage) -> NSImage? {
    guard let sized = symbol.withSymbolConfiguration(
        .init(pointSize: menuBarPointSize, weight: .regular)
    ) else { return nil }

    let cell = NSImage(size: NSSize(width: menuBarBox, height: menuBarBox))
    cell.lockFocus()
    NSColor.black.set()
    sized.draw(in: NSRect(
        x: (menuBarBox - sized.size.width) / 2,
        y: (menuBarBox - sized.size.height) / 2,
        width: sized.size.width,
        height: sized.size.height
    ))
    cell.unlockFocus()
    return cell
}

let sheet = NSImage(size: NSSize(width: width, height: height))
sheet.lockFocus()
NSColor.white.setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

var missing: [String] = []

for (index, name) in names.enumerated() {
    let bottom = height - gap / 2 - rowHeight * CGFloat(index + 1)
    (name as NSString).draw(
        at: NSPoint(x: gap, y: bottom + rowHeight / 2 - 14),
        withAttributes: nameAttributes
    )

    guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil),
          let large = symbol.withSymbolConfiguration(.init(pointSize: 72, weight: .regular)),
          let pixels = menuBarPixels(of: symbol) else {
        missing.append(name)
        ("unavailable" as NSString).draw(
            at: NSPoint(x: labelWidth + gap * 2, y: bottom + rowHeight / 2 - 12),
            withAttributes: unavailableAttributes
        )
        continue
    }

    large.isTemplate = true
    NSColor.black.set()
    large.draw(in: NSRect(
        x: labelWidth + gap * 2,
        y: bottom + 20,
        width: large.size.width,
        height: large.size.height
    ))

    NSGraphicsContext.current?.imageInterpolation = .none
    pixels.draw(in: NSRect(x: labelWidth + columnWidth + gap * 3, y: bottom + 18, width: 90, height: 90))
    NSGraphicsContext.current?.imageInterpolation = .default
}

sheet.unlockFocus()

guard let tiff = sheet.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    print("error: could not encode the sheet")
    exit(1)
}

do {
    try png.write(to: URL(fileURLWithPath: outputPath))
} catch {
    print("error: \(error.localizedDescription)")
    exit(1)
}

print("wrote \(outputPath)")
if !missing.isEmpty {
    print("unavailable: \(missing.joined(separator: ", "))")
}
