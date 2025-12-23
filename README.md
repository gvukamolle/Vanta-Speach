# Vanta Speech

Мультиплатформенное приложение для записи, транскрипции и саммаризации встреч.

<p align="center">
  <img src="shared/icons/app-icon-preview.png" alt="Vanta Speech" width="128" />
</p>

## Platforms

| Platform | Technology | Status |
|----------|------------|--------|
| iOS | Swift/SwiftUI | ✅ Production |
| macOS | Swift/SwiftUI | ✅ Production |
| Android | Kotlin/Jetpack Compose | 🚧 Development |
| Windows | C#/WinUI 3 | 🚧 Development |

## Features

- **Audio Recording** - Локальная запись аудио встреч с поддержкой фоновой записи
- **Transcription** - Отправка на сервер для распознавания речи (AI-powered)
- **Summarization** - Автоматическое создание саммари встречи
- **Playback** - Воспроизведение записей с удобным плеером
- **Library** - Управление записями с поиском и фильтрацией
- **Export** - Интеграция с Confluence, Notion, Google Docs (planned)

## Quick Start

### iOS / macOS

```bash
# Requirements: Xcode 16.0+, iOS 17.0+ / macOS 14.0+

# Open project
open VantaSpeech.xcodeproj

# Or build via CLI
xcodebuild -scheme VantaSpeech -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Android

```bash
# Requirements: Android Studio 2024.2+, JDK 17+, SDK 26-35

cd VantaSpeech-Android
./gradlew assembleDebug
./gradlew installDebug
```

### Windows

```bash
# Requirements: Visual Studio 2022, .NET 8.0 SDK, Windows App SDK 1.5+

cd VantaSpeech-Windows
dotnet build
dotnet run --project VantaSpeech
```

## Project Structure

```
Vanta-Speach/
├── VantaSpeech/              # iOS Swift code (primary)
│   ├── App/                  # Entry point
│   ├── Features/             # Feature modules
│   ├── Core/                 # Audio, Network, Storage services
│   └── Shared/               # Reusable UI components
│
├── VantaSpeech-macOS/        # macOS native app
│   └── VantaSpeech/          # SwiftUI views, menu bar extra
│
├── VantaSpeech-Android/      # Android app
│   └── app/                  # Kotlin + Jetpack Compose
│
├── VantaSpeech-Windows/      # Windows app
│   └── VantaSpeech/          # WinUI 3 + .NET 8
│
└── shared/                   # Cross-platform resources
    ├── icons/                # App icon sources
    ├── localization/         # Translation files (EN, RU)
    └── docs/                 # Architecture docs
```

## Tech Stack

### iOS / macOS
- **SwiftUI** - User interface
- **SwiftData** - Local persistence
- **AVFoundation** - Audio recording & playback
- **FFmpegKit** - OGG/Opus conversion
- **URLSession** - Async networking

### Android
- **Jetpack Compose** - Modern UI toolkit
- **Room** - SQLite database
- **MediaRecorder** - Audio recording
- **Media3 (ExoPlayer)** - Audio playback
- **Hilt** - Dependency injection
- **Retrofit + OkHttp** - Networking

### Windows
- **WinUI 3** - Windows App SDK UI
- **Entity Framework Core** - SQLite storage
- **NAudio** - Audio recording & playback
- **Concentus** - OGG/Opus encoding

## Configuration

### Server Setup

Configure your transcription server URL in the app settings:

```
Settings → Server URL → https://your-server.com
```

### API Endpoint

The app expects a transcription server with the following endpoint:

```
POST /transcribe
Content-Type: multipart/form-data

Request: file (audio/m4a, audio/ogg, audio/mp3, audio/wav)

Response:
{
  "transcription": "Full transcription text...",
  "summary": "Meeting summary...",
  "language": "en",
  "duration": 125.5
}
```

## Permissions

### iOS / macOS
- Microphone access
- Background audio (iOS)

### Android
- `RECORD_AUDIO` - Microphone access
- `FOREGROUND_SERVICE_MICROPHONE` - Background recording
- `INTERNET` - Network access

### Windows
- Microphone capability

## Development

### iOS-First Strategy

1. New features are developed on iOS first
2. Then ported to other platforms
3. Platform-specific adaptations as needed

### Building for All Platforms

```bash
# iOS
xcodebuild -scheme VantaSpeech -destination 'generic/platform=iOS'

# macOS
xcodebuild -scheme VantaSpeech-macOS -destination 'platform=macOS'

# Android
cd VantaSpeech-Android && ./gradlew assembleRelease

# Windows
cd VantaSpeech-Windows && dotnet publish -c Release -r win-x64
```

## Contributing

See [CLAUDE.md](CLAUDE.md) for development guidelines and architecture details.

## License

Proprietary - Internal use only
