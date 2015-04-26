//
//  Goal.m
//  FlappyFly
//
//  Created by Jose Aponte on 10/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Goal.h"

@implementation Goal


-(void)didLoadFromCCB
{
    self.physicsBody.collisionType = @"goal";
    self.physicsBody.sensor = true;
}

@end
