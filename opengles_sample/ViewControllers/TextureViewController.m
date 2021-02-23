//
//  TextureViewController.m
//  opengles_sample
//
//  Created by huluobo on 2021/2/23.
//

#import "TextureViewController.h"
#import "ShaderProgram.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface TextureViewController () {
    GLKTextureInfo *textureInfo1;
    GLKTextureInfo *textureInfo2;
}

@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, readonly, strong) EAGLContext *context;

@end

@implementation TextureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)setup {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    GLKView *glkView = (GLKView *)self.view;
    glkView.context = context;
    [EAGLContext setCurrentContext:context];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    
    CGImageRef imageRef = [UIImage imageNamed:@"leaf.jpeg"].CGImage;
    NSDictionary *opts = @{GLKTextureLoaderOriginBottomLeft: @(YES)};
    textureInfo1 = [GLKTextureLoader textureWithCGImage:imageRef options:opts error:NULL];
    
    CGImageRef imageRef2 = [UIImage imageNamed:@"beetle.png"].CGImage;
    textureInfo2 = [GLKTextureLoader textureWithCGImage:imageRef2 options:opts error:NULL];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.2, 0.3, 0.3, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    // 开启混合
    glEnable(GL_BLEND);
    // 设置混合函数
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    static float vertices[] = {
        -1.0f,  1.0f, 0.0f, 0.0f, 1.0f, // 左上角
        -1.0f, -1.0f, 0.0f, 0.0f, 0.0f, // 右下角
         1.0f,  1.0f, 0.0f, 1.0f, 1.0f, // 右上角
         1.0f, -1.0f, 0.0f, 1.0f, 0.0f, // 右下角
    };
    
    GLuint vertexbuffer;
    glGenBuffers(1, &vertexbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *)0);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *)(3*sizeof(float)));
    
    // 绘制叶子
    self.baseEffect.texture2d0.name = textureInfo1.name;
    self.baseEffect.texture2d0.target = textureInfo1.target;
    [self.baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // 绘制虫子
    self.baseEffect.texture2d0.name = textureInfo2.name;
    self.baseEffect.texture2d0.target = textureInfo2.target;
    [self.baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDeleteBuffers(1, &vertexbuffer);
}

@end
#pragma clang diagnostic pop
