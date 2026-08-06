import SwiftUI

enum AppColor {
    static let ink = Color(red: 0.16, green: 0.14, blue: 0.13)
    static let muted = Color(red: 0.42, green: 0.39, blue: 0.36)
    static let paper = Color(red: 0.96, green: 0.93, blue: 0.88)
    static let warmWhite = Color(red: 1.00, green: 0.98, blue: 0.95)
    static let terracotta = Color(red: 0.62, green: 0.34, blue: 0.25)
    static let terracottaSoft = Color(red: 0.92, green: 0.84, blue: 0.78)
    static let teal = Color(red: 0.14, green: 0.36, blue: 0.35)
    static let tealSoft = Color(red: 0.84, green: 0.91, blue: 0.89)
    static let divider = Color(red: 0.70, green: 0.65, blue: 0.61)

    static func background(style: Int, colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color(red: 0.10, green: 0.09, blue: 0.08)
        }
        switch style {
        case 1:
            return Color(red: 0.93, green: 0.95, blue: 0.93)
        case 2:
            return Color(red: 0.93, green: 0.94, blue: 0.97)
        default:
            return paper
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 16)
            .foregroundStyle(.white)
            .background(
                isEnabled ? AppColor.terracotta : AppColor.muted,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 16)
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppColor.divider, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                AppColor.warmWhite,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(AppColor.divider.opacity(0.8), lineWidth: 1)
            }
            .foregroundStyle(AppColor.ink)
    }
}

extension View {
    func appCard() -> some View {
        modifier(CardModifier())
    }

    func minimumAccessibleTarget() -> some View {
        frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}
