//
//  BloomFilter.m
//  BloomFilter
//
//  Created by Ryan on 6/4/13.
//  Copyright (c) 2013 Pickmoto. All rights reserved.
//

#import "BloomFilter.h"
#import "HashFunctions.h"

@interface BloomFilter ()
@property(assign, nonatomic) NSInteger numBits;
@property(assign, nonatomic) NSInteger numHashes;
@end

@implementation BloomFilter

- (id)initWithNumberOfBits:(NSInteger)bits andWithNumberOfHashes:(NSInteger)hashes {
    self = [super init];
    if(self) {
        self.numBits = bits;
        self.numHashes = hashes;
        self.bitvector = CFBitVectorCreateMutable(NULL, 0);
        CFBitVectorSetAllBits(self.bitvector, 0);
    }
    
    return self;
}

-(void)addToSet:(NSString *)word {
    
    // Initialize the vector
    if(CFBitVectorGetCount(self.bitvector) == 0) {
        CFBitVectorSetCount(self.bitvector, self.numBits);
    }
    
    [self hash:word];
}

-(BOOL)lookup:(NSString *)word {
    const char* str = [word UTF8String];
    int len = [word length];

    // Each hash value should provide an index into the bit array
    // Lookup and see if each bit is set. If so, then the word is in the set.
    
    BOOL foundWord = YES;
    uint32_t lastHash = MurmurHash2(str, len, 0);
    for(NSInteger hashCnt = 0; hashCnt < self.numHashes; hashCnt++) {
        
        // Check if the bit is set at the index array (lastHash % self.numBits)
        foundWord = foundWord && CFBitVectorGetBitAtIndex(self.bitvector, (lastHash % self.numBits));
        
        // If not, break immediately
        if(!foundWord) {
            break;
        } else {        
            // Hash the previous hash to get a new index
            lastHash = MurmurHash2(str, len, lastHash);
        }
    }
    
    return foundWord;
}

- (void)hash:(NSString *)word {
    const char* str = [word UTF8String];
    int len = [word length];
    
    // Each hash value should provide an index into the bit array
    // Set the bit for each array index that is created for each hash value
    
    uint32_t lastHash = MurmurHash2(str, len, 0);
    for(NSInteger hashCnt = 0; hashCnt < self.numHashes; hashCnt++) {
        
        // Check if the bit is set at the index array (lastHash % self.numBits)
        CFBitVectorSetBitAtIndex(self.bitvector, (lastHash % self.numBits), 1);
        
        // Hash the previous hash to get a new index
        lastHash = MurmurHash2(str, len, lastHash);
    }
}

@end
