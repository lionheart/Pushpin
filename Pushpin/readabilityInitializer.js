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

var parsedXML = new XMLSerializer().serializeToString(document.body);
var doc = new JSDOMParser().parse(parsedXML);
var article = new Readability(uri, doc).parse()

