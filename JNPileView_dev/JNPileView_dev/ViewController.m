//
//  ViewController.m
//  JNPileView_dev
//
//  Created by Joao Neves on 22/11/13.
//  Copyright (c) 2013 JHNeves. All rights reserved.
//

#import "ViewController.h"
#import "JNPileView.h"

@interface ViewController () <JNPileViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    JNPileView* pv = [[JNPileView alloc] initWithFrame:self.view.bounds];
    pv.delegate = self;
    [self.view addSubview:pv];
    
    UIButton* bt = [UIButton buttonWithType:UIButtonTypeSystem];
    [bt setTitle:@"reset" forState:UIControlStateNormal];
    bt.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:.3];
    bt.showsTouchWhenHighlighted = YES;
    bt.frame = CGRectMake(0, 10, 50, 30);
    [bt addTarget:pv action:@selector(reloadData) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bt];
}


#pragma mark - JNPileViewDelegate Methods

- (NSInteger)numberOfViewsInPileView:(JNPileView *)pileView
{
    return 100;
}

- (UIView*)pileView:(JNPileView *)pileView viewForIndex:(NSInteger)index
{
    static NSArray* colors;
    if (!colors) {
        colors = @[UIColor.blueColor, UIColor.redColor,
                   UIColor.greenColor, UIColor.yellowColor,
                   UIColor.cyanColor, UIColor.magentaColor,
                   UIColor.brownColor];
    }
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
    view.backgroundColor = colors[index % 7];
    
    return view;
}

@end
