import AppKit
import SwiftUI

struct CatMascotView: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = fufuImage {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.48, weight: .bold))
                    .foregroundStyle(PastePawTheme.coffee)
                    .frame(width: size, height: size)
            }
        }
        .shadow(color: PastePawTheme.coffee.opacity(0.18), radius: size * 0.05, y: size * 0.025)
        .accessibilityLabel("FuFu")
    }

    private var fufuImage: NSImage? {
        let candidates = [
            Bundle.main.resourceURL?
                .appendingPathComponent("PastePaw_PastePaw.bundle")
                .appendingPathComponent("fufu-idle.png"),
            Bundle.main.bundleURL
                .appendingPathComponent("PastePaw_PastePaw.bundle")
                .appendingPathComponent("fufu-idle.png")
        ].compactMap { $0 }

        for url in candidates {
            if let image = NSImage(contentsOf: url) {
                return image
            }
        }

        return nil
    }
}
