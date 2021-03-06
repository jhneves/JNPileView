//
//  JNPileView.h
//
//  Created by Joao Neves on 20/11/13.
//  Copyright (c) 2013 JHNeves. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JNPileView;

typedef NS_ENUM(NSInteger, JNPileViewDiscardSide)
{
    JNPileViewDiscardSideNone,
    JNPileViewDiscardSideLeft,
    JNPileViewDiscardSideRight
};

@protocol JNPileViewDelegate <NSObject>
@required

/// The number of the views in the pile
- (NSInteger)numberOfViewsInPileView:(JNPileView*)pileView;

/// A view for a index
- (UIView*)pileView:(JNPileView*)pileView viewForIndex:(NSInteger)index;


@optional

/// Called when the view is about the be displayed and become the top view on the pile
- (void)pileView:(JNPileView*)pileview willShowView:(UIView*)view forIndex:(NSInteger)index;

/// Called whenever the view being handled is moved
- (void)pileView:(JNPileView*)pileView translated:(CGFloat)translation forView:(UIView*)view;

/// This method is called when the discard translation is crossed either inside or outside
/// If it crossed outside the view did reach the mininum value necessary to be discarded
/// This method is usefull to play a little sound indicating the boundaries for discarding has been crossed
- (void)pileView:(JNPileView*)pileview didCrossDiscardBoundaries:(BOOL)outside forView:(UIView*)view;

/// Return true to discard the view for the specified area
- (BOOL)pileView:(JNPileView*)pileview shouldDiscardView:(UIView*)view forSide:(JNPileViewDiscardSide)side;

/// Called when the discard animation finishes
- (void)pileView:(JNPileView*)pileView didDiscardView:(UIView*)view forSide:(JNPileViewDiscardSide)side;

@end



@interface JNPileView : UIView

@property (nonatomic, weak) id<JNPileViewDelegate> delegate;

/// The mininum translation to discard a view
/// The default value is XX.
@property (nonatomic, assign) CGFloat discardTranslation;

/// The hanlded view becomes trasnparent as it gets away from the center
/// Default value is YES.
@property (nonatomic, assign) CGFloat applyAlphaFactorForHandledView;

/// The rotation is attenuated as the touch gets closer to the center
/// The default value is NO.
@property (nonatomic, assign) BOOL attenuatesRotationBasedOnLocationOfTouch;


/// The top view on the pile (the handled view)
- (UIView*)firstView;

/// The view below the top view on the pile
- (UIView*)secondView;

/// Reload everything from scratch.
- (void)reloadData;

@end
