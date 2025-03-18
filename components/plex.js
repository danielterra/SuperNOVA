import {createTag} from '../utils.js';
import { COLORS } from './theme.js';

export default class Plex {
    render(parentTag) {
        // TYPOGRAPHY
        const FONTS = {
            STANDARD: new FontFace("custom-font", "url(/fonts/Monoid-Retina.ttf)")
        }

        document.fonts.add(FONTS.STANDARD);

        for (const font in FONTS) {
            FONTS[font].load();
        }

        // Clear entire body
        parentTag.innerHTML = "";
        parentTag.style.fontFamily = FONTS.STANDARD.family;
        parentTag.style.backgroundColor = COLORS.CONTENT_BACKGROUND;
        parentTag.style.color = COLORS.CONTENT;

        const title = createTag("h1");
        title.innerText = "SUPERNOVA";
        
        this.container = createTag("div");
        this.container.style.margin = "15px 30px";
        this.container.style.display = "flex";
        this.container.style.flexDirection = "row";
        this.container.style.alignItems = "center";
        this.container.style.justifyContent = "space-between";
        parentTag.appendChild(this.container);
    }

    addComponent(component) {
        this.container.appendChild(component.render());
    }
}