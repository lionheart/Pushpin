var AppExtensionClass = function () {};

AppExtensionClass.prototype = {
    run: function(arguments) {
        arguments.completionFunction({"title": document.title, "url": window.location.href, "selection": window.getSelection().toString() });
    },
    
    finalize: function(arguments) {
        
    }
}

var ExtensionPreprocessingJS = new AppExtensionClass;