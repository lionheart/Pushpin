var hrefLength = location.href.length;
var pathLength = (location.pathname + location.search + location.hash).length;
var prePath = location.href.substring(0, hrefLength - pathLength);

var uri = {
    spec: document.location.toString(),
    host: document.location.host,
    prePath: prePath,

    // This cuts off the final colon
    scheme: location.protocol.substring(0, location.protocol.length-1),
    pathBase: prePath + "/"
};

var parsedXML = new XMLSerializer().serializeToString(document);
var doc = new JSDOMParser().parse(parsedXML);
var article = new Readability(uri, doc).parse()

var html = document.createElement("html");
var head = document.createElement("head");

var link = document.createElement("link");
link.rel = "stylesheet";
link.href = "readability.css";
head.appendChild(link);
html.appendChild(head);

var body = document.createElement("body");
body.innerHTML = article.content;

html.appendChild(body);

var readabilityElement;
var children = body.children;
var childrenToAppend = [];
for (var i=0; i<children.length; i++) {
    var child = children[i];
    if (child.id !== "readability-page-1") {
        childrenToAppend.push(child);
    } else {
        readabilityElement = child;
    }
}

for (var i=0; i<childrenToAppend.length; i++) {
    readabilityElement.appendChild(childrenToAppend[i]);
}

var htmlString = html.outerHTML;
// document.innerHTML = htmlString;
document.body.innerHTML = "";
document.body.appendChild(readabilityElement);
document.head.innerHTML = "";
document.head.appendChild(link);

