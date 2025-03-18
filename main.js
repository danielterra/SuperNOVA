import {init, getLatestFactsByAttribute} from '/dataStorage.js';
import * as test from './tests.js';
import Plex from './components/plex.js';
import SearchInput from './components/searchInput.js';

// SUPER NOVA
// This is a fast and pratical IDE and REPL for creating modeling and automation using javascript in the browser

// PRINCIPLES
// 1. RADICAL SIMPLICITY
// We aim to create this application using only vanilla javascript, no frameworks, minimal amount of css and html, this script should be 99% of the application. Like LEGO BLOCKS we should have only a few primitives that cam be composed to create more complex systems.

// 2. EXPLICIT LAYERS OF ABSTRACTIONS
// Like pages of a spreadsheet, the user should be abble to separate their entities in different layers of abstraction, the only rule is that the bottom layers does not know about upper layers, but the upper layers can acess entities in the bottom.

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
        const plex = new Plex();
        plex.render(window.document.body);
        plex.addComponent(new SearchInput());
    }
}

await init();
await test.installSchema();
console.log("schemas", await getLatestFactsByAttribute(":db/ident"));
SN.render();