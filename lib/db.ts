
export interface OfflineFile {
    id: string;
    name: string;
    subject: number;
    semester: number;
    module: number;
    type: string;
    blob: Blob;
    size: number;
    downloadedAt: number;
    mimeType: string;
    remoteUrl: string;
}

const DB_NAME = "NotesHubDB";
const STORE_NAME = "downloads";
const DB_VERSION = 1;

export const dbInit = (): Promise<IDBDatabase> => {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION);

        request.onupgradeneeded = (event) => {
            const db = (event.target as IDBOpenDBRequest).result;
            if (!db.objectStoreNames.contains(STORE_NAME)) {
                db.createObjectStore(STORE_NAME, { keyPath: "id" });
            }
        };

        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
    });
};

export const saveFile = async (file: OfflineFile): Promise<void> => {
    const db = await dbInit();
    return new Promise((resolve, reject) => {
        const tx = db.transaction(STORE_NAME, "readwrite");
        const store = tx.objectStore(STORE_NAME);
        const request = store.put(file);

        request.onsuccess = () => resolve();
        request.onerror = () => reject(request.error);
    });
};

export const getFiles = async (): Promise<Omit<OfflineFile, "blob">[]> => {
    const db = await dbInit();
    return new Promise((resolve, reject) => {
        const tx = db.transaction(STORE_NAME, "readonly");
        const store = tx.objectStore(STORE_NAME);
        const request = store.openCursor();
        const files: Omit<OfflineFile, "blob">[] = [];

        request.onsuccess = (event) => {
            const cursor = (event.target as IDBRequest).result;
            if (cursor) {
                // eslint-disable-next-line @typescript-eslint/no-unused-vars
                const { blob, ...metadata } = cursor.value;
                files.push(metadata);
                cursor.continue();
            } else {
                resolve(files);
            }
        };
        request.onerror = () => reject(request.error);
    });
};

export const getFile = async (id: string): Promise<OfflineFile> => {
    const db = await dbInit();
    return new Promise((resolve, reject) => {
        const tx = db.transaction(STORE_NAME, "readonly");
        const store = tx.objectStore(STORE_NAME);
        const request = store.get(id);

        request.onsuccess = () => {
            if (request.result) resolve(request.result);
            else reject(new Error("File not found"));
        };
        request.onerror = () => reject(request.error);
    });
};

export const deleteFile = async (id: string): Promise<void> => {
    const db = await dbInit();
    return new Promise((resolve, reject) => {
        const tx = db.transaction(STORE_NAME, "readwrite");
        const store = tx.objectStore(STORE_NAME);
        const request = store.delete(id);

        request.onsuccess = () => resolve();
        request.onerror = () => reject(request.error);
    });
};

export const checkQuota = async (): Promise<{
    usage: number;
    quota: number;
    percentage: number;
}> => {
    if (navigator.storage && navigator.storage.estimate) {
        const estimate = await navigator.storage.estimate();
        const usage = estimate.usage || 0;
        const quota = estimate.quota || 1;
        return {
            usage,
            quota,
            percentage: (usage / quota) * 100,
        };
    }
    return { usage: 0, quota: 0, percentage: 0 };
};
