import SwiftUI

/// View настроек интеграции с Google Docs
struct GoogleDocsSettingsView: View {
    @ObservedObject private var manager = GoogleDocsManager.shared
    @State private var showDisconnectConfirmation = false
    @State private var showFolderPicker = false
    @State private var isLoading = false

    var body: some View {
        Form {
            // Статус подключения
            connectionSection

            if manager.isSignedIn {
                // Настройки папки
                folderSection

                // Действия
                actionsSection
            }
        }
        .navigationTitle("Google Docs")
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerSheet(
                folders: manager.availableFolders,
                selectedFolder: manager.selectedFolder,
                isLoading: manager.isLoadingFolders,
                onSelect: { folder in
                    manager.selectFolder(folder)
                    showFolderPicker = false
                },
                onRefresh: {
                    Task { await manager.loadFolders() }
                }
            )
        }
        .alert("Отключить Google?", isPresented: $showDisconnectConfirmation) {
            Button("Отмена", role: .cancel) {}
            Button("Отключить", role: .destructive) {
                manager.signOut()
            }
        } message: {
            Text("Связь с Google Docs будет удалена. Созданные документы останутся в вашем Google Drive.")
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        Section {
            if manager.isSignedIn {
                // Подключено
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Подключено")
                            .font(.headline)

                        if let email = manager.userEmail {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 4)

            } else {
                // Не подключено
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.blue)
                            .font(.title2)

                        Text("Не подключено")
                            .font(.headline)
                    }

                    Text("Подключите Google для экспорта саммари встреч в Google Docs.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        Task { await signIn() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                googleLogo
                            }
                            Text("Войти через Google")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(isLoading)
                }
                .padding(.vertical, 8)
            }

            // Ошибка
            if let error = manager.lastError {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Подключение")
        } footer: {
            if !manager.isSignedIn {
                Text("Vanta Speech получит доступ к созданию документов в вашем Google Drive.")
            }
        }
    }

    // MARK: - Folder Section

    private var folderSection: some View {
        Section {
            Button {
                showFolderPicker = true
            } label: {
                HStack {
                    Label {
                        Text("Папка для сохранения")
                    } icon: {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    Text(manager.selectedFolder?.name ?? "Мой диск")
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        } header: {
            Text("Настройки")
        } footer: {
            Text("Документы будут создаваться в выбранной папке Google Drive.")
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section {
            // Обновить список папок
            Button {
                Task { await manager.loadFolders() }
            } label: {
                HStack {
                    Label("Обновить папки", systemImage: "arrow.clockwise")

                    if manager.isLoadingFolders {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(manager.isLoadingFolders)

            // Отключить
            Button(role: .destructive) {
                showDisconnectConfirmation = true
            } label: {
                Label("Отключить Google", systemImage: "link.badge.minus")
            }
        } header: {
            Text("Действия")
        }
    }

    // MARK: - Google Logo

    private var googleLogo: some View {
        // Simple "G" as placeholder - replace with actual Google logo asset
        Text("G")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
    }

    // MARK: - Actions

    private func signIn() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        await manager.signIn(from: viewController)
    }
}

// MARK: - Folder Picker Sheet

struct FolderPickerSheet: View {
    let folders: [DriveFolder]
    let selectedFolder: DriveFolder?
    let isLoading: Bool
    let onSelect: (DriveFolder?) -> Void
    let onRefresh: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Root option
                Button {
                    onSelect(nil)
                } label: {
                    HStack {
                        Label("Мой диск", systemImage: "folder")

                        Spacer()

                        if selectedFolder == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .foregroundStyle(.primary)

                // Folders
                ForEach(folders) { folder in
                    Button {
                        onSelect(folder)
                    } label: {
                        HStack {
                            Label(folder.name, systemImage: "folder.fill")
                                .foregroundStyle(.primary, .blue)

                            Spacer()

                            if selectedFolder?.id == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Выбор папки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onRefresh()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .overlay {
                if isLoading && folders.isEmpty {
                    ProgressView("Загрузка папок...")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GoogleDocsSettingsView()
    }
}
