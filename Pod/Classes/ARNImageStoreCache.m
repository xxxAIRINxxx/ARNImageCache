//
//  ARNImageStoreCache.m
//  ARNImageCache
//
//  Created by Airin on 2014/10/18.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import "ARNImageStoreCache.h"

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static NSString *const ARNImageCacheFolderName    = @"ARNImageCache";
static NSString *const ARNImageCacheNameThumbnail = @"ARNThumbnail";
static NSString *const ARNImageCacheNameImage     = @"ARNImage";

static NSCache *thumbnailCache_ = nil;
static NSCache *imageCache_     = nil;

@implementation ARNImageStoreCache

+ (NSCache *)thumbnailCache
{
    if (!thumbnailCache_) {
        thumbnailCache_            = [[NSCache alloc] init];
        thumbnailCache_.countLimit = 30;
    }
    return thumbnailCache_;
}

+ (void)setThumbnailCacheLimit:(NSUInteger)cacheLimit
{
    [self thumbnailCache].countLimit = cacheLimit;
}

+ (NSCache *)imageCache
{
    if (!imageCache_) {
        imageCache_            = [[NSCache alloc] init];
        imageCache_.countLimit = 15;
    }
    return imageCache_;
}

+ (void)setImageCacheLimit:(NSUInteger)cacheLimit
{
    [self imageCache].countLimit = cacheLimit;
}

+ (NSString *)cacheImageFolderPath
{
    return [self checkAndCreateDirectoryAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ARNImageCacheFolderName]];
}

+ (NSString *)checkAndCreateDirectoryAtPath:(NSString *)path
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        // ないので作る
        NSError *error = nil;
        if ([[NSFileManager defaultManager] createDirectoryAtPath:path
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error]) {
            if (error) {
                NSLog(@"checkAndCreateDirectoryAtPath error : %@", [error localizedDescription]);
                
                return nil;
            }
            return path;
        } else {
            return nil;
        }
    } else {
        return path;
    }
}

+ (void)clear
{
    [self.thumbnailCache removeAllObjects];
    [self.imageCache removeAllObjects];
    
    [[NSFileManager defaultManager] removeItemAtPath:[self cacheImageFolderPath] error:nil];
}

+ (void)addThumbnailImageWithImage:(UIImage *)image imageURL:(NSURL *)imageURL
{
    if (!image || !imageURL) { return; }
    
    if (![self.thumbnailCache objectForKey:imageURL.absoluteString]) {
        [self.thumbnailCache setObject:image forKey:imageURL.absoluteString];
    }
    [self addLocalCacheWithImage:image imageURL:imageURL key:ARNImageCacheNameThumbnail];
}

+ (void)addImageWithImage:(UIImage *)image imageURL:(NSURL *)imageURL
{
    if (!image || !imageURL) { return; }
    
    if (![self.imageCache objectForKey:imageURL.absoluteString]) {
        [self.imageCache setObject:image forKey:imageURL.absoluteString];
    }
    [self addLocalCacheWithImage:image imageURL:imageURL key:ARNImageCacheNameImage];
}

+ (void)addLocalCacheWithImage:(UIImage *)image imageURL:(NSURL *)imageURL key:(NSString *)key
{
    @synchronized(self)
    {
        NSString *filePath = [self filePathWIthImageURL:imageURL key:key];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSData *data = [[NSData alloc] initWithData:UIImagePNGRepresentation(image)];
            [data writeToURL:[NSURL fileURLWithPath:filePath] atomically:NO];
        }
    }
}

+ (UIImage *)cacheThumbnailImageWIthURL:(NSURL *)imageURL
{
    if (!imageURL) { return nil; }
    
    UIImage *cachedImage = [self.thumbnailCache objectForKey:imageURL.absoluteString];
    if (cachedImage) {
        return cachedImage;
    } else {
        return [self hasLocalCacheImageWIthURL:imageURL key:ARNImageCacheNameThumbnail];
    }
}

+ (UIImage *)cacheImageWIthURL:(NSURL *)imageURL
{
    if (!imageURL) { return nil; }
    
    UIImage *cachedImage = [self.imageCache objectForKey:imageURL.absoluteString];
    if (cachedImage) {
        return cachedImage;
    } else {
        return [self hasLocalCacheImageWIthURL:imageURL key:ARNImageCacheNameImage];
    }
}

+ (UIImage *)hasLocalCacheImageWIthURL:(NSURL *)imageURL key:(NSString *)key
{
    NSString *filePath = [self filePathWIthImageURL:imageURL key:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData  *data  = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
        UIImage *image = [UIImage imageWithData:data];
        return image;
    }
    return nil;
}

+ (NSString *)filePathWIthImageURL:(NSURL *)imageURL key:(NSString *)key
{
    if (!imageURL || !key) { return nil; }
    
    NSString *fileDirectoryString = [[self cacheImageFolderPath] stringByAppendingPathComponent:key];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileDirectoryString]) {
        NSError *error   = nil;
        BOOL     created = [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectoryString
                                                     withIntermediateDirectories:NO
                                                                      attributes:nil
                                                                           error:&error];
        if (!created) {
            NSLog(@"filePathWIthImageURL error : %@", error.description);
            abort();
        }
    }
    return [fileDirectoryString stringByAppendingPathComponent:[self escapeString:imageURL.absoluteString]];
}

+ (NSString *)escapeString:(NSString *)aString
{
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (CFStringRef)aString,
                                                                                 NULL,
                                                                                 (CFStringRef)@"-._~:/?#[]@!$&'()*+,;=",
                                                                                 kCFStringEncodingUTF8);
}

@end
