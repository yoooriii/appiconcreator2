//
//  main.m
//  AppIconCreator2
//
//  Created by 100500 on 11/03/15.
//  Copyright (c) 2015 Leonid 100500. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/**
 @arguments
 1. path to the source image
 2. path to Images.xcassets
 */

NSData * resizeImage (NSImage *srcImage, const CGFloat imgW, const CGFloat imgH);

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		if (argc != 3) {
			const char * myname = argv[0];
			NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:myname length:strlen(myname)];
			NSString *appname = [path lastPathComponent];
			NSLog(@"wrong arguments; how to use:\n>>%@  src-image.png  Images.xcassets", appname);
			return -1;
		}
		const char * cimgpath = argv[1];
		NSString *pathToImage = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:cimgpath length:strlen(cimgpath)];
		NSImage *srcImage = [[NSImage alloc] initWithContentsOfFile:pathToImage];

		const char * cdir = argv[2];
		NSString *assetsDir = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:cdir length:strlen(cdir)];
		NSString *subdir = [assetsDir stringByAppendingPathComponent:@"AppIcon.appiconset"];
		NSString *jsonFile = [subdir stringByAppendingPathComponent:@"Contents.json"];
		NSData *jsonData = [NSData dataWithContentsOfFile:jsonFile];
		NSError *error = nil;
		NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
		if (!json) {
			NSLog(@"cannot read assets JSON");
			return -1;
		}

		NSArray *arrImages = json[@"images"];
		for (NSMutableDictionary *entry in arrImages) {
			NSString *filename = entry[@"filename"];
			if (filename) {
				NSString *path = [subdir stringByAppendingPathComponent:filename];
				[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
				[entry removeObjectForKey:@"filename"];
			}
			NSString *idiom = entry[@"idiom"];//iphone/ipad
			NSString *scale = entry[@"scale"];// 1x/2x;3x
			NSString *size = entry[@"size"];// 29x29;
			int scaleFactor = 1;
			if (scale) {
				if ([scale isEqualToString:@"2x"]) {
					scaleFactor = 2;
				}
				else if ([scale isEqualToString:@"3x"]) {
					scaleFactor = 3;
				}
			}
			NSString *scaleTxt = @"";
			switch (scaleFactor) {
				default:
				case 1:			scaleTxt = @"";			break;
				case 2:			scaleTxt = @"@2x";		break;
				case 3:			scaleTxt = @"@3x";		break;
			}
			if (idiom) {
				idiom = [@"~" stringByAppendingString:idiom];
			}
			filename = [NSString stringWithFormat:@"icon%@%@%@.png", size, scaleTxt, idiom ? : @""];
			//	get icon size
			NSArray *sizeComponents = [size componentsSeparatedByString:@"x"];
			if (2 == sizeComponents.count) {
				const int width = [sizeComponents[0] intValue] * scaleFactor;
				const int height = [sizeComponents[1] intValue] * scaleFactor;
				NSData *imgData = resizeImage(srcImage, width, height);
				NSString *resultImgPath = [subdir stringByAppendingPathComponent:filename];
				[[NSFileManager defaultManager] removeItemAtPath:resultImgPath error:NULL];
				BOOL success = [imgData writeToFile:resultImgPath atomically:YES];
				if (!success) {
					NSLog(@"cannot write image file %@", resultImgPath);
					continue;
				}
				entry[@"filename"] = filename;
			}
		}
		NSData *updJsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
		if (updJsonData) {
			[[NSFileManager defaultManager] removeItemAtPath:jsonFile error:NULL];
			BOOL success = [updJsonData writeToFile:jsonFile atomically:YES];
			if (!success) {
				NSLog(@"cannot overwrite json file");
				return -1;
			}
		}
	}

	NSLog(@"OK");
    return 0;
}

NSData * resizeImage (NSImage *srcImage, const CGFloat imgW, const CGFloat imgH) {
	//	Drawing directly to a bitmap
	NSRect offscreenRect = NSMakeRect(0.0, 0.0, imgW, imgH);
	NSBitmapImageRep *offscreenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
																			 pixelsWide:offscreenRect.size.width
																			 pixelsHigh:offscreenRect.size.height
																		  bitsPerSample:8
																		samplesPerPixel:4
																			   hasAlpha:YES
																			   isPlanar:NO
																		 colorSpaceName:NSCalibratedRGBColorSpace
																		   bitmapFormat:0
																			bytesPerRow:(4 * offscreenRect.size.width)
																		   bitsPerPixel:32];

	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext
										  graphicsContextWithBitmapImageRep:offscreenRep]];

	[srcImage drawInRect:offscreenRect];

	[NSGraphicsContext restoreGraphicsState];

	NSDictionary *properties = nil;
	NSData *imgData = [offscreenRep representationUsingType:NSPNGFileType properties:properties];
	return imgData;
}
