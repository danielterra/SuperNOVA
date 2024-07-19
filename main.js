const {body} = window.document;
const varToString = varObj => Object.keys(varObj)[0]

class SuperNOVA {
    constructor (layers) {
        this.layers = layers || []
    }   
    addLayer = (layer) => {
        body.innerHTML = "";
        this.layers.push(layer);
        layer.render();
    }
}

class Layer {
    constructor (name, objects) {
        this.name = name;
        this.objects = objects || [];
    }
    render = () => {
        window.document.body.innerHTML = "";
        this.renderTitle();
        const container = window.document.createElement("div");
        container.className = "layer-container";
        const title = this.renderTitle()
        container.appendChild(title);
        this.objects.forEach(element => {
            const tag = element.renderThumbnail();

            container.appendChild(tag);
        });

        body.appendChild(container);
    };
    renderTitle = () => {
        const container = window.document.createElement("div");
        container.className = "title-container";

        const title = window.document.createElement("h1");
        title.innerText = this.name;

        container.appendChild(title);
        return container;
    }
    addObj = (obj) => {
        this.objects.push(obj);
        this.render()
    }
    addObjs = (objs) => {
        objs.forEach(obj => {
            this.addObj(obj)
        })
    }
}

class Entity {
    constructor(type, name, states, attrs){
        this.type = type;
        this.name = name;
        this.states = states || [];
        this.attrs = attrs;
    }
}

class State {
    constructor(name, description) {
        this.name = name;
        this.description = description;
    }
}

class Collection {
    constructor(type, name) {
        this.type = `${type} collection`;
        this.name = name;
        this.items = [];
        this.actions = [
            new Action("button", "Abrir", this.renderContainer)
        ]
    }
    addItem = (item) => {
        this.items.push(item)
    }
    renderThumbnail = () => {
        const tag = window.document.createElement("div");
        const type_tag = window.document.createElement("span");

        tag.innerHTML = this.name;
        tag.className = `object-container`;
        
        type_tag.innerHTML = this.type.toUpperCase()
        type_tag.className = "type-tag"
        
        tag.style.color = "#00d7e1";
        tag.style.backgroundColor = "#00d7e112";
        tag.appendChild(type_tag);

        const actions_container = window.document.createElement("div");
        actions_container.className = "actions-container";

        this.actions.map(ac => {
            const action_button = ac.render();
            actions_container.appendChild(action_button);
        });

        if (actions_container.childNodes.length > 0) {
            tag.appendChild(actions_container);
        }

        return tag;
    }
    renderContainer = () => {
        const container = window.document.createElement("div");
        container.classname = "collection-container";
        return container;
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
        const action_button = window.document.createElement("button");
        action_button.innerText = this.name;
        action_button.onclick = this.func;
        return action_button;
    }
}

window.onload = function coldStart() {
    const layer_zero = new Layer("LAYER ZERO");
    layer_zero.addObjs(
        [
            new Collection("person", "People")
        ]
    )

    window.superNOVA = new SuperNOVA();
    window.superNOVA.addLayer(layer_zero);
}