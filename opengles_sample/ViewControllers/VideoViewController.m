//
//  VideoViewController.m
//  opengles_sample
//
//  Created by huluobo on 2021/4/28.
//

#import "VideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import "MGLView.h"
#import "ShaderProgram.h"
#import "GLTool.h"
@import OpenGLES;

/*:
 
 ## CVOpenGLESTextureRef
 
 `Core Video` 和 `OpenGL Es` 的图片数据和属性，供两端交互的存储区。
 
 ## CVOpenGLESTextureCacheRef 纹理缓存管理类
 
 用来创建和管理 `CVOpenGLESTextureRef` 的类
 
 ## 将 CMSampleBuffer 转为 OpenGL 纹理的步骤：
 
 1. 使用 `CVOpenGLESTextureCacheCreate` 创建 `CVOpenGLESTextureCacheRef` 纹理缓存管理类，用于生成 `CVOpenGLESTextureRef`;
 2. 使用 `CMSampleBufferGetImageBuffer` 将 `CMSampleBuffer` 转成 `CVPixelBufferRef`;
 3. 使用 `CVOpenGLESTextureCacheCreateTextureFromImage` 从 `CVPixelBufferRef` 创建 `CVOpenGLESTextureRef`, 然后使用 `CVOpenGLESTextureGetName`
    来获得 texture 的 id.
 4. 绑定纹理
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static NSString *const VertexShaderSourceCode = SHADER_SOURCE
(
 attribute vec3 position;
 attribute vec2 aTexCoord;

 varying vec2 TexCoord;
 
 void main()
 {
    gl_Position = vec4(position, 1.0);
    TexCoord = aTexCoord;
 }
);

static NSString *const FragmentShaderSourceCode = SHADER_SOURCE
(
 precision highp float;

 varying highp vec2 TexCoord;
 uniform sampler2D aTexture;

 void main()
 {
    gl_FragColor = texture2D(aTexture, TexCoord);
}
);

@interface VideoViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, MGLViewDelegate> {
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureRef _texture;
    GLuint vbo, vao;
}

@property (strong, nonatomic) MGLView *glView;
@property (nonatomic, strong) ShaderProgram *shaderProgram;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOuput;

@end

@implementation VideoViewController

- (void)dealloc {
    CVOpenGLESTextureCacheFlush(_textureCache, 0);
    glDeleteVertexArrays(1, &vao);
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupGLView];
    [self setupBuffer];
    [self setupCapture];
    [self setupCVOpenGLTextureCache];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.session startRunning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.session stopRunning];
}

- (void)setupGLView {
    CGRect bounds = [UIScreen mainScreen].bounds;
    self.glView = [[MGLView alloc] initWithFrame: bounds];
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    self.glView.context = context;
    self.glView.delegate = self;
    [self.view addSubview:self.glView];
    
    self.shaderProgram = [[ShaderProgram alloc] initWithVertexShaderSource:VertexShaderSourceCode
                                                   andFragmentShaderSource:FragmentShaderSourceCode];
    [_shaderProgram link];
    [_shaderProgram use];
    
    int sampler0 = [_shaderProgram getUniformLocation:@"aTexture"];
    glUniform1i(sampler0, 0);
}


- (void)setupCapture {
    self.session = [[AVCaptureSession alloc] init];
    self.videoDataOuput = [[AVCaptureVideoDataOutput alloc] init];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"Could not create video device input: %@", error);
        return;
    }
    
    [self.session beginConfiguration];
    
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    } else {
        [self.session commitConfiguration];
        return;
    }
    
    if ([self.session canAddOutput:self.videoDataOuput]) {
        [self.session addOutput:self.videoDataOuput];
        self.videoDataOuput.alwaysDiscardsLateVideoFrames = YES;
    } else {
        [self.session commitConfiguration];
        return;
    }
    
    AVCaptureConnection *connection = [self.videoDataOuput connectionWithMediaType:AVMediaTypeVideo];
   
    // 因为 Core Video 和 OpenGL ES 的坐标系中，前者的原点在左上角，后者的原点在左下角，因此 Y 轴的相反的，所以渲染出的画面是上下颠倒
    // 下面的设置让采集的图像原点也在左下角
    connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    
    [self.session commitConfiguration];
}

- (void)setupCVOpenGLTextureCache {
    CVReturn res = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glView.context, NULL, &_textureCache);
    if (res != kCVReturnSuccess) {
        NSLog(@"Create cache failed");
    }
}

- (CVOpenGLESTextureRef)acquireTextureFromBuffer: (CVPixelBufferRef)buffer {
    GLsizei width = (GLsizei)CVPixelBufferGetWidth(buffer);
    GLsizei height = (GLsizei)CVPixelBufferGetHeight(buffer);
    // 将 PixelBuffer 转成 OpenGL ES 的 Texture，并且将句柄存在 cvTexture 中
    CVOpenGLESTextureRef texture;
    CVReturn res = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                _textureCache,
                                                                buffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                width,
                                                                height,
                                                                GL_RGBA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &texture);
    if (res != kCVReturnSuccess) {
        NSLog(@"Create texture failed");
    }
    return texture;
}

- (void)setupBuffer {
    static float vertices[] = {
        -1.0f,  0.5f, 0.0f, 0.0f, 1.0f, // 左上角
        -1.0f, -0.5f, 0.0f, 0.0f, 0.0f, // 右下角
         1.0f,  0.5f, 0.0f, 1.0f, 1.0f, // 右上角
         1.0f, -0.5f, 0.0f, 1.0f, 0.0f, // 右下角
    };
    
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    
    GLuint vlocation = [_shaderProgram getAttributeLocation:@"position"];
    GLuint coordlocation = [_shaderProgram getAttributeLocation:@"aTexCoord"];
    
    glEnableVertexAttribArray(vlocation);
    glVertexAttribPointer(vlocation, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *)0);
    
    glEnableVertexAttribArray(coordlocation);
    glVertexAttribPointer(coordlocation, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
    
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

- (void)mglView:(MGLView *)glView drawInRect:(CGRect)rect {
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
//    static float vertices[] = {
//        -1.0f,  0.5f, 0.0f, 0.0f, 1.0f, // 左上角
//        -1.0f, -0.5f, 0.0f, 0.0f, 0.0f, // 右下角
//         1.0f,  0.5f, 0.0f, 1.0f, 1.0f, // 右上角
//         1.0f, -0.5f, 0.0f, 1.0f, 0.0f, // 右下角
//    };
//
//    GLuint vertexbuffer;
//    glGenBuffers(1, &vertexbuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
//
//
    glBindVertexArray(vao);
    
    GLuint texture = CVOpenGLESTextureGetName(_texture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDeleteTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindVertexArray(0);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

/**
 CVOpenGLESTextureCacheCreateTextureFromImage -> CVImageBufferRef-> Texture
 CVOpenGLESTextureCacheCreateTextureFromImage -> CVPixelBufferRef-> Texture
 CVOpenGLESTextureCacheCreateTextureFromImage -> CMSampleBufferRef-> CVPixelBufferRef -> Texture

 CVImageBufferRef == CVPixelBufferRef 等价
 CVPixelBufferRef-> Texture-> OpenGL ES 或 Metal渲染
 CMSampleBufferRef->Texture-> OpenGL ES 或 Metal渲染
 */
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    // 由于该回调在 子线程 回调，一个线程对应一个 Context
    if ([EAGLContext currentContext] == NULL) {
        [EAGLContext setCurrentContext: self.glView.context];
    }
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    _texture = [self acquireTextureFromBuffer:pixelBuffer];
    // 通过 CVOpenGLESTextureGetName(CVOpenGLESTextureRef texture) 获取纹理 id
    
    [self.glView display];
    
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    if (_texture != NULL) {
        CFRelease(_texture);
    }
}

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // from: https://developer.apple.com/library/archive/qa/qa1702/_index.html
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    //
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPreRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPreRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return  image;
}

@end

#pragma clang diagnostic pop
