import SwiftUI
import SwiftData

struct NotificationsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager

    @State private var prefs: ReminderPreferences = NotificationManager.shared.loadPreferences()
    @State private var showPermissionAlert = false

    private let maxReminders = 3
    @State private var classInput: String = ""
    @State private var classUnit: TimeUnit = .minutes
    @State private var assignmentInput: String = ""
    @State private var assignmentUnit: TimeUnit = .minutes

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Classes")) {
                    Toggle("Enable class reminders", isOn: Binding(
                        get: { prefs.classEnabled },
                        set: { newVal in
                            prefs.classEnabled = newVal
                            saveAndReschedule()
                        }
                    ))

                    if prefs.classEnabled {
                        addReminderInput(
                            placeholder: "Minutes or hours",
                            value: $classInput,
                            unit: $classUnit,
                            onAdd: {
                                addOffset(to: &prefs.classOffsetsMinutes, input: classInput, unit: classUnit)
                                classInput = ""
                                saveAndReschedule()
                            }
                        )
                        chipsList(offsets: prefs.classOffsetsMinutes) { index in
                            prefs.classOffsetsMinutes.remove(at: index)
                            saveAndReschedule()
                        }
                    }
                }

                Section(header: Text("Assignments")) {
                    Toggle("Enable assignment reminders", isOn: Binding(
                        get: { prefs.assignmentEnabled },
                        set: { newVal in
                            prefs.assignmentEnabled = newVal
                            saveAndReschedule()
                        }
                    ))

                    if prefs.assignmentEnabled {
                        addReminderInput(
                            placeholder: "Minutes or hours",
                            value: $assignmentInput,
                            unit: $assignmentUnit,
                            onAdd: {
                                addOffset(to: &prefs.assignmentOffsetsMinutes, input: assignmentInput, unit: assignmentUnit)
                                assignmentInput = ""
                                saveAndReschedule()
                            }
                        )
                        chipsList(offsets: prefs.assignmentOffsetsMinutes) { index in
                            prefs.assignmentOffsetsMinutes.remove(at: index)
                            saveAndReschedule()
                        }
                    }
                }

                if prefs.classOffsetsMinutes.count > maxReminders || prefs.assignmentOffsetsMinutes.count > maxReminders {
                    Text("Maximum \(maxReminders) reminders allowed per type.")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                NotificationManager.shared.requestPermission { granted in
                    if !granted { showPermissionAlert = true }
                }
            }
            .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable notifications in Settings to receive reminders.")
            }
        }
    }

    // MARK: - UI Helpers
    private func addReminderInput(placeholder: String, value: Binding<String>, unit: Binding<TimeUnit>, onAdd: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(placeholder, text: value)
                    .keyboardType(.numberPad)
                Picker("Unit", selection: unit) {
                    ForEach(TimeUnit.allCases, id: \.self) { u in
                        Text(u.rawValue.capitalized).tag(u)
                    }
                }
                .pickerStyle(.segmented)
                Button("Add") { onAdd() }
                    .disabled(!canAdd(value: value.wrappedValue))
            }
            Text("Add up to \(maxReminders) reminders.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func chipsList(offsets: [Int], onDelete: @escaping (Int) -> Void) -> some View {
        WrapChips(spacing: 8) {
            ForEach(Array(offsets.enumerated()), id: \.offset) { index, minutes in
                HStack(spacing: 6) {
                    Text(label(for: minutes))
                        .font(.caption)
                    Button(action: { onDelete(index) }) {
                        Image(systemName: "xmark")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.15))
                .clipShape(Capsule())
            }
        }
    }

    private func label(for minutes: Int) -> String {
        if minutes % 60 == 0 { return "\(minutes/60)h" }
        return "\(minutes)m"
    }

    // MARK: - Actions
    private func saveAndReschedule() {
        NotificationManager.shared.savePreferences(prefs)
        guard let userId = authManager.currentUserId, !userId.isEmpty else { return }
        NotificationManager.shared.rescheduleAllNotifications(modelContext: modelContext, currentUserId: userId)
    }

    private func canAdd(value: String) -> Bool {
        guard let num = Int(value), num > 0 else { return false }
        return true
    }

    private func addOffset(to array: inout [Int], input: String, unit: TimeUnit) {
        guard let num = Int(input), num > 0 else { return }
        var minutes = num
        if unit == .hours { minutes = num * 60 }
        if array.contains(minutes) { return }
        if array.count >= maxReminders { return }
        array.append(minutes)
        array.sort()
    }
}
 
enum TimeUnit: String, CaseIterable { case minutes, hours }

// Simple wrapping layout for chips
struct WrapChips<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ChipsFlowLayout(spacing: spacing) {
            content()
        }
    }
}

private struct ChipsFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth {
                width = max(width, currentRowWidth)
                height += currentRowHeight + spacing
                currentRowWidth = size.width + spacing
                currentRowHeight = size.height
            } else {
                currentRowWidth += size.width + spacing
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }
        width = max(width, currentRowWidth)
        height += currentRowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}
