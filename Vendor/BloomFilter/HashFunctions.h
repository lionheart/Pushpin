//
//  HashFunctions.h
//  BloomFilter
//
//  Created by Ryan on 6/4/13.
//  Copyright (c) 2013 Pickmoto. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HashFunctions : NSObject

uint32_t MurmurHash2( const void * key, int len, unsigned int seed );

@end
