//
//  Seal.m
//  PeevedPenguins
//
//  Created by rush on 1/30/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Seal.h"

@implementation Seal

- (id)init
{
    if ((self = [super init])) {
        CCLOG(@"Seal created");
    }
    return self;
}

- (void)didLoadFromCCB
{
    NSLog(@"did load...");
    self.physicsBody.collisionType = @"seal";
}

@end
