//
//  CCGraphics.m
//  Nextcloud
//
//  Created by Marino Faggiana on 04/02/16.
//  Copyright (c) 2016 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "CCGraphics.h"
#import "CCUtility.h"
#import "NCBridgeSwift.h"

@implementation CCGraphics

+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetIG =
    [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetIG.appliesPreferredTrackTransform = YES;
    assetIG.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *igError = nil;
    thumbnailImageRef =
    [assetIG copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60) actualTime:NULL error:&igError];
    
    if (!thumbnailImageRef) NSLog(@"[LOG] thumbnailImageGenerationError %@", igError );
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    
    return thumbnailImage;
}

+ (UIImage *)generateImageFromVideo:(NSString *)videoPath
{
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    NSError *error = NULL;

    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    // CMTime time = CMTimeMake(1, 65);
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:&error];
    if(error) return nil;
    UIImage* image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return image;
}

+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)targetSize isAspectRation:(BOOL)aspect
{
    CGFloat originRatio = image.size.width / image.size.height;
    CGFloat newRatio = targetSize.width / targetSize.height;
    CGSize sz;
    CGFloat scale = 1.0;
    
    if (!aspect) {
        sz = targetSize;
    }else {
        if (originRatio < newRatio) {
            sz.height = targetSize.height;
            sz.width = targetSize.height * originRatio;
        }else {
            sz.width = targetSize.width;
            sz.height = targetSize.width / originRatio;
        }
    }
    
    sz.width /= scale;
    sz.height /= scale;
    
    UIGraphicsBeginImageContextWithOptions(sz, NO, UIScreen.mainScreen.scale);
    [image drawInRect:CGRectMake(0, 0, sz.width, sz.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (void)createNewImageFrom:(NSString *)fileName ocId:(NSString *)ocId etag:(NSString *)etag typeFile:(NSString *)typeFile
{
    UIImage *originalImage;
    UIImage *scaleImagePreview;
    UIImage *scaleImageIcon;
    NSString *fileNamePath = [CCUtility getDirectoryProviderStorageOcId:ocId fileNameView:fileName];
    NSString *fileNamePathPreview = [CCUtility getDirectoryProviderStoragePreviewOcId:ocId etag:etag];
    NSString *fileNamePathIcon = [CCUtility getDirectoryProviderStorageIconOcId:ocId etag:etag];

    if (![CCUtility fileProviderStorageExists:ocId fileNameView:fileName]) return;
    
    // only viedo / image
    if (![typeFile isEqualToString: NCBrandGlobal.shared.metadataTypeFileImage] && ![typeFile isEqualToString: NCBrandGlobal.shared.metadataTypeFileVideo]) return;
    
    if ([typeFile isEqualToString: NCBrandGlobal.shared.metadataTypeFileImage]) {
        
        originalImage = [UIImage imageWithContentsOfFile:fileNamePath];
        if (originalImage == nil) { return; }
    }
    
    if ([typeFile isEqualToString: NCBrandGlobal.shared.metadataTypeFileVideo]) {
        
        // create symbolik link for read video file in temp
        [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingString:@"tempvideo.mp4"] error:nil];
        [[NSFileManager defaultManager] linkItemAtPath:fileNamePath toPath:[NSTemporaryDirectory() stringByAppendingString:@"tempvideo.mp4"] error:nil];
        
        originalImage = [self generateImageFromVideo:[NSTemporaryDirectory() stringByAppendingString:@"tempvideo.mp4"]];
    }

    scaleImagePreview = [self scaleImage:originalImage toSize:CGSizeMake(NCBrandGlobal.shared.sizePreview, NCBrandGlobal.shared.sizePreview) isAspectRation:YES];
    scaleImageIcon = [self scaleImage:originalImage toSize:CGSizeMake(NCBrandGlobal.shared.sizeIcon, NCBrandGlobal.shared.sizeIcon) isAspectRation:YES];

    scaleImagePreview = [UIImage imageWithData:UIImageJPEGRepresentation(scaleImagePreview, 0.5f)];
    scaleImageIcon = [UIImage imageWithData:UIImageJPEGRepresentation(scaleImageIcon, 0.5f)];
    
    // it is request write photo  ?
    if (scaleImagePreview && scaleImageIcon) {
                    
        [UIImageJPEGRepresentation(scaleImagePreview, 0.5) writeToFile:fileNamePathPreview atomically:true];
        [UIImageJPEGRepresentation(scaleImageIcon, 0.5) writeToFile:fileNamePathIcon atomically:true];
    }
    
    return;
}

+ (UIColor *)colorFromHexString:(NSString *)hexString
{
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (UIImage *)changeThemingColorImage:(UIImage *)image multiplier:(NSInteger)multiplier color:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, image.size.width*multiplier / (2 / UIScreen.mainScreen.scale), image.size.height*multiplier / (2 / UIScreen.mainScreen.scale));
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToMask(context, rect, image.CGImage);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithCGImage:img.CGImage scale:UIScreen.mainScreen.scale orientation: UIImageOrientationDownMirrored];
}

+ (UIImage *)changeThemingColorImage:(UIImage *)image width:(CGFloat)width height:(CGFloat)height color:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, width / (2 / UIScreen.mainScreen.scale), height / (2 / UIScreen.mainScreen.scale));
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToMask(context, rect, image.CGImage);
    if (color)
        CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithCGImage:img.CGImage scale:UIScreen.mainScreen.scale orientation: UIImageOrientationDownMirrored];
}

+ (UIImage *)grayscale:(UIImage *)sourceImage
{
    /* const UInt8 luminance = (red * 0.2126) + (green * 0.7152) + (blue * 0.0722); // Good luminance value */
    /// Create a gray bitmap context
    const size_t width = (size_t)sourceImage.size.width;
    const size_t height = (size_t)sourceImage.size.height;
    
    const int kNyxNumberOfComponentsPerGreyPixel = 3;
    
    CGRect imageRect = CGRectMake(0, 0, sourceImage.size.width, sourceImage.size.height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8/*Bits per component*/, width * kNyxNumberOfComponentsPerGreyPixel, colorSpace, kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    if (!bmContext)
        return nil;
    
    /// Image quality
    CGContextSetShouldAntialias(bmContext, false);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, imageRect, sourceImage.CGImage);
    
    /// Create an image object from the context
    CGImageRef grayscaledImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage *grayscaled = [UIImage imageWithCGImage:grayscaledImageRef scale:sourceImage.scale orientation:sourceImage.imageOrientation];
    
    /// Cleanup
    CGImageRelease(grayscaledImageRef);
    CGContextRelease(bmContext);
    
    return grayscaled;
}

+ (void)settingThemingColor:(NSString *)themingColor themingColorElement:(NSString *)themingColorElement themingColorText:(NSString *)themingColorText
{
    UIColor *newColor, *newColorElement, *newColorText;
    
    // COLOR
    if (themingColor.length == 7) {
        newColor = [CCGraphics colorFromHexString:themingColor];
    } else {
        newColor = NCBrandColor.shared.customer;
    }
            
    // COLOR TEXT
    if (themingColorText.length == 7) {
        newColorText = [CCGraphics colorFromHexString:themingColorText];
    } else {
        newColorText = NCBrandColor.shared.customerText;
    }
            
    // COLOR ELEMENT
    if (themingColorElement.length == 7) {
        newColorElement = [CCGraphics colorFromHexString:themingColorElement];
    } else {
        if ([themingColorText isEqualToString:@"#000000"])
            newColorElement = [UIColor blackColor];
        else
            newColorElement = newColor;
    }
            
    NCBrandColor.shared.brand = newColor;
    NCBrandColor.shared.brandElement = newColorElement;
    NCBrandColor.shared.brandText = newColorText;
}

@end
