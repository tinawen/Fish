//
//  FishingViewController.m
//  Fishing
//
//  Created by tina on 8/6/13.
//  Copyright (c) 2013 tina. All rights reserved.
//

#import "FishingViewController.h"
#import "FishingMyScene.h"
#import <Dropbox/Dropbox.h>

@implementation FishingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    #ifdef DEBUG
    if ([[DBAccountManager sharedManager] linkedAccount]) {
    #endif
        [self presentSceneWithView];
    #ifdef DEBUG
    } else {
        [[DBAccountManager sharedManager] linkFromController:self];
    }
    #endif
}

#ifdef DEBUG
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if ([[DBAccountManager sharedManager] linkedAccount]) {
        if ([self.view isKindOfClass:[SKView class]])
            return;
        [self presentSceneWithView];
    }
}
#endif

#pragma mark private methods
- (void)presentSceneWithView {
    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    // Create and configure the scene.
    SKScene * scene = [FishingMyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
}

@end
