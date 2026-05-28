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
        guard let url = Bundle.module.url(forResource: "fufu-idle", withExtension: "png") else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}
