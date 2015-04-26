//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "Obstacle.h"
#import "Goal.h"
#import "Power.h"

static const CGFloat firstObstaclePosition = 280.f;
static const CGFloat distanceBetweenObstacles = 160.f;
static const CGFloat MAX_TIME_TO_POWER_ON = 5.f;
static const CGFloat NORMAL_SPEED = 80.f;
static const CGFloat MAX_SPEED_POWER = 600.f;

typedef NS_ENUM(NSInteger, DrawingOrder)
{
    DrawingOrderPipes,
    DrawingOrderGrounds,
    DrawingOrderHero
};

@implementation MainScene
{
    CCSprite *_hero;
    CCPhysicsNode *_physicsNode;
    CCNode *_ground1;
    CCNode *_ground2;
    
    NSArray *_grounds;
    
    NSTimeInterval _sinceTouch;
    
    NSMutableArray *_obstacles;
    
    CCButton *_restartButton;
    
    BOOL _gameOver;
    CGFloat _scrollSpeed;
    
    NSInteger _points;
    CCLabelTTF *_scoreLabel;
    
    OALSimpleAudio *_audio;
    
    BOOL powerOn;
    CGFloat _timePowerOn;
}

-(void)didLoadFromCCB
{
    _physicsNode.collisionDelegate = self;
    
    self.userInteractionEnabled = YES;
    
    _audio = [OALSimpleAudio sharedInstance];
    [_audio preloadEffect:@"hit_hero.wav"];
    [_audio preloadEffect:@"goal.wav"];
    
    _scrollSpeed = 80.f;
    
    _grounds = @[_ground1, _ground2];
    
    for (CCNode *ground in _grounds)
    {
        ground.physicsBody.collisionType = @"level";
        ground.zOrder = DrawingOrderGrounds;
    }
    
    _hero.physicsBody.collisionType = @"hero";
    _hero.zOrder = DrawingOrderHero;
    
    _obstacles = [NSMutableArray array];
    [self spawnNewObstacles];
    [self spawnNewObstacles];
    [self spawnNewObstacles];
    


}

-(void)update:(CCTime)delta
{
    _hero.position = ccp(_hero.position.x + delta * _scrollSpeed, _hero.position.y);
    _physicsNode.position = ccp(_physicsNode.position.x + delta - (_scrollSpeed * delta), _physicsNode.position.y);
    
    for (CCNode *ground in _grounds)
    {
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:ground.position];
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        
        if (groundScreenPosition.x <= (ground.contentSize.width * -1))
        {
            ground.position = ccp(ground.position.x + 2 * ground.contentSize.width, ground.position.y);
        }
    }
    
    float yVelocity = clampf(_hero.physicsBody.velocity.y, -1 * MAXFLOAT, 200.f);
    _hero.physicsBody.velocity = ccp(0, yVelocity);
    
    _sinceTouch += delta;
    _hero.rotation = clampf(_hero.rotation, -30.f, 90.f);
    if (_hero.physicsBody.allowsRotation)
    {
        float angularVelocity = clampf(_hero.physicsBody.angularVelocity, -2.f, 1.f);
        _hero.physicsBody.angularVelocity = angularVelocity;
    }
    if (_sinceTouch > 0.5f)
    {
        [_hero.physicsBody applyAngularImpulse:-40000.f * delta];
    }
    
    NSMutableArray *offScreenObstacles = nil;
    
    for (CCNode *obstacle in _obstacles)
    {
        CGPoint obstacleWorlPosition = [_physicsNode convertToWorldSpace:obstacle.position];
        CGPoint obstacleScreenPosition = [self convertToNodeSpace:obstacleWorlPosition];
        if (obstacleScreenPosition.x < -obstacle.contentSize.width)
        {
            if (!offScreenObstacles)
            {
                offScreenObstacles = [NSMutableArray array];
            }
            [offScreenObstacles addObject:obstacle];
        }
    }
    
    for (CCNode *obstacleToRemove in offScreenObstacles)
    {
        [obstacleToRemove removeFromParent];
        [_obstacles removeObject:obstacleToRemove];
        
        [self spawnNewObstacles];
    }
    
    [self checkStatusPower:delta];
    
}

#pragma mark - Thouc Methods
-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!_gameOver)
    {
        [_hero.physicsBody applyImpulse:CGPointMake(0, 400.f)];
        [_hero.physicsBody applyAngularImpulse:10000.f];
        _sinceTouch = 0.f;
    }
}


#pragma mark - Logical Methods
-(void)spawnNewObstacles
{
    CCNode *previewsObstacle = [_obstacles lastObject];
    CGFloat previewsObstaclesXPosition = previewsObstacle.position.x;
    
    if (!previewsObstacle)
    {
        previewsObstaclesXPosition = firstObstaclePosition;
    }
    
    Obstacle *obstacle = (Obstacle*)[CCBReader load:@"Obstacle"];
    obstacle.position = ccp(previewsObstaclesXPosition + distanceBetweenObstacles, 0);
    obstacle.zOrder = DrawingOrderPipes;
    [obstacle setupRandomPosition];
    
    [_physicsNode addChild:obstacle];
    [_obstacles addObject:obstacle];

    
    Power *power = (Power*)[CCBReader load:@"Power"];
    power.position = ccp(previewsObstaclesXPosition + distanceBetweenObstacles, 393);
    power.zOrder = 5;
    [_physicsNode addChild:power];
    
    CCLOG(@"x coord: %f",(previewsObstaclesXPosition + distanceBetweenObstacles));

    
}

-(void)gameOver
{
    if (!_gameOver)
    {
        _scrollSpeed = 0.f;
        _gameOver = true;
        _restartButton.visible = true;
        _hero.rotation = 90.f;
        _hero.physicsBody.allowsRotation = false;
        _hero.physicsBody.collisionType = @"none";
        [_hero stopAllActions];
        [_hero.animationManager setPaused:true];
        
        
        CCActionMoveBy *moveBy = [CCActionMoveBy actionWithDuration:0.2f position:ccp(-2, 2)];
        CCActionInterval *reverseMovement = [moveBy reverse];
        CCActionSequence *shakeSecuence = [CCActionSequence actionWithArray:@[moveBy, reverseMovement]];
        CCActionEaseBounce *bounce = [CCActionEaseBounce actionWithAction:shakeSecuence];
        [self runAction:bounce];
    }
}


-(void)checkStatusPower:(CCTime)delta
{
    if (powerOn)
    {
        _timePowerOn += delta;
        if (_timePowerOn >= MAX_TIME_TO_POWER_ON)
        {
            powerOn = false;
            _hero.physicsBody.collisionType = @"hero";
            _scrollSpeed = NORMAL_SPEED;
            _timePowerOn = 0.f;
        }
    }
}

#pragma mark - Collision Methos
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)nodeA level:(CCNode *)nodeB
{
    [_audio playEffect:@"hit_hero.wav"];
    [self gameOver];
    return true;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)nodeA obstacle:(CCNode *)nodeB
{
    [_audio playEffect:@"hit_hero.wav"];
    [self gameOver];
    return true;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero goal:(CCNode *)goal
{
    [_audio playEffect:@"goal.wav"];
    [goal removeFromParent];
    _points++;
    _scoreLabel.string = [NSString stringWithFormat:@"%d",_points];
    return  true;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero power:(CCNode *)nodeB
{
    powerOn = YES;
    hero.physicsBody.collisionType = @"heroPowerOn";
    _scrollSpeed = MAX_SPEED_POWER;
    return true;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair heroPowerOn:(CCNode *)hero goal:(CCNode *)goal
{
    [_audio playEffect:@"goal.wav"];
    [goal removeFromParent];
    _points++;
    _scoreLabel.string = [NSString stringWithFormat:@"%d",_points];
    return  true;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair heroPowerOn:(CCNode *)hero level:(CCNode *)level
{
    powerOn = false;
    _hero.physicsBody.collisionType = @"hero";
    _scrollSpeed = NORMAL_SPEED;
    _timePowerOn = 0.f;
    
    [_audio playEffect:@"hit_hero.wav"];
    [self gameOver];
    return true;
}

#pragma mark - Action Buttons Methods
-(void)restart
{
    _hero.physicsBody.collisionType = @"hero";
    _restartButton.visible = false;
    CCScene *scene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:scene];
}




@end
