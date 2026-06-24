@echo off
title IM Editorial Flutter — Setup
cd /d "%~dp0"
echo.
echo ================================================================
echo   IM Editorial — Configurazione app Flutter
echo ================================================================
echo.

:: Verifica Flutter
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERRORE] Flutter non trovato nel PATH.
  echo.
  echo Completa prima l'installazione di Flutter:
  echo 1. Attendi che C:\Users\%USERNAME%\Downloads\flutter_sdk.zip
  echo    finisca di scaricarsi
  echo 2. Estrai in C:\flutter
  echo 3. Aggiungi C:\flutter\bin al PATH di Windows
  echo 4. Riavvia questo file
  echo.
  pause
  exit /b 1
)

echo [OK] Flutter trovato.
echo.

:: Dipendenze
echo Installazione dipendenze...
call flutter pub get
if %errorlevel% neq 0 ( echo [ERRORE] pub get fallito. & pause & exit /b 1 )
echo [OK] Dipendenze installate.
echo.

:: Icona app
if exist "assets\icon.png" (
  echo Generazione icone app da logo...
  call dart run flutter_launcher_icons
  echo [OK] Icone generate.
  echo.
) else (
  echo [NOTA] Nessun file assets\icon.png trovato.
  echo        Copia il logo Innovation Machine come assets\icon.png
  echo        e riesegui questo script per aggiornare l'icona.
  echo.
)

:: Dispositivi
echo Dispositivi connessi:
flutter devices
echo.

:: Build APK Android
echo Build APK Android (5-10 minuti)...
call flutter build apk --release
if %errorlevel% neq 0 ( echo [ERRORE] Build Android fallita. & pause & exit /b 1 )

echo.
echo ================================================================
echo   Build completata!
echo ================================================================
echo.
echo APK Android: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Per installare sull'Android:
echo   - Copia app-release.apk sul telefono
echo   - Apri il file dal telefono (abilita "Origini sconosciute")
echo.
echo Per iOS (richiede Mac o Codemagic):
echo   Vedi README_iOS.txt
echo.
pause
