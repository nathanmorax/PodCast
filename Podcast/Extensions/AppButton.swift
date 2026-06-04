//
//  AppButton.swift
//  Podcast
//
//  Created by Satori Tech 341 on 12/05/26.
//
import SwiftUI

public struct AppButton: View {
    
    // MARK: - Style -
    
    /// Define cómo se ve el botón visualmente.
    public enum Style: String, CaseIterable {
        case filled       // con fondo sólido
        case outlined     // solo borde
        case plain        // sin fondo ni borde, solo texto
        case icon         // redondo, solo ícono (bookmark, download, etc.)
    }
    
    // MARK: - Size -
    
    /// Tamaño del botón.
    public enum Size: String, CaseIterable {
        
        case regular
        case compact
        
        var height: CGFloat {
            switch self {
            case .regular: return 48
            case .compact: return 42
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .regular: return 20
            case .compact: return 16
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .regular: return 2
            case .compact: return 1
            }
        }
        
        /// Tamaño del botón circular cuando style == .icon
        var iconButtonSize: CGFloat {
            switch self {
            case .regular: return 68
            case .compact: return 48
            }
        }
    }
    
    // MARK: - Tone -
    
    /// Semántica del color: comunica intención, no solo apariencia.
    public enum Tone: String, CaseIterable {
        
        case neutral
        case brand
        case critical
        case success
        case warning
        
        var palette: ButtonPalette {
            switch self {
            case .neutral:
                return ButtonPalette(
                    activeBackground: AppColor.Text.primary,
                    activeForeground: AppColor.Text.inverse,
                    inactiveBackground: AppColor.slateGray.opacity(0.15),
                    inactiveForeground: AppColor.Text.primary
                )
                
            case .brand:
                return ButtonPalette(
                    activeBackground: .yellow,
                    activeForeground: .yellow,
                    inactiveBackground: AppColor.slateGray,
                    inactiveForeground: .black
                )
                
            case .critical:
                return ButtonPalette(
                    activeBackground: AppColor.Status.critical,
                    activeForeground: AppColor.Text.inverse,
                    inactiveBackground: AppColor.Status.critical.opacity(0.15),
                    inactiveForeground: AppColor.Status.critical
                )
                
            case .success:
                return ButtonPalette(
                    activeBackground: AppColor.Status.success,
                    activeForeground: AppColor.Text.inverse,
                    inactiveBackground: AppColor.Status.success.opacity(0.15),
                    inactiveForeground: AppColor.Status.success
                )
                
            case .warning:
                return ButtonPalette(
                    activeBackground: AppColor.Status.warning,
                    activeForeground: AppColor.Text.inverse,
                    inactiveBackground: AppColor.Status.warning.opacity(0.15),
                    inactiveForeground: AppColor.Status.warning
                )
            }
        }
    }
    
    // MARK: - Palette -
    
    /// Define los pares de colores para los estados activo e inactivo del botón.
    public struct ButtonPalette {
        let activeBackground: Color
        let activeForeground: Color
        let inactiveBackground: Color
        let inactiveForeground: Color
    }
    
    // MARK: - Icon Placement -
    
    /// Posición del ícono dentro del botón.
    public enum IconPlacement {
        case leading(Image)
        case trailing(Image)
        case only(Image)                                       // ícono estático en botón circular
        case toggle(selected: Image, unselected: Image)        // ícono cambia según isSelected
    }
    
    // MARK: - Properties -
    
    private let style: Style
    private let tone: Tone
    private let size: Size
    private let icon: IconPlacement?
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void
    
    // MARK: - Init -
    
    public init(style: Style = .filled,
                tone: Tone = .neutral,
                size: Size = .regular,
                icon: IconPlacement? = nil,
                title: String,
                isSelected: Bool = false,
                action: @escaping () -> Void) {
        
        self.style = style
        self.tone = tone
        self.size = size
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }
    
    // MARK: - Body -
    
    public var body: some View {
        Button(action: action) {
            buttonForStyle
        }
    }
    
    @ViewBuilder
    private var buttonForStyle: some View {
        switch style {
        case .filled:
            filledButton
        case .outlined:
            outlinedButton
        case .plain:
            plainButton
        case .icon:
            iconButton
        }
    }
    
    // MARK: - Button Styles -
    
    private var filledButton: some View {
        buttonContent
            .foregroundColor(tone.palette.activeForeground)
            .frame(height: size.height)
            .filledBackground(tone.palette.activeBackground)
    }
    
    private var outlinedButton: some View {
        buttonContent
            .foregroundColor(tone.palette.activeBackground)
            .frame(height: size.height)
            .outlinedBorder(tone.palette.activeBackground, width: size.borderWidth)
    }
    
    private var plainButton: some View {
        buttonContent
            .foregroundColor(tone.palette.activeBackground)
            .frame(height: size.height)
            .contentShape(Rectangle())
    }
    
    private var iconButton: some View {
        Group {
            if let iconImage = currentIconImage {
                iconImage
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.iconSize, height: size.iconSize)
                    .foregroundColor(iconForegroundColor)
            }
        }
        .frame(width: size.iconButtonSize, height: size.iconButtonSize)
        .background(Circle().fill(iconBackgroundColor))
    }
    
    // MARK: - Icon Resolution Helpers -
    
    private var currentIconImage: Image? {
        guard let icon = icon else { return nil }
        switch icon {
        case .only(let image):
            return image
        case .toggle(let selected, let unselected):
            return isSelected ? selected : unselected
        case .leading, .trailing:
            return nil
        }
    }
    
    private var iconBackgroundColor: Color {
        isSelected ? tone.palette.activeBackground : tone.palette.inactiveBackground
    }
    
    private var iconForegroundColor: Color {
        isSelected ? tone.palette.activeForeground : tone.palette.inactiveForeground
    }
    
    // MARK: - Content -
    
    private var buttonContent: some View {
        HStack(spacing: 16) {
            if case .leading(let image) = icon {
                iconView(for: image)
            }
            
            Text(title)
                .applyFontStyle(for: size)
            
            if case .trailing(let image) = icon {
                iconView(for: image)
            }
        }
    }
    
    private func iconView(for image: Image) -> some View {
        image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.iconSize, height: size.iconSize)
    }
}

// MARK: - View Extensions -

private extension View {
    
    @ViewBuilder
    func applyFontStyle(for size: AppButton.Size) -> some View {
        switch size {
        case .regular:
            font(.system(size: 17, weight: .semibold))
        case .compact:
            font(.system(size: 15, weight: .semibold))
        }
    }
    
    func filledBackground(_ color: Color) -> some View {
        frame(maxWidth: .infinity)
            .background(Capsule().fill(color))
    }
    
    func outlinedBorder(_ color: Color, width: CGFloat) -> some View {
        frame(maxWidth: .infinity)
            .background(Capsule().stroke(color, lineWidth: width))
    }
}

// MARK: - Hashable Conformance -

/// Conformando a Hashable para usar AppButton con ForEach en la Button Library.
extension AppButton: Hashable {
    
    public static func == (lhs: AppButton, rhs: AppButton) -> Bool {
        lhs.style == rhs.style
            && lhs.tone == rhs.tone
            && lhs.size == rhs.size
            && lhs.title == rhs.title
            && lhs.isSelected == rhs.isSelected
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(style)
        hasher.combine(tone)
        hasher.combine(size)
        hasher.combine(title)
        hasher.combine(isSelected)
    }
}

// MARK: - Preview -

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            AppButton(
                style: .filled,
                tone: .brand,
                icon: .leading(Image(systemName: "play.fill")),
                title: "Play Podcast"
            ) { }
            
            AppButton(
                style: .outlined,
                tone: .brand,
                title: "Suscribirse"
            ) { }
            
            AppButton(
                style: .plain,
                tone: .neutral,
                title: "Cancelar"
            ) { }
            
            HStack(spacing: 16) {
                AppButton(
                    style: .icon,
                    tone: .brand,
                    icon: .toggle(
                        selected: Image(systemName: "bookmark.fill"),
                        unselected: Image(systemName: "bookmark")
                    ),
                    title: "Bookmark",
                    isSelected: true
                ) { }
                
                AppButton(
                    style: .icon,
                    tone: .neutral,
                    icon: .toggle(
                        selected: Image(systemName: "checkmark"),
                        unselected: Image(systemName: "arrow.down")
                    ),
                    title: "Download",
                    isSelected: false
                ) { }
            }
            
            AppButton(
                style: .filled,
                tone: .critical,
                title: "Eliminar episodio"
            ) { }
            
            AppButton(
                style: .filled,
                tone: .success,
                title: "Marcar como escuchado"
            ) { }
            
            AppButton(
                style: .outlined,
                tone: .warning,
                title: "Sin conexión"
            ) { }
        }
        .padding()
    }
}
