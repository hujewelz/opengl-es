//
//  MGLView.m
//  opengles_sample
//
//  Created by huluobo on 2021/2/20.
//

#import "MGLView.h"
@import OpenGLES;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation MGLView {
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    CGSize _sizeAfterFrameBufferCreated;
}

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context {
    self = [super initWithFrame:frame];
    if (self) {
        self.context = context;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc {
    [self destoryFramebuffer];
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    _context = nil;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)drawRect:(CGRect)rect {
    if (self.delegate) {
        [self.delegate mglView:self drawInRect:rect];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGSizeEqualToSize(self.frame.size, _sizeAfterFrameBufferCreated) &&
        !CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self destoryFramebuffer];
        [self createFrameBuffer];
    }
}

- (void)setContext:(EAGLContext *)context {
    if (_context != context) {
        [self destoryFramebuffer];
        
        _context = context;
        
        if (_context) {
            [self createFrameBuffer];
        }
    }
}

- (void)commonInit {
    CAEAGLLayer *gllayer = (CAEAGLLayer *)self.layer;
    gllayer.opaque = YES;
    NSDictionary *props = @{
        kEAGLDrawablePropertyRetainedBacking: @(NO),
        kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
    };
    [gllayer setDrawableProperties:props];
}

- (void)createFrameBuffer {
    [EAGLContext setCurrentContext:_context];
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    // 为渲染缓冲区分配内存
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
    GLint width, height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
//    NSLog(@"width: %d, height: %d", width, height);
    if (width == 0 || height == 0) {
        [self destoryFramebuffer];
        return;;
    }
    
    // 将渲染缓冲区绑定到帧缓冲区
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        return;
    }
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Failure with display framebuffer generation for display of size: %f, %f",
             self.bounds.size.width, self.bounds.size.height);
    
    _sizeAfterFrameBufferCreated = self.frame.size;
}

- (NSInteger)drawalbeWidth {
    GLint width;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    return (NSInteger)width;
}

- (NSInteger)drawalbeHeight {
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    return (NSInteger)height;
}

- (void)display {
    [EAGLContext setCurrentContext:_context]; 
    glViewport(0, 0, (GLsizei)self.drawalbeWidth, (GLsizei)self.drawalbeHeight);
   
    [self drawRect:self.bounds];
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)destoryFramebuffer {
    if (!_frameBuffer) {
        glDeleteFramebuffers(GL_FRAMEBUFFER, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    if (!_renderBuffer) {
        glDeleteRenderbuffers(GL_RENDERBUFFER, &_renderBuffer);
        _renderBuffer = 0;
    }
}

#pragma clang diagnostic pop
@end
