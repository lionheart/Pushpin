var PINBOARD_ACTIVE_ELEMENT;

function PINBOARD_CLOSEST_LINK_AT(x,y) {
    offset = 0;
    while (offset < 20) {
        e = document.elementFromPoint(x,y + offset);
        while (e) {
            if (e.nodeName == 'A')
                return e;
            e = e.parentNode;
        }
        e = document.elementFromPoint(x,y - offset);
        while (e) {
            if (e.nodeName == 'A')
                return e;
            e = e.parentNode;
        }
        offset++;
    }
    
    return null;
}