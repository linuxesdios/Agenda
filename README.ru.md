<div align="center">

[Español](README.md) · [English](README.en.md) · **[Русский](README.ru.md)** · [中文](README.zh.md)

# 📋 Agenda

Кроссплатформенный персональный органайзер на Flutter: календарь, задачи в формате Kanban, заметки, закладки, зашифрованные пароли, таймер Помодоро, шаблоны и синхронизация между устройствами через приватный GitHub Gist.

<!-- Замените linuxesdios на ваш логин/организацию GitHub перед публикацией -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build & Release](https://github.com/linuxesdios/agenda/actions/workflows/release.yml/badge.svg)](https://github.com/linuxesdios/agenda/actions/workflows/release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.12-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20Android%20%7C%20Linux-informational)](#-сборка-из-исходного-кода)

</div>

## 🖼️ Скриншоты

<p align="center">
  <img src="docs/screenshots/demo_claro.png" alt="Главный экран, светлая тема" width="49%">
  <img src="docs/screenshots/demo_oscuro.png" alt="Главный экран, тёмная тема" width="49%">
</p>

> Демонстрационные данные — ни один скриншот в этом репозитории не содержит реальных данных пользователя.

## ✨ Возможности

- 📅 Календарь и недельный вид встреч
- ✅ Доска задач Kanban с приоритетами и напоминаниями
- 📝 Быстрые заметки ("brain dump")
- 🔖 Закладки / сохранённые ссылки
- 🔐 Менеджер паролей с шифрованием (`cryptography`)
- 🍅 Таймер Помодоро
- 🧩 Шаблоны и пользовательские списки
- ☁️ Синхронизация между устройствами через приватный GitHub Gist
- 🔔 Локальные запланированные уведомления
- 🖥️ Виджет на главном экране Android (со своей тёмной темой)
- 🌗 Тёмная тема, цветовые палитры и язык — всё настраивается
- 🌍 Интерфейс на испанском, английском, русском и китайском языках

## 📂 Структура проекта

Это единый проект Flutter: весь код приложения находится в [lib/](lib/) и собирается для каждой платформы с использованием стандартных папок, которые генерирует сам Flutter (`android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`). Это не отдельные подпроекты — они полностью используют общую логику и интерфейс.

```
lib/
├── main.dart          # запуск, тема, жизненный цикл окна
├── i18n/               # словарь переводов и хелперы языка
├── modelos/           # модели данных (Cita, Tarea, Configuracion, ...)
├── estado/            # глобальное состояние приложения (Provider/ChangeNotifier)
├── repositorios/      # хранение данных (SQLite и JSON) и общий интерфейс
├── servicios/         # уведомления, шифрование, виджет Android, синхронизация
├── pantallas/         # основные экраны
└── widgets/           # переиспользуемые компоненты и диалоги

android/ ios/ linux/ macos/ web/ windows/   # нативные оболочки, сгенерированные Flutter
installer/             # скрипт Inno Setup для установщика Windows
```

## 🔨 Сборка из исходного кода

Общие требования: [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.12 в PATH и однократный запуск `flutter pub get` в корне репозитория.

```bash
git clone https://github.com/linuxesdios/agenda.git
cd agenda
flutter pub get
```

### Windows

Требуется Visual Studio 2022 с компонентом **"Разработка классических приложений на C++"**.

```powershell
flutter build windows --release
```

Результат: `build\windows\x64\runner\Release\agenda.exe` (+ необходимые DLL в той же папке).

Чтобы собрать установщик `.exe` (нужен [Inno Setup](https://jrsoftware.org/isinfo.php) 6 или новее):

```powershell
"C:\Program Files\Inno Setup 7\ISCC.exe" installer\agenda_setup.iss
```

Результат: `installer\Output\AgendaSetup.exe`.

### Android

Требуется Android SDK (через Android Studio) с настроенными `flutter.sdk` / `sdk.dir` (Flutter автоматически создаёт `android/local.properties` при первой сборке; этот файл локальный для вашей машины и не версионируется).

```bash
flutter build apk --release
```

Результат: `build/app/outputs/flutter-apk/app-release.apk`.

### Linux

Требуются зависимости для разработки GTK 3 (`libgtk-3-dev`, `cmake`, `ninja-build`, `clang`).

```bash
flutter build linux --release
```

Результат: `build/linux/x64/release/bundle/` (вся папка; `agenda` — исполняемый файл).

### macOS / iOS / Web

Папки `macos/`, `ios/` и `web/` присутствуют (созданы Flutter), но не собираются и не тестируются регулярно в этом проекте. Они должны работать со стандартными командами (`flutter build macos`, `flutter build ios`, `flutter build web`), но гарантий нет — issues/PR приветствуются, если возникнут проблемы.

## ⬇️ Скачать готовую сборку

Собирать ничего не нужно: каждый [Release](https://github.com/linuxesdios/agenda/releases) содержит бинарники, уже собранные через CI.

| Платформа | Файл для загрузки | Что это |
|---|---|---|
| 🪟 Windows | `AgendaSetup.exe` | Установщик (рекомендуется) — создаёт ярлыки и деинсталлятор |
| 🪟 Windows | `agenda-windows-portable.zip` | Портативная папка, без установки — распаковать и запустить `agenda.exe` |
| 🤖 Android | `app-release.apk` | Установите, включив "неизвестные источники" на телефоне |
| 🐧 Linux | `agenda-linux-x64.tar.gz` | Портативный бандл (best-effort, см. примечание ниже) — распаковать и запустить `agenda` |

### Как создать новый релиз

```bash
git tag v1.0.0
git push origin v1.0.0
```

Это запускает `.github/workflows/release.yml`, который собирает все 3 платформы и автоматически публикует Release с прикреплёнными бинарниками. Можно также запустить вручную во вкладке **Actions → Build & Release → Run workflow** (это не публикует Release, а только оставляет артефакты сборки, чтобы проверить, что всё собирается).

> **Примечание:** задача для Linux выполняется на `ubuntu-latest`, но никогда не тестировалась локально (на машине разработки нет Linux). Помечена как `continue-on-error`, поэтому если она упадёт, это не заблокирует релиз для Windows/Android — но нет гарантии, что она сработает до первого реального запуска.

## 🌍 Языки

Приложение определяет язык системы при первом запуске и позволяет изменить его в Настройках → Внешний вид. Доступные языки: испанский, английский, русский, китайский.

## 📄 Лицензия

Этот проект распространяется под лицензией [MIT](LICENSE).
