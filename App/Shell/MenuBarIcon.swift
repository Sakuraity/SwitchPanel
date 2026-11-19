import AppKit
import SwiftUI

/// Concept A — stacked cards (from `media/icon-concepts/concept-a.svg`, 18×18 design space).
enum MenuBarIcon {
    static let canvasSize = NSSize(width: 20, height: 20)

    /// SVG viewBox width/height — geometry taken from concept-a.svg, not approximated.
    private static let designSize: CGFloat = 18
    private static var unit: CGFloat { canvasSize.width / designSize }

    // Back (unchecked) card — outline upper-right
    private static let backOrigin = CGPoint(x: 6.25, y: 2.25)
    private static let backSize = CGSize(width: 9.5, height: 9.5)
    private static let backRadius: CGFloat = 2.6
    private static let backStrokeWidth: CGFloat = 1.5

    // Front (checked) card — solid lower-left
    private static let frontOrigin = CGPoint(x: 1.5, y: 5.5)
    private static let frontSize = CGSize(width: 11, height: 11)
    private static let frontRadius: CGFloat = 3
    private static let checkStrokeWidth: CGFloat = 1.6

  private static let checkPointsSVG: [CGPoint] = [
        CGPoint(x: 4.45, y: 11.15),
        CGPoint(x: 6.35, y: 13.05),
        CGPoint(x: 9.65, y: 9.0),
    ]

    /// - Parameter emphasizeChecked: any stateful toggle on → emphasize front checked card; all off → emphasize back outline card.
    static func statusImage(emphasizeChecked: Bool) -> NSImage {
        let image = NSImage(size: canvasSize)
        image.lockFocus()
        defer { image.unlockFocus() }

        let backAlpha: CGFloat = emphasizeChecked ? 0.32 : 1
        let frontAlpha: CGFloat = emphasizeChecked ? 1 : 0.36

        let backRect = svgRect(origin: backOrigin, size: backSize)
        strokeRoundedRect(
            backRect,
            radius: backRadius * unit,
            lineWidth: backStrokeWidth * unit,
            alpha: backAlpha
        )

        let frontRect = svgRect(origin: frontOrigin, size: frontSize)
        drawFrontCheckedCard(
            rect: frontRect,
            radius: frontRadius * unit,
            fillAlpha: frontAlpha,
            checkLineWidth: checkStrokeWidth * unit
        )

        image.isTemplate = true
        return image
    }

    static var settingsImage: NSImage {
        statusImage(emphasizeChecked: false)
    }

    private static func svgRect(origin: CGPoint, size: CGSize) -> NSRect {
        let x = origin.x * unit
        let w = size.width * unit
        let h = size.height * unit
        let y = (designSize - origin.y - size.height) * unit
        return NSRect(x: x, y: y, width: w, height: h)
    }

    private static func svgPoint(_ point: CGPoint) -> NSPoint {
        NSPoint(x: point.x * unit, y: (designSize - point.y) * unit)
    }

    private static func strokeRoundedRect(_ rect: NSRect, radius: CGFloat, lineWidth: CGFloat, alpha: CGFloat) {
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        NSColor.black.withAlphaComponent(alpha).setStroke()
        path.stroke()
    }

    /// Solid front card, then knockout check (SVG mask `chk` → menu bar shows through the tick).
    private static func drawFrontCheckedCard(
        rect: NSRect,
        radius: CGFloat,
        fillAlpha: CGFloat,
        checkLineWidth: CGFloat
    ) {
        let fillPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        NSColor.black.withAlphaComponent(fillAlpha).setFill()
        fillPath.fill()

        guard checkPointsSVG.count >= 3, let context = NSGraphicsContext.current else { return }
        let checkPath = NSBezierPath()
        checkPath.move(to: svgPoint(checkPointsSVG[0]))
        for point in checkPointsSVG.dropFirst() {
            checkPath.line(to: svgPoint(point))
        }
        checkPath.lineWidth = checkLineWidth
        checkPath.lineCapStyle = .round
        checkPath.lineJoinStyle = .round

        context.saveGraphicsState()
        context.cgContext.setBlendMode(.destinationOut)
        NSColor.white.setStroke()
        checkPath.stroke()
        context.restoreGraphicsState()
    }
}