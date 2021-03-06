//
//  SOSPicker.m
//  SyncOnSet
//
//  Created by Christopher Sullivan on 10/25/13.
//  Updated by John Weaver on  12/7/2017
//
//

#import "SOSPicker.h"

#import "GMImagePickerController.h"
#import "GMFetchItem.h"

#define CDV_PHOTO_PREFIX @"cdv_photo_"

typedef enum : NSUInteger {
    FILE_URI = 0,
    BASE64_STRING = 1
} SOSPickerOutputType;

@interface SOSPicker () <GMImagePickerControllerDelegate>
@end

@implementation SOSPicker 

@synthesize callbackId;

- (void) getPictures:(CDVInvokedUrlCommand *)command {
    
    NSDictionary *options = [command.arguments objectAtIndex: 0];
  
    self.outputType = [[options objectForKey:@"outputType"] integerValue];
	int media_type = [[options objectForKey:@"media_type" ] integerValue ];
    //BOOL allow_video = [[options objectForKey:@"allow_video" ] boolValue ];
    NSString * title = [options objectForKey:@"title"];
    NSString * message = [options objectForKey:@"message"];
    if (message == (id)[NSNull null]) {
      message = nil;
    }
    self.width = [[options objectForKey:@"width"] integerValue];
    self.height = [[options objectForKey:@"height"] integerValue];
    self.quality = [[options objectForKey:@"quality"] integerValue];

    self.maxCount = [[options objectForKey:@"maximumCount"] integerValue];
	  self.maxVideoDuration = [[options objectForKey:@"maximumVideoDuration"] integerValue];

    self.error_max_exceeded_title = [options objectForKey:@"error_max_exceeded_title"];
    self.error_max_exceeded_message = [options objectForKey:@"error_max_exceeded_message"];
    self.error_max_exceeded_ok = [options objectForKey:@"error_max_exceeded_ok"];

    self.callbackId = command.callbackId;

    //[self launchGMImagePicker:allow_video title:title message:message];
	[self launchGMImagePicker:media_type title:title message:message];
}

//- (void)launchGMImagePicker:(bool)allow_video title:(NSString *)title message:(NSString *)message
- (void)launchGMImagePicker:(int)media_type title:(NSString *)title message:(NSString *)message
{
    //GMImagePickerController *picker = [[GMImagePickerController alloc] init:allow_video];
	GMImagePickerController *picker = [[GMImagePickerController alloc] init:media_type];
    picker.delegate = self;
    picker.title = title;
    picker.customNavigationBarPrompt = message;
    picker.colsInPortrait = 4;
    picker.colsInLandscape = 6;
    picker.minimumInteritemSpacing = 2.0;
    picker.modalPresentationStyle = UIModalPresentationPopover;

	picker.maxVideoDuration = self.maxVideoDuration;
    
    UIPopoverPresentationController *popPC = picker.popoverPresentationController;
    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popPC.sourceView = picker.view;
    //popPC.sourceRect = nil;
    
    [self.viewController showViewController:picker sender:nil];
}


- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize
{
    UIImage* sourceImage = anImage;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = frameSize.width;
    CGFloat targetHeight = frameSize.height;
    CGFloat scaleFactor = 0.0;
    CGSize scaledSize = frameSize;

    if (CGSizeEqualToSize(imageSize, frameSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
        if (widthFactor == 0.0) {
            scaleFactor = heightFactor;
        } else if (heightFactor == 0.0) {
            scaleFactor = widthFactor;
        } else if (widthFactor > heightFactor) {
            scaleFactor = heightFactor; // scale to fit height
        } else {
            scaleFactor = widthFactor; // scale to fit width
        }
        scaledSize = CGSizeMake(floor(width * scaleFactor), floor(height * scaleFactor));
    }

    UIGraphicsBeginImageContext(scaledSize); // this will resize

    [sourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];

    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }

    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}


#pragma mark - UIImagePickerControllerDelegate


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"UIImagePickerController: User finished picking assets");
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"UIImagePickerController: User pressed cancel button");
}

#pragma mark - GMImagePickerControllerDelegate

- (void)assetsPickerController:(GMImagePickerController *)picker didFinishPickingAssets:(NSArray *)fetchArray
{
    if (fetchArray.count > self.maxCount)
    {
        //NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%d PHOTOS SELECTED!", nil), fetchArray.count];
        //NSString *message = [NSString stringWithFormat:NSLocalizedString(@"You can only select %d photos at a time.", nil), self.maxCount];
        //[[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];

        NSString *title = [NSString stringWithFormat:NSLocalizedString(self.error_max_exceeded_title, nil), fetchArray.count];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(self.error_max_exceeded_message, nil), self.maxCount];
        [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(self.error_max_exceeded_ok, nil), nil] show];
        
    }
    else
    {
        [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        
        NSLog(@"GMImagePicker: User finished picking assets. Number of selected items is: %lu", (unsigned long)fetchArray.count);
        
        NSMutableArray * result_all = [[NSMutableArray alloc] init];
        CGSize targetSize = CGSizeMake(self.width, self.height);
        NSFileManager* fileMgr = [[NSFileManager alloc] init];
        NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
    
        NSError* err = nil;
        int i = 1;
        NSString* filePath;
		NSString* strResults;

        CDVPluginResult* result = nil;
        for (GMFetchItem *item in fetchArray) {
            
			if (item.video_path ) {
                NSLog(@"GOT VIDEO PATH: %@", item.video_path);
            }	
			
			if (item.video_preferred_angle ) {
                NSLog(@"GOT VIDEO PREFERRED ANGLE: %f", item.video_preferred_angle);
            }		

            if ( !item.image_fullsize ) {
                continue;
            }
          
            do {
                filePath = [NSString stringWithFormat:@"%@/%@%03d.%@", docsPath, CDV_PHOTO_PREFIX, i++, @"jpg"];
            } while ([fileMgr fileExistsAtPath:filePath]);
    
            NSData* data = nil;
            if (self.width == 0 && self.height == 0) {
                // no scaling required
                if (self.outputType == BASE64_STRING){
                    UIImage* image = [UIImage imageNamed:item.image_fullsize];
                    [result_all addObject:[UIImageJPEGRepresentation(image, self.quality/100.0f) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
                } else {
                    if (self.quality == 100) {
                        // no scaling, no downsampling, this is the fastest option
						if (item.video_path)
						{
							//strResults = [NSString stringWithFormat:@"%@|%@", item.image_fullsize, item.video_path];
							strResults = [NSString stringWithFormat:@"%@|%@|%f", item.image_fullsize, item.video_path, item.video_preferred_angle];
						}
						else
						{
							strResults = [NSString stringWithFormat:@"%@", item.image_fullsize];
						}
                        //[result_all addObject:item.image_fullsize];
						[result_all addObject:strResults];
                    } else {
                        // resample first
                        UIImage* image = [UIImage imageNamed:item.image_fullsize];
                        data = UIImageJPEGRepresentation(image, self.quality/100.0f);
                        if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                            break;
                        } else {
							if (item.video_path)
							{
								//strResults = [NSString stringWithFormat:@"%@|%@", [[NSURL fileURLWithPath:filePath] absoluteString], item.video_path];
								strResults = [NSString stringWithFormat:@"%@|%@|%@", [[NSURL fileURLWithPath:filePath] absoluteString], item.video_path, item.video_preferred_angle];
							}
							else
							{
								strResults = [NSString stringWithFormat:@"%@", [[NSURL fileURLWithPath:filePath] absoluteString]];
							}
                            //[result_all addObject:[[NSURL fileURLWithPath:filePath] absoluteString]];
							[result_all addObject:strResults];
                        }
                    }
                }
            } else {
                // scale
                UIImage* image = [UIImage imageNamed:item.image_fullsize];
                UIImage* scaledImage = [self imageByScalingNotCroppingForSize:image toSize:targetSize];
                data = UIImageJPEGRepresentation(scaledImage, self.quality/100.0f);
    
                if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                    break;
                } else {
                    if(self.outputType == BASE64_STRING){
                        [result_all addObject:[data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
                    } else {
						if (item.video_path)
						{
							//strResults = [NSString stringWithFormat:@"%@|%@", [[NSURL fileURLWithPath:filePath] absoluteString], item.video_path];
							strResults = [NSString stringWithFormat:@"%@|%@|%@", [[NSURL fileURLWithPath:filePath] absoluteString], item.video_path, item.video_preferred_angle];
						}
						else
						{
							strResults = [NSString stringWithFormat:@"%@", [[NSURL fileURLWithPath:filePath] absoluteString]];
						}
                        //[result_all addObject:[[NSURL fileURLWithPath:filePath] absoluteString]];
						[result_all addObject:strResults];
                    }
                }
            }
        }
        
        if (result == nil) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:result_all];
        }
    
        [self.viewController dismissViewControllerAnimated:YES completion:nil];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    }
    
}

//Optional implementation:
-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker
{
    NSLog(@"GMImagePicker: User pressed cancel button");
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}


@end
