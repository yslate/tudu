import SwiftUI

// New page: add a case, give it a title/icon/keywords and a Form in the switch below.
enum SettingsPage: String, CaseIterable, Identifiable {
    case general
    case appearance
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .general: return "General"
        case .appearance: return "Appearance"
        case .about: return "About"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "paintbrush"
        case .about: return "info.circle"
        }
    }

    // Tiles sit at the top of the sidebar, the rest are plain rows below.
    var isTile: Bool { self != .about }

    var keywords: String {
        switch self {
        case .general: return "pin top float window"
        case .appearance: return "style theme color white black warm glass opacity blur"
        case .about: return "version license source github"
        }
    }
}

struct SettingsView: View {
    @State private var page: SettingsPage = .general
    @State private var search = ""

    private var pages: [SettingsPage] {
        guard !search.isEmpty else { return SettingsPage.allCases }
        return SettingsPage.allCases.filter { "\($0.title) \($0.keywords)".localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible())], spacing: 8) {
                        ForEach(pages.filter(\.isTile)) { tile($0) }
                    }
                    VStack(spacing: 2) {
                        ForEach(pages.filter { !$0.isTile }) { row($0) }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .searchable(text: $search, placement: .sidebar, prompt: "Search settings")
            .navigationSplitViewColumnWidth(250)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            Group {
                switch page {
                case .general: GeneralSettings()
                case .appearance: AppearanceSettings()
                case .about: AboutSettings()
                }
            }
            .formStyle(.grouped)
            .navigationTitle(page.title)
        }
        .frame(width: 740, height: 540)
        .onChange(of: search) {
            if let first = pages.first, !pages.contains(page) { page = first }
        }
    }

    private func tile(_ p: SettingsPage) -> some View {
        Button { page = p } label: {
            VStack(alignment: .leading) {
                SettingsIcon(name: p.icon, size: 30)
                Spacer(minLength: 18)
                Text(p.title).font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.primary.opacity(page == p ? 0.14 : 0.05), in: .rect(cornerRadius: 16))
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func row(_ p: SettingsPage) -> some View {
        Button { page = p } label: {
            HStack(spacing: 10) {
                SettingsIcon(name: p.icon, size: 24)
                Text(p.title)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.primary.opacity(page == p ? 0.14 : 0), in: .rect(cornerRadius: 10))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsIcon: View {
    let name: String
    let size: CGFloat

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size * 0.5, weight: .medium))
            .frame(width: size, height: size)
            .background(.primary.opacity(0.1), in: .rect(cornerRadius: size * 0.28))
    }
}

struct InfoLabel: View {
    let title: String
    let info: String

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
            Image(systemName: "info.circle")
                .foregroundStyle(.tertiary)
                .help(info)
        }
    }
}

struct GeneralSettings: View {
    @AppStorage("pinned") private var isPinned = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $isPinned) {
                    InfoLabel(title: "Keep window on top", info: "Keeps the list above other windows. Same as the pin button.")
                }
                .toggleStyle(.switch)
            }
        }
    }
}

struct AppearanceSettings: View {
    @AppStorage("style") private var selectedStyle: AppStyle = .system
    @AppStorage("glassOpacity") private var glassOpacity = 0.75
    @AppStorage("glassBlur") private var glassBlur = 25.0

    var body: some View {
        Form {
            Section("Style") {
                HStack(spacing: 14) {
                    ForEach(AppStyle.allCases) { style in
                        Button { selectedStyle = style } label: {
                            VStack(spacing: 6) {
                                HStack(spacing: 0) {
                                    Color(nsColor: style.tint(.light))
                                    Color(nsColor: style.tint(.dark))
                                }
                                .frame(height: 44)
                                .clipShape(.rect(cornerRadius: 10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(selectedStyle == style ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary),
                                                      lineWidth: selectedStyle == style ? 2 : 1)
                                }
                                Text(style.title)
                                    .font(.caption)
                                    .foregroundStyle(selectedStyle == style ? .primary : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Glass") {
                LabeledContent {
                    slider($glassOpacity, in: 0...1, label: glassOpacity.formatted(.percent.precision(.fractionLength(0))))
                } label: {
                    InfoLabel(title: "Opacity", info: "How much of the color covers what's behind the window.")
                }
                LabeledContent {
                    slider($glassBlur, in: 0...60, label: "\(Int(glassBlur))")
                } label: {
                    InfoLabel(title: "Blur", info: "How strongly the background behind the window is blurred.")
                }
            }
        }
    }

    private func slider(_ value: Binding<Double>, in range: ClosedRange<Double>, label: String) -> some View {
        HStack {
            Slider(value: value, in: range).frame(width: 200)
            Text(label)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

struct AboutSettings: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("tudu").font(.title2.bold())
                        Text("Version \(version)").foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            Section {
                LabeledContent("Source") {
                    Link("GitHub", destination: URL(string: "https://github.com/yslate/tudu")!)
                }
                LabeledContent("License", value: "MIT")
            }
        }
    }
}

#Preview {
    SettingsView()
}
