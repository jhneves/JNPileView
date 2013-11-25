//
//  JNPileView.h
//  InstaBeans
//
//  Created by Joao Neves on 20/11/13.
//  Copyright (c) 2013 JHNeves. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JNPileView;

typedef NS_ENUM(NSInteger, JNPileViewDiscardSide)
{
    JNPileViewDiscardSideLeft = -1,
    JNPileViewDiscardSideNone,
    JNPileViewDiscardSideRight
};

@protocol JNPileViewDelegate <NSObject>
@required

/// The number of the views in the pile
- (NSInteger)numberOfViewsInPileView:(JNPileView*)pileView;

/// A view for a index
- (UIView*)pileView:(JNPileView*)pileView viewForIndex:(NSInteger)index;


@optional

/// This method is called when the discard translation is crossed either inside or outside
/// If it crossed outside the view did reach the mininum value necessary to be discarded
/// This method is usefull to play a little sound indicating the boundaries for discarding has been crossed
- (void)pileView:(JNPileView*)pileview didCrossDiscardBoundaries:(BOOL)outside forView:(UIView*)view;

/// Return true to discard the view for the specified area
- (BOOL)pileView:(JNPileView*)pileview shouldDiscardView:(UIView*)view forSide:(JNPileViewDiscardSide)side;

/// Called before the discard animation starts
- (void)pileView:(JNPileView*)pileView willDiscardView:(UIView*)view forSide:(JNPileViewDiscardSide)side;

/// Called when the discard animation finishes
- (void)pileView:(JNPileView*)pileView didDiscardView:(UIView*)view forSide:(JNPileViewDiscardSide)side;

@end

@interface JNPileView : UIView

@property (nonatomic, weak) id<JNPileViewDelegate> delegate;

/// The mininum translation to discard a view
/// The default value is XX.
@property (nonatomic, assign) CGFloat discardTranslation;

/// The rotation is attenuated as the touch gets closer to the center
/// The default value is NO.
@property (nonatomic, assign) BOOL attenuatesRotationBasedOnLocationOfTouch;


/// Reload everything from scratch.
- (void)reloadData;

@end
