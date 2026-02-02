import SwiftUI

@MainActor
public struct EduRow<Leading: View, Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let leading: Leading?
    private let trailing: Trailing?
    private let showDivider: Bool
    private let onTap: (() -> Void)?
    
    public init(
        _ title: String,
        subtitle: String? = nil,
        showDivider: Bool = true,
        onTap: (() -> Void)? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showDivider = showDivider
        self.onTap = onTap
        self.leading = leading()
        self.trailing = trailing()
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Button(action: { onTap?() }) {
                HStack(spacing: 12) {
                    if let leading = leading {
                        leading
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.body)
                            .foregroundStyle(.primary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let trailing = trailing {
                        trailing
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
            
            if showDivider {
                Divider()
                    .padding(.leading, leading != nil ? 60 : 16)
            }
        }
    }
}

extension EduRow where Leading == EmptyView {
    public init(
        _ title: String,
        subtitle: String? = nil,
        showDivider: Bool = true,
        onTap: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title, subtitle: subtitle, showDivider: showDivider, onTap: onTap, leading: { EmptyView() }, trailing: trailing)
    }
}

extension EduRow where Trailing == EmptyView {
    public init(
        _ title: String,
        subtitle: String? = nil,
        showDivider: Bool = true,
        onTap: (() -> Void)? = nil,
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(title, subtitle: subtitle, showDivider: showDivider, onTap: onTap, leading: leading, trailing: { EmptyView() })
    }
}

extension EduRow where Leading == EmptyView, Trailing == EmptyView {
    public init(
        _ title: String,
        subtitle: String? = nil,
        showDivider: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.init(title, subtitle: subtitle, showDivider: showDivider, onTap: onTap, leading: { EmptyView() }, trailing: { EmptyView() })
    }
}
