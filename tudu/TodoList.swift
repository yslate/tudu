import SwiftUI

struct Todo: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var done = false

    static func load() -> [Todo] {
        guard let json = UserDefaults.standard.data(forKey: "todos") else { return [] }
        return (try? JSONDecoder().decode([Todo].self, from: json)) ?? []
    }

    static func save(_ todos: [Todo]) {
        UserDefaults.standard.set(try? JSONEncoder().encode(todos), forKey: "todos")
    }
}

struct TodoList: View {
    @State private var todos = Todo.load()
    @State private var draft = ""
    @State private var shakes = 0
    @FocusState private var typing: Bool

    @AppStorage("style") private var style: AppStyle = .system
    @AppStorage("glassOpacity") private var opacity = 0.75
    @AppStorage("glassBlur") private var blur = 25.0
    @AppStorage("pinned") private var pinned = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            input
            if todos.isEmpty {
                Spacer()
                Text("Nothing to do")
                    .foregroundStyle(.tertiary)
                Spacer()
            } else {
                List {
                    ForEach($todos) { $todo in
                        TodoRow(todo: $todo) { delete(todo) }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .padding(.top, 8)
        .frame(minWidth: 280, minHeight: 360)
        .background(GlassWindow(tint: style.tint(colorScheme), opacity: opacity, blur: blur, pinned: pinned))
        .preferredColorScheme(style.colorScheme)
        .toolbar {
            Toggle(isOn: $pinned) {
                Image(systemName: pinned ? "pin.fill" : "pin")
            }
            .help(pinned ? "Unpin window" : "Keep window on top")
            SettingsLink {
                Image(systemName: "gearshape")
            }
            .help("Settings")
        }
        .onChange(of: todos) { Todo.save(todos) }
    }

    private var input: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)
            TextField("Add a task", text: $draft)
                .textFieldStyle(.plain)
                .focused($typing)
                .onSubmit(add)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.primary.opacity(0.07), in: .rect(cornerRadius: 12))
        .keyframeAnimator(initialValue: 0.0, trigger: shakes) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            LinearKeyframe(7, duration: 0.05)
            LinearKeyframe(-5, duration: 0.07)
            LinearKeyframe(3, duration: 0.07)
            LinearKeyframe(0, duration: 0.06)
        }
        .padding(.horizontal, 12)
        .onAppear { typing = true }
    }

    private func add() {
        let title = draft.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else {
            shakes += 1
            return
        }
        withAnimation(.snappy) { todos.append(Todo(title: title)) }
        draft = ""
    }

    private func delete(_ todo: Todo) {
        withAnimation(.snappy) { todos.removeAll { $0.id == todo.id } }
    }
}

struct TodoRow: View {
    @Binding var todo: Todo
    var onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(todo.done ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                .contentTransition(.symbolEffect(.replace))
            Text(todo.title)
                .strikethrough(todo.done)
                .foregroundStyle(todo.done ? .secondary : .primary)
            Spacer()
            if todo.done && hovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
                .help("Delete")
            }
        }
        .padding(.vertical, 3)
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.snappy) { todo.done.toggle() }
        }
        .onHover { hovering = $0 }
        .contextMenu {
            Button(todo.done ? "Mark as not done" : "Mark as done") { todo.done.toggle() }
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}

#Preview {
    TodoList()
}
