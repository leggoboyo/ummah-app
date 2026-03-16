import AppKit
import Foundation

struct AssetPaths {
    let iconDir: String
    let launchDir: String
}

struct GenerateIosBrandAssets {
    static func run() throws {
        let root = FileManager.default.currentDirectoryPath
        let paths = AssetPaths(
            iconDir: "\(root)/mobile/app/ios/Runner/Assets.xcassets/AppIcon.appiconset",
            launchDir: "\(root)/mobile/app/ios/Runner/Assets.xcassets/LaunchImage.imageset",
        )

        try generateAppIcons(paths: paths)
        try generateLaunchImages(paths: paths)
        print("Generated iOS brand assets.")
    }

    static func generateAppIcons(paths: AssetPaths) throws {
        let master = drawImage(size: NSSize(width: 1024, height: 1024)) { rect in
            let background = NSColor(calibratedRed: 0.06, green: 0.43, blue: 0.35, alpha: 1)
            background.setFill()
            rect.fill()

            let insetRect = rect.insetBy(dx: 96, dy: 96)
            let borderPath = NSBezierPath(roundedRect: insetRect, xRadius: 180, yRadius: 180)
            NSColor(calibratedWhite: 1, alpha: 0.10).setStroke()
            borderPath.lineWidth = 10
            borderPath.stroke()

            let letterParagraph = NSMutableParagraphStyle()
            letterParagraph.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 540, weight: .bold),
                .foregroundColor: NSColor(calibratedRed: 0.97, green: 0.95, blue: 0.90, alpha: 1),
                .paragraphStyle: letterParagraph,
            ]
            let letter = NSAttributedString(string: "U", attributes: attributes)
            let letterRect = NSRect(x: 0, y: 250, width: rect.width, height: 420)
            letter.draw(in: letterRect)

            let accentPath = NSBezierPath()
            accentPath.move(to: NSPoint(x: rect.midX - 130, y: 765))
            accentPath.line(to: NSPoint(x: rect.midX + 130, y: 765))
            NSColor(calibratedRed: 0.85, green: 0.74, blue: 0.44, alpha: 1).setStroke()
            accentPath.lineWidth = 18
            accentPath.lineCapStyle = .round
            accentPath.stroke()
        }

        let iconSizes: [String: CGFloat] = [
            "Icon-App-20x20@1x.png": 20,
            "Icon-App-20x20@2x.png": 40,
            "Icon-App-20x20@3x.png": 60,
            "Icon-App-29x29@1x.png": 29,
            "Icon-App-29x29@2x.png": 58,
            "Icon-App-29x29@3x.png": 87,
            "Icon-App-40x40@1x.png": 40,
            "Icon-App-40x40@2x.png": 80,
            "Icon-App-40x40@3x.png": 120,
            "Icon-App-60x60@2x.png": 120,
            "Icon-App-60x60@3x.png": 180,
            "Icon-App-76x76@1x.png": 76,
            "Icon-App-76x76@2x.png": 152,
            "Icon-App-83.5x83.5@2x.png": 167,
            "Icon-App-1024x1024@1x.png": 1024,
        ]

        for (filename, dimension) in iconSizes {
            let resized = resize(image: master, size: NSSize(width: dimension, height: dimension))
            try savePng(resized, to: "\(paths.iconDir)/\(filename)")
        }
    }

    static func generateLaunchImages(paths: AssetPaths) throws {
        let launchSizes: [String: NSSize] = [
            "LaunchImage.png": NSSize(width: 168, height: 185),
            "LaunchImage@2x.png": NSSize(width: 336, height: 370),
            "LaunchImage@3x.png": NSSize(width: 504, height: 555),
        ]

        for (filename, size) in launchSizes {
            let pixelWidth = Int(size.width.rounded())
            let pixelHeight = Int(size.height.rounded())
            let image = drawImage(size: size) { rect in
                NSColor.clear.setFill()
                rect.fill()

                let iconSide = min(rect.width * 0.56, rect.height * 0.50)
                let iconRect = NSRect(
                    x: (rect.width - iconSide) / 2,
                    y: rect.height * 0.36,
                    width: iconSide,
                    height: iconSide,
                )

                let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: iconSide * 0.24, yRadius: iconSide * 0.24)
                NSColor(calibratedRed: 0.06, green: 0.43, blue: 0.35, alpha: 1).setFill()
                iconPath.fill()

                let letterParagraph = NSMutableParagraphStyle()
                letterParagraph.alignment = .center
                let letterAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: iconSide * 0.56, weight: .bold),
                    .foregroundColor: NSColor(calibratedRed: 0.97, green: 0.95, blue: 0.90, alpha: 1),
                    .paragraphStyle: letterParagraph,
                ]
                let letter = NSAttributedString(string: "U", attributes: letterAttributes)
                let letterRect = NSRect(
                    x: iconRect.minX,
                    y: iconRect.minY + iconSide * 0.20,
                    width: iconRect.width,
                    height: iconSide * 0.50,
                )
                letter.draw(in: letterRect)

                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: rect.width * 0.115, weight: .semibold),
                    .foregroundColor: NSColor(calibratedRed: 0.14, green: 0.19, blue: 0.17, alpha: 1),
                    .paragraphStyle: letterParagraph,
                ]
                let title = NSAttributedString(string: "Ummah App", attributes: titleAttributes)
                let titleRect = NSRect(
                    x: 0,
                    y: rect.height * 0.14,
                    width: rect.width,
                    height: rect.height * 0.12,
                )
                title.draw(in: titleRect)
            }
            let outputPath = "\(paths.launchDir)/\(filename)"
            try savePng(image, to: outputPath)
            try resamplePngInPlace(
                outputPath,
                width: pixelWidth,
                height: pixelHeight,
            )
        }
    }

    static func drawImage(size: NSSize, drawing: (NSRect) -> Void) -> NSImage {
        let pixelsWide = Int(size.width.rounded())
        let pixelsHigh = Int(size.height.rounded())
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelsWide,
            pixelsHigh: pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            fatalError("Failed to create bitmap rep")
        }

        bitmap.size = size

        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            fatalError("Failed to create graphics context")
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        drawing(NSRect(origin: .zero, size: size))
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: size)
        image.addRepresentation(bitmap)
        return image
    }

    static func resize(image: NSImage, size: NSSize) -> NSImage {
        drawImage(size: size) { rect in
            image.draw(in: rect)
        }
    }

    static func savePng(_ image: NSImage, to path: String) throws {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw NSError(domain: "GenerateIosBrandAssets", code: 1)
        }

        try pngData.write(to: URL(fileURLWithPath: path))
    }

    static func resamplePngInPlace(
        _ path: String,
        width: Int,
        height: Int,
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        process.arguments = [
            "-z",
            "\(height)",
            "\(width)",
            path,
            "--out",
            path,
        ]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw NSError(domain: "GenerateIosBrandAssets", code: 2)
        }
    }
}

try GenerateIosBrandAssets.run()
