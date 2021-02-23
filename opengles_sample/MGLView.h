//
//  MGLView.h
//  opengles_sample
//
//  Created by huluobo on 2021/2/20.
//

#import <UIKit/UIKit.h>

#define GLES_SILENCE_DEPRECATION
NS_ASSUME_NONNULL_BEGIN

@class MGLView;
@protocol MGLViewDelegate <NSObject>

@required
- (void)mglView:(MGLView *)glView drawInRect:(CGRect)rect;

@end


@interface MGLView : UIView

@property(nonatomic, readonly, assign) NSInteger drawalbeWidth;
@property(nonatomic, readonly, assign) NSInteger drawalbeHeight;
@property(nonatomic, weak) id<MGLViewDelegate> delegate;
 
- (void)display;

@end

NS_ASSUME_NONNULL_END
