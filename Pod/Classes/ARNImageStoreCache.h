//
//  ARNImageStoreCache.h
//  ARNImageCache
//
//  Created by Airin on 2014/10/18.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import <Foundation/Foundation.h>

// Attention!
// Library/Cachesに保存するので、OSによって消されている可能性がある

@interface ARNImageStoreCache : NSObject

+ (void)clear;

+ (void)setThumbnailCacheLimit:(NSUInteger)cacheLimit;
+ (void)setImageCacheLimit:(NSUInteger)cacheLimit;

+ (void)addThumbnailImageWithImage:(UIImage *)image imageURL:(NSURL *)imageURL;
+ (void)addImageWithImage:(UIImage *)image imageURL:(NSURL *)imageURL;

+ (UIImage *)cacheThumbnailImageWIthURL:(NSURL *)imageURL;
+ (UIImage *)cacheImageWIthURL:(NSURL *)imageURL;

@end
