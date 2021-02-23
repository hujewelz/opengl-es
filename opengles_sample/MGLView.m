//
//  MGLView.m
//  opengles_sample
//
//  Created by huluobo on 2021/2/20.
//

#import "MGLView.h"
#import "ShaderProgram.h"
#import "GLTool.h"
@import OpenGLES;

NSString *const VertexShaderSourceCode = SHADER_SOURCE
(
 attribute vec3 position;
 attribute vec2 aTexCoord;
 varying vec4 vertexColor;
 varying vec2 TexCoord;
 
 void main()
 {
    gl_Position = vec4(position, 1.0);
    vertexColor = vec4(0.5, 0.0, 0.0, 0.1);
    TexCoord = aTexCoord;
 }
);

NSString *const FragmentShaderSourceCode = SHADER_SOURCE
(
 precision highp float;
 varying highp vec4 vertexColor;
 varying highp vec2 TexCoord;
 uniform sampler2D aTexture;

 void main()
 {
    gl_FragColor = texture2D(aTexture, TexCoord);
}
);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation MGLView {
    EAGLContext *_context;
    ShaderProgram *_shaderProgram;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    CGSize _sizeAfterFrameBufferCreated;
    GLuint vao, vbo;
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
    if (/*!CGSizeEqualToSize(self.frame.size, _sizeAfterFrameBufferCreated) &&*/
        !CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self destoryFramebuffer];
        [self createFrameBuffer];
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
    
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    _context = context;
    [EAGLContext setCurrentContext:context];
    
    _shaderProgram = [[ShaderProgram alloc] initWithVertexShaderSource:VertexShaderSourceCode andFragmentShaderSource:FragmentShaderSourceCode];
    [_shaderProgram link];
    [_shaderProgram use];
    [self createFrameBuffer];
//    [self setupVertex];
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

- (void)setupVertex {
    static float vertices[] = {
        -1.0f,  1.0f, 0.0f, 0.0f, 1.0f, // 左上角
        -1.0f, -1.0f, 0.0f, 0.0f, 0.0f, // 右下角
         1.0f,  1.0f, 0.0f, 1.0f, 1.0f, // 右上角
         1.0f, -1.0f, 0.0f, 1.0f, 0.0f, // 右下角
    };
    
//    glGenVertexArrays(1, &vao);
//    glBindVertexArray(vao);
//
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    
    GLuint vlocation = [_shaderProgram getAttributeLocation:@"position"];
    GLuint coordlocation = [_shaderProgram getAttributeLocation:@"aTexCoord"];
    
    glEnableVertexAttribArray(vlocation);
    glVertexAttribPointer(vlocation, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *)0);
    
    glEnableVertexAttribArray(coordlocation);
    glVertexAttribPointer(coordlocation, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
    
//    glBindBuffer(GL_ARRAY_BUFFER, 0);
////    glBindVertexArray(0);
//    glDisableVertexAttribArray(0);
//    glDisableVertexAttribArray(1);
}


- (void)display {
    [EAGLContext setCurrentContext:_context]; 
    glViewport(0, 0, (GLsizei)self.drawalbeWidth, (GLsizei)self.drawalbeHeight);
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
//    glBindVertexArray(vao);

    UIImage *image = [UIImage imageNamed:@"leaf.jpeg"];
    GLuint texture = createTextureWithCGImage(image.CGImage);

    glBindTexture(GL_TEXTURE_2D, texture);

    int l = [_shaderProgram getUniformLocation:@"aTexture"];
    glUniform1i(l, 0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);

    [self setupVertex];

    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [self drawRect:self.bounds];
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    glDeleteTextures(1, &texture);
    glBindVertexArray(0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glDeleteBuffers(1, &vbo);
}

- (void)destoryFramebuffer {
    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    
    glDeleteRenderbuffers(1, &_renderBuffer);
    _renderBuffer = 0;
}

#pragma clang diagnostic pop
@end
