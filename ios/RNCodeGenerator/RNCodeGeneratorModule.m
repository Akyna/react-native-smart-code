//
//  RNCodeGeneratorModule.m
//  Jerry-Luo<tiancailuohao@gmail.com>
//
//  Created by Jerry on 2018/1/17.
//  Copyright © 2018年 Jerry. All rights reserved.
//

#import "RNCodeGeneratorModule.h"
#import "NKDCode128Barcode.h"
#import "UIImage-NKDBarcode.h"
@implementation RNCodeGeneratorModule

RCT_EXPORT_MODULE();
+ (BOOL)requiresMainQueueSetup{
    return NO;
}
- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.Jerry.ReactNativeGeneratorModuleQueue", DISPATCH_QUEUE_SERIAL);
}
- (NSDictionary *)constantsToExport
{
    return @{
             @"Code128" : @(GeneratorCode_Code128),
             @"QRCode" : @(GeneratorCode_QRCode),
             };
};


RCT_EXPORT_METHOD(
                  generateCode:(NSDictionary *)infoDict
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  ){
    
    NSString *code=infoDict[@"code"];
    
    CGFloat width=[infoDict[@"width"] floatValue];
    CGFloat height=[infoDict[@"height"] floatValue];
    CGSize size=CGSizeMake(width, height);
    
    NSNumber *typeNumber=infoDict[@"type"];
    GeneratorCodeType type=typeNumber.integerValue;
    
    
    
    @try {
        UIImage *image;
        switch (type) {
            case GeneratorCode_Code128:
            {
                image=[RNCodeGeneratorModule generterCode128:code size:size];
                
            }
                break;
            case GeneratorCode_QRCode:
            {
                image=[RNCodeGeneratorModule generterQRCode:code size:size];
            }
                break;
                
            default:
                reject(@"-1",@"Code Type is incorrect",nil);
                return;
        }
        
        NSData *imageData=UIImagePNGRepresentation(image);
        NSString *encodedImageStr =[imageData base64EncodedStringWithOptions: 0];
        
        
        resolve(encodedImageStr);
    } @catch (NSException *exception) {
        NSError *error=[NSError errorWithDomain:exception.name code:-1 userInfo:exception.userInfo];
        reject(@"-1",error.domain,error);
    }
}

#pragma mark -
#pragma mark Code128
#pragma mark -
+ (UIImage *)generterCode128:(NSString *)code size:(CGSize)size{
    
    CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    [filter setDefaults];
    
    NSData *data = [code dataUsingEncoding:NSUTF8StringEncoding];
    
    NSNumber *barcodeHeight = [NSNumber numberWithInt: 60];
    NSNumber *quietSpace = [NSNumber numberWithInt: 2];
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:barcodeHeight forKey:@"inputBarcodeHeight"];
    [filter setValue:quietSpace forKey:@"inputQuietSpace"];
    

    CIImage *outputImage = [filter outputImage];
    UIImage *qrcode=[RNCodeGeneratorModule createNonInterpolatedUIImageFromCIImage:outputImage withSize:size];
    return qrcode;
}

#pragma mark -
#pragma mark QRCode
#pragma mark -
+ (UIImage *)generterQRCode:(NSString *)code size:(CGSize)size{
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    [filter setDefaults];
    
    NSData *data = [code dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@"L" forKey:@"inputCorrectionLevel"];
    CIImage *outputImage = [filter outputImage];
    UIImage *qrcode=[RNCodeGeneratorModule createNonInterpolatedUIImageFromCIImage:outputImage withSize:size];
    return qrcode;
}

+(UIImage *)createNonInterpolatedUIImageFromCIImage:(CIImage *)image withSize:(CGSize)size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGRect withOutMargin = CGRectMake(1, 1, extent.size.width-2, extent.size.height-2);
    CGFloat scale = MIN(size.width/CGRectGetWidth(extent), size.height/CGRectGetHeight(extent));
    
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:withOutMargin];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}
@end
