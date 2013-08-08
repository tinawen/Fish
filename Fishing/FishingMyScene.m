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

@interface FishingMyScene() <SKPhysicsContactDelegate>
@property (nonatomic, strong) NSMutableArray *fishArray;
@property (nonatomic, strong) NSMutableArray *fishPhysicsArray;
@property (nonatomic, strong) NSArray *fishSwim;
@property (nonatomic, strong) VSTheme *theme;
@property (nonatomic, strong) SKSpriteNode *hookLine;
@property (nonatomic, strong) SKSpriteNode *hook;
@property (nonatomic, strong) SKSpriteNode *hookPhysicsNode;
@property (nonatomic, strong) SKSpriteNode *boat;
@property (nonatomic) BOOL canHookFish;
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
        cloud.position = CGPointMake(-100, self.frame.size.height - cloud.size.height);
        cloud.anchorPoint = CGPointZero;
        [self addChild:cloud];
        SKAction *cloudMoveRightAction = [SKAction moveByX:self.frame.size.width+100 y:0 duration:5];
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
        SKPhysicsBody *hookPhysicsBody = [SKPhysicsBody bodyWithCircleOfRadius:3];
        self.hookPhysicsNode = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(4, 4)];
        self.hookPhysicsNode.position = CGPointMake(self.hook.position.x + 8, self.hook.position.y - 10);
        [self addChild:self.hookPhysicsNode];
        hookPhysicsBody.categoryBitMask = HOOK;
        hookPhysicsBody.collisionBitMask = 0;
        hookPhysicsBody.contactTestBitMask = FISHIES;
        self.hookPhysicsNode.physicsBody = hookPhysicsBody;
        self.canHookFish = YES;
        
        self.hookLine = [SKSpriteNode spriteNodeWithColor:[UIColor blackColor] size:CGSizeMake(3, 0)];
        self.hookLine.position = CGPointMake(self.boat.frame.origin.x, self.boat.frame.origin.y + self.boat.frame.size.height);
        [self addChild:self.hookLine];
        
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
//    fish.anchorPoint = CGPointMake(0, CGRectGetMidY(fish.frame));
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

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // add hook
    CGPoint hookDefaultPosition = CGPointMake(self.boat.frame.origin.x, CGRectGetMaxY(self.frame) - 50);
    self.hook.position = hookDefaultPosition;
    self.hookPhysicsNode.position = CGPointMake(self.hook.position.x + 15, self.hook.position.y - 16);
    SKAction *hookGoingDownAction = [SKAction moveByX:0 y:-1 * self.frame.size.height+50 duration:2];
    SKAction *hookGoingUpAction = [SKAction moveTo:hookDefaultPosition duration:2];
    SKAction *hookAction = [SKAction sequence:@[hookGoingDownAction, hookGoingUpAction]];
    [self.hook runAction:hookAction];
    [self.hookPhysicsNode runAction:hookAction];
    
    
    SKAction *hookLineGoingDownXAction = [SKAction moveByX:0 y:(-1 * self.frame.size.height+50)/2 duration:2];
    SKAction *hookLineGoingDownScaleAction = [SKAction resizeToHeight:self.frame.size.height - 50 duration:2];
    SKAction *hookLineGoingDownAction = [SKAction group:@[hookLineGoingDownXAction, hookLineGoingDownScaleAction]];
    SKAction *hookLineGoingUpXAction = [SKAction moveByX:0 y:(self.frame.size.height - 50) /2 duration:2];
    SKAction *hookLineGoingUpScaleAction = [SKAction resizeToHeight:0 duration:2];
    SKAction *hookLineGoingUpAction = [SKAction group:@[hookLineGoingUpXAction, hookLineGoingUpScaleAction]];
    SKAction *hookLineAction = [SKAction sequence:@[hookLineGoingDownAction, hookLineGoingUpAction]];
    [self.hookLine runAction:hookLineAction];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    if (!self.canHookFish)
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
        self.canHookFish = NO;
        CGFloat fullWidth = CGRectGetMaxY(self.frame);
        CGFloat duration = (fullWidth - self.hook.position.y) / fullWidth * 3.0;
        SKAction *hookAction = [SKAction moveTo:CGPointMake(self.boat.frame.origin.x, CGRectGetMaxY(self.frame) - 50) duration:duration];
        [fish removeAllActions];
        [self.hook removeAllActions];
        [self.hook runAction:hookAction];
        
        [self.hookPhysicsNode runAction:hookAction];
        [self.hookLine removeAllActions];
        SKAction *hookLineGoingUpXAction = [SKAction moveTo:CGPointMake(self.boat.frame.origin.x, self.boat.frame.origin.y + self.boat.frame.size.height) duration:duration];
        SKAction *hookLineGoingUpScaleAction = [SKAction resizeToHeight:0 duration:duration];
        SKAction *hookLineGoingUpAction = [SKAction group:@[hookLineGoingUpXAction, hookLineGoingUpScaleAction]];
        [self.hookLine runAction:hookLineGoingUpAction];

        
        fish.position = CGPointMake(CGRectGetMidX(self.frame), self.hookPhysicsNode.position.y - 5);
        
        CGFloat rotateAngle = 0.5 * M_PI;
        if (fish.xScale == -1) {
            rotateAngle = -0.5 * M_PI;
        }
        SKAction *followHookAction = [SKAction moveTo:CGPointMake(CGRectGetMidX(self.frame), CGRectGetMaxY(self.frame) - 65) duration:duration];
        SKAction *rotateFishAction = [SKAction rotateByAngle:rotateAngle duration:0.5];
        SKAction *fishActions = [SKAction group:@[rotateFishAction, followHookAction]];
        [fish runAction:fishActions completion:^{
            fish.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:fish.size];
            fish.physicsBody.allowsRotation = YES;
            [fish.physicsBody applyImpulse:CGPointMake(5, 20) atPoint:CGPointMake(fish.frame.origin.x, fish.frame.origin.y)];
            [fish runAction:[SKAction waitForDuration:1] completion:^{
                fish.physicsBody = NULL;
                [fish removeFromParent];
                [self.fishArray removeObject:fish];
                self.canHookFish = YES;
            }];
        }];
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
