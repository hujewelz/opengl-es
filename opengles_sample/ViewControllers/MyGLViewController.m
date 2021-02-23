//
//  MyGLViewController.m
//  opengles_sample
//
//  Created by huluobo on 2021/2/20.
//

#import "MyGLViewController.h"
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


@interface MyGLViewController () <MGLViewDelegate>

@property (strong, nonatomic) MGLView *glView;
@property (nonatomic, strong) ShaderProgram *shaderProgram;
@end

@implementation MyGLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect bounds = [UIScreen mainScreen].bounds;
    self.glView = [[MGLView alloc] initWithFrame: bounds];
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    self.glView.context = context;
    self.glView.delegate = self;
    [self.view addSubview:self.glView];
    
    
    [self setup];
    [self.glView display];
    
}

- (void)setup {
    self.shaderProgram = [[ShaderProgram alloc] initWithVertexShaderSource:VertexShaderSourceCode
                                                   andFragmentShaderSource:FragmentShaderSourceCode];
    [_shaderProgram link];
    [_shaderProgram use];
}

- (void)mglView:(MGLView *)glView drawInRect:(CGRect)rect {
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    static float vertices[] = {
        -1.0f,  0.5f, 0.0f, 0.0f, 1.0f, // 左上角
        -1.0f, -0.5f, 0.0f, 0.0f, 0.0f, // 右下角
         1.0f,  0.5f, 0.0f, 1.0f, 1.0f, // 右上角
         1.0f, -0.5f, 0.0f, 1.0f, 0.0f, // 右下角
    };
    
    GLuint vertexbuffer;
    glGenBuffers(1, &vertexbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    
    GLuint vlocation = [_shaderProgram getAttributeLocation:@"position"];
    GLuint coordlocation = [_shaderProgram getAttributeLocation:@"aTexCoord"];
    
    glEnableVertexAttribArray(vlocation);
    glVertexAttribPointer(vlocation, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *)0);
    
    glEnableVertexAttribArray(coordlocation);
    glVertexAttribPointer(coordlocation, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
    
    UIImage *image = [UIImage imageNamed:@"leaf.jpeg"];
    GLuint texture = createTextureWithCGImage(image.CGImage);

    glBindTexture(GL_TEXTURE_2D, texture);

    int l = [_shaderProgram getUniformLocation:@"aTexture"];
    glUniform1i(l, 0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);

    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDeleteTextures(1, &texture);
    glBindVertexArray(0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glDeleteBuffers(1, &vertexbuffer);
    
}

@end

#pragma clang diagnostic pop