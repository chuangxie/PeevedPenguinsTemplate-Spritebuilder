//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by rush on 1/30/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Gameplay.h"

@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_caltapultArm;
    CCNode *_levelNode;
}

// is called when CCB file has completed loading
- (void)didLoadFromCCB
{
    // tell this scene to accept touches
    self.userInteractionEnabled = YES;
    
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild:level];
}

- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [self launchPenguin];
}

- (void)launchPenguin
{
    // loads the Penguin.ccb we have set up in Spritebuilder
    CCNode *penguin = [CCBReader load:@"Penguin"];
    // position the penguin at the bowl of the catapult
    penguin.position = ccpAdd(_caltapultArm.position, ccp(16, 50));
    
    // add the penguin to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:penguin];
    
    // manually create & apply a force to launch the penguin
    CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [penguin.physicsBody applyForce:force];
}

@end
