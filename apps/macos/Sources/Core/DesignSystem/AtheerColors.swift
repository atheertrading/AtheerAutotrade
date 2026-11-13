import SwiftUI

/// Centralized visual tokens for the AtheerAutotrade macOS interface.
enum AtheerColors {
    // MARK: - Backgrounds and surfaces

    static let canvas = Color(red: 0.055, green: 0.071, blue: 0.094)
    static let sidebar = Color(red: 0.071, green: 0.086, blue: 0.110)
    static let surface = Color(red: 0.090, green: 0.110, blue: 0.137)
    static let elevated = Color(red: 0.114, green: 0.137, blue: 0.169)
    static let surfaceHighlight = Color(red: 0.145, green: 0.173, blue: 0.208)

    // MARK: - Borders

    static let border = Color.white.opacity(0.08)
    static let borderStrong = Color.white.opacity(0.13)

    // MARK: - Typography

    static let textPrimary = Color(red: 0.91, green: 0.93, blue: 0.96)
    static let textSecondary = Color(red: 0.55, green: 0.60, blue: 0.67)
    static let textTertiary = Color(red: 0.40, green: 0.46, blue: 0.54)

    // MARK: - Semantic trading colors

    static let accent = Color(red: 0.31, green: 0.78, blue: 0.71)
    static let accentMuted = accent.opacity(0.12)
    static let info = Color(red: 0.36, green: 0.68, blue: 0.95)
    static let positive = Color(red: 0.25, green: 0.76, blue: 0.49)
    static let negative = Color(red: 0.88, green: 0.31, blue: 0.34)
    static let warning = Color(red: 0.91, green: 0.68, blue: 0.36)
    static let unavailable = warning
}

/// Consistent spacing scale, measured in points.
enum AtheerSpacing {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
}

/// Consistent corner radii for cards and controls.
enum AtheerRadius {
    static let small: CGFloat = 7
    static let medium: CGFloat = 10
    static let large: CGFloat = 14
}
