# Risoluzione Problemi - Salvataggio Password Server

## Problema: Le password dei server non vengono salvate

### Sintomi
- Dopo aver aggiunto un server, la password non viene ricordata
- Ogni volta che si riavvia l'app, bisogna reinserire le credenziali
- Errori durante l'aggiunta di server relativi al salvataggio delle credenziali

### Sistema di Salvataggio a Livelli

L'app usa un sistema di salvataggio a 3 livelli per massimizzare la compatibilità:

1. **🔒 Secure Storage** (Più sicuro): Keychain/Keystore del sistema operativo
2. **🔐 Database Crittografato** (Fallback sicuro): Database locale con crittografia
3. **💾 Cache Memoria** (Temporaneo): Solo durante l'esecuzione dell'app

### Cause Possibili

1. **Secure Storage non disponibile**: Il sistema di archiviazione sicura potrebbe non essere configurato correttamente sulla piattaforma
2. **Permessi mancanti**: L'app potrebbe non avere i permessi necessari per accedere al keychain/keystore
3. **Problemi di piattaforma**: Alcune piattaforme potrebbero avere limitazioni specifiche
4. **Crittografia fallita**: Il sistema di crittografia del database potrebbe avere problemi

### Diagnostica

1. **Apri la diagnostica**:
   - Vai in "Server Management" 
   - Tocca il menu (⋮) in alto a destra
   - Seleziona "Diagnostics"

2. **Controlla lo stato**:
   - `Initialized`: Dovrebbe essere "Yes"
   - `Available`: Dovrebbe essere "Yes" 
   - `Database Fallback`: Dovrebbe essere "Yes"
   - `Encryption Test`: Dovrebbe essere "Yes"
   - `Cached Passwords`: Mostra quante password sono in cache

3. **Esegui il test**:
   - Tocca "Test Storage"
   - Se il test fallisce, vedrai il messaggio di errore specifico

### Soluzioni

#### Soluzione 1: Riavvia l'app
- Chiudi completamente l'app
- Riavviala
- Prova ad aggiungere nuovamente il server

#### Soluzione 2: Controlla i permessi (Android)
- Vai nelle impostazioni del dispositivo
- Trova l'app Omnisonic
- Verifica che abbia tutti i permessi necessari
- Riavvia l'app

#### Soluzione 3: Keychain/Keystore (iOS/macOS)
- Su iOS: Verifica che il dispositivo non sia in modalità "Accesso guidato"
- Su macOS: Controlla che il Keychain sia sbloccato
- Riavvia l'app

#### Soluzione 4: Verifica crittografia database
- Apri la diagnostica
- Controlla che "Encryption Test" sia "Yes"
- Se è "No", prova a riavviare l'app
- Se persiste, potrebbe essere un problema di compatibilità

#### Soluzione 5: Modalità sviluppo (temporanea)
Se né secure storage né database funzionano, l'app userà la cache in memoria:
- ⚠️ Le password saranno perse al riavvio dell'app
- Funziona per test temporanei
- Non raccomandato per uso quotidiano

### Messaggi di Errore Comuni

#### "Secure storage not available on this platform"
- Il secure storage non è supportato o configurato
- Prova a riavviare l'app
- Verifica i permessi dell'app

#### "Failed to store password securely: [dettagli errore]"
- Problema con secure storage, ma database fallback dovrebbe funzionare
- Controlla la diagnostica per vedere se "Database Fallback" è attivo
- Se il database fallback funziona, le password saranno comunque salvate

#### "Failed to encrypt password: [dettagli errore]"
- Problema con il sistema di crittografia del database
- Prova a riavviare l'app
- Controlla che "Encryption Test" passi nella diagnostica

#### "No stored password found for server"
- La password non è stata salvata correttamente
- Prova a rimuovere e riaggiungere il server
- Verifica che il secure storage funzioni con la diagnostica

### Informazioni Tecniche

L'app usa un sistema di salvataggio a livelli per massimizzare la compatibilità:

**Livello 1 - Secure Storage** (Preferito):
- **Android**: Android Keystore
- **iOS**: iOS Keychain  
- **macOS**: macOS Keychain
- **Windows**: Windows Credential Store
- **Linux**: Secret Service API

**Livello 2 - Database Crittografato** (Fallback):
- Database SQLite locale con crittografia XOR
- Chiave di crittografia basata su caratteristiche del dispositivo
- Più sicuro del testo in chiaro, meno sicuro del secure storage

**Livello 3 - Cache Memoria** (Temporaneo):
- Solo durante l'esecuzione dell'app
- Perso al riavvio
- Usato solo come ultima risorsa

### Contatto Supporto

Se il problema persiste:
1. Esegui la diagnostica e annota i risultati
2. Controlla i log dell'app per errori specifici
3. Includi informazioni su:
   - Piattaforma (Android/iOS/etc.)
   - Versione del sistema operativo
   - Risultati della diagnostica
   - Messaggi di errore specifici