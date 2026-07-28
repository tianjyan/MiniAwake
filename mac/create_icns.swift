import Cocoa

let src = CommandLine.arguments[1]
let out = CommandLine.arguments[2]  // .iconset directory

guard let image = NSImage(contentsOfFile: src) else {
    print("Failed to load \(src)")
    exit(1)
}

let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

for (size, name) in sizes {
    let nsSize = NSSize(width: size, height: size)
    let img = NSImage(size: nsSize)
    img.lockFocus()
    image.draw(in: NSRect(origin: .zero, size: nsSize),
               from: .zero, operation: .sourceOver, fraction: 1.0)
    img.unlockFocus()

    guard let tiff = img.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else { continue }

    try png.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
}
