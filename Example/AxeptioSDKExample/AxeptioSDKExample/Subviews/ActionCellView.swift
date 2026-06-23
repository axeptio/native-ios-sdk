import SwiftUI

struct ActionCellView: View {
    let type: ActionType
    let didTapCell: () -> ()

    var body: some View {
        Button {
            didTapCell()
        } label: {
            content
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .alignmentGuide(.listRowSeparatorTrailing) { d in d[.trailing] }
        .alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] }
    }

    var content: some View {
        HStack(spacing: 0.0) {
            VStack(alignment: .leading, spacing: 4.0) {
                Text(type.title)
                    .bold()
                Text(type.subtitle)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            Spacer(minLength: 16.0)
            Image(systemName: "chevron.right")
        }
        .padding(20.0)
        .font(.title3)
        .contentShape(Rectangle())
    }
}

#Preview {
    ActionCellView(type: .openMainFlow) {}
}
