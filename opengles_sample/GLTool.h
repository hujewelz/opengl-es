//
//  GLTool.h
//  opengles_sample
//
//  Created by huluobo on 2021/2/22.
//


#import <Foundation/Foundation.h>
@import OpenGLES;

static void *createImageDataWithCGImage(CGImageRef cgImage, size_t *width, size_t *height)
{
    size_t imgWidht = CGImageGetWidth(cgImage);
    size_t imgHeight = CGImageGetHeight(cgImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    
    void *data = malloc(imgWidht * imgHeight * 4);
    CGContextRef context = CGBitmapContextCreate(data,
                                                 imgWidht,
                                                 imgHeight,
                                                 8,
                                                 4 * imgWidht,
                                                 colorSpace,
                                                 alphaInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextTranslateCTM(context, 0, imgHeight);
    CGContextScaleCTM(context, 1, -1);
    
    CGContextDrawImage(context, CGRectMake(0, 0, imgWidht, imgHeight), cgImage);
    
    CGContextRelease(context);
    
    *width = imgWidht;
    *height = imgHeight;
    return data;
}

static GLuint createTextureWithCGImage(CGImageRef cgimage)
{
    size_t width, height;
    void *data = createImageDataWithCGImage(cgimage, &width, &height);
    
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    free(data);
    return texture;
}

