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

NSInteger FISHTYPE = 0;
NSInteger SHARKTYPE = 1;
NSInteger WHALETYPE = 2;

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
@property (nonatomic, strong) SKLabelNode *scoreLabel;
@property (nonatomic, strong) SKLabelNode *timerLabel;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic) NSUInteger score;
@property (nonatomic, strong) SKSpriteNode *nessie;
@property (nonatomic, strong) CIFilter *filter;
@property (nonatomic) BOOL filterAnimatingOut;
@property (nonatomic) BOOL gameIsOver;
@property (nonatomic, strong) SKSpriteNode *sky;
@property (nonatomic, strong) NSTimer *gameOverTimer;
@property (nonatomic, strong) NSString *fishermanImageName;
@property (nonatomic, strong) SKSpriteNode *fisherMan;
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
        
        self.sky = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:217.0/255.0 green:239.0/255.0 blue:246.0/255.0 alpha:1.0] size:CGSizeMake(self.frame.size.width, 0.2 * self.frame.size.height)];
        self.sky.anchorPoint = CGPointZero;
        self.sky.position = CGPointMake(0, 0.8 * self.frame.size.height);
        [self addChild:self.sky];
        
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
        
        _fishermanImageName = [self.theme stringForKey:@"fisherman"];
        self.fisherMan = [SKSpriteNode spriteNodeWithImageNamed:_fishermanImageName];
        self.fisherMan.position = CGPointMake(self.frame.size.width - 0.53 * self.boat.size.width, 30 + 0.8 * self.frame.size.height);
        self.fisherMan.anchorPoint = CGPointZero;
        [self addChild:self.fisherMan];
        
        self.scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue"];
        self.scoreLabel.fontSize = 16;
        self.scoreLabel.fontColor = [SKColor blackColor];
        self.score = 0;
        self.scoreLabel.position = CGPointMake(self.size.width - self.scoreLabel.frame.size.width + 10, self.size.height - self.scoreLabel.frame.size.height - 20);
        //CGPointMake(CGRectGetMaxX(self.frame) - self.size.width, CGRectGetMaxY(self.frame) - self.size.height);
        [self addChild:self.scoreLabel];
        
//        self.timerLabel = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue"];
//        self.timerLabel.fontSize = 16;
//        self.timerLabel.fontColor = [SKColor blackColor];
//        self.startTime = [NSDate date];
//        [self updateTimer];
//        self.timerLabel.position = CGPointMake(self.size.width - self.timerLabel.frame.size.width + 14, self.size.height - self.scoreLabel.frame.size.height - self.timerLabel.frame.size.height - 20);
//        [self addChild:self.timerLabel];
//        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
        
        SKEmitterNode *sunEmitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Sun" ofType:@"sks"]];
        sunEmitter.position = CGPointMake(30, self.frame.size.height - 40);
        [self addChild:sunEmitter];

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
        
        SKEmitterNode *fishLeftEmitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"FishLeft" ofType:@"sks"]];
        fishLeftEmitter.position = CGPointMake(-50, CGRectGetMinY(self.frame));;
        [self addChild:fishLeftEmitter];

        SKEmitterNode *fishRightEmitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"FishRight" ofType:@"sks"]];
        fishRightEmitter.position = CGPointMake(CGRectGetMaxX(self.frame) + 50, CGRectGetMinY(self.frame));;
        [self addChild:fishRightEmitter];
        
        SKEmitterNode *sharkLeftEmitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"SharkLeft" ofType:@"sks"]];
        sharkLeftEmitter.position = CGPointMake(-50, CGRectGetMinY(self.frame));
        [self addChild:sharkLeftEmitter];
        
        SKEmitterNode *sharkRightEmitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"SharkRight" ofType:@"sks"]];
        sharkRightEmitter.position = CGPointMake(CGRectGetMaxX(self.frame) + 50, CGRectGetMinY(self.frame));
        [self addChild:sharkRightEmitter];

        SKEmitterNode *whaleLeftEmitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"WhaleLeft" ofType:@"sks"]];
        whaleLeftEmitter.position = CGPointMake(-50, CGRectGetMinY(self.frame));;
        [self addChild:whaleLeftEmitter];
        
        SKEmitterNode *whaleRightEmitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"WhaleRight" ofType:@"sks"]];
        whaleRightEmitter.position = CGPointMake(CGRectGetMaxX(self.frame) + 50, CGRectGetMinY(self.frame));
        [self addChild:whaleRightEmitter];
        
        NSMutableArray *fishSwimmingFrames = [NSMutableArray array];
        SKTextureAtlas *animAtlas = [SKTextureAtlas atlasNamed:@"small_fish"];
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
        self.hook.position = CGPointMake(self.boat.frame.origin.x + self.hook.size.width/2.0 - 5, CGRectGetMaxY(self.boat.frame) - self.hook.size.height - 5);
        self.hook.anchorPoint = CGPointMake(0.5, 0.0);
        [self addChild:self.hook];
        SKPhysicsBody *hookPhysicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(10, 10)];
        hookPhysicsBody.categoryBitMask = HOOK;
        hookPhysicsBody.collisionBitMask = BOUND;
        hookPhysicsBody.contactTestBitMask = FISHIES | BOUND;
        hookPhysicsBody.usesPreciseCollisionDetection = YES;
        self.hook.physicsBody = hookPhysicsBody;
        
        self.hookLine = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:CGSizeMake(2, 6)];
        self.hookLine.anchorPoint = CGPointMake(0.5, 1.0);
        self.hookLine.position = CGPointMake(self.hook.position.x - 4.5, self.hook.position.y + 3 + self.hook.size.height);
        [self addChild:self.hookLine];
        
        SKPhysicsBody *boundPhysicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, 0, self.frame.size.width, 0.88 * self.frame.size.height)];
        boundPhysicsBody.categoryBitMask = BOUND;
        boundPhysicsBody.collisionBitMask = HOOK;
        boundPhysicsBody.contactTestBitMask = HOOK;
        self.physicsBody = boundPhysicsBody;
    }
    return self;
}

- (void)gameOver {
    self.filter = [CIFilter filterWithName:@"CITwirlDistortion"];
    [self.filter setValue:[NSNumber numberWithFloat:0] forKey:@"inputAngle"];
    [self.filter setValue:[NSNumber numberWithFloat:250] forKey:@"inputRadius"];
    self.shouldEnableEffects = YES;
    self.shouldCenterFilter = YES;
    self.blendMode = SKBlendModeMultiply;
    
    self.filterAnimatingOut = YES;
    self.gameOverTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(gameOverAnimation) userInfo:nil repeats:YES];
    
}

- (void)gameOverAnimation {
    CGFloat angle = [[self.filter valueForKey:@"inputAngle"] floatValue];
    CGFloat radius = [[self.filter valueForKey:@"inputRadius"] floatValue];
    if (radius > 1000 || [self.theme floatForKey:@"gameOver"] == 0) {
        [self.gameOverTimer invalidate];
        self.filter = nil;
        self.shouldEnableEffects = NO;
        self.gameIsOver = NO;
        return;
    }
    
    if (angle >= 5 * M_PI) {
        self.filterAnimatingOut = NO;
    } else if (angle <= -5 * M_PI) {
        self.filterAnimatingOut = YES;
    }
    
    if (self.filterAnimatingOut) {
        angle += M_PI / 10;
        radius += 5;
    } else {
        angle -= M_PI / 10;
        radius -= 2.5;
    }
    [self.filter setValue:[NSNumber numberWithFloat:angle] forKey:@"inputAngle"];
    [self.filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputRadius"];
}
- (void)showNessie {
    self.nessie = [SKSpriteNode spriteNodeWithImageNamed:@"nessie"];
    self.nessie.alpha = 0.3;
    self.nessie.anchorPoint = CGPointZero;
    self.nessie.position = CGPointMake(-80, CGRectGetMinY(self.frame) + 20);
    [self addChild:self.nessie];
    [self updateNessie];
}

- (void)updateNessie {
    if (self.nessie.position.x > self.frame.size.width + self.nessie.size.width/2.0) {
        [self.nessie removeFromParent];
        self.nessie = nil;
        return;
    }
    NSUInteger delta = 20;
    CGFloat deltaY = arc4random() % delta - delta / 2.0;
    SKAction *nessieMoveAction = [SKAction moveByX:20 y:deltaY duration:1];
    [self.nessie runAction:nessieMoveAction];
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateNessie) userInfo:nil repeats:NO];
}

- (void)setFishermanImageName:(NSString *)fishermanImageName {
    if (![_fishermanImageName isEqualToString:fishermanImageName]) {
        _fishermanImageName = fishermanImageName;
        SKAction *oldFishermanFadeOut = [SKAction fadeOutWithDuration:0.5];
        [self.fisherMan runAction:oldFishermanFadeOut completion:^{
            [self.fisherMan removeFromParent];
            self.fisherMan = [SKSpriteNode spriteNodeWithImageNamed:fishermanImageName];
            self.fisherMan.position = CGPointMake(self.frame.size.width - 0.53 * self.boat.size.width, 30 + 0.8 * self.frame.size.height);
            self.fisherMan.anchorPoint = CGPointZero;
            self.fisherMan.alpha = 0;
            [self addChild:self.fisherMan];
            SKAction *newFishermanFadeIn = [SKAction fadeAlphaBy:1.0 duration:0.5];
            [self.fisherMan runAction:newFishermanFadeIn];
        }];
    }
}

- (void)setScore:(NSUInteger)score {
    _score = score;
    self.scoreLabel.text = [NSString stringWithFormat:@"%04d", self.score];
}

- (void)updateTimer {
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
    int minutes = floor(duration / 60);
    int seconds = round(duration - minutes * 60);
    self.timerLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
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

    NSUInteger delta = 20;
    CGFloat deltaY = arc4random() % delta - delta / 2.0;
    SKAction *fishMoveAction = goingRight ? [SKAction moveByX:self.frame.size.width + 400 y:deltaY duration:duration] : [SKAction moveByX:-1 * (self.frame.size.width + 400) y:deltaY duration:duration];
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
    
    if ([self.theme floatForKey:@"shouldShowEasterEgg"] == 1 && !self.nessie) {
        [self showNessie];
    }
    if (!self.gameIsOver && [self.theme floatForKey:@"gameOver"] == 1) {
        self.gameIsOver = YES;
        [self gameOver];
    }
  
    if ([@[@"tina", @"panda"] containsObject:[self.theme stringForKey:@"fisherman"]]) {
        [self setFishermanImageName:[self.theme stringForKey:@"fisherman"]];
    }
}

- (void)dropHook {
    [self.hook removeAllActions];
    [self.hookLine removeAllActions];
    SKAction *hookGoingDownOnceAction = [SKAction moveByX:0 y:-20 duration:1/[self.theme floatForKey:@"hookDroppingSpeed"]];
    SKAction *hookGoingDownAction = [SKAction repeatActionForever:hookGoingDownOnceAction];
    [self.hook runAction:hookGoingDownAction];
    SKAction *hookLineOnceAction = [SKAction resizeByWidth:0 height:20 duration:1/[self.theme floatForKey:@"hookDroppingSpeed"]];
    SKAction *hookLineAction = [SKAction repeatActionForever:hookLineOnceAction];
    [self.hookLine runAction:hookLineAction];
}

- (void)raiseHook {
    [self.hook removeAllActions];
    [self.hookLine removeAllActions];
    if (self.hook.position.y >= CGRectGetMaxY(self.boat.frame) - self.hook.size.height - 10) {
        return;
    }
     SKAction *hookGoingUpOnceAction = [SKAction moveByX:0 y:20 duration:1/[self.theme floatForKey:@"hookRaisingSpeed"]];
    SKAction *hookGoingUpAction = [SKAction repeatActionForever:hookGoingUpOnceAction];
    [self.hook runAction:hookGoingUpAction];
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
            self.hook.position = CGPointMake(self.boat.frame.origin.x + self.hook.size.width/2.0 - 5, CGRectGetMaxY(self.boat.frame) - self.hook.size.height - 5);
            self.hookLine.position = CGPointMake(self.hook.position.x - 4.5, self.hook.position.y + 3 + self.hook.size.height);
            self.hookLine.size = CGSizeMake(2, 6);
            if (self.fishBeingCaught) {
                [self.fishBeingCaught removeAllActions];

                SKAction *fishThrownAwayTraslateAction = [SKAction moveByX:150 y:150 duration:0.5];
                SKAction *fishThrownAwayRotateAction = [SKAction rotateByAngle:-M_PI duration:0.5];
                SKAction *fishThrownAwayAction = [SKAction group:@[fishThrownAwayTraslateAction, fishThrownAwayRotateAction]];
                [self.fishBeingCaught runAction:fishThrownAwayAction completion:^{
                    [self.fishBeingCaught removeFromParent];
                    NSUInteger index = [self.fishArray indexOfObject:self.fishBeingCaught];
                    if (index != NSNotFound) {
                        switch ([self.fishTypeArray[index] integerValue]) {
                            case 0:
                                //fish
                                self.score += 1;
                                break;
                            case 1:
                                //shark
                                self.score += 25;
                                break;
                                
                            case 2:
                                //whale
                                self.score += 250;
                                break;
                            default:
                                break;
                        }
                        NSLog(@"the caught fish is type %@", self.fishTypeArray[index]);
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
         self.fishBeingCaught = fish;
        [self raiseHook];
        [fish removeAllActions];
        
        CGFloat rotateAngle = 0.5 * M_PI;
        if (fish.xScale == -1) {
            rotateAngle = -0.5 * M_PI;
            // to offset the hook
        }
        SKAction *fishToHookTranslationAction = [SKAction moveTo:self.hook.position duration:0];
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
