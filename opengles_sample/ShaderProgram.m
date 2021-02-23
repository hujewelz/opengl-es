//
//  ShaderProgram.m
//  opengles_sample
//
//  Created by huluobo on 2021/2/20.
//

#import "ShaderProgram.h"
@import OpenGLES;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface ShaderProgram () {
    GLuint _program, _vertShader, _fragShader;
}

@end

@implementation ShaderProgram

- (instancetype)initWithVertexShaderSource:(NSString *)vShaderSource andFragmentShaderSource:(NSString *)fShaderSource;
{
    self = [super init];
    if (self) {
        _program = glCreateProgram();
        
        if (![self compileShader:&_vertShader type:GL_VERTEX_SHADER sourceCode:vShaderSource]) {
            NSLog(@"Failed to compile vertex shader");
        }
        if (![self compileShader:&_fragShader type:GL_FRAGMENT_SHADER sourceCode:fShaderSource]) {
            NSLog(@"Failed to compile fragment shader");
        }
        glAttachShader(_program, _vertShader);
        glAttachShader(_program, _fragShader);
    }
    return self;
}

- (instancetype)initWithVertexShaderFile:(NSString *)vShaderFile andFragmentShaderFile:(NSString *)fShaderFile {
    NSString *vShaderSource = [NSString stringWithContentsOfFile:vShaderFile encoding:NSUTF8StringEncoding error:nil];
    NSString *fShaderSource = [NSString stringWithContentsOfFile:fShaderFile encoding:NSUTF8StringEncoding error:nil];
    return [self initWithVertexShaderSource:vShaderSource andFragmentShaderSource:fShaderSource];
}

+ (instancetype)shaderWithVertexShaderFilename:(NSString *)vShaderFilename andFragmentShaderFile:(NSString *)fShaderFilename {
    NSString *vsfile = [[NSBundle mainBundle] pathForResource:@"core" ofType:@"vsh"];
    NSString *fsfile = [[NSBundle mainBundle] pathForResource:@"core" ofType:@"fsh"];
    return [[ShaderProgram alloc] initWithVertexShaderFile:vsfile andFragmentShaderFile:fsfile];
}

- (void)dealloc {
    glDeleteShader(_vertShader);
    glDeleteShader(_fragShader);
    glDeleteProgram(_program);
}

- (BOOL)link {
    glLinkProgram(_program);
    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status != GL_TRUE) {
        GLint infoLength;
        glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &infoLength);
        GLchar *log = (GLchar *)malloc(infoLength);
        glGetProgramInfoLog(_program, infoLength, &infoLength, log);
        printf("Link program failed: %s", log);
        free(log);
    }
    glDeleteShader(_vertShader);
    _vertShader = 0;
    glDeleteShader(_fragShader);
    _fragShader = 0;
    return status == GL_TRUE;
}

- (void)use {
    glUseProgram(_program);
}

- (int)getAttributeLocation:(NSString *)param {
    const GLchar *name = [param UTF8String];
    return glGetAttribLocation(_program, name);
}

- (void)bindAttributeLocation:(int)index name:(NSString *)name {
    const GLchar *cname = [name UTF8String];
    glBindAttribLocation(_program, index, cname);
}

- (int)getUniformLocation:(NSString *)param {
    const GLchar *name = [param UTF8String];
    return glGetUniformLocation(_program, name);
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)shaderType sourceCode:(NSString *)code {
    
    *shader = glCreateShader(shaderType);
    const GLchar *source = (GLchar *)[code UTF8String];
    if (!source) {
        NSLog(@"Failed to load %s shader", shaderType == GL_VERTEX_SHADER ? "vertex" : "fragment");
        return NO;
    }
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint status;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE) {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            NSLog(@"❗️Compile shader with error: %s", log);
            free(log);
        }
    }
    
    return status == GL_TRUE;
}

#pragma clang diagnostic pop
@end
