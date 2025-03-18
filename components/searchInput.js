import { createTag } from "../utils.js";
import { COLORS } from "./theme.js";

export default class SearchInput {
    render() {
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
        return searchInput;
    }
}