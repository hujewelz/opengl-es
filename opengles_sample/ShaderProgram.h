//
//  ShaderProgram.h
//  opengles_sample
//
//  Created by huluobo on 2021/2/20.
//

#import <Foundation/Foundation.h>


#define STRINGFILY(str) #str
#define SHADER_SOURCE(text) @STRINGFILY(text)

NS_ASSUME_NONNULL_BEGIN

@interface ShaderProgram : NSObject

- (instancetype)initWithVertexShaderSource:(NSString *)vShaderSource andFragmentShaderSource:(NSString *)fShaderSource;
- (instancetype)initWithVertexShaderFile:(NSString *)vShaderFile andFragmentShaderFile:(NSString *)fShaderFile;

+ (instancetype)shaderWithVertexShaderFilename:(NSString *)vShaderFilename andFragmentShaderFile:(NSString *)fShaderFilename;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (BOOL)link;
- (void)use;

- (int)getAttributeLocation:(NSString *)param;
- (void)bindAttributeLocation:(int)index name:(NSString *)name;

- (int)getUniformLocation:(NSString *)param;

@end

NS_ASSUME_NONNULL_END
