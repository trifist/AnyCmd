import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedCommandID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailPane
        }
        .frame(minWidth: 760, minHeight: 460)
        .onAppear {
            if selectedCommandID == nil {
                selectedCommandID = appState.settings.commands.first?.id
            }
        }
        .onChange(of: appState.settings.commands) { commands in
            guard let selectedCommandID else {
                self.selectedCommandID = commands.first?.id
                return
            }

            if !commands.contains(where: { $0.id == selectedCommandID }) {
                self.selectedCommandID = commands.first?.id
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $selectedCommandID) {
                ForEach(appState.settings.commands) { command in
                    Text(command.name.isEmpty ? "Untitled Command" : command.name)
                        .lineLimit(1)
                        .tag(command.id)
                }
            }
            .listStyle(.sidebar)

            Divider()

            HStack {
                Button {
                    selectedCommandID = appState.addCommand()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add command")

                Button {
                    deleteSelectedCommand()
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete command")
                .disabled(selectedCommandID == nil)

                Spacer()
            }
            .padding(8)
        }
        .frame(width: 230)
    }

    @ViewBuilder
    private var detailPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            globalSettings

            Divider()

            if let selectedCommandID, appState.command(id: selectedCommandID) != nil {
                commandEditor(for: selectedCommandID)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "command")
                        .font(.system(size: 42))
                        .foregroundStyle(.secondary)
                    Text("Add a command to get started")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Button {
                        self.selectedCommandID = appState.addCommand()
                    } label: {
                        Label("Add Command", systemImage: "plus")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(24)
    }

    private var globalSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Toggle("Enable AnyCmd", isOn: enabledBinding)
                    .toggleStyle(.switch)

                Spacer()

                Button {
                    importSettings()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .help("Import commands from a backup file")

                Button {
                    exportSettings()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .help("Export commands to a backup file")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Global Shortcut")
                    .font(.headline)

                HStack(spacing: 12) {
                    HotkeyRecorderView(hotkey: appState.settings.hotkey) { hotkey in
                        appState.settings.hotkey = hotkey
                    } onRecordingChanged: { isRecording in
                        appState.isRecordingHotkey = isRecording
                    }
                    .frame(width: 220, height: 34)

                    Text("Click the field, then press a shortcut.")
                        .foregroundStyle(.secondary)
                }

                if case .failed = appState.hotkeyRegistrationStatus {
                    Text(appState.hotkeyRegistrationStatus.message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var exportContentType: UTType {
        UTType(filenameExtension: "json") ?? .json
    }

    private func commandEditor(for id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                TextField("Command name", text: nameBinding(for: id))
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.headline)
                TextEditor(text: contentBinding(for: id))
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
            }

            Spacer()
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding {
            appState.settings.enabled
        } set: { isEnabled in
            appState.settings.enabled = isEnabled
        }
    }

    private func nameBinding(for id: UUID) -> Binding<String> {
        Binding {
            appState.command(id: id)?.name ?? ""
        } set: { name in
            appState.updateCommandName(id: id, name: name)
        }
    }

    private func contentBinding(for id: UUID) -> Binding<String> {
        Binding {
            appState.command(id: id)?.content ?? ""
        } set: { content in
            appState.updateCommandContent(id: id, content: content)
        }
    }

    private func exportSettings() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export AnyCmd Commands"
        savePanel.nameFieldStringValue = "AnyCmd-\(Self.exportDateString()).anycmd.json"
        savePanel.allowedContentTypes = [exportContentType]
        savePanel.canCreateDirectories = true

        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            return
        }

        do {
            try appState.exportSettings(to: url)
        } catch {
            showAlert(
                title: "Export Failed",
                message: error.localizedDescription
            )
        }
    }

    private func importSettings() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import AnyCmd Commands"
        openPanel.allowedContentTypes = [exportContentType]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true

        guard openPanel.runModal() == .OK, let url = openPanel.url else {
            return
        }

        do {
            try appState.importSettings(from: url)
            selectedCommandID = appState.settings.commands.first?.id
        } catch {
            showAlert(
                title: "Import Failed",
                message: error.localizedDescription
            )
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static func exportDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func deleteSelectedCommand() {
        guard let selectedCommandID else {
            return
        }

        let commands = appState.settings.commands
        let deletedIndex = commands.firstIndex { $0.id == selectedCommandID }
        appState.deleteCommand(id: selectedCommandID)

        guard !appState.settings.commands.isEmpty else {
            self.selectedCommandID = nil
            return
        }

        let nextIndex = min(deletedIndex ?? 0, appState.settings.commands.count - 1)
        self.selectedCommandID = appState.settings.commands[nextIndex].id
    }
}
