//
//  MGLView.h
//  opengles_sample
//
//  Created by huluobo on 2021/2/20.
//

#import <UIKit/UIKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
NS_ASSUME_NONNULL_BEGIN

@class MGLView;
@protocol MGLViewDelegate <NSObject>

@required
- (void)mglView:(MGLView *)glView drawInRect:(CGRect)rect;

@end


@interface MGLView : UIView

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context;

@property(nonatomic, strong) EAGLContext *context;
@property(nonatomic, readonly, assign) NSInteger drawalbeWidth;
@property(nonatomic, readonly, assign) NSInteger drawalbeHeight;
@property(nonatomic, weak) id<MGLViewDelegate> delegate;
 
- (void)display;

@end

NS_ASSUME_NONNULL_END
#pragma clang diagnostic pop
