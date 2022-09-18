function offsetForElement(element) {
    var el = document.getElementById(element);
    var viewportOffset = el.getBoundingClientRect();
    return viewportOffset.top;
}

function wrapTables() {
    var allTables = document.getElementsByTagName('table');
    for (var i = 0; i < allTables.length; i++) {
        var table = allTables[i];
        var overflowWrapper = document.createElement('div');
        overflowWrapper.classList.add('u-overflow-x');
        table.parentNode.insertBefore(overflowWrapper, table);
        overflowWrapper.appendChild(table);
    }
}
