// Copyright (c) 2012 Jonathan Penn (http://cocoamanifest.net/)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


// Pull in the special function, captureLocalizedScreenshot(), that names files
// according to device, language, and orientation
#import "capture.js"

// Now, we simply drive the application! For more information, check out my
// resources on UI Automation at http://cocoamanifest.net/features

UIATarget.onAlert = function onAlert(alert){
    
    if (alert.name() != "Resetting stored URL list" && alert.name() != "Success" ){
        target.frontMostApp().alert().cancelButton().tap();
        captureLocalizedScreenshot("screen1");
        
    }
    else {
        
        return false;
    }
    
}

var target = UIATarget.localTarget();

target.delay(1.5);

//capture



//


var searchBar = target.frontMostApp().mainWindow().tableViews()[0].elements()["Search Bar"];
searchBar.tap();
searchBar.setValue('Py');
target.frontMostApp().mainWindow().elements()["Search Bar"].tapWithOptions({tapOffset:{x:0.72, y:0.80}});
target.delay(0.5);
//capture
captureLocalizedScreenshot("screen2");
target.frontMostApp().mainWindow().elements()["Search Bar"].tapWithOptions({tapOffset:{x:0.90, y:0.27}});


target.frontMostApp().mainWindow().tap();
target.delay(3.0);
//capture
captureLocalizedScreenshot("screen3");
target.frontMostApp().mainWindow().buttons()["back icon"].tap();


target.frontMostApp().mainWindow().touchAndHold(1.1);
target.frontMostApp().actionSheet().buttons()[1].tap();
target.frontMostApp().mainWindow().tableViews()[0].cells()[2].tap();
//target.frontMostApp().mainWindow().tableViews()["Empty list"].tapWithOptions({tapOffset:{x:0.30, y:0.36}});
target.frontMostApp().keyboard().typeString("app");
target.delay(1.0);
//capture
captureLocalizedScreenshot("screen4");
target.frontMostApp().navigationBar().leftButton().tap();
target.frontMostApp().navigationBar().leftButton().tap();

target.frontMostApp().navigationBar().leftButton().tap();
target.delay(1.0);
//capture
captureLocalizedScreenshot("screen5");

target.frontMostApp().navigationBar().leftButton().tap();
//target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Advanced Settings"].tap();
//target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[2].scrollToVisible();
target.frontMostApp().mainWindow().tableViews()[0].cells()["Advanced Settings"].tap();
//target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Always show add prompt, Always show the add bookmark prompt, even for URLs that Pushpin has seen before."].scrollToVisible();
target.frontMostApp().mainWindow().tableViews()[0].cells()["Reset URL"].scrollToVisible();
//target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Reset the list of stored URLs, Resets the list of URLs that you've decided not to add from the clipboard."].scrollToVisible();
target.frontMostApp().mainWindow().tableViews()[0].cells()["Reset URL"].tap();
//target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Reset the list of stored URLs, Resets the list of URLs that you've decided not to add from the clipboard."].tap();
target.delay(3.0);


