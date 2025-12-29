import SwiftUI

/// View настроек интеграции с Exchange Web Services (on-premises)
struct EWSCalendarSettingsView: View {
    @ObservedObject private var manager = EWSCalendarManager.shared
    @State private var showDisconnectConfirmation = false
    @State private var isLoading = false

    // Форма подключения
    @State private var serverURL = ""
    @State private var domain = ""
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        Form {
            // Статус подключения
            connectionSection

            if manager.isConnected {
                // Информация о синхронизации
                syncSection

                // Действия
                actionsSection
            }
        }
        .navigationTitle("Exchange Calendar")
        .alert("Отключить Exchange?", isPresented: $showDisconnectConfirmation) {
            Button("Отмена", role: .cancel) {}
            Button("Отключить", role: .destructive) {
                disconnect()
            }
        } message: {
            Text("Связь с календарём Exchange будет удалена. Существующие записи сохранятся.")
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        Section {
            if manager.isConnected {
                // Подключено
                connectedView
            } else {
                // Форма подключения
                connectionForm
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
            if !manager.isConnected {
                Text("Подключитесь к корпоративному Exchange Server для синхронизации календаря и отправки саммари участникам.")
            }
        }
    }

    private var connectedView: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            if let serverURL = manager.serverURL {
                HStack {
                    Image(systemName: "server.rack")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    Text(serverURL)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var connectionForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок
            HStack {
                Image(systemName: "building.2")
                    .foregroundStyle(.orange)
                    .font(.title2)

                Text("Exchange Server (On-Premises)")
                    .font(.headline)
            }

            // Server URL
            VStack(alignment: .leading, spacing: 4) {
                Text("URL сервера")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("https://exchange.company.ru", text: $serverURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            // Domain
            VStack(alignment: .leading, spacing: 4) {
                Text("Домен")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("COMPANY", text: $domain)
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
            }

            // Username
            VStack(alignment: .leading, spacing: 4) {
                Text("Имя пользователя")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("username", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            // Password
            VStack(alignment: .leading, spacing: 4) {
                Text("Пароль")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    if showPassword {
                        TextField("Пароль", text: $password)
                    } else {
                        SecureField("Пароль", text: $password)
                    }

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .textContentType(.password)
            }

            // Connect Button
            Button {
                Task { await connect() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "link")
                    }
                    Text("Подключить")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(!isFormValid || isLoading)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        Section {
            // Последняя синхронизация
            HStack {
                Label("Последняя синхронизация", systemImage: "arrow.triangle.2.circlepath")

                Spacer()

                if manager.isSyncing {
                    ProgressView()
                } else if let date = manager.lastSyncDate {
                    Text(formatRelativeDate(date))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Никогда")
                        .foregroundStyle(.secondary)
                }
            }

            // Количество событий
            HStack {
                Label("Событий в кэше", systemImage: "calendar")

                Spacer()

                Text("\(manager.cachedEvents.count)")
                    .foregroundStyle(.secondary)
            }

            // Кнопка синхронизации
            Button {
                Task { await syncNow() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Синхронизировать")
                }
            }
            .disabled(manager.isSyncing)

        } header: {
            Text("Синхронизация")
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section {
            // Отключить
            Button(role: .destructive) {
                showDisconnectConfirmation = true
            } label: {
                Label("Отключить Exchange", systemImage: "link.badge.minus")
            }
        } header: {
            Text("Действия")
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !serverURL.trimmingCharacters(in: .whitespaces).isEmpty &&
        !domain.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    // MARK: - Actions

    private func connect() async {
        isLoading = true
        defer { isLoading = false }

        let normalizedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "/$", with: "", options: .regularExpression)

        let success = await manager.connect(
            serverURL: normalizedURL,
            domain: domain.trimmingCharacters(in: .whitespaces).uppercased(),
            username: username.trimmingCharacters(in: .whitespaces),
            password: password
        )

        if success {
            // Clear form
            password = ""
        }
    }

    private func disconnect() {
        manager.disconnect()
        // Reset form
        serverURL = ""
        domain = ""
        username = ""
        password = ""
    }

    private func syncNow() async {
        await manager.syncEvents()
    }

    // MARK: - Helpers

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EWSCalendarSettingsView()
    }
}
