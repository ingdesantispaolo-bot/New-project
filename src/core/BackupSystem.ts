const KEY_PREFIX = "eli-quest-";
const BACKUP_VERSION = 1;

type BackupFile = {
  format: "eli-quest-backup";
  version: number;
  exportedAt: string;
  entries: Record<string, string>;
};

/**
 * Esporta/importa su file tutti i dati locali del gioco (profili, salvataggi,
 * impostazioni, record). Protegge i progressi dalla pulizia dello storage che
 * i tablet applicano ai siti non visitati da tempo e permette di spostare i
 * profili su un altro dispositivo.
 */
export const backupSystem = {
  /** Numero di voci che finirebbero nel backup (per mostrare lo stato in UI). */
  entryCount(): number {
    return collectEntries().size;
  },

  /** Scarica un file JSON con tutti i dati del gioco. Ritorna il nome file. */
  exportToFile(): string {
    const entries = collectEntries();
    const backup: BackupFile = {
      format: "eli-quest-backup",
      version: BACKUP_VERSION,
      exportedAt: new Date().toISOString(),
      entries: Object.fromEntries(entries),
    };
    const stamp = new Date().toISOString().slice(0, 10);
    const fileName = `eli-quest-backup-${stamp}.json`;
    const blob = new Blob([JSON.stringify(backup, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = fileName;
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    window.setTimeout(() => URL.revokeObjectURL(url), 4_000);
    return fileName;
  },

  /** Apre il selettore file e importa un backup. Risolve col numero di voci. */
  importFromFile(): Promise<number> {
    return new Promise((resolve, reject) => {
      const input = document.createElement("input");
      input.type = "file";
      input.accept = "application/json,.json";
      input.addEventListener("change", () => {
        const file = input.files?.[0];
        if (!file) {
          reject(new Error("Nessun file selezionato."));
          return;
        }
        file.text()
          .then((raw) => resolve(backupSystem.restore(raw)))
          .catch(() => reject(new Error("Non riesco a leggere il file.")));
      });
      // Su alcuni browser annullare il picker non emette eventi: nessun timeout,
      // la promise resta semplicemente inevasa e la UI non cambia stato.
      input.click();
    });
  },

  /** Valida e applica il contenuto di un backup. Ritorna le voci ripristinate. */
  restore(raw: string): number {
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch {
      throw new Error("Il file non è un backup valido (JSON illeggibile).");
    }
    const backup = parsed as Partial<BackupFile>;
    if (backup?.format !== "eli-quest-backup" || typeof backup.entries !== "object" || backup.entries === null) {
      throw new Error("Il file non è un backup di Eli Quest.");
    }
    const entries = Object.entries(backup.entries)
      .filter(([key, value]) => key.startsWith(KEY_PREFIX) && typeof value === "string");
    if (entries.length === 0) {
      throw new Error("Il backup non contiene dati di gioco.");
    }
    // Sostituzione completa: prima rimuove le chiavi correnti del gioco, così
    // un profilo cancellato nel backup non "risorge" mescolandosi al presente.
    for (let index = localStorage.length - 1; index >= 0; index -= 1) {
      const key = localStorage.key(index);
      if (key?.startsWith(KEY_PREFIX)) {
        localStorage.removeItem(key);
      }
    }
    entries.forEach(([key, value]) => localStorage.setItem(key, value));
    return entries.length;
  },
};

function collectEntries(): Map<string, string> {
  const entries = new Map<string, string>();
  for (let index = 0; index < localStorage.length; index += 1) {
    const key = localStorage.key(index);
    if (!key?.startsWith(KEY_PREFIX)) {
      continue;
    }
    const value = localStorage.getItem(key);
    if (value !== null) {
      entries.set(key, value);
    }
  }
  return entries;
}
