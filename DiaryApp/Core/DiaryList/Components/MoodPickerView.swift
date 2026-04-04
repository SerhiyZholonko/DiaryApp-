// MARK: - Mood Picker View
// Горизонтальний рядок вибору настрою (використовується в EntryEditorView).
import SwiftUI

struct MoodPickerView: View {
    @Binding var selected: MoodLevel?
    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MoodLevel.allCases) { mood in
                Button(action: { withAnimation(.spring(response: 0.3)) { selected = mood } }) {
                    ZStack {
                        if selected == mood {
                            Circle()
                                .fill(theme.accent.opacity(0.25))
                                .frame(width: 52, height: 52)
                        }
                        Text(mood.emoji)
                            .font(.system(size: 30))
                            .scaleEffect(selected == mood ? 1.15 : 1.0)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    MoodPickerView(selected: .constant(.good))
        .padding()
        .background(Color.diaryCard)
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}
