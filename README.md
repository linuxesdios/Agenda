<div align="center">

**[Español](README.md)** · [English](README.en.md) · [Русский](README.ru.md) · [中文](README.zh.md)

# 📋 Agenda

Agenda personal multiplataforma hecha con Flutter: calendario, tareas en formato Kanban, notas, marcadores, contraseñas cifradas, Pomodoro, plantillas y sincronización entre dispositivos vía GitHub Gist privado.

<!-- Reemplazá linuxesdios por tu usuario/organización de GitHub antes de publicar -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build & Release](https://github.com/linuxesdios/agenda/actions/workflows/release.yml/badge.svg)](https://github.com/linuxesdios/agenda/actions/workflows/release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.12-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20Android%20%7C%20Linux-informational)](#-compilar-desde-el-código-fuente)

</div>

## 🖼️ Capturas

<p align="center">
  <img src="docs/screenshots/demo_claro.png" alt="Pantalla principal, modo claro" width="49%">
  <img src="docs/screenshots/demo_oscuro.png" alt="Pantalla principal, modo oscuro" width="49%">
</p>

> Datos de ejemplo genéricos — ninguna captura de este repo corresponde a datos reales de un usuario.

## ✨ Funcionalidades

- 📅 Calendario y vista semanal de citas
- ✅ Tareas en tablero Kanban, con criticidad y recordatorios
- 📝 Notas rápidas ("brain dump")
- 🔖 Marcadores / enlaces guardados
- 🔐 Gestor de contraseñas cifrado (`cryptography`)
- 🍅 Temporizador Pomodoro
- 🧩 Plantillas y listas personalizadas
- ☁️ Sincronización entre dispositivos vía GitHub Gist privado
- 🔔 Notificaciones locales programadas
- 🖥️ Widget de pantalla de inicio en Android (con modo oscuro propio)
- 🌗 Modo oscuro, paletas de color e idioma configurables
- 🌍 Interfaz en Español, English, Русский y 中文

## 📂 Estructura del proyecto

Es un único proyecto Flutter: todo el código de la aplicación vive en [lib/](lib/) y se compila para cada plataforma usando las carpetas estándar que genera el propio Flutter (`android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`). No son subproyectos independientes — comparten el 100% de la lógica y la interfaz.

```
lib/
├── main.dart          # arranque, tema, ciclo de vida de ventana
├── i18n/               # diccionario de traducciones y helpers de idioma
├── modelos/           # entidades de datos (Cita, Tarea, Configuracion, ...)
├── estado/            # estado global de la app (Provider/ChangeNotifier)
├── repositorios/      # persistencia (SQLite y JSON) y su interfaz común
├── servicios/         # notificaciones, cifrado, widget de Android, sync a la nube
├── pantallas/         # pantallas principales
└── widgets/           # componentes y diálogos reutilizables

android/ ios/ linux/ macos/ web/ windows/   # shells nativos generados por Flutter
installer/             # script de Inno Setup para el instalador de Windows
```

## 🔨 Compilar desde el código fuente

Requisitos comunes: [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.12 en el PATH, y `flutter pub get` corrido una vez en la raíz del repo.

```bash
git clone https://github.com/linuxesdios/agenda.git
cd agenda
flutter pub get
```

### Windows

Requiere Visual Studio 2022 con la carga de trabajo **"Desarrollo para el escritorio con C++"**.

```powershell
flutter build windows --release
```

Resultado: `build\windows\x64\runner\Release\agenda.exe` (+ DLLs necesarias en la misma carpeta).

Para generar el instalador `.exe` (requiere [Inno Setup](https://jrsoftware.org/isinfo.php) 6 o superior):

```powershell
"C:\Program Files\Inno Setup 7\ISCC.exe" installer\agenda_setup.iss
```

Resultado: `installer\Output\AgendaSetup.exe`.

### Android

Requiere Android SDK (vía Android Studio) y `flutter.sdk` / `sdk.dir` configurados (Flutter genera `android/local.properties` automáticamente en el primer build; ese archivo es local a tu máquina y no se versiona).

```bash
flutter build apk --release
```

Resultado: `build/app/outputs/flutter-apk/app-release.apk`.

### Linux

Requiere las dependencias de desarrollo de GTK 3 (`libgtk-3-dev`, `cmake`, `ninja-build`, `clang`).

```bash
flutter build linux --release
```

Resultado: `build/linux/x64/release/bundle/` (carpeta completa; `agenda` es el ejecutable).

### macOS / iOS / Web

Las carpetas `macos/`, `ios/` y `web/` están presentes (generadas por Flutter) pero no se compilan ni se prueban de forma regular en este proyecto. Deberían funcionar con los comandos estándar (`flutter build macos`, `flutter build ios`, `flutter build web`), pero no hay garantía — si encontrás problemas, son bienvenidos los issues/PRs.

## ⬇️ Descargar versión ya compilada

No hace falta compilar nada: cada [Release](https://github.com/linuxesdios/agenda/releases) trae los binarios ya generados por CI.

| Plataforma | Archivo a bajar | Qué es |
|---|---|---|
| 🪟 Windows | `AgendaSetup.exe` | Instalador (recomendado) — crea accesos directos y desinstalador |
| 🪟 Windows | `agenda-windows-portable.zip` | Carpeta portable, sin instalar — descomprimir y ejecutar `agenda.exe` |
| 🤖 Android | `app-release.apk` | Instalá habilitando "orígenes desconocidos" en el teléfono |
| 🐧 Linux | `agenda-linux-x64.tar.gz` | Bundle portable (best-effort, ver nota abajo) — descomprimir y ejecutar `agenda` |

### Generar un release nuevo

```bash
git tag v1.0.0
git push origin v1.0.0
```

Esto dispara `.github/workflows/release.yml`, que compila las 3 plataformas y publica el Release automáticamente con los binarios adjuntos. También se puede correr manualmente desde la pestaña **Actions → Build & Release → Run workflow** (no publica un Release, solo deja los artifacts para verificar que el build funciona).

> **Nota:** el job de Linux corre en `ubuntu-latest` pero nunca se probó localmente (no hay Linux disponible en la máquina de desarrollo). Está marcado `continue-on-error`, así que si falla no bloquea el release de Windows/Android — pero no está garantizado que funcione hasta la primera corrida real.

## ☁️ Sincronización entre dispositivos

La app sincroniza datos entre tus dispositivos (PC del trabajo, PC de casa, celular, etc.) usando un **[Gist](https://docs.github.com/es/get-started/writing-on-github/editing-and-sharing-content-with-gists/creating-gists) privado de GitHub** como almacenamiento — no hay backend propio ni servidor: es solo un archivo de texto privado en tu cuenta de GitHub que la app lee y escribe.

### Cómo decide qué versión gana

Cada vez que sincroniza (al abrir la app, cada 15 minutos si hubo cambios, o con el botón manual 🔄), la app compara fechas en vez de sobreescribir a ciegas:

- **Si no tenés cambios locales sin subir** → solo *lee*: si la nube tiene algo más nuevo que la última vez que sincronizaste, lo trae.
- **Si tenés cambios locales sin subir** → compara la fecha de tu cambio contra la fecha de lo que hay en la nube, y **gana el más reciente**: si lo tuyo es más nuevo, se sube; si la nube tiene algo posterior (por ejemplo, subido desde otro dispositivo), se descarta tu cambio local y se trae eso.

Al cerrar la app, lo que estabas editando se sube directo (sin comparar), porque en ese momento es por definición tu versión más reciente.

> Esto cubre el uso normal (editás en un dispositivo por vez, y sincronizás al pasar a otro). No hay una pantalla de "resolver conflicto" para el caso raro de editar los dos dispositivos a la vez sin sincronizar entre medio — en ese caso gana el que tenga la fecha más reciente, sin avisar.

### Configurar la sincronización (una vez por dispositivo)

1. **Creá una cuenta de GitHub** si todavía no tenés una: [github.com/join](https://github.com/join) (es gratis).
2. **Generá un token de acceso** con permiso *solo* para Gists:
   - Andá a [github.com/settings/tokens?type=beta](https://github.com/settings/tokens?type=beta)
   - **Generate new token** → poné un nombre, por ejemplo "Agenda"
   - En **Account permissions**, buscá **Gists** y poné **Read and Write**
   - Generá el token y copialo (empieza con `github_pat_...`) — GitHub solo lo muestra una vez
3. **En la app**, andá a Ajustes → Sincronización, pegá el token, y tocá **"Crear gist"** (esto crea el Gist privado automáticamente y completa el Gist ID).
4. **En tus otros dispositivos**, repetí el paso 3 pero usando **"Importar"** en vez de crear uno nuevo: en el primer dispositivo tocá **"Exportar"** (copia token + Gist ID al portapapeles), y en el dispositivo nuevo pegalo con **"Importar"** — así todos apuntan al mismo Gist.

El token queda guardado solo localmente en cada dispositivo (nunca se commitea ni se comparte); el Gist es privado, solo vos podés verlo con tu cuenta de GitHub.

## 🌍 Idiomas

La app detecta el idioma del sistema en el primer arranque y permite cambiarlo desde Ajustes → Apariencia. Idiomas disponibles: Español, English, Русский, 中文.

## 📄 Licencia

Este proyecto está bajo licencia [MIT](LICENSE).
