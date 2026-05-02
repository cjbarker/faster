import SwiftUI

enum AppFont {
    static let display    = Font.system(size: 48, weight: .bold,     design: .rounded)
    static let largeTitle = Font.system(size: 34, weight: .bold,     design: .rounded)
    static let title      = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3     = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline   = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let callout    = Font.system(size: 15, weight: .medium,   design: .rounded)
    static let body       = Font.system(size: 16, weight: .regular,  design: .default)
    static let timer      = Font.system(size: 54, weight: .semibold, design: .rounded).monospacedDigit()
    static let caption    = Font.system(size: 12, weight: .regular,  design: .default)
    static let caption2   = Font.system(size: 11, weight: .medium,   design: .rounded)
}
