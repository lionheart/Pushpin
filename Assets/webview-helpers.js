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

function colorToHex(color) {
    if (color.substr(0, 1) === '#') {
        return color;
    }
    var digits = /(.*?)rgb\((\d+), (\d+), (\d+)\)/.exec(color);
    
    var red = parseInt(digits[2]);
    var green = parseInt(digits[3]);
    var blue = parseInt(digits[4]);
    
    var rgb = blue | (green << 8) | (red << 16);
    return digits[1] + '#' + rgb.toString(16);
};