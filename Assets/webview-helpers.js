var PINBOARD_ACTIVE_ELEMENT;

function PINBOARD_CLOSEST_LINK_AT(x,y) {
    offset = 0;
    while (offset < 20) {
        e = document.elementFromPoint(x,y + offset);
        if (e.nodeName == 'A')
            return e;
        e = document.elementFromPoint(x,y - offset);
        if (e.nodeName == 'A')
            return e;
        offset++;
    }
    
    return null;
}