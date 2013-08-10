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

//    
//    if ([[DBAccountManager sharedManager] linkedAccount]) {
        // Create and configure the scene.
        // Configure the view.
        SKView * skView = (SKView *)self.view;
        skView.showsFPS = YES;
        skView.showsNodeCount = YES;
        SKScene * scene = [FishingMyScene sceneWithSize:skView.bounds.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        
        // Present the scene.
        [skView presentScene:scene];
//    } else {
//        [[DBAccountManager sharedManager] linkFromController:self];
//    }
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
//	if ([[DBAccountManager sharedManager] linkedAccount]) {
//        if ([self.view isKindOfClass:[SKView class]])
//            return;
//        // Configure the view.
//        SKView * skView = (SKView *)self.view;
//        skView.showsFPS = YES;
//        skView.showsNodeCount = YES;
//        // Create and configure the scene.
//        SKScene * scene = [FishingMyScene sceneWithSize:skView.bounds.size];
//        scene.scaleMode = SKSceneScaleModeAspectFill;
//        
//        // Present the scene.
//        [skView presentScene:scene];
//    }
}


- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
