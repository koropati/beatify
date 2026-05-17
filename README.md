# Beatify 🎵

Beatify is a full-stack, cross-platform music streaming application built with Flutter (Frontend) and Python/FastAPI (Backend). It supports both online streaming from the backend API and offline playback from the user's local device library.

## Features

*   **Cross-Platform Client**: Built with Flutter (Android, iOS, Web).
*   **Clean Architecture**: Frontend structured using Domain, Data, and Presentation layers.
*   **State Management**: Powered by `flutter_riverpod`.
*   **Audio Playback**: Uses `just_audio` for robust streaming and local playback.
*   **Local Device Scanning**: Uses `on_audio_query` to fetch and play local `.mp3` files (Android/iOS only).
*   **Python Backend**: Fast and modern API built with `FastAPI` and `SQLAlchemy`.
*   **MySQL Database**: Uses MySQL for robust data storage.

---

## Architecture Overview

### Frontend (Flutter)
The Flutter app (`flutter_app/`) follows **Clean Architecture** principles to separate concerns:
1.  **Domain**: Contains the core business logic, Use Cases (`GetOnlineSongs`, `GetLocalSongs`), and Entities (`SongEntity`). Independent of any other layer.
2.  **Data**: Contains Repositories implementation and Data Sources (Remote API via `dio`, Local via `on_audio_query`). Maps JSON/Native data to Domain Entities.
3.  **Presentation**: Contains the UI (`pages`, `widgets`) and State Management (`providers`).

### Backend (Python)
The backend (`backend/`) is a simple monolithic REST API:
*   `main.py`: FastAPI application entry point defining the routes (`/api/songs`, `/api/stream/{id}`).
*   `models.py` & `schemas.py`: SQLAlchemy database models and Pydantic validation schemas.
*   `database.py`: Database connection setup using `dotenv` for MySQL config.

---

## 🚀 Getting Started

### 1. Backend Setup (Python)

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Create and activate a virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows use: venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. **Database Configuration**: 
   * Ensure you have MySQL running.
   * Create a database named `beatify_db` (or whatever you configure).
   * Update the `DATABASE_URL` in the `backend/.env` file with your MySQL credentials:
     `DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@localhost:3306/beatify_db`
5. Seed the database with dummy data (this also creates dummy audio files):
   ```bash
   python seed.py
   ```
6. Run the FastAPI server:
   ```bash
   uvicorn main:app --reload
   ```
   The backend will be available at `http://127.0.0.1:8000`.

### 2. Frontend Setup (Flutter)

1. Navigate to the flutter app directory:
   ```bash
   cd flutter_app
   ```
2. Get the dependencies:
   ```bash
   flutter pub get
   ```
3. **Android Configuration**: To allow the app to read local files and access cleartext traffic (localhost), ensure your `android/app/src/main/AndroidManifest.xml` has the following permissions:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
   ```
   *Note: If running on Android Emulator and connecting to localhost backend, the base URL in `music_remote_data_source.dart` is set to `http://localhost:8000`. If it fails to connect on the emulator, change it to `http://10.0.2.2:8000`.*

4. Run the app:
   ```bash
   flutter run
   ```
   You can select your target device (Chrome for Web, Android Emulator, or iOS Simulator). Note that Local Library scanning (`on_audio_query`) is not supported on Flutter Web.

   To list connected devices
   ```bash
   flutter devices
   ```
   Run Flutter with specific device
   ```bash
   flutter run -d [DEVICE_ID]
   ```
   Example:
   ```bash
   flutter run -d ZP22223GB9
   ```
5. Build apk file
   ```bash
   flutter build apk --debug
   ```
   Output will be in `build/app/outputs/flutter-apk/app-debug.apk`.
   

## Future Improvements for MVP
- [ ] Implement `just_audio_background` for background play controls.
- [ ] Implement actual song downloading for offline use (currently "offline" means scanning device).
- [ ] Add real UI sliders for seeking audio.
- [ ] Add User Authentication.
