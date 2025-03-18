// DATABASE
const DB_VERSION = 1;
const DB_OPEN_REQUEST = window.indexedDB.open("supernova", DB_VERSION);

export const hashObject = async (obj) => {
    // Converter o objeto para uma string JSON ordenada
    const json = JSON.stringify(obj, Object.keys(obj).sort());

    // Criar um hash SHA-256
    const encoder = new TextEncoder();
    const data = encoder.encode(json);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);

    // Converter buffer para string hexadecimal
    return Array.from(new Uint8Array(hashBuffer))
        .map(byte => byte.toString(16).padStart(2, "0"))
        .join("");
}

const handleDBUpgradeNeeded = () => {
    console.log("UPGRADE NEEDED");
    const db = DB_OPEN_REQUEST.result;

    if (!db.objectStoreNames.contains("facts")) {
        const store = db.createObjectStore("facts", { keyPath: "id", autoIncrement: false });
        
        if (!store.indexNames.contains("factsByEntityAndAttribute")) {
            store.createIndex("factsByEntityAndAttribute", ["entity", "attribute", "time"], { unique: false });
        }

        if (!store.indexNames.contains("factsByAttribute")) {
            store.createIndex("factsByAttribute", "attribute", { unique: false });
        }
    }
}

export const init = async () => {
    return new Promise((resolve, reject) => {
        DB_OPEN_REQUEST.onerror = (err) => {
            alert(err.target.error.message);
            console.error(err);
        }
        
        DB_OPEN_REQUEST.onupgradeneeded = () => handleDBUpgradeNeeded();
        DB_OPEN_REQUEST.onsuccess = resolve;
        DB_OPEN_REQUEST.onerror = reject;
    });
}

export const addFact = async (entity, attribute, value, time) => {
    if (!time) {
        time = new Date().valueOf();
    }
    
    const payload = {
        entity,
        attribute,
        value,
        time
    }

    const id = await hashObject(payload);
    const fact = {
        id,
        ...payload
    }

    const db = DB_OPEN_REQUEST.result;
    const transaction = db.transaction("facts", "readwrite");
    const store = transaction.objectStore("facts");
    // const index = this.entityStore.index("facts");

    return new Promise((resolve, reject) => {
        const req = store.put(fact);

        req.onsuccess = () => resolve(req.result);
        req.onerror = () => reject(req.error);
    });
}

export const addFacts = async (facts) => {
    const results = [];
    facts.forEach((fact) => {
        results.push(addFact(fact.entity, fact.attribute, fact.value, fact.time));
    });

    return Promise.all(results);
}

export const getFacts = async () => {
    db = DB_OPEN_REQUEST.result;
    const transaction = db.transaction("facts", "readwrite");
    const store = transaction.objectStore("facts");

    return store.load();
}

export const getLatestFactsByEntity = async (entity) => {
    return new Promise((resolve, reject) => {
        const db = DB_OPEN_REQUEST.result;
        const transaction = db.transaction("facts", "readonly");
        const store = transaction.objectStore("facts");
        const index = store.index("factsByEntityAndAttribute");

        // Criar um intervalo que filtra pela entidade, pelo atributo, e ignora os fatos "removidos"
        const range = IDBKeyRange.bound([entity], [entity, []]);

        const cursorRequest = index.openCursor(range, "prev"); // Reverter a ordem para pegar o mais recente primeiro

        const latestFacts = new Map();

        cursorRequest.onsuccess = (event) => {
            const cursor = event.target.result;
            if (!cursor) {
                const result = latestFacts.values().filter(f => {
                    if (f.deleted) {
                        return false;
                    }
                    
                    return true;
                });

                return resolve(Array.from(result));
            }

            const fact = cursor.value;
            const attribute = fact.attribute;
            
            // Se ainda não armazenamos um fato para esse atributo, adicionamos o mais recente
            if (!latestFacts.has(attribute)) {
                latestFacts.set(attribute, fact);
            }

            cursor.continue(); // Continuar percorrendo
        };

        cursorRequest.onerror = () => reject(cursorRequest.error);
    });
};

export const getSchemaByEntity = async (entityPrefix) => {
    return new Promise((resolve, reject) => {
        const db = DB_OPEN_REQUEST.result;
        const transaction = db.transaction("facts", "readonly");
        const store = transaction.objectStore("facts");
        const index = store.index("factsByEntityAndAttribute");

        // Criar um intervalo que filtra pela entidade
        const range = IDBKeyRange.bound(
            [entityPrefix + "/"],  
            [entityPrefix + "/\uffff"]
        );

        const cursorRequest = index.openCursor(range, "prev"); // Ordem decrescente para pegar os mais recentes primeiro
        const latestFacts = new Map(); 

        cursorRequest.onsuccess = (event) => {
            const cursor = event.target.result;
            if (!cursor) {
                return resolve(Array.from(latestFacts.values())); // Retorna apenas os últimos fatos
            }

            const fact = cursor.value;
            const isRelevantAttribute = [":db/ident", ":db/valueType", ":db/label"].includes(fact.attribute);

            if (isRelevantAttribute) {
                const key = `${fact.entity}-${fact.attribute}`;
                if (!latestFacts.has(key)) {
                    latestFacts.set(key, fact); // Guarda apenas o fato mais recente por entidade-atributo
                }
            }

            cursor.continue();
        };

        cursorRequest.onerror = () => reject(cursorRequest.error);
    });
};

export const getLatestFactByEntityAndAttribute = async (entity, attribute) => {
    return new Promise((resolve, reject) => {
        const db = DB_OPEN_REQUEST.result;
        const transaction = db.transaction("facts", "readonly");
        const store = transaction.objectStore("facts");
        const index = store.index("factsByEntityAndAttribute");

        // Criar um intervalo que filtra pela entidade e pelo atributo
        const range = IDBKeyRange.bound([entity, attribute], [entity, attribute, []]);

        // Abrir o cursor em ordem reversa (do mais recente para o mais antigo)
        const cursorRequest = index.openCursor(range, "prev");

        cursorRequest.onsuccess = (event) => {
            const cursor = event.target.result;
            if (!cursor) {
                return resolve(null);  // Nenhum fato encontrado
            }

            // O cursor está na posição do fato mais recente
            const latestFact = cursor.value;
            resolve(latestFact);
        };

        cursorRequest.onerror = () => reject(cursorRequest.error);
    });
};

export const removeFact = async (entity, attribute) => {
    const db = DB_OPEN_REQUEST.result;

    // Criar um fato de "removido" com o timestamp atual
    const time = new Date().valueOf();
    const factToRemove = {
        entity,
        attribute,
        value: -1,
        time, // Data da remoção
        deleted: true
    };

    // Gerar o ID do fato de remoção com base na entidade, atributo e momento da remoção
    const id = await hashObject(factToRemove);
    const fact = {
        id,
        ...factToRemove
    };

    // Adicionar o fato de remoção ao banco
    const transaction = db.transaction("facts", "readwrite");
    const store = transaction.objectStore("facts");

    return new Promise((resolve, reject) => {
        const req = store.put(fact);

        req.onsuccess = () => resolve(req.result);
        req.onerror = () => reject(req.error);
    });
};

export const getLatestFactsByAttribute = async (attribute) => {
    return new Promise((resolve, reject) => {
        const db = DB_OPEN_REQUEST.result;
        const transaction = db.transaction("facts", "readonly");
        const store = transaction.objectStore("facts");
        const index = store.index("factsByAttribute");

        const range = IDBKeyRange.only(attribute); // Filtra pelo atributo
        const cursorRequest = index.openCursor(range, "prev"); // Ordenação reversa (últimos fatos primeiro)

        const latestFacts = [];
        const seenEntities = new Set(); // Rastreamos entidades já adicionadas

        cursorRequest.onsuccess = (event) => {
            const cursor = event.target.result;
            if (!cursor) {
                return resolve(latestFacts); // Retorna os fatos mais recentes
            }

            const fact = cursor.value;
            if (!seenEntities.has(fact.entity)) {
                latestFacts.push(fact);
                seenEntities.add(fact.entity); // Marca a entidade como processada
            }

            cursor.continue(); // Continua percorrendo os fatos
        };

        cursorRequest.onerror = () => reject(cursorRequest.error);
    });
};