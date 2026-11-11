
import SwiftUI

/// Reusable drag handle for resizing workspace regions.
///
/// The handle reports drag translation to its parent.
/// It does not own or persist workspace layout state.
struct WorkspaceResizeHandle: View {

    /// Direction in which the user drags.
    /// .horizontal creates a vertical handle.
    /// .vertical creates a horizontal handle.
    let axis: Axis

    /// Called continuously with the current drag translation.
    let onDragChanged: (CGFloat) -> Void

    /// Called when the drag gesture ends.
    let onDragEnded: () -> Void

    @State private var isDragging = false
    @State private var isHovering = false

    private var handleColor: Color {
        if isDragging {
            return AtheerColors.accent
        }

        if isHovering {
            return AtheerColors.accent.opacity(0.7)
        }

        return AtheerColors.border
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)

            Capsule()
                .fill(handleColor)
                .frame(
                    width: axis == .horizontal ? 3 : 28,
                    height: axis == .horizontal ? 28 : 3
                )
        }
        .frame(
            width: axis == .horizontal ? 8 : nil,
            height: axis == .vertical ? 8 : nil
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    isDragging = true

                    let translation: CGFloat

                    switch axis {
                    case .horizontal:
                        translation = value.translation.width

                    case .vertical:
                        translation = value.translation.height
                    }

                    onDragChanged(translation)
                }
                .onEnded { _ in
                    isDragging = false
                    onDragEnded()
                }
        )
        .help(
            axis == .horizontal
                ? "Drag horizontally to resize"
                : "Drag vertically to resize"
        )
        .accessibilityLabel("Workspace resize handle")
    }
}

