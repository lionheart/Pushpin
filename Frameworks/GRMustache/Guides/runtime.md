[up](../../../../GRMustache), [next](runtime/context_stack.md)

GRMustache runtime
==================

## Overview

`valueForKey:`, `description`, `<NSFastEnumeration>`.
  
Those are the only interfaces that you have to care about when providing data to GRMustache.

- `valueForKey:` is the standard [Key-Value Coding](http://developer.apple.com/documentation/Cocoa/Conceptual/KeyValueCoding/Articles/KeyValueCoding.html) method, that GRMustache invokes when looking for the data that will be rendered. Basically, for a `{{name}}` tag to be rendered, all you need to provide is an NSDictionary with the `@"name"` key, or an object declaring the `name` property.

- `description` is the standard [NSObject](http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Protocols/NSObject_Protocol/Reference/NSObject.html) method, that GRMustache invokes when rendering the data it has fetched from `valueForKey:`. Most classes of Apple frameworks already have sensible implementations of `description`: NSString, NSNumber, etc. You generally won't have to think a lot about it.

- `NSFastEnumeration` is the standard protocol for [enumerable objects](http://developer.apple.com/documentation/Cocoa/Conceptual/ObjectiveC/Chapters/ocFastEnumeration.html). The most obvious enumerable is NSArray. There are others, and you may provide your own. Objects that conform to the `NSFastEnumeration` protocol are the base of GRMustache loops. You'll read more on this topic in the [loops.md](runtime/loops.md) guide.

For instance, let's consider the following code:

```obcj
NSDictionary *dictionary = [NSDictionary dictionaryWithObject:@"Arthur" forKey:@"name"];
NSString *templateString = @"Hello {{name}}!";
NSString *rendering = [GRMustacheTemplate renderObject:dictionary fromString:templateString error:NULL];
```

1. When GRMustache renders the `{{name}}` tag, it invokes `valueForKey:` with the key `@"name"` on the dictionary. It gets `@"Arthur"` as a result.
2. The `description` method of NSString returns the string itself: `@"Arthur"`.
3. Hence we'll get the expected rendering: `@"Hello Arthur!"`.


## In Detail

Mustache does a little more than rendering plain `{{name}}` tags. Let's review Mustache features and how GRMustache help you leverage them.

- [context_stack.md](runtime/context_stack.md)

    This guide digs into Mustache sections such as `{{#section}}...{{/section}}`, and the key lookup mechanism.
    
- [loops.md](runtime/loops.md)
    
    Learn how to render template sections as many times as there are objects in enumerable objects such as arrays.
    
- [booleans.md](runtime/booleans.md)

    Control whether a Mustache section should render or not.
    
- [helpers.md](runtime/helpers.md)

    Mustache has "lambda sections". These are sections that allow you to execute custom code, and implement nifty features like caching, filtering, whatever, on portions of your templates.


[up](../../../../GRMustache), [next](runtime/context_stack.md)
