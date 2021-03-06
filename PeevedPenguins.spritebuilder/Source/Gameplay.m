//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by rush on 1/30/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCPhysics+ObjectiveChipmunk.h"
#import "Penguin.h"
#import "Gameplay.h"

static const float MIN_SPEED = 5.f;

@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
    CCNode *_pullbackNode;
    
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    
    Penguin *_currentPenguin;
    CCPhysicsJoint *_penguinCatapultJoint;
    
    CCAction *_followPenguin;
}

// is called when CCB file has completed loading
- (void)didLoadFromCCB
{
    // tell this scene to accept touches
    self.userInteractionEnabled = YES;
    
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild:level];
    
    // visualize physics bodies & joints
//    _physicsNode.debugDraw = YES;
    
    // nothing shall collide with our invisible nodes
    _pullbackNode.physicsBody.collisionMask = @[];
    _mouseJointNode.physicsBody.collisionMask = @[];
    
    _physicsNode.collisionDelegate = self;
}

- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    // start catapult dragging when a touch inside of the catapult arm
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation)) {
        // move the mouseJointNode to the touch position
        _mouseJointNode.position = touchLocation;
        // setup a sprint joint between the mouseJointNode and the catapultArm
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(6, 132) restLength:0.f stiffness:1000.f damping:150.f];
        
        // create a penguin from the ccb-file
        _currentPenguin = (Penguin *)[CCBReader load:@"Penguin"];
        // initially position it on the scoop. 12, 138 is the position in the
        // node space of the _catapultArm
        CGPoint penguinPosition = [_catapultArm convertToWorldSpace:ccp(28, 132)];
        // transform the world position to the node space which the penguin will be added (_physicsNode)
        _currentPenguin.position = [_physicsNode convertToNodeSpace:penguinPosition];
        // add it to the physics world
        [_physicsNode addChild:_currentPenguin];
        // we don't want the penguin to rotate in the scoop
        _currentPenguin.physicsBody.allowsRotation = NO;
        
        // create a joint to keep the penguin fixed to the scoop until the catapult is released
        _penguinCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentPenguin.physicsBody bodyB:_catapultArm.physicsBody anchorA:_currentPenguin.anchorPointInPoints];
    }
}

- (void)touchMoved:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    // whenever touches move, update the position of the mouseJointNode to the touch position
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    _mouseJointNode.position = touchLocation;
}

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    // when touches end, meaning the user release their finger, release the catapult
    [self releaseCatapult];
}

- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    // when touches are cancelled, meaning the user drags their finger off the screen
    [self releaseCatapult];
}

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)nodeB
{
    float energy = [pair totalKineticEnergy];
    // if energy is large enough, remove the seal
    if (energy > 5000.f) {
        // to ensure running the code block only per key and frame
        [[_physicsNode space] addPostStepBlock:^{
            [self sealRemoved:nodeA];
        } key:nodeA];
    }
}

- (void)sealRemoved:(CCNode *)seal
{
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SealExplosion"];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = TRUE;
    // place the particle effect on the seals position
    explosion.position = seal.position;
    // add the particle effect to the same node that the seal is on
    [seal.parent addChild:explosion];
    
    [seal removeFromParent];
}

- (void)releaseCatapult
{
    if (_mouseJoint != nil) {
        // release the joint and lets the catapult snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;
        
        // after snapping rotation is fine
        _currentPenguin.physicsBody.allowsRotation = YES;
        
        // follow the flying penguin
        _followPenguin = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:_followPenguin];
        
        _currentPenguin.launched = YES;
    }
}

- (void)retry
{
    // reload this level
    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

- (void)update:(CCTime)delta
{
    if (!_currentPenguin.launched) return;
    // if speed is below minimum speed, assume this attempt is over
    if (ccpLength(_currentPenguin.physicsBody.velocity) < MIN_SPEED) {
        [self nextAttemp];
        return;
    }
    int xMin = _currentPenguin.boundingBox.origin.x;
    if (xMin < self.boundingBox.origin.x) {
        [self nextAttemp];
        return;
    }
    int xMax = xMin + _currentPenguin.boundingBox.size.width;
    if (xMax > (self.boundingBox.size.width + self.boundingBox.origin.x)) {
        [self nextAttemp];
        return;
    }
}

- (void)nextAttemp
{
    _currentPenguin = nil;
    [_contentNode stopAction:_followPenguin];
    
    CCActionMoveTo *actionMoveTo = [CCActionMoveTo actionWithDuration:1.f position:ccp(0, 0)];
    [_contentNode runAction:actionMoveTo];
}

@end
