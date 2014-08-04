function formatArticle(content) {
    var html = document.createElement("html");
    var head = document.createElement("head");
    
    var script = document.createElement("script");
    script.type = "text/javascript";
    script.innerHTML = "var isLoaded = true";

    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = "reader-base.css";

    head.appendChild(script);
    head.appendChild(link);
    html.appendChild(head);
    
    var body = document.createElement("body");
    body.innerHTML = content;
    html.appendChild(body);
    
    return html.outerHTML;
}

