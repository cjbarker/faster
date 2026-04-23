import SwiftUI

enum AppFont {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let timer = Font.system(size: 52, weight: .semibold, design: .rounded).monospacedDigit()
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
}
