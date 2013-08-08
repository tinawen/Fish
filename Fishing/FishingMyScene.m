//
//  FishingMyScene.m
//  Fishing
//
//  Created by tina on 8/6/13.
//  Copyright (c) 2013 tina. All rights reserved.
//

#import "FishingMyScene.h"

#import "FishingThemeManager.h"
#import "VSTheme.h"

const uint32_t HOOK = 0x1 << 0;
const uint32_t FISHIES = 0x1 << 1;
const uint32_t BOUND = 0x1 << 2;

NSUInteger FISHTYPE = 0;
NSUInteger SHARKTYPE = 1;
NSUInteger WHALETYPE = 2;

@interface FishingMyScene() <SKPhysicsContactDelegate>
@property (nonatomic, strong) NSMutableArray *fishTypeArray;
@property (nonatomic, strong) NSMutableArray *fishArray;
@property (nonatomic, strong) NSArray *fishSwim;
@property (nonatomic, strong) NSArray *sharkSwim;
@property (nonatomic, strong) NSArray *whaleSwim;
@property (nonatomic, strong) VSTheme *theme;
@property (nonatomic, strong) SKSpriteNode *hookLine;
@property (nonatomic, strong) SKSpriteNode *hook;
@property (nonatomic, strong) SKSpriteNode *boat;
@property (nonatomic, strong) SKSpriteNode *fishBeingCaught;
@end

@implementation FishingMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        _theme = [FishingThemeManager themeNamed:@"FishingMyScene"];

        SKSpriteNode *sea = [SKSpriteNode spriteNodeWithImageNamed:@"bg"];
        sea.anchorPoint = CGPointZero;
        sea.position = CGPointMake(0, 0);
        sea.size = CGSizeMake(self.frame.size.width, 0.8 * self.frame.size.height);
        [self addChild:sea];
        
        SKSpriteNode *sky = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:217.0/255.0 green:239.0/255.0 blue:246.0/255.0 alpha:1.0] size:CGSizeMake(self.frame.size.width, 0.2 * self.frame.size.height)];
        sky.anchorPoint = CGPointZero;
        sky.position = CGPointMake(0, 0.8 * self.frame.size.height);
        [self addChild:sky];
        
        SKSpriteNode *cloud = [SKSpriteNode spriteNodeWithImageNamed:@"cloud"];
        cloud.position = CGPointMake(-100, self.frame.size.height - cloud.size.height - 10);
        cloud.anchorPoint = CGPointZero;
        [self addChild:cloud];
        
        SKAction *cloudMoveRightAction = [SKAction moveByX:self.frame.size.width+100 y:0 duration:10];
        SKAction *cloudResetAction = [SKAction moveByX:-self.frame.size.width-100 y:0 duration:0];
        SKAction *cloudAction = [SKAction repeatActionForever:[SKAction sequence:@[cloudMoveRightAction, cloudResetAction]]];
        [cloud runAction:cloudAction];
        
        self.boat = [SKSpriteNode spriteNodeWithImageNamed:@"boat"];
        self.boat.position = CGPointMake(self.frame.size.width - self.boat.size.width, 5 + 0.8 * self.frame.size.height);
        self.boat.anchorPoint = CGPointZero;
        [self addChild:self.boat];
        
        SKSpriteNode *sun = [SKSpriteNode spriteNodeWithImageNamed:@"sun"];
        sun.position = CGPointMake(15, self.frame.size.height - 40);
        sun.anchorPoint = CGPointZero;
        [self addChild:sun];
        
        SKSpriteNode *waves = [SKSpriteNode spriteNodeWithImageNamed:@"waves"];
        waves.size = CGSizeMake(self.frame.size.width + 100, waves.size.height);
        waves.position = CGPointMake(0, 20 + 0.8 * self.frame.size.height - waves.size.height);
        waves.anchorPoint = CGPointZero;
        [self addChild:waves];
        SKAction *wavesMoveUpAction = [SKAction moveByX:0 y:-5 duration:5];
        SKAction *wavesMoveDownAction = [SKAction moveByX:0 y:5 duration:5];
        SKAction *wavesUpDownAction = [SKAction sequence:@[wavesMoveUpAction, wavesMoveDownAction]];
        SKAction *wavesMoveRightAction = [SKAction moveByX:100 y:0 duration:10];
        SKAction *wavesMoveLeftAction = [SKAction moveByX:-100 y:0 duration:10];
        SKAction *wavesGroupRightAction = [SKAction group:@[wavesUpDownAction, wavesMoveRightAction]];
        SKAction *wavesGroupLeftAction = [SKAction group:@[wavesUpDownAction, wavesMoveLeftAction]];
        SKAction *wavesAction = [SKAction repeatActionForever:[SKAction sequence:@[wavesGroupLeftAction, wavesGroupRightAction]]];
        [waves runAction:wavesAction];
        
        SKEmitterNode *emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"MyParticle" ofType:@"sks"]];
        emitter.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame));
        [self addChild:emitter];

        NSMutableArray *fishSwimmingFrames = [NSMutableArray array];
        SKTextureAtlas *animAtlas = [SKTextureAtlas atlasNamed:@"fish1"];
        for (int i = 1; i < animAtlas.textureNames.count; ++i) {
            NSString *tex = [NSString stringWithFormat:@"s%02d", i];
            [fishSwimmingFrames addObject:[animAtlas textureNamed:tex]];
        }
        _fishSwim = fishSwimmingFrames;
        
        NSMutableArray *sharkSwimmingFrames = [NSMutableArray array];
        SKTextureAtlas *sharkAnimAtlas = [SKTextureAtlas atlasNamed:@"shark"];
        for (int i = 1; i < sharkAnimAtlas.textureNames.count; ++i) {
            NSString *tex = [NSString stringWithFormat:@"s%02d", i];
            [sharkSwimmingFrames addObject:[sharkAnimAtlas textureNamed:tex]];
        }
        _sharkSwim = sharkSwimmingFrames;

        NSMutableArray *whaleSwimmingFrames = [NSMutableArray array];
        SKTextureAtlas *whaleAnimAtlas = [SKTextureAtlas atlasNamed:@"whale"];
        for (int i = 1; i < whaleAnimAtlas.textureNames.count; ++i) {
            NSString *tex = [NSString stringWithFormat:@"s%02d", i];
            [whaleSwimmingFrames addObject:[whaleAnimAtlas textureNamed:tex]];
        }
        _whaleSwim = whaleSwimmingFrames;
        
        _fishArray = [[NSMutableArray alloc] init];
        _fishTypeArray = [[NSMutableArray alloc] init];
        
        self.physicsWorld.gravity = CGPointMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        [self generateRandomFish];
        
        self.hook = [SKSpriteNode spriteNodeWithImageNamed:@"hook"];
        self.hook.position = CGPointMake(self.boat.frame.origin.x + self.hook.size.width/2.0, CGRectGetMaxY(self.boat.frame) - self.hook.size.height - 5);
        self.hook.anchorPoint = CGPointMake(0.5, 0.0);
        [self addChild:self.hook];
        SKPhysicsBody *hookPhysicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(10, 10)];
        hookPhysicsBody.categoryBitMask = HOOK;
        hookPhysicsBody.collisionBitMask = BOUND;
        hookPhysicsBody.contactTestBitMask = FISHIES | BOUND;
        hookPhysicsBody.usesPreciseCollisionDetection = YES;
        self.hook.physicsBody = hookPhysicsBody;
        
        self.hookLine = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:CGSizeMake(4, 3)];
        self.hookLine.anchorPoint = CGPointMake(0.5, 1.0);
        self.hookLine.position = CGPointMake(self.hook.position.x - 4, self.hook.position.y + self.hook.size.height);
        [self addChild:self.hookLine];
        
        SKPhysicsBody *boundPhysicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, 0, self.frame.size.width, 0.88 * self.frame.size.height)];
        boundPhysicsBody.categoryBitMask = BOUND;
        boundPhysicsBody.collisionBitMask = HOOK;
        boundPhysicsBody.contactTestBitMask = HOOK;
        self.physicsBody = boundPhysicsBody;
    }
    return self;
}

- (void)generateRandomFish {
    BOOL goingRight = arc4random() % 100 <= [self.theme floatForKey:@"percentComingFromLeft"];
    //fish type
    NSUInteger fishType = arc4random() % (int)[self.theme floatForKey:@"fishToWhaleFrequency"];
    NSArray *swim = self.fishSwim;
    CGFloat yRange = 0.75;
    CGFloat duration = 100.0/[self.theme floatForKey:@"fishSwimmingSpeed"];
    CGFloat fishMouthXOffsetRatio = 0.9;
    CGFloat fishMouthYOffsetRatio = 0.5;
    NSUInteger fishTypeNum = FISHTYPE;
    CGFloat fishMouthHitTargetRadius = [self.theme floatForKey:@"fishMouthHitTargetRadius"];
    if (fishType == 0) {
        swim = self.whaleSwim;
        yRange = 0.2;
        duration = 100.0/[self.theme floatForKey:@"whaleSwimmingSpeed"];
        fishMouthXOffsetRatio = 0.93;
        fishMouthYOffsetRatio = 0.26;
        fishTypeNum = WHALETYPE;
        fishMouthHitTargetRadius = [self.theme floatForKey:@"whaleMouthHitTargetRadius"];
    } else if (fishType % [self.theme integerForKey:@"fishToSharkFrequency"] == 0) {
        swim = self.sharkSwim;
        yRange = 0.6;
        duration = 100.0/[self.theme floatForKey:@"sharkSwimmingSpeed"];
        fishMouthXOffsetRatio = 0.97;
        fishMouthYOffsetRatio = 0.4;
        fishTypeNum = SHARKTYPE;
        fishMouthHitTargetRadius = [self.theme floatForKey:@"sharkMouthHitTargetRadius"];
    }
    SKSpriteNode *fish = [SKSpriteNode spriteNodeWithTexture:[swim firstObject]];
    [self.fishArray addObject:fish];
    [self.fishTypeArray addObject:@(fishTypeNum)];
    fish.anchorPoint = CGPointMake(fishMouthXOffsetRatio, fishMouthYOffsetRatio);
    
    CGFloat x = goingRight ? -200 : self.frame.size.width + 200;
    CGFloat yOffset = [swim[0] size].height / 2;
    int yInt = arc4random() % (int)((self.frame.size.height - yOffset) * yRange) + yOffset;
    CGFloat y = (CGFloat)yInt;
    CGPoint fishLocation = CGPointMake(x, y);
    
    fish.position = fishLocation;
    [self addChild:fish];
    
    fish.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:fishMouthHitTargetRadius];
    fish.physicsBody.categoryBitMask = FISHIES;
    fish.physicsBody.collisionBitMask = 0;
    fish.physicsBody.contactTestBitMask = HOOK;
    fish.physicsBody.usesPreciseCollisionDetection = YES;

    const NSTimeInterval kFishAnimSpeed = 1 / 5.0;
    SKAction *fishSwimmingAction = [SKAction animateWithTextures:swim timePerFrame:kFishAnimSpeed];
    SKAction *fishSwimmingForeverAction = [SKAction repeatActionForever:fishSwimmingAction];
    
    [fish runAction:fishSwimmingForeverAction];

    SKAction *fishMoveAction = goingRight ? [SKAction moveByX:self.frame.size.width + 400 y:0 duration:duration] : [SKAction moveByX:-1 * (self.frame.size.width + 400) y:0 duration:duration];
    if (!goingRight) {
        fish.xScale = -1;
    }
    __weak NSMutableArray *fishArray = self.fishArray;
    [fish runAction:fishMoveAction completion:^{
        [fish removeFromParent];
        NSUInteger index = [fishArray indexOfObject:fish];
        if (index != NSNotFound) {
            [fishArray removeObjectAtIndex:index];
            [self.fishTypeArray removeObjectAtIndex:index];
        }
    }];
    [NSTimer scheduledTimerWithTimeInterval:1/[self.theme floatForKey:@"fishDensity"] target:self selector:@selector(generateRandomFish) userInfo:nil repeats:NO];
}

- (void)dropHook {
    [self.hook removeAllActions];
     SKAction *hookGoingDownOnceAction = [SKAction moveByX:0 y:-20 duration:1/[self.theme floatForKey:@"hookDroppingSpeed"]];
    SKAction *hookGoingDownAction = [SKAction repeatActionForever:hookGoingDownOnceAction];
    [self.hook runAction:hookGoingDownAction];
    SKAction *hookLineOnceAction = [SKAction resizeByWidth:0 height:20 duration:1/[self.theme floatForKey:@"hookDroppingSpeed"]];

    SKAction *hookLineAction = [SKAction repeatActionForever:hookLineOnceAction];
    [self.hookLine runAction:hookLineAction];
}

- (void)raiseHook {
    [self.hook removeAllActions];
     SKAction *hookGoingUpOnceAction = [SKAction moveByX:0 y:20 duration:1/[self.theme floatForKey:@"hookRaisingSpeed"]];
    SKAction *hookGoingUpAction = [SKAction repeatActionForever:hookGoingUpOnceAction];
    [self.hook runAction:hookGoingUpAction];
     [self.hookLine removeAllActions];
    SKAction *hookLineOnceAction = [SKAction resizeByWidth:0 height:-20 duration:1/[self.theme floatForKey:@"hookRaisingSpeed"]];
    SKAction *hookLineAction = [SKAction repeatActionForever:hookLineOnceAction];
    [self.hookLine runAction:hookLineAction];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.fishBeingCaught)
        return;
    [self dropHook];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.fishBeingCaught)
        return;

    [self raiseHook];
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    
    // wall collision
    if ((contact.bodyA.node == self.scene && contact.bodyB.node == self.hook) ||
        (contact.bodyB.node == self.scene && contact.bodyA.node == self.hook)) {
        [self.hook removeAllActions];
        [self.hookLine removeAllActions];
        if (contact.contactPoint.y > 0.7 * self.frame.size.height) {
            self.hook.position = CGPointMake(self.boat.frame.origin.x + self.hook.size.width/2.0, CGRectGetMaxY(self.boat.frame) - self.hook.size.height - 5);
            self.hookLine.position = CGPointMake(self.hook.position.x - 4, self.hook.position.y + self.hook.size.height);
            if (self.fishBeingCaught) {
                [self.fishBeingCaught removeAllActions];

                SKAction *fishThrownAwayTraslateAction = [SKAction moveByX:150 y:150 duration:0.5];
                SKAction *fishThrownAwayRotateAction = [SKAction rotateByAngle:-M_PI duration:0.5];
                SKAction *fishThrownAwayAction = [SKAction group:@[fishThrownAwayTraslateAction, fishThrownAwayRotateAction]];
                [self.fishBeingCaught runAction:fishThrownAwayAction completion:^{
                    [self.fishBeingCaught removeFromParent];
                    NSUInteger index = [self.fishArray indexOfObject:self.fishBeingCaught];
                    if (index != NSNotFound) {
                        [self.fishArray removeObjectAtIndex:index];
                        [self.fishTypeArray removeObjectAtIndex:index];
                    }
                    self.fishBeingCaught = nil;
                }];
            }

        }
        return;
    }
    if (self.fishBeingCaught)
        return;
    
    SKSpriteNode *fish = nil;
    if ([self.fishArray containsObject:contact.bodyA.node]) {
        fish = (SKSpriteNode *)contact.bodyA.node;
    } else if ([self.fishArray containsObject:contact.bodyB.node]) {
        fish = (SKSpriteNode *)contact.bodyB.node;
    }
    if (fish) {
        CGFloat deltaX = self.hook.size.width / 2.0;
         self.fishBeingCaught = fish;
        [self raiseHook];
        
        [fish removeAllActions];
        
        CGFloat rotateAngle = 0.5 * M_PI;
        if (fish.xScale == -1) {
            rotateAngle = -0.5 * M_PI;
            // to offset the hook
            deltaX = -self.hook.size.width / 2.0;
        }
        SKAction *fishToHookTranslationAction = [SKAction moveByX:deltaX y:0 duration:1/[self.theme floatForKey:@"hookRaisingSpeed"]];
        SKAction *fishToHookRotationAction = [SKAction rotateByAngle:rotateAngle duration:1/[self.theme floatForKey:@"hookRaisingSpeed"]];
        SKAction *fishToHookAction = [SKAction group:@[fishToHookTranslationAction, fishToHookRotationAction]];
        SKAction *followHookOnceAction = [SKAction moveByX:0 y:20 duration:1/[self.theme floatForKey:@"hookRaisingSpeed"]];
        SKAction *followHookAction = [SKAction repeatActionForever:followHookOnceAction];
        SKAction *fishActions = [SKAction group:@[fishToHookAction, followHookAction]];
        [fish runAction:fishActions];
        
    }
}
- (void)didEndContact:(SKPhysicsContact *)contact {

}
@end
