import * as db from '/dataStorage.js';
import * as utils from '/utils.js';

// SUPER NOVA
// This is a fast and pratical IDE and REPL for creating modeling and automation using javascript in the browser

// PRINCIPLES
// 1. RADICAL SIMPLICITY
// We aim to create this application using only vanilla javascript, no frameworks, minimal amount of css and html, this script should be 99% of the application. Like LEGO BLOCKS we should have only a few primitives that cam be composed to create more complex systems.

// 2. EXPLICIT LAYERS OF ABSTRACTIONS
// Like pages of a spreadsheet, the user should be abble to separate their entities in different layers of abstraction, the only rule is that the bottom layers does not know about upper layers, but the upper layers can acess entities in the bottom.


// CONSTANTS

// STYLING
const COLORS = {
    ACTION: "#ff6100",
    ACTION_BACKGROUND: "#ff610038",
    CONTENT: "#ffffffbf",
    CONTENT_BACKGROUND: "#000000"
}

// TYPOGRAPHY
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

class SN {
    static layers = [];
    static entities = [];

    static isInstalled () {
        return window.chrome.app.isInstalled;
    }

    static getPerformance () {
        return window.chrome.loadTimes();
    }

    static find (e) {
        if (e.key !== "Enter") {
            return;
        }
        const term = e.srcElement.value;
        window.find(term, false, false, true, false, true, true)
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
        title.innerText = "SUPERNOVA";
        
        const container = createTag("div");
        container.style.margin = "15px 30px";
        container.style.display = "flex";
        container.style.flexDirection = "row";
        container.style.alignItems = "center";
        container.style.justifyContent = "space-between";
        container.appendChild(title);
        container.appendChild(searchInput);

        body.appendChild(container);
        
        this.layers.forEach(layer => {
            const layerTag = layer.render();
            body.appendChild(layerTag);
        });
    }
}

async function coldStart() {
    await db.addFacts(
        [
            {
                entity: ":user/name",
                attribute: ":db/ident",
                value: ":user/name"
            },
            {
                entity: ":user/name",
                attribute: ":db/valueType",
                value: ":db.type/string"
            },
            {
                entity: ":user/name",
                attribute: ":db/label",
                value: "Nome"
            },
            {
                entity: ":user/birthday",
                attribute: ":db/ident",
                value: ":user/birthday"
            },
            {
                entity: ":user/birthday",
                attribute: ":db/label",
                value: "Aniversário"
            },
            {
                entity: ":user/lastSeen",
                attribute: ":db/ident",
                value: ":user/lastSeen"
            },
            {
                entity: ":user/lastSeen",
                attribute: ":db/label",
                value: "Visto por último"
            },
            {
                entity: ":user/1",
                attribute: ":user/name",
                value: "Daniel Terra"
            },
            {
                entity: ":user/1",
                attribute: ":user/birthday",
                value: 593661600000
            },
            {
                entity: ":user/1",
                attribute: ":user/lastSeen",
                value: new Date().valueOf()
            }
        ]
    );

    await utils.logTimeDiff("user schema", db.getSchemaByEntity(":user"));

    // console.log(":user", await db.getLatestFactsByEntity(":user"));
    await utils.logTimeDiff(":user/1", db.getLatestFactsByEntity(":user/1"));
    await utils.logTimeDiff("Remove lastSeen do :user/1", db.removeFact(":user/1",":user/lastSeen"));
    await utils.logTimeDiff("Remove lastSeen do :user/1", db.getLatestFactByEntityAndAttribute(":user/1",":user/lastSeen"));
    await utils.logTimeDiff(":user/1 após remoção", db.getLatestFactsByEntity(":user/1"));
}

db.init(coldStart);