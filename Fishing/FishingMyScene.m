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

NSUInteger WHALESCORE = 250;
NSUInteger SHARKSCORE = 25;
NSUInteger FISHSCORE = 1;

const int timeLimit = 60;
const CGFloat seaSkyPercentage = 0.8;

@interface FishingMyScene() <SKPhysicsContactDelegate>

@property (nonatomic, strong) VSTheme *theme;

// fishes
@property (nonatomic, strong) NSMutableArray *fishTypeArray;
@property (nonatomic, strong) NSMutableArray *fishArray;
@property (nonatomic, strong) NSArray *fishSwim;
@property (nonatomic, strong) NSArray *sharkSwim;
@property (nonatomic, strong) NSArray *whaleSwim;
@property (nonatomic, strong) SKSpriteNode *fishBeingCaught;

// hook
@property (nonatomic, strong) SKSpriteNode *hookLine;
@property (nonatomic, strong) SKSpriteNode *hook;
@property (nonatomic, strong) SKSpriteNode *boat;

// score
@property (nonatomic, strong) SKLabelNode *scoreLabel;
@property (nonatomic, strong) SKLabelNode *timerLabel;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic) NSUInteger score;

// special feature
@property (nonatomic, strong) SKSpriteNode *nessie;
@property (nonatomic, strong) NSString *fishermanImageName;
@property (nonatomic, strong) SKSpriteNode *fisherMan;
@property (nonatomic, strong) CIFilter *filter;
@property (nonatomic) BOOL filterAnimatingOut;

// game
@property (nonatomic) BOOL gameIsOver;
@property (nonatomic, strong) NSTimer *gameOverTimer;
@property (nonatomic, strong) NSTimer *gameTimer;

@end

@implementation FishingMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        _theme = [FishingThemeManager themeNamed:@"FishingMyScene"];

        // set up background
        SKSpriteNode *sea = [SKSpriteNode spriteNodeWithImageNamed:@"bg"];
        sea.anchorPoint = CGPointZero;
        sea.position = CGPointZero;
        sea.size = CGSizeMake(self.frame.size.width, seaSkyPercentage * self.frame.size.height);
        [self addChild:sea];
        
        SKSpriteNode *sky = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:217.0/255.0 green:239.0/255.0 blue:246.0/255.0 alpha:1.0] size:CGSizeMake(self.frame.size.width, (1.0 - seaSkyPercentage) * self.frame.size.height)];
        sky.anchorPoint = CGPointZero;
        sky.position = CGPointMake(0, seaSkyPercentage * self.frame.size.height);
        [self addChild:sky];
        
        CGFloat cloudShiftXDelta = 100;
        SKSpriteNode *cloud = [SKSpriteNode spriteNodeWithImageNamed:@"cloud"];
        cloud.position = CGPointMake(-cloudShiftXDelta, self.frame.size.height - cloud.size.height - 10); // offset cloud y a bit
        cloud.anchorPoint = CGPointZero;
        [self addChild:cloud];
        
        SKAction *cloudMoveRightAction = [SKAction moveByX:self.frame.size.width+cloudShiftXDelta y:0 duration:10];
        SKAction *cloudResetAction = [SKAction moveByX:-self.frame.size.width-cloudShiftXDelta y:0 duration:0];
        SKAction *cloudAction = [SKAction repeatActionForever:[SKAction sequence:@[cloudMoveRightAction, cloudResetAction]]];
        [cloud runAction:cloudAction];
        
        SKEmitterNode *sunEmitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Sun" ofType:@"sks"]];
        sunEmitter.position = CGPointMake(30, self.frame.size.height - 40);
        [self addChild:sunEmitter];
        
        SKSpriteNode *waves = [SKSpriteNode spriteNodeWithImageNamed:@"waves"];
        waves.size = CGSizeMake(self.frame.size.width + 100, waves.size.height);
        waves.position = CGPointMake(0, 20 + seaSkyPercentage * self.frame.size.height - waves.size.height);
        waves.anchorPoint = CGPointZero;
        [self addChild:waves];
        
        CGFloat waveYDelta = 5;
        CGFloat waveXDelta = 100;
        CGFloat waveXMovementPeriod = 10;
        SKAction *wavesMoveUpAction = [SKAction moveByX:0 y:-waveYDelta duration:waveXMovementPeriod/2];
        SKAction *wavesMoveDownAction = [SKAction moveByX:0 y:waveYDelta duration:waveXMovementPeriod/2];
        SKAction *wavesUpDownAction = [SKAction sequence:@[wavesMoveUpAction, wavesMoveDownAction]];
        SKAction *wavesMoveRightAction = [SKAction moveByX:waveXDelta y:0 duration:waveXMovementPeriod];
        SKAction *wavesMoveLeftAction = [SKAction moveByX:-waveXDelta y:0 duration:waveXMovementPeriod];
        SKAction *wavesGroupRightAction = [SKAction group:@[wavesUpDownAction, wavesMoveRightAction]];
        SKAction *wavesGroupLeftAction = [SKAction group:@[wavesUpDownAction, wavesMoveLeftAction]];
        SKAction *wavesAction = [SKAction repeatActionForever:[SKAction sequence:@[wavesGroupLeftAction, wavesGroupRightAction]]];
        [waves runAction:wavesAction];
        
        CGPoint bubblesPosition = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame));
        [self addEmitterWithFileNamed:@"Bubbles" atPosition:bubblesPosition];
        
        CGFloat fishesXDelta = 50;
        CGPoint fishLeftPosition = CGPointMake(-fishesXDelta, CGRectGetMinY(self.frame));
        [self addEmitterWithFileNamed:@"FishLeft" atPosition:fishLeftPosition];
        CGPoint fishRightPosition = CGPointMake(CGRectGetMaxX(self.frame) + fishesXDelta, CGRectGetMinY(self.frame));
        [self addEmitterWithFileNamed:@"FishRight" atPosition:fishRightPosition];
        
        CGPoint sharkLeftPosition = CGPointMake(-fishesXDelta, CGRectGetMinY(self.frame));
        [self addEmitterWithFileNamed:@"SharkLeft" atPosition:sharkLeftPosition];
        CGPoint sharkRightPosition = CGPointMake(CGRectGetMaxX(self.frame) + fishesXDelta, CGRectGetMinY(self.frame));
        [self addEmitterWithFileNamed:@"SharkRight" atPosition:sharkRightPosition];
        
        CGPoint whaleLeftPosition = CGPointMake(-fishesXDelta, CGRectGetMinY(self.frame));
        [self addEmitterWithFileNamed:@"WhaleLeft" atPosition:whaleLeftPosition];
        CGPoint whaleRightPosition = CGPointMake(CGRectGetMaxX(self.frame) + fishesXDelta, CGRectGetMinY(self.frame));
        [self addEmitterWithFileNamed:@"WhaleRight" atPosition:whaleRightPosition];
        
        // set up boat and fisherman
        _boat = [SKSpriteNode spriteNodeWithImageNamed:@"boat"];
        _boat.position = CGPointMake(self.frame.size.width - _boat.size.width, 5 + seaSkyPercentage * self.frame.size.height);
        _boat.anchorPoint = CGPointZero;
        [self addChild:_boat];
        
        _fishermanImageName = [_theme stringForKey:@"fisherman"];
        _fisherMan = [SKSpriteNode spriteNodeWithImageNamed:_fishermanImageName];
        _fisherMan.position = CGPointMake(self.frame.size.width - 0.53 * self.boat.size.width, 30 + seaSkyPercentage * self.frame.size.height);
        _fisherMan.anchorPoint = CGPointZero;
        [self addChild:_fisherMan];
        
        // set up score and timer labels and start the timer
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue"];
        _scoreLabel.fontSize = 16;
        _scoreLabel.fontColor = [SKColor blackColor];
        self.score = 0;
        _scoreLabel.position = CGPointMake(self.size.width - _scoreLabel.frame.size.width + 10, self.size.height - _scoreLabel.frame.size.height - 20);
        [self addChild:_scoreLabel];
        
        _timerLabel = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue"];
        _timerLabel.fontSize = 16;
        _timerLabel.fontColor = [SKColor blackColor];
        _startTime = [NSDate date];
        [self updateTimer];
        _timerLabel.position = CGPointMake(self.size.width - _timerLabel.frame.size.width, self.size.height - _scoreLabel.frame.size.height - _timerLabel.frame.size.height - 20);
        [self addChild:_timerLabel];
        _gameTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
        
        // set up swimming fishes
        _fishSwim = [self swimmingFramesWithAtlasNamed:@"small_fish"];
        _sharkSwim = [self swimmingFramesWithAtlasNamed:@"shark"];
        _whaleSwim = [self swimmingFramesWithAtlasNamed:@"whale"];

        _fishArray = [@[] mutableCopy];
        _fishTypeArray = [@[] mutableCopy];
        self.physicsWorld.gravity = CGPointMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        [self generateRandomFish];
        
        // set up hook and hook line
        _hook = [SKSpriteNode spriteNodeWithImageNamed:@"hook"];
        _hook.position = CGPointMake(_boat.frame.origin.x + _hook.size.width/2.0 - 5, CGRectGetMaxY(_boat.frame) - _hook.size.height - 5);
        _hook.anchorPoint = CGPointMake(0.5, 0.0);
        [self addChild:_hook];
        SKPhysicsBody *hookPhysicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(10, 10)];
        hookPhysicsBody.categoryBitMask = HOOK;
        hookPhysicsBody.collisionBitMask = BOUND;
        hookPhysicsBody.contactTestBitMask = FISHIES | BOUND;
        hookPhysicsBody.usesPreciseCollisionDetection = YES;
        _hook.physicsBody = hookPhysicsBody;
        
        _hookLine = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:CGSizeMake(2, 6)];
        _hookLine.anchorPoint = CGPointMake(0.5, 1.0);
        _hookLine.position = CGPointMake(_hook.position.x - 4.5, _hook.position.y + 3 + _hook.size.height);
        [self addChild:_hookLine];
        
        // so that hook can't go off the screen
        SKPhysicsBody *boundPhysicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, 0, self.frame.size.width, 0.88 * self.frame.size.height)];
        boundPhysicsBody.categoryBitMask = BOUND;
        boundPhysicsBody.collisionBitMask = HOOK;
        boundPhysicsBody.contactTestBitMask = HOOK;
        self.physicsBody = boundPhysicsBody;
    }
    return self;
}

#pragma mark special features
#pragma mark game over
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
    if (radius > 500) {
        [self.gameOverTimer invalidate];
        self.filter = nil;
        self.shouldEnableEffects = NO;
        self.gameIsOver = NO;
        self.startTime = [NSDate date];
        self.score = 0;
        self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
        self.timerLabel.text = [NSString stringWithFormat:@":%d", 60];
        self.timerLabel.hidden = NO;
    } else {
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
}

#pragma mark easter egg
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

#pragma mark generate random fish
- (void)generateRandomFish {
    // random fish swimming direction
    BOOL goingRight = arc4random() % 100 <= [self.theme floatForKey:@"percentComingFromLeft"];
    // random fish type
    NSUInteger fishToWhale = arc4random() % (int)[self.theme floatForKey:@"fishToWhaleFrequency"];
    // default is small fish
    NSArray *swim = self.fishSwim;
    CGFloat fishAppearingYRangePercentage = 0.75;
    CGFloat duration = 100.0/[self.theme floatForKey:@"fishSwimmingSpeed"];
    CGFloat fishMouthXOffsetRatio = 0.9;
    CGFloat fishMouthYOffsetRatio = 0.5;
    NSUInteger fishTypeNum = FISHTYPE;
    CGFloat fishMouthHitTargetRadius = [self.theme floatForKey:@"fishMouthHitTargetRadius"];
    
    if (fishToWhale == 0) {
        swim = self.whaleSwim;
        fishAppearingYRangePercentage = 0.2;
        duration = 100.0/[self.theme floatForKey:@"whaleSwimmingSpeed"];
        fishMouthXOffsetRatio = 0.93;
        fishMouthYOffsetRatio = 0.26;
        fishTypeNum = WHALETYPE;
        fishMouthHitTargetRadius = [self.theme floatForKey:@"whaleMouthHitTargetRadius"];
    } else if (fishToWhale % [self.theme integerForKey:@"fishToSharkFrequency"] == 0) {
        swim = self.sharkSwim;
        fishAppearingYRangePercentage = 0.6;
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
    
    CGFloat fishAppearingXDelta = 200;
    CGFloat x = goingRight ? -fishAppearingXDelta : self.frame.size.width + fishAppearingXDelta;
    CGFloat yOffset = [swim[0] size].height / 2;
    int yInt = arc4random() % (int)((self.frame.size.height - yOffset) * fishAppearingYRangePercentage) + yOffset;
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

    NSUInteger deltaYInterval = 20;
    CGFloat deltaY = arc4random() % deltaYInterval - deltaYInterval / 2.0;
    CGFloat deltaX = 600;
    SKAction *fishMoveAction = goingRight ? [SKAction moveByX:self.frame.size.width + deltaX y:deltaY duration:duration] : [SKAction moveByX:-1 * (self.frame.size.width + deltaX) y:deltaY duration:duration];
    if (!goingRight) {
        fish.xScale = -1;
    }
    __weak FishingMyScene *slf = self;
    [fish runAction:fishMoveAction completion:^{
        [fish removeFromParent];
        NSUInteger index = [slf.fishArray indexOfObject:fish];
        if (index != NSNotFound) {
            [slf.fishArray removeObjectAtIndex:index];
            [slf.fishTypeArray removeObjectAtIndex:index];
        }
    }];
    [NSTimer scheduledTimerWithTimeInterval:1/[self.theme floatForKey:@"fishDensity"] target:self selector:@selector(generateRandomFish) userInfo:nil repeats:NO];
    
    // enable special features if needed
    if ([self.theme floatForKey:@"shouldShowEasterEgg"] == 1 && !self.nessie) {
        [self showNessie];
    }
    if (!self.gameIsOver && [self.theme floatForKey:@"gameOver"] == 1) {
        self.gameIsOver = YES;
        [self gameOver];
    }
  
    if ([@[@"tina", @"panda", @"drew"] containsObject:[self.theme stringForKey:@"fisherman"]]) {
        [self setFishermanImageName:[self.theme stringForKey:@"fisherman"]];
    }
}

#pragma mark hook actions
- (void)dropHook {
    [self.hook removeAllActions];
    [self.hookLine removeAllActions];
    CGFloat hookMovementDeltaY = 20;
    SKAction *hookGoingDownOnceAction = [SKAction moveByX:0 y:-hookMovementDeltaY duration:1/[self.theme floatForKey:@"hookDroppingSpeed"]];
    SKAction *hookGoingDownAction = [SKAction repeatActionForever:hookGoingDownOnceAction];
    [self.hook runAction:hookGoingDownAction];
    SKAction *hookLineOnceAction = [SKAction resizeByWidth:0 height:hookMovementDeltaY duration:1/[self.theme floatForKey:@"hookDroppingSpeed"]];
    SKAction *hookLineAction = [SKAction repeatActionForever:hookLineOnceAction];
    [self.hookLine runAction:hookLineAction];
}

- (void)raiseHook {
    [self.hook removeAllActions];
    [self.hookLine removeAllActions];
    if (self.hook.position.y >= CGRectGetMaxY(self.boat.frame) - self.hook.size.height - 10) {
        return;
    }
    CGFloat hookMovementDeltaY = 20;
    SKAction *hookGoingUpOnceAction = [SKAction moveByX:0 y:hookMovementDeltaY duration:1/[self.theme floatForKey:@"hookRaisingSpeed"]];
    SKAction *hookGoingUpAction = [SKAction repeatActionForever:hookGoingUpOnceAction];
    [self.hook runAction:hookGoingUpAction];
    SKAction *hookLineOnceAction = [SKAction resizeByWidth:0 height:-hookMovementDeltaY duration:1/[self.theme floatForKey:@"hookRaisingSpeed"]];
    SKAction *hookLineAction = [SKAction repeatActionForever:hookLineOnceAction];
    [self.hookLine runAction:hookLineAction];
}

#pragma mark touch events callback
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

#pragma mark contact delegate
- (void)didBeginContact:(SKPhysicsContact *)contact {
    // hook going out of bound
    if ((contact.bodyA.node == self.scene && contact.bodyB.node == self.hook) ||
        (contact.bodyB.node == self.scene && contact.bodyA.node == self.hook)) {
        [self.hook removeAllActions];
        [self.hookLine removeAllActions];
        if (contact.contactPoint.y > 0.7 * self.frame.size.height) { // if at the top
            // reset hook and hookline positions
            self.hook.position = CGPointMake(self.boat.frame.origin.x + self.hook.size.width/2.0 - 5, CGRectGetMaxY(self.boat.frame) - self.hook.size.height - 5);
            self.hookLine.position = CGPointMake(self.hook.position.x - 4.5, self.hook.position.y + 3 + self.hook.size.height);
            self.hookLine.size = CGSizeMake(2, 6);
            
            if (self.fishBeingCaught) {
                [self.fishBeingCaught removeAllActions];
                
                // show fish thrown away animation
                SKAction *fishThrownAwayTraslateAction = [SKAction moveByX:150 y:150 duration:0.5];
                SKAction *fishThrownAwayRotateAction = [SKAction rotateByAngle:-M_PI duration:0.5];
                SKAction *fishThrownAwayAction = [SKAction group:@[fishThrownAwayTraslateAction, fishThrownAwayRotateAction]];
                __weak FishingMyScene *slf = self;
                [self.fishBeingCaught runAction:fishThrownAwayAction completion:^{
                    [slf.fishBeingCaught removeFromParent];
                    NSUInteger index = [slf.fishArray indexOfObject:slf.fishBeingCaught];
                    if (index != NSNotFound) {
                        switch ([slf.fishTypeArray[index] integerValue]) {
                            case 0: // fish
                                slf.score += FISHSCORE;
                                break;
                            case 1: // shark
                                slf.score += SHARKSCORE;
                                break;
                            case 2: // whale
                                slf.score += WHALESCORE;
                                break;
                            default:
                                break;
                        }
                        [slf.fishArray removeObjectAtIndex:index];
                        [slf.fishTypeArray removeObjectAtIndex:index];
                    }
                    slf.fishBeingCaught = nil;
                }];
            }

        }
        return;
    }
    if (self.fishBeingCaught)
        return;
    
    // check if caught a fish
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
        
        // put the fish onto the hook
        CGFloat rotateAngle = 0.5 * M_PI;
        if (fish.xScale == -1) {
            rotateAngle = -0.5 * M_PI;
        }
        // raise the hook
        SKAction *fishToHookTranslationAction = [SKAction moveTo:self.hook.position duration:0];
        SKAction *fishToHookRotationAction = [SKAction rotateByAngle:rotateAngle duration:1/[self.theme floatForKey:@"hookRaisingSpeed"]];
        SKAction *fishToHookAction = [SKAction group:@[fishToHookTranslationAction, fishToHookRotationAction]];
        SKAction *followHookOnceAction = [SKAction moveByX:0 y:20 duration:1/[self.theme floatForKey:@"hookRaisingSpeed"]];
        SKAction *followHookAction = [SKAction repeatActionForever:followHookOnceAction];
        SKAction *fishActions = [SKAction group:@[fishToHookAction, followHookAction]];
        [fish runAction:fishActions];
        
    }
}

#pragma mark private methods
- (void)addEmitterWithFileNamed:(NSString *)fileName atPosition:(CGPoint)position {
    SKEmitterNode *emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@"sks"]];
    emitter.position = position;
    [self addChild:emitter];

}

- (NSArray *)swimmingFramesWithAtlasNamed:(NSString *)atlasName {
    NSMutableArray *swimmingFrames = [@[] mutableCopy];
    SKTextureAtlas *animAtlas = [SKTextureAtlas atlasNamed:atlasName];
    for (int i = 1; i < animAtlas.textureNames.count; ++i) {
        NSString *tex = [NSString stringWithFormat:@"s%02d", i];
        [swimmingFrames addObject:[animAtlas textureNamed:tex]];
    }
    return swimmingFrames;
}

- (void)setFishermanImageName:(NSString *)fishermanImageName {
    if (![_fishermanImageName isEqualToString:fishermanImageName]) {
        _fishermanImageName = fishermanImageName;
        
        // change fisherman image with a fade out and in animation
        SKAction *oldFishermanFadeOut = [SKAction fadeOutWithDuration:0.5];
        [self.fisherMan runAction:oldFishermanFadeOut completion:^{
            [self.fisherMan removeFromParent];
            self.fisherMan = [SKSpriteNode spriteNodeWithImageNamed:fishermanImageName];
            self.fisherMan.position = CGPointMake(self.frame.size.width - 0.53 * self.boat.size.width, 30 + seaSkyPercentage * self.frame.size.height);
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
    // if only a whale is caught during the playing duration, show nessie
    if (score == WHALESCORE) {
        [self showNessie];
    }
    self.scoreLabel.text = [NSString stringWithFormat:@"%04d", self.score];
}

- (void)updateTimer {
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
    int minutes = floor(duration / 60);
    int seconds = duration - minutes * 60;
    seconds = timeLimit - seconds;
    if (seconds <= 1) { // set game duration to be a minute
        [self.gameTimer invalidate];
        self.timerLabel.hidden = YES;
        [self gameOver];
    }
    self.timerLabel.text = [NSString stringWithFormat:@":%02d", seconds];
}

@end
