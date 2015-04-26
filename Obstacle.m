//
//  Obstacle.m
//  FlappyFly
//
//  Created by Jose Aponte on 10/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Obstacle.h"

@implementation Obstacle
{
    CCNode *_topPipe;
    CCNode *_bottomPipe;
}

#define ARC4RANDOM_MAX 0x100000000

static const CGFloat minimumYPositionTopPipe = 128.f;
static const CGFloat maximunYPositionBottomPipe = 440.f;
static const CGFloat pipeDistance = 142.f;
static const CGFloat maximumYPositionTopPipe = maximunYPositionBottomPipe - pipeDistance;


-(void)didLoadFromCCB
{
    _topPipe.physicsBody.collisionType = @"obstacle";
    _topPipe.physicsBody.sensor = true;
    
    _bottomPipe.physicsBody.collisionType = @"obstacle";
    _bottomPipe.physicsBody.sensor = true;
}

-(void)setupRandomPosition
{
    CGFloat random = ((double) arc4random() / ARC4RANDOM_MAX);
    CGFloat range = maximumYPositionTopPipe - minimumYPositionTopPipe;
    _topPipe.position = ccp(_topPipe.position.x, minimumYPositionTopPipe + (random * range));
    _bottomPipe.position = ccp(_bottomPipe.position.x, _topPipe.position.y + pipeDistance);
}

@end
