//
//  SOSPicker.h
//  SyncOnSet
//
//  Created by Christopher Sullivan on 10/25/13.
//  Updated by John Weaver on  12/7/2017
//
//

#import <Cordova/CDVPlugin.h>


@interface SOSPicker : CDVPlugin < UINavigationControllerDelegate, UIScrollViewDelegate>

@property (copy)   NSString* callbackId;

- (void) getPictures:(CDVInvokedUrlCommand *)command;
- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize;

@property (nonatomic, assign) NSInteger maxVideoDuration;
@property (nonatomic, assign) NSInteger maxCount;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger quality;
@property (nonatomic, assign) NSInteger outputType;

@end
