//
//  JNPileView.m
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
   
    /// The flags to handle the boundaries for discarding a view
    struct {
        BOOL reachedDiscard; /// Flag to indicate if the translation reached the mininum value necessary to discard
        BOOL previousReachedDiscard; /// Flag to hold the previous value for the flag above
    } _boundaryFlags;
    
    BOOL _loadedOnFirstAppear;
}
@end


/// Views wrapper
@interface JNPileViewWrapper : NSObject

/// The view itself
@property (nonatomic, retain) UIView* view;

/// The index this view was fetched for
@property (nonatomic, assign) NSInteger fetchIndex;

@end

@implementation JNPileViewWrapper
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
        
        /// Default values
        self.discardTranslation = 90;
        self.applyAlphaFactorForHandledView = YES;
        self.attenuatesRotationBasedOnLocationOfTouch = NO;
        
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
    
    /// Load data once when appearing for the first time
    if (!_loadedOnFirstAppear) {
        [self reloadData];
        _loadedOnFirstAppear = YES;
    }
}


#pragma mark - Public Methods

- (UIView*)firstView
{
    if (_views.count >= 1) {
        JNPileViewWrapper* w = _views[0];
        return w.view;
    }
    return nil;
}

- (UIView*)secondView
{
    if (_views.count >= 2) {
        JNPileViewWrapper* w = _views[1];
        return w.view;
    }
    return nil;
}

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
    JNPileViewWrapper* wrapperForHandledView = _views[0];
    UIView* handledView = wrapperForHandledView.view;
    
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
        
        /// Start value
        _boundaryFlags.reachedDiscard =
        _boundaryFlags.previousReachedDiscard = NO;
    }
    
    /// Handle pan
    else if (panGesture.state == UIGestureRecognizerStateChanged) {
        
        /// Inform delegate about the translation
        if ([_delegate respondsToSelector:@selector(pileView:translated:forView:)]) {
            [_delegate pileView:self translated:translation.x forView:handledView];
        }
        
        /// Calculate if the boundary has been reached
        _boundaryFlags.reachedDiscard = fabsf(translation.x) > self.discardTranslation;
        
        /// Tell delegate if crossed the discard boundaries
        if (_boundaryFlags.reachedDiscard != _boundaryFlags.previousReachedDiscard) {
            
            /// Hold the current value
            _boundaryFlags.previousReachedDiscard = _boundaryFlags.reachedDiscard;
            
            /// Tell the delegate we crossed boundaries
            if ([_delegate respondsToSelector:@selector(pileView:didCrossDiscardBoundaries:forView:)]) {
                [_delegate pileView:self didCrossDiscardBoundaries:_boundaryFlags.reachedDiscard forView:handledView];
            }
        }
        
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
        
        if (self.applyAlphaFactorForHandledView) {
            const CGFloat minimumAlpha = .75; /// should be a value between 0 and 1
            handledView.alpha = 1 - ((distanceFromCenter / __CENTER_X) * (1 - minimumAlpha));
        }
    }
    
    /// Discard if the gesture ended on the discard area
    else if (panGesture.state == UIGestureRecognizerStateEnded) {
        
        /// Should discard?
        if (_boundaryFlags.reachedDiscard) {
            [self discardView:wrapperForHandledView];
        } else {
            /// If not its not going to be discarded then re-center it
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

    /// Create the wrapper and fetch the view
    JNPileViewWrapper* wrapper = [JNPileViewWrapper new];
    wrapper.view = [_delegate pileView:self viewForIndex:_pileFlags.fetchIndex];
    wrapper.fetchIndex = _pileFlags.fetchIndex;
    
    /// Add the fetched view to the pile
    [self addToPile:wrapper];
    
    /// Increase fetch index
    ++_pileFlags.fetchIndex;
    
    return YES;
}

- (void)addToPile:(JNPileViewWrapper*)wrapper
{
    /// Add the view behind the last view on the pile
    if (_views.count >= 1) {
        JNPileViewWrapper* wLast = _views.lastObject;
        [self insertSubview:wrapper.view belowSubview:wLast.view];
    }
    else {
        [self addSubview:wrapper.view];
        
        /// (this is the top view, so tell the delegate it will be shown)
        [self notifityViewWillBeShown:wrapper];
    }
    
    /// Add to the end of the array
    [_views addObject:wrapper];
    
    /// Center it
    [self centerView:wrapper.view animated:NO];
}

- (void)removeFromPile:(JNPileViewWrapper*)wrapper
{
    /// Grab original index on the array
    NSInteger idx = [_views indexOfObject:wrapper];
    
    /// Remove from the array
    [_views removeObject:wrapper];
    
    /// If we removed the top view on the pile tell the delegate we will show a new one (if theres any)
    if (idx == 0 && _views.count > 0) {
        [self notifityViewWillBeShown:_views[0]];
    }
}

- (void)notifityViewWillBeShown:(JNPileViewWrapper*)wrapper
{
    if ([_delegate respondsToSelector:@selector(pileView:willShowView:forIndex:)]) {
        [_delegate pileView:self willShowView:wrapper.view forIndex:wrapper.fetchIndex];
    }
}

- (void)centerView:(UIView*)view animated:(BOOL)isAnimated
{
    /// Since the view is going to be centered
    /// Tell the delegate we had a 0 translation
    if ([_delegate respondsToSelector:@selector(pileView:translated:forView:)]) {
        [_delegate pileView:self translated:0 forView:view];
    }
    
    /// Block to center the view
    void (^DoCenter)() = ^() {
    
        view.center = CGPointMake(__CENTER_X, __CENTER_Y);
        view.transform = CGAffineTransformMakeRotation(0);
        
        if (_applyAlphaFactorForHandledView) {
            view.alpha = 1;
        }
    };
    
    if (isAnimated == NO) {
        DoCenter();
    } else {
        [UIView animateWithDuration:.2 animations:^{
            DoCenter();
        }];
    }
}

- (BOOL)discardView:(JNPileViewWrapper*)wrapper
{
    JNPileViewDiscardSide discardSide = (wrapper.view.center.x < __CENTER_X) ? JNPileViewDiscardSideLeft : JNPileViewDiscardSideRight;
    
    /// Ask the delegate if the view can be discarded
    BOOL canDiscard = YES;
    if ([_delegate respondsToSelector:@selector(pileView:shouldDiscardView:forSide:)]) {
        canDiscard = [_delegate pileView:self shouldDiscardView:wrapper.view forSide:discardSide];
    }
    
    /// Discard if enabled
    if (canDiscard) {
        
        /// Remove it from the array
        [self removeFromPile:wrapper];
        
        /// Fetch a new view
        [self fetchView];
        
        /// Animate discard
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            CGPoint center = wrapper.view.center;
            
            /// Adds the distance from the view center to the super center
            center.y += wrapper.view.center.y - __CENTER_Y;
            
            /// Get offscreen
            if (discardSide == JNPileViewDiscardSideLeft) {
                center.x -= CGRectGetMaxX(wrapper.view.frame);
            } else {
                center.x += self.bounds.size.width - wrapper.view.frame.origin.x;
            }
            wrapper.view.center = center;
            
            /// Increase rotation a little bit
            CGFloat angle = atan2f(wrapper.view.transform.b, wrapper.view.transform.a);
            angle *= 1.2f;
            wrapper.view.transform = CGAffineTransformMakeRotation(angle);
            
            /// Make it dissapear
            if (_applyAlphaFactorForHandledView) {
                wrapper.view.alpha = 0;
            }
            
        } completion:^(BOOL finished) {
            
            /// Remove it from super view
            [wrapper.view removeFromSuperview];
            
            /// Tell delegate on completion
            if ([_delegate respondsToSelector:@selector(pileView:didDiscardView:forSide:)]) {
                [_delegate pileView:self didDiscardView:wrapper.view forSide:discardSide];
            }
        }];
    }
    
    return canDiscard;
}

@end
