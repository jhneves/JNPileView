//
//  JNPileView.m
//  InstaBeans
//
//  Created by Joao Neves on 20/11/13.
//  Copyright (c) 2013 JHNeves. All rights reserved.
//

#import "JNPileView.h"

@interface JNPileView()
{
    /// The views on the pile
    NSMutableArray* _views;
    
    /// Pile control flags
    struct {
        NSInteger numberOfViews; /// The number of views
        NSInteger fetchIndex; /// The index to fetch
    } _pileFlags;
    
    /// Rotation flags for the handled view
    struct {
        CGFloat direction; /// The direction to rotate
        CGFloat attenuationFactor; /// How much to attenuate the rotation
    } _rotationFlags;
}
@end


/// HELPERS
static CGFloat _DegToRad(CGFloat degrees)
{
    return degrees * 0.01745329252f /* pi/180 */;
}

#define __CENTER_X (self.bounds.size.width / 2)
#define __CENTER_Y (self.bounds.size.height / 2)
///


@implementation JNPileView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        
        /// Default background color
        self.backgroundColor = [UIColor whiteColor];
        
        /// Initialize views array
        _views = [NSMutableArray array];
        
        /// Default value
        self.discardTranslation = 90;
        
        /// Adds the pan gesture
        UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        panGesture.maximumNumberOfTouches = 1;
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    /// Reload data when appearing
    [self reloadData];
}


#pragma mark - Public Methods

- (void)reloadData
{
    /// Get rid of all views
    [_views removeAllObjects];
    
    /// Restart control flags
    _pileFlags.numberOfViews = [_delegate numberOfViewsInPileView:self];
    _pileFlags.fetchIndex = 0;
    
    /// Fetch 2 views
    [self fetchView];
    [self fetchView];
}


#pragma mark - Touches Handling

- (void)handlePanGesture:(UIPanGestureRecognizer*)panGesture
{
    /// Do nothing if there are no views on the pile
    if (_views.count == 0) {
        return;
    }
    
    /// Translation of the gesture
    const CGPoint translation = [panGesture translationInView:self];
    
    /// The gesture will work with the top view on the pile
    UIView* handledView = _views[0];
    
    /// Initial state
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        
        const CGPoint touchLocationHandledView = [panGesture locationInView:handledView];
        const CGFloat centerHandledView = handledView.frame.size.height / 2;
        
        /// Decide rotation direction based on the point of touch
        /// If the touch is above the half size of the handled view the rotation is opposite to the direction of the trasnlation
        /// otherwise it will rotate to the same direction of the translation
        if (touchLocationHandledView.y > centerHandledView) {
            _rotationFlags.direction = -1;
        } else {
            _rotationFlags.direction = 1;
        }
        
        /// The attenuation factor is based on the distance of the touch to the center of the view (on the y-axis)
        /// The further from the center, the bigger the factor is
        _rotationFlags.attenuationFactor = fabsf(touchLocationHandledView.y - centerHandledView) / centerHandledView;
    }
    
    /// Handle pan
    else if (panGesture.state == UIGestureRecognizerStateChanged) {
        
        /// Set position
        CGFloat x = __CENTER_X + translation.x;
        CGFloat y = __CENTER_Y + translation.y;
        CGPoint p = handledView.center;
        p.x = x;
        p.y = y;
        handledView.center = p;
        
        /// Rotation
        /// If the touch is above the center or under the rotation angle varies
        CGFloat rot = (translation.x * .1) * _rotationFlags.direction;
        if (self.attenuatesRotationBasedOnLocationOfTouch) {
            rot *= _rotationFlags.attenuationFactor;
        }
        handledView.transform = CGAffineTransformMakeRotation(_DegToRad(rot));
        
        /// Fade out as it aproximate to borders
        CGFloat distanceFromCenter;
        if (p.x < __CENTER_X) {
            distanceFromCenter = __CENTER_X - p.x;
        } else {
            distanceFromCenter = p.x - __CENTER_X;
        }
        
        const CGFloat minimumAlpha = .75; /// should be a value between 0 and 1
        handledView.alpha = 1 - ((distanceFromCenter / __CENTER_X) * (1 - minimumAlpha));
    }
    
    /// Discard if the gesture ended on the discard area
    else if (panGesture.state == UIGestureRecognizerStateEnded) {
        
        /// Should discard?
        BOOL willDiscard = NO;
        if (fabsf(translation.x) > self.discardTranslation) {
            willDiscard = [self discardView:handledView];
        }
        
        /// If not its not going to be discarded then re-center it
        if (!willDiscard) {
            
            [self centerView:handledView animated:YES];
        }
    }
    
    /// Failed, canceled, etc states
    else {
        
        [self centerView:handledView animated:YES];
    }
}


#pragma mark - Private Methods

- (BOOL)fetchView
{
    /// No more views to fetch
    if (_pileFlags.fetchIndex >= _pileFlags.numberOfViews) {
        return NO;
    }

    /// Add the fetched view to the pile
    UIView* fetchedView = [_delegate pileView:self viewForIndex:_pileFlags.fetchIndex];
    [self addViewToPile:fetchedView];
    
    /// Increase fetch index
    ++_pileFlags.fetchIndex;
    
    return YES;
}

- (void)addViewToPile:(UIView*)view
{
    /// Add to the end of the array
    [_views addObject:view];
    
    /// Add behind the view before
    if (_views.count > 1) {
        [self insertSubview:view belowSubview:_views[[_views indexOfObject:view] - 1]];
    }
    else {
        [self addSubview:view];
    }
    
    /// Center it
    [self centerView:view animated:NO];
}

- (void)centerView:(UIView*)view animated:(BOOL)isAnimated
{
    void (^DoCenter)() = ^() {
    
        view.center = CGPointMake(__CENTER_X, __CENTER_Y);
        view.transform = CGAffineTransformMakeRotation(0);
        view.alpha = 1;
    };
    
    if (isAnimated == NO) {
        DoCenter();
    } else {
        [UIView animateWithDuration:.2 animations:^{
            DoCenter();
        }];
    }
}

- (BOOL)discardView:(UIView*)view
{
    JNPileViewDiscardSide discardSide = (view.center.x < __CENTER_X) ? JNPileViewDiscardSideLeft : JNPileViewDiscardSideRight;
    
    /// Ask the delegate if the view can be discarded
    BOOL canDiscard = YES;
    if ([_delegate respondsToSelector:@selector(pileView:shouldDiscardView:forSide:)]) {
        canDiscard = [_delegate pileView:self shouldDiscardView:view forSide:discardSide];
    }
    
    /// Discard if enabled
    if (canDiscard) {
        
        /// Notify delegate the view will be discarded
        if ([_delegate respondsToSelector:@selector(pileView:willDiscardView:forSide:)]) {
            [_delegate pileView:self willDiscardView:view forSide:discardSide];
        }
        
        /// Fetch a new view
        [self fetchView];
                
        /// Remove it from the array
        [_views removeObject:view];
        
        /// Animate discard
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            CGPoint center = view.center;
            
            /// Adds the distance from the view center to the super center
            center.y += view.center.y - __CENTER_Y;
            
            /// Get offscreen
            if (discardSide == JNPileViewDiscardSideLeft) {
                center.x -= CGRectGetMaxX(view.frame);
            } else {
                center.x += self.bounds.size.width - view.frame.origin.x;
            }
            view.center = center;
            
            /// Increase rotation a little bit
            CGFloat angle = atan2f(view.transform.b, view.transform.a);
            angle *= 1.2f;
            view.transform = CGAffineTransformMakeRotation(angle);
            
            /// Make it dissapear
            view.alpha = 0;
            
        } completion:^(BOOL finished) {
            
            /// Remove it from super view
            [view removeFromSuperview];
            
            /// Tell delegate on completion
            if ([_delegate respondsToSelector:@selector(pileView:didDiscardView:forSide:)]) {
                [_delegate pileView:self didDiscardView:view forSide:discardSide];
            }
        }];
    }
    
    return canDiscard;
}

@end
