const log = (str) => console.log(str);

// The core classes for the ontology goes here, everything else can be loaded as needed
class Icon {
    constructor(label, icon_url) {
        this._label = label;
        this._img = new Image();
        this._img.src = icon_url;
    }
    
    get image() {
        return this._img;
    }
}

// That's a thing
class Entity {
    constructor(label, icon) {
        this._label = label;
        this._icon = icon;
        this._props = [];
    }
    
    get label() {
        return this._label;
    }
    
    render = (ctx,layout, x, y) => {
        this._icon.image ? ctx.drawImage(this._icon.image,x,y,layout.height,layout.height): null;
        ctx.fillStyle = layout.textColor;
        ctx.font = `${layout.height/2}px Helvetica`;
        ctx.fillText(this._label,x+layout.height + 20,y+layout.height/2)
    }
}

// This controls all the rendering and positioning
class SuperNova {
    constructor() {
        // All of the visual features goes here
        this._LAYOUT = {
            textColor: "#ffffff",
            actionColor: "#ff610033",
            height: 25
        }
        // All the rendered entities
        this._layers = [];
        this._selectedLayer = 0;
        
        // Build and bind HTML Canvas
        this._canvas = document.createElement("canvas");
        this._canvas.width = window.innerWidth;
        this._canvas.height = window.innerHeight;
        document.body.appendChild(this._canvas);
        this._ctx = this._canvas.getContext("2d");

        this._attachCmd = () => {
            // Build and bind the CMD
            this._LAYOUT.cmd = {
                position: "fixed",
                bottom: 10,
                width: 300,
                left: window.innerWidth / 2 - 150,
                border: `1px solid ${this._LAYOUT.actionColor}`,
                color: this._LAYOUT.textColor,
                padding: "5px 10px",
                fontFamily: "monospace",
                textAlign: "center",
                background: "transparent",
                borderRadius: "6px"
            }

            const cmd = document.createElement("input");
            cmd.style.position = this._LAYOUT.cmd.position;
            cmd.style.bottom = this._LAYOUT.cmd.bottom + "px";
            cmd.style.width = this._LAYOUT.cmd.width + "px";
            cmd.style.left = this._LAYOUT.cmd.left + "px";
            cmd.style.border = this._LAYOUT.cmd.border;
            cmd.style.color = this._LAYOUT.cmd.color;
            cmd.style.padding = this._LAYOUT.cmd.padding;
            cmd.style.fontFamily = this._LAYOUT.cmd.fontFamily;
            cmd.style.textAlign = this._LAYOUT.cmd.textAlign;
            cmd.style.background = this._LAYOUT.cmd.background;
            cmd.style.borderRadius = this._LAYOUT.cmd.borderRadius;
            cmd.onchange = this.handleCmd;
            document.body.appendChild(cmd);
            cmd.focus();
        }
        
        // Render loop, UI does not need to update more ofter than the frames per second, we can increase and reduce to control power consumption and performance
        this._interval = setInterval(this.render, 33);
        this._center = {
            x: 0,
            y: this._canvas.height/2
        }
        // TODO: on resize calculate the center again

        window.onload = () => {
            this._attachCmd();
        };
    }
    
    addEntity = (entity, layer) => {
        // find the layer
        let currentLayer = this._layers.find(l => l.name === layer);
        if (!currentLayer) {
            currentLayer = {
                name: layer,
                entities: []
            }

            this._layers.push(currentLayer);
        }

        const offset = currentLayer.entities.length * (this._LAYOUT.height + this._LAYOUT.height/2);
        
        const coord = {
            x: this._center.x,
            y: this._center.y + offset,
            ent: entity
        }
        currentLayer.entities.push(coord);
    }

    // Handle commands
    handleCmd = async (e) => {
        e.preventDefault();
        const value = e.target.value;
        switch (value) {
            case "r":
                this._layers[0].entities.forEach((e, i) => {
                    e.x = 0;
                    e.y = 0 + (50 * i)
                });
                break;
            case "si":
                // Where i define what can be called here?
                const filehandles = await showOpenFilePicker();
                log(filehandles);
                filehandles.forEach(async f => {
                    const file = await f.getFile();
                    const r = await file.text();
                    debugger;
                    const buffer = await file.text();
                    this.addEntity(new Entity(file.name, new Icon("file", `data:image/png;base64,${buffer}`)));
                })
                break;
        
            default:
                log(`no cmd found for ${value}`)
                break;
        }

        e.target.value = "";
    }

    render = () => {
        const selectedLayer = this._layers[this._selectedLayer];
        log(new Date().toISOString());

        if (selectedLayer.entities.length === 0) {
            // there is no point
            return;
        }
        
        // clear canvas
        this._ctx.clearRect(0,0,this._canvas.width,this._canvas.height)

        // render the selected layer
        selectedLayer.entities.forEach((coord) => {
            coord.x = coord.x + Math.random();
            coord.y = coord.y + Math.random();
            coord.ent.render(this._ctx, this._LAYOUT, coord.x, coord.y); 
        });
    }
}


const computerIcon = new Icon("computer", "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAAAb1BMVEUAAAD///+rq6uenp7FxcXe3t7Z2dk2Njavr6/V1dV+fn5bW1tpaWmampp3d3eGhoaNjY28vLw7OzvNzc3y8vKlpaW2trYRERH4+PgmJibq6urk5ORAQEAeHh5JSUlUVFRubm4xMTEXFxdgYGCKiopvhDdyAAADp0lEQVR4nO3c6XqiQBCFYSWKuMdBFPcluf9rnCyenvgkaOiuaaqS8/4WrE9Ni0Jsta4sV6ft/jB8Go1GkxeDZxh/LdEn67WqnbN5277yWF3YaXo4IYPKwrTp0YQ8sNA8FtrHQvu+X9gxwrdwfqi8oTL7tVdh/xxxxkDn1KdwHHHCYIlPYfXNFMpYeMFCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhcBCvVgILNSLhXBVmEQcMJhXYRZxwGAsBBbqxUJgoV4sBBbqxUJgoV4sBBbqxUKwW7j48YUzn0JT39N4FS4iDhjMq3AWccBgLAQW6sVCYKFeXoWdiAMGy1l4wUK9WAi/rDCPOGCwlIVf3c5UYdensB9xwGBrn8I04oDBvAq7EQcM5lW4iThgMK/CecQBg819CtsRBwy18yvcRhwx0L7tVWjoI3DmV9jumtH2LDSLhfax0D4W2sdC+8aVhYf1/a0NSJaVha3WcZwsOi/yV/1ahB+dtNadv82bvww+K6b7G31BxqKBGj+dChfeeqU1hIUsZGHzWFizMPr8u+ngtklHtLC8d3+DoXDhH9H5JUh/FaivUPocNQvjkz6Dy8L4fn6h9DlqfYXS56j1FUqfo9ZXuGah+cKShTX1mg76RLrw0HTQJ8KFk7LpoM8kPz4tcbF/OT31mnba4/TKWuxD8GFz2WWu5BKbBzyN1adgannE/vT8+tcQ10Dlp/Cd7XAJ9Vz6i5EQS3wrVE5Cd3XEEjNT9vXewA12DtpP4ZYYocHkbLHgbA7+OzlhJ6mSJeYaHv72o+8enrGHQnIuQW7BSXs+m+/wx7weSU8mxs1YDupvPMRZ69lKfjI5Uyw4i7oroXtT1bfEXNvi0st1rQWn59YplUvMtcTjCMc99TZ+OeIJf1D97y447jj7+D/nErSqd4TjHpFU4JgvFnfs/I0Fx72qbbxCwV3Otblz+Lzd1Hq+FXFvjbcXHHc42zX0CgV3mj2vfAdf/TtR3UmSohi/enw3vZh8dBx97WnoqWJ/o6t7xSjP75O9TflQFEnh/nGm8gXojmTtY6F9LLSPhfb92sLs/pZWVBQu7m9pBQvtY6F9v7Zwdn9LKyoKJ1nyQ3z8ddm/RHN2PwmZ2WwAAAAASUVORK5CYII=");

const superNova = new SuperNova();

superNova.addEntity(new Entity("your machine", computerIcon), "physical");
superNova.addEntity(new Entity("other machine", computerIcon), "physical");
superNova.addEntity(new Entity("other machine", computerIcon), "physical");
superNova.addEntity(new Entity("other machine", computerIcon), "physical");
superNova.addEntity(new Entity("other machine", computerIcon), "physical");
superNova.addEntity(new Entity("other machine", computerIcon), "physical");