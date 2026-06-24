BUILD iOS — IM Editorial
========================

Opzione A: Codemagic (cloud, gratuito per build occasionali)
-------------------------------------------------------------
1. Vai su codemagic.io e crea un account gratuito
2. Collega il repository o carica il progetto
3. Seleziona "Flutter" → configura build iOS
4. Ottieni l'IPA e installalo con AltStore o TestFlight

Opzione B: Mac locale (se hai un Mac)
--------------------------------------
1. Copia la cartella im_editorial_flutter sul Mac
2. Installa Flutter sul Mac: https://flutter.dev
3. Apri Xcode e configura il team di firma (Apple Developer account)
4. Esegui: flutter build ios --release
5. Distribuisci con TestFlight o installazione diretta via Xcode

Opzione C: Expo/Capacitor (alternativa senza Mac)
-------------------------------------------------
Contattare il team di sviluppo per valutare la conversione
a un wrapper web (Capacitor) che non richiede Xcode.

Note
----
- Un account Apple Developer costa 99$/anno ed è necessario
  per pubblicare su App Store o installare via TestFlight
- Per uso interno/aziendale, AltStore permette l'installazione
  senza account developer (ma richiede refresh ogni 7 giorni)
