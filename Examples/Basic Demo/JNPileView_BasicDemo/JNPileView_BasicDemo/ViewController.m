//
//  ViewController.m
//  JNPileView_BasicDemo
//
//  Created by Joao Neves on 14/01/14.
//  Copyright (c) 2014 JHNeves. All rights reserved.
//

#import "ViewController.h"
#import "JNPileView.h"

@import QuartzCore;

@interface ViewController () <JNPileViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /// Create the pile view
    JNPileView* pv = [[JNPileView alloc] initWithFrame:self.view.bounds];
    pv.delegate = self;
    [self.view addSubview:pv];
    
    /// Create a reset button
    UIButton* bt = [UIButton buttonWithType:UIButtonTypeSystem];
    [bt setTitle:@"reset" forState:UIControlStateNormal];
    bt.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:.3];
    bt.frame = CGRectMake(5, self.view.bounds.size.height - 35, 50, 30);
    [bt addTarget:pv action:@selector(reloadData) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bt];
}


#pragma mark - JNPileViewDelegate Methods

- (NSInteger)numberOfViewsInPileView:(JNPileView *)pileView
{
    return 20;
}

- (UIView*)pileView:(JNPileView *)pileView viewForIndex:(NSInteger)index
{
    static NSMutableArray* colors = nil;
    if (!colors) {
        colors = [@[] mutableCopy];
        [colors addObject:[UIColor colorWithRed:71.f/255 green:120.f/255 blue:234.f/255 alpha:1]]; //blue
        [colors addObject:[UIColor colorWithRed:234.f/255 green:71.f/255 blue:71.f/255 alpha:1]]; //red
        [colors addObject:[UIColor colorWithRed:71.f/255 green:234.f/255 blue:109.f/255 alpha:1]]; //green
        [colors addObject:[UIColor colorWithRed:234.f/255 green:215.f/255 blue:71.f/255 alpha:1]]; //yellow
        [colors addObject:[UIColor colorWithRed:71.f/255 green:223.f/255 blue:235.f/255 alpha:1]]; //cyan
        [colors addObject:[UIColor colorWithRed:220.f/255 green:71.f/255 blue:234.f/255 alpha:1]]; //magenta
        [colors addObject:[UIColor colorWithRed:234.f/255 green:166.f/255 blue:71.f/255 alpha:1]]; //brown
    }
    
    /// Create a view
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
    view.backgroundColor = colors[index % 7];
    view.layer.borderWidth = 4;
    view.layer.borderColor = [colors[6 - (index % 7)] CGColor];
    view.layer.cornerRadius = 5;
    
    
    /// Add a label to it
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    label.textColor = [UIColor colorWithWhite:0.15 alpha:1];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [NSString stringWithFormat:@"view #%0i", index];
    label.center = CGPointMake(view.frame.size.width / 2, view.frame.size.height / 2);
    [view addSubview:label];
    
    return view;
}

@end
