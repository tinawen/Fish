//
//  FishingMyScene.m
//  Fishing
//
//  Created by tina on 8/6/13.
//  Copyright (c) 2013 tina. All rights reserved.
//

#import "FishingMyScene.h"

@interface FishingMyScene()
@property (nonatomic, strong) NSMutableArray *fishArray;
@property (nonatomic, strong) NSArray *fishSwim;
@end

@implementation FishingMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
//        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
//        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
//        
//        myLabel.text = @"Hello, World!";
//        myLabel.fontSize = 30;
//        myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
//                                       CGRectGetMidY(self.frame));
//        
//        [self addChild:myLabel];
        SKSpriteNode *backgrouund = [SKSpriteNode spriteNodeWithImageNamed:@"bg"];
        backgrouund.anchorPoint = CGPointZero;
        backgrouund.position = CGPointZero;
        backgrouund.size = self.frame.size;
        [self addChild:backgrouund];
        
        SKEmitterNode *emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"MyParticle" ofType:@"sks"]];
        emitter.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMinY(self.frame));
        [self addChild:emitter];

        NSMutableArray *fishSwimmingFrames = [NSMutableArray array];
        SKTextureAtlas *animAtlas = [SKTextureAtlas atlasNamed:@"fish"];
        for (int i = 1; i < animAtlas.textureNames.count; ++i) {
            NSString *tex = [NSString stringWithFormat:@"s%02d", i];
            [fishSwimmingFrames addObject:[animAtlas textureNamed:tex]];
        }
        _fishSwim = fishSwimmingFrames;
        _fishArray = [[NSMutableArray alloc] init];
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(generateRandomFish) userInfo:nil repeats:YES];
        
    }
    return self;
}

- (void)generateRandomFish {
    BOOL goingRight = arc4random() % 2 == 0;
    CGFloat x = goingRight ? -50 : self.frame.size.width + 50;
    int yInt = arc4random() % (int)self.frame.size.height;
    CGFloat y = (CGFloat)yInt;
    CGPoint fishLocation = CGPointMake(x, y);
    SKSpriteNode *fish = [SKSpriteNode spriteNodeWithTexture:[self.fishSwim firstObject]];
    [self.fishArray addObject:fish];
    fish.position = fishLocation;
    [self addChild:fish];
    const NSTimeInterval kFishAnimSpeed = 1 / 5.0;
    SKAction *fishSwimmingAction = [SKAction animateWithTextures:self.fishSwim timePerFrame:kFishAnimSpeed];
    SKAction *fishSwimmingForeverAction = [SKAction repeatActionForever:fishSwimmingAction];
    
    [fish runAction:fishSwimmingForeverAction];

    SKAction *fishMoveAction = goingRight ? [SKAction moveToX:self.frame.size.width + 50 duration:4] : [SKAction moveToX:-50 duration:4];
    if (!goingRight) {
        fish.zRotation = M_PI;
    }
    __weak NSMutableArray *fishArray = self.fishArray;
    [fish runAction:fishMoveAction completion:^{
        [fish removeFromParent];
        [fishArray removeObject:fish];
    }];

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
//       CGPoint location = [touch locationInNode:self];
//        
////        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
////        
////        sprite.position = location;
////        
////        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
////        
////        [sprite runAction:[SKAction repeatActionForever:action]];
////        
////        [self addChild:sprite];
//        
//    //    _fish.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
//        SKSpriteNode *fish = [SKSpriteNode spriteNodeWithTexture:[self.fishSwim firstObject]];
//        [self.fishArray addObject:fish];
//        fish.position = location;
//        [self addChild:fish];
//        const NSTimeInterval kFishAnimSpeed = 1 / 5.0;
//        SKAction *fishSwimmingAction = [SKAction animateWithTextures:self.fishSwim timePerFrame:kFishAnimSpeed];
//        SKAction *fishSwimmingForeverAction = [SKAction repeatActionForever:fishSwimmingAction];
//        
//        [fish runAction:fishSwimmingForeverAction];
//        SKAction *fishMoveAction = [SKAction moveToX:0 duration:4];
//        __weak NSMutableArray *fishArray = self.fishArray;
//        [fish runAction:fishMoveAction completion:^{
//            [fish removeFromParent];
//            [fishArray removeObject:fish];
//        }];
        [self generateRandomFish];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
