//
//  EditViewController.h
//  VideoBlurDemo
//
//  Created by MAXToooNG on 15/3/9.
//  Copyright (c) 2015年 Chen.Liu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRecorder.h"
#import "SCVideoPlayerView.h"
@interface EditViewController : UIViewController

@property (strong, nonatomic) SCRecordSession *recordSession;
@property (strong, nonatomic) SCSwipeableFilterView *filterSwitcherView;

- (id)initWithEditFilePath:(NSString *)filePath;

@end
