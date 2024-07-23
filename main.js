// SUPER NOVA
// This is a fast and pratical IDE and REPL for creating modeling and automation using javascript in the browser

// PRINCIPLES
// 1. RADICAL SIMPLICITY
// We aim to create this application using only vanilla javascript, no frameworks, minimal amount of css and html, this script should be 99% of the application. Like LEGO BLOCKS we should have only a few primitives that cam be composed to create more complex systems.

// 2. EXPLICIT LAYERS OF ABSTRACTIONS
// Like pages of a spreadsheet, the user should be abble to separate their entities in different layers of abstraction, the only rule is that the bottom layers does not know about upper layers, but the upper layers can acess entities in the bottom.

// STYLING
// Constants
const COLORS = {
    ACTION: "#ff6100",
    ACTION_BACKGROUND: "#ff610038",
    CONTENT: "#ffffffbf",
    CONTENT_BACKGROUND: "#000000"
}

// Typography
const FONTS = {
    STANDARD: new FontFace("custom-font", "url(/fonts/Monoid-Retina.ttf)")
}

document.fonts.add(FONTS.STANDARD);

for (const font in FONTS) {
    FONTS[font].load();
}

// SHORTCUTS
// This is only shortcuts for long name variables
const body = window.document.body;
const createTag = (name) => {
    return window.document.createElement(name);
}

// CLASSES
// SuperNOVA
// This is mostly a static class to handle the layer 0 of abstraction
class SN {
    static layers = [];
    static entities = [];

    static dbOpenRequest = window.indexedDB.open("supernova", 4);
    static db; // Opened IndexedDB instance
    static entityStore; // IndexedDB entity object store
    

    static {
        this.dbOpenRequest.onerror = (err) => {
            alert(err.target.error.message);
            console.error(err);
        }
        this.dbOpenRequest.onupgradeneeded = () => this.setupDb();
        this.dbOpenRequest.onsuccess = () => this.dbReady();
    }

    static isInstalled () {
        return window.chrome.app.isInstalled;
    }

    static getPerformance () {
        return window.chrome.loadTimes();
    }

    static find (e) {
        console.log(e);
        if (e.key !== "Enter") {
            return;
        }
        const term = e.srcElement.value;
        console.log(term);
        window.find(term, false, false, true, false, true, true)
    }

    static addLayer (layer) {
        this.layers.push(layer);
        // TBD: Save to local storage
        layer.render();
    }

    static addEntity (name, states, attrs) {
        this.entityStore.put({
            type: "entity", 
            name,
            states,
            attrs
        });
        // Load entities again
    }

    static render () {
        // Clear entire body
        body.innerHTML = "";
        body.style.fontFamily = FONTS.STANDARD.family;
        body.style.backgroundColor = COLORS.CONTENT_BACKGROUND;
        body.style.color = COLORS.CONTENT;
        
        const searchInput = createTag("input");
        searchInput.style.backgroundColor = COLORS.ACTION_BACKGROUND;
        searchInput.style.color = COLORS.ACTION;
        searchInput.style.padding = "5px 10px";
        searchInput.style.border = "1px solid";
        searchInput.style.flexGrow = "1";
        searchInput.style.margin = "0 0 0 20px";
        searchInput.style.fontVariantLigatures = "common-ligatures no-discretionary-ligatures historical-ligatures contextual";
        searchInput.onkeydown = this.find;
        searchInput.type = "text";
        searchInput.placeholder = "Digite e pressione enter para pesquisar";

        const title = createTag("h1");
        title.innerText = "SuperNOVA";
        
        const container = createTag("div");
        container.style.margin = "15px 30px";
        container.style.display = "flex";
        container.style.flexDirection = "row";
        container.style.alignItems = "center";
        container.style.justifyContent = "space-between";
        container.appendChild(title);
        container.appendChild(searchInput);
        
        body.appendChild(container);
    }

    static broadcastMessage (message) {
        this.entities.forEach(entity => {
            entity.receiveMessage(message)
        });
    }

    static setupDb () {
        console.log("UPGRADE NEEDED");
        this.db = this.dbOpenRequest.result;
        const store = this.db.createObjectStore("entity", {
            keyPath: "name"
        });
        
        // Indexes
        store.createIndex("names", ["name"], {
            unique: true
        });
    }

    static dbReady () {
        console.log("DB IS READY", this);
        this.db = this.dbOpenRequest.result;
        const transaction = this.db.transaction("entity", "readwrite");

        this.entityStore = transaction.objectStore("entity");
        console.log(this.entityStore);
        this.entityNameIndex = this.entityStore.index("names");
        this.loadEntities();
    }

    static loadEntities () {
        this.entityStore.load()
            .then((response) => {
                this.entities = response;
                console.log(this.entities);
            })
    }
}

class Entity {
    constructor(type, name, states, attrs){
        this.type = type;
        this.name = name;
        this.states = states || [];
        this.attrs = attrs;
        this.save();
    }

    renderThumbnail = () => {
        const container = createTag("div");
        container.className = "entity-container";
        container.style.color = "white";
        container.style.padding = "10px 25px";
        container.style.border = "1px solid";
        container.style.margin = "5px";
        container.style.textAlign = "center";
        // TBD: Add a nice border to indicate what is being focused

        const label = createTag("span");
        label.innerText = `${this.name} | ${this.type}`;

        container.appendChild(label);
        return container;
    }

    receiveMessage = (message) => {
        // check states and try to execute the action for the message received
    }

    save = () => {
        // Save to indexedDB
    }

    addState = (name, description) => {
        this.states.push(new State(name, description))
    }

    addRow = (attrs) => {
        // validate attrs
        // save to IndexedDB table
    }

    search = (attrs) => {
        // Search by attrs
        // Return entities with attrs
    }

}

class State {
    constructor(name, description, actions) {
        this.name = name;
        this.description = description;
        this.actions = actions;
        // Save to indexDB
    }

    renderThumbnail = () => {
        const tag = createTag("div");
        tag.className = "state-container";

        const label = createTag("span");
        label.innerText = `${this.name}`;
        label.style.display = "block";

        tag.appendChild(label);
        
        this.actions.map(ac => {
            const action_button = ac.render();
            actions_container.appendChild(action_button);
        });

        if (actions_container.childNodes.length > 0) {
            tag.appendChild(actions_container);
        }

        return tag;
    }
}

class Action {
    constructor(mode, name, func) {
        this.type = "action",
        this.mode = mode;
        this.name = name;
        this.func = func;
    }
    render = () => {
        const action_button = createTag("button");
        action_button.innerText = this.name;
        action_button.onclick = this.func;
        return action_button;
    }
}

class Message {
    constructor(senderRef, actionName, data) {
        this.senderRef = senderRef;
        this.actionName = actionName;
        this.data = data;
    }
}

window.onload = function coldStart() {
    SN.render();
}