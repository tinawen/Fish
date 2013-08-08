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

@interface FishingMyScene() <SKPhysicsContactDelegate>
@property (nonatomic, strong) NSMutableArray *fishArray;
@property (nonatomic, strong) NSMutableArray *fishPhysicsArray;
@property (nonatomic, strong) NSArray *fishSwim;
@property (nonatomic, strong) VSTheme *theme;
@property (nonatomic, strong) SKSpriteNode *hookLine;
@property (nonatomic, strong) SKSpriteNode *hook;
@property (nonatomic, strong) SKSpriteNode *hookPhysicsNode;
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
        _fishArray = [[NSMutableArray alloc] init];
        _fishPhysicsArray = [[NSMutableArray alloc] init];
        
        self.physicsWorld.gravity = CGPointMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        [self generateRandomFish];
        
        self.hook = [SKSpriteNode spriteNodeWithImageNamed:@"hook"];
    //    self.hook.zPosition = 100;
        self.hook.position = CGPointMake(self.boat.frame.origin.x + 5, CGRectGetMaxY(self.frame) - 53);
        [self addChild:self.hook];
        SKPhysicsBody *hookPhysicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(4, 4)];
        self.hookPhysicsNode = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(4, 4)];
        self.hookPhysicsNode.position = CGPointMake(self.hook.position.x + 8, self.hook.position.y - 10);
        [self addChild:self.hookPhysicsNode];
        hookPhysicsBody.categoryBitMask = HOOK;
        hookPhysicsBody.collisionBitMask = BOUND;
        hookPhysicsBody.contactTestBitMask = FISHIES | BOUND;
        self.hookPhysicsNode.physicsBody = hookPhysicsBody;
        
        self.hookLine = [SKSpriteNode spriteNodeWithColor:[UIColor blackColor] size:CGSizeMake(3, 0)];
        self.hookLine.position = CGPointMake(self.boat.frame.origin.x, self.boat.frame.origin.y + self.boat.frame.size.height);
        [self addChild:self.hookLine];
        
        SKPhysicsBody *boundPhysicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, 0, self.frame.size.width, 0.90 * self.frame.size.height)];
        boundPhysicsBody.categoryBitMask = BOUND;
        boundPhysicsBody.collisionBitMask = HOOK;
        boundPhysicsBody.contactTestBitMask = HOOK;
        self.physicsBody = boundPhysicsBody;
    }
    return self;
}

- (void)generateRandomFish {
    BOOL goingRight = arc4random() % 2 == 0;
    CGFloat x = goingRight ? -50 : self.frame.size.width + 50;
    int yInt = arc4random() % (int)(self.frame.size.height * 0.75);
    CGFloat y = (CGFloat)yInt;
    CGPoint fishLocation = CGPointMake(x, y);
    SKSpriteNode *fish = [SKSpriteNode spriteNodeWithTexture:[self.fishSwim firstObject]];
    [self.fishArray addObject:fish];
    
    fish.position = fishLocation;
    [self addChild:fish];
    
    SKSpriteNode *fishPhysicsNode = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(4, 4)];
    if (goingRight) {
        fishPhysicsNode.position = CGPointMake(fish.position.x + 15, fish.position.y);
    } else {
        fishPhysicsNode.position = CGPointMake(fish.position.x - 15, fish.position.y);
    }
    [self addChild:fishPhysicsNode];
    fishPhysicsNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6];
    fishPhysicsNode.physicsBody.categoryBitMask = FISHIES;
    fishPhysicsNode.physicsBody.collisionBitMask = 0;
    fishPhysicsNode.physicsBody.contactTestBitMask = HOOK;
    [self.fishPhysicsArray addObject:fishPhysicsNode];
    
    const NSTimeInterval kFishAnimSpeed = 1 / 5.0;
    SKAction *fishSwimmingAction = [SKAction animateWithTextures:self.fishSwim timePerFrame:kFishAnimSpeed];
    SKAction *fishSwimmingForeverAction = [SKAction repeatActionForever:fishSwimmingAction];
    
    [fish runAction:fishSwimmingForeverAction];

    SKAction *fishMoveAction = goingRight ? [SKAction moveByX:self.frame.size.width + 100 y:0 duration:4] : [SKAction moveByX:-1 * (self.frame.size.width + 100) y:0 duration:4];
    if (!goingRight) {
        fish.xScale = -1;
    }
    __weak NSMutableArray *fishArray = self.fishArray;
    [fish runAction:fishMoveAction completion:^{
        [fish removeFromParent];
        [fishArray removeObject:fish];
    }];
    __weak NSMutableArray *fishPhysicsArray = self.fishPhysicsArray;
    [fishPhysicsNode runAction:fishMoveAction completion:^{
        [fishPhysicsNode removeFromParent];
        [fishPhysicsArray removeObject:fishPhysicsNode];
    }];
    [NSTimer scheduledTimerWithTimeInterval:[self.theme floatForKey:@"fishGenerationInterval"] target:self selector:@selector(generateRandomFish) userInfo:nil repeats:NO];
}

- (void)dropHook {
    [self.hook removeAllActions];
    [self.hookPhysicsNode removeAllActions];
    SKAction *hookGoingDownOnceAction = [SKAction moveByX:0 y:-20 duration:0.5];
    SKAction *hookGoingDownAction = [SKAction repeatActionForever:hookGoingDownOnceAction];
    [self.hook runAction:hookGoingDownAction];
    [self.hookPhysicsNode runAction:hookGoingDownAction];
}

- (void)raiseHook {
    [self.hook removeAllActions];
    [self.hookPhysicsNode removeAllActions];
    SKAction *hookGoingUpOnceAction = [SKAction moveByX:0 y:20 duration:0.5];
    SKAction *hookGoingUpAction = [SKAction repeatActionForever:hookGoingUpOnceAction];
    [self.hook runAction:hookGoingUpAction];
    [self.hookPhysicsNode runAction:hookGoingUpAction];
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
    if ((contact.bodyA.node == self.scene && contact.bodyB.node == self.hookPhysicsNode) ||
        (contact.bodyB.node == self.scene && contact.bodyA.node == self.hookPhysicsNode)) {
        [self.hook removeAllActions];
        [self.hookPhysicsNode removeAllActions];
        if (contact.contactPoint.y > 0.7 * self.frame.size.height) {
            if (self.fishBeingCaught) {
                [self.fishBeingCaught removeAllActions];

                SKAction *fishThrownAwayTraslateAction = [SKAction moveByX:100 y:100 duration:0.5];
                SKAction *fishThrownAwayRotateAction = [SKAction rotateByAngle:-M_PI duration:0.5];
                SKAction *fishThrownAwayAction = [SKAction group:@[fishThrownAwayTraslateAction, fishThrownAwayRotateAction]];
                [self.fishBeingCaught runAction:fishThrownAwayAction completion:^{
                    [self.fishBeingCaught removeFromParent];
                    NSUInteger index = [self.fishArray indexOfObject:self.fishBeingCaught];
                    if (index != NSNotFound) {
                        [self.fishArray removeObjectAtIndex:index];
                        [self.fishPhysicsArray removeObjectAtIndex:index];
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
    NSUInteger index = [self.fishPhysicsArray indexOfObject:contact.bodyA.node];
    if (index != NSNotFound) {
        fish = [self.fishArray objectAtIndex:index];
        [contact.bodyA.node removeFromParent];
        [self.fishPhysicsArray removeObject:contact.bodyA.node];
    } else {
        index = [self.fishPhysicsArray indexOfObject:contact.bodyB.node];
        if (index != NSNotFound) {
            fish = [self.fishArray objectAtIndex:index];
            [contact.bodyB.node removeFromParent];
            [self.fishPhysicsArray removeObject:contact.bodyB.node];
        }
    }
    if (fish) {
        self.fishBeingCaught = fish;
        [self raiseHook];
        
        fish.position = CGPointMake(CGRectGetMidX(self.frame), self.hookPhysicsNode.position.y - 5);
        [fish removeAllActions];
        
        CGFloat rotateAngle = 0.5 * M_PI;
        if (fish.xScale == -1) {
            rotateAngle = -0.5 * M_PI;
        }
        SKAction *followHookOnceAction = [SKAction moveByX:0 y:20 duration:0.5];
        SKAction *followHookAction = [SKAction repeatActionForever:followHookOnceAction];
        SKAction *rotateFishAction = [SKAction rotateByAngle:rotateAngle duration:0.5];
        SKAction *fishActions = [SKAction group:@[rotateFishAction, followHookAction]];
        [fish runAction:fishActions];
        
    }
}
- (void)didEndContact:(SKPhysicsContact *)contact {
    SKSpriteNode *fish = nil;
    if ([self.fishArray containsObject:contact.bodyA.node]) {
        fish = (SKSpriteNode *)contact.bodyA.node;
    } else if ([self.fishArray containsObject:contact.bodyB.node]) {
        fish = (SKSpriteNode *)contact.bodyB.node;
    }
    if (fish) {
        fish.colorBlendFactor = 0;
    }

}
@end
