//
//  Power.m
//  FlappyFly
//
//  Created by Jose Aponte on 12/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Power.h"

@implementation Power

-(void)didLoadFromCCB
{
    self.physicsBody.collisionType = @"power";
    self.physicsBody.sensor = true;
}

-(void)setupRandomPosition
{
    
}

@end
