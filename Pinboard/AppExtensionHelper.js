var AppExtensionClass = function () {};

AppExtensionClass.prototype = {
    run: function(arguments) {
        arguments.completionFunction({"title": document.title, "url": window.location.href });
    },
    
    finalize: function(arguments) {
        
    }
}

var ExtensionPreprocessingJS = new AppExtensionClass;