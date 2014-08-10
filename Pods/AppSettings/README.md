AppSettings
===========

`AppSettings` is a simple tool that allows automatic serialization and deserialization of objects to `NSDictionary` with writing and reading them from `NSUserDefaults`. Originally created to simply manage app settings in `NSUserDefaults`.

Abstract
--------

When you want to persist your custom object to e.g. `NSUserDefaults` you have to serialize it using `NSCoding` and `NSKeyedArchiver`. It's not hard but it's time consuming and Xcode does not make it easier by generating some kind of default encoding and decoding method stubs. It becomes real pain in the ass when you have to manually serialize all properties.

On the other hand it is very convenient to have a model object for your app settings instead of just writing values for keys in `NSUserDefaults`. Your can use code completion, compiler warns you when you make a typo and you don't have to remember all the strings for keys in your custom dictionary.

So why not to write a serializer that converts your custom object with properties to `NSDictionary` and saves it under key of your class name? `AppSettings` does exactly that! :)

How to use it?
--------------

All you have to do is to create your own class that inherits from `AppSettings`.
Fields you want to save have to be declared as properties (`@property`) in your `.h` file, just like in any other object.
When you are done and your object is ready you call `save` to persist your object.
When you want to load your previously saved object you call `- (id)load` which returns instance of `AppSettings` subclass.
That's it! :)

Example usage:
--------------

* Declare your custom settings class, that inherits from `AppSettings`

```objective-c
#import "AppSettings.h"
#import "MyNestedSettings.h"

@interface MySettings : AppSettings

@property (nonatomic, strong) NSDate *exampleDate;
@property (nonatomic, strong) NSString *exampleString;
@property (nonatomic, strong) NSNumber *exampleNumber;
@property (nonatomic, assign) int exampleInt;
@property (nonatomic, assign) BOOL exampleBool;

@end
```

* Create instance of your class and set some values

```objective-c
MySettings *mySettings = [[MySettings alloc] init];
mySettings.exampleDate = [NSDate date];
```

* Save it when your're done

```objective-c
[mySettings save];
```

* Load it next time you launch your app

```objective-c
MySettings *mySettings = [MySettings load];
```

Your settings are saved under `MySettings` key and look similar to this:
```
    MySettings =     {
        exampleBool = 1;
        exampleDate = "2013-12-08 11:26:56 +0000";
        exampleInt = 456;
        exampleNumber = 123;
        exampleString = "Example string \U0105\U0119\U015b\U0107";
    };
```

Additional methods
------------------

You can play with other methods that are implemented in `AppSettings` class:

```objective-c
- (id)initWithDictionary:(NSDictionary*)dictionaryOfPropertiesAndValues;

- (NSArray*)propertiesNames;
- (NSDictionary*)dictionaryOfPropertiesAndValues;

- (BOOL)save;
- (BOOL)saveUnderKey:(NSString*)mainKey;

+ (id)load;
+ (id)loadFromKey:(NSString*)mainKey;
```

You can e.g. extract dictionary of properties and values and handle it by yourself or save your settings under different key.

You can also see the `AppSettingsTests.m` file to see each method in action.

Nested objects
--------------

Yes, you can have nested objects. Just declare them also as subclasses of `AppSettings` and use as properties in your main settings class. See `MySettings.h` and `MyNestedSettings.h` files in test section.

```objective-c
#import "AppSettings.h"
#import "MyNestedSettings.h"

@interface MySettings : AppSettings

@property (nonatomic, strong) NSDate *exampleDate;
@property (nonatomic, strong) NSString *exampleString;
@property (nonatomic, strong) NSNumber *exampleNumber;
@property (nonatomic, assign) int exampleInt;
@property (nonatomic, assign) BOOL exampleBool;

@property (nonatomic, strong) MyNestedSettings *myNestedSettings;

@end
```

```objective-c
#import "AppSettings.h"

@interface MyNestedSettings : AppSettings

@property (nonatomic, strong) NSString *nestedSettingsString;

@end
```

Your saved settings with nested objects now look similar to this:
```
    MySettings =     {
        exampleBool = 1;
        exampleDate = "2013-12-08 11:26:56 +0000";
        exampleInt = 456;
        exampleNumber = 123;
        exampleString = "Example string \U0105\U0119\U015b\U0107";
        myNestedSettings =         {
            nestedSettingsString = "nested example string";
        };
    };
```

Answering some questions
------------------------

* Yes, it uses `<objc/runtime.h>` to extract information about properties and `KVC` to set and get values for them.
* If you don't like to read the license: Yes, you can use it to do whatever you want, personally and commercially without fee, but you cannot use it to destroy the world! ;)

License
-------
`AppSettings` is available under the MIT license. See the LICENSE file for more info.

