//
//  MyUtils.m
/*
 This file is part of kitskam DSLR controller for OS X 10.5 and above.
 
 kitskam is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 kitskam is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
 
 Copyright Duncan Rawlinson, February 2010.   All rights reserved.
 Code written by:
 
 http://www.elance.com/php/profile/main/eolproviderprofile.php?userid=2443714
 http://www.RentACoder.com/RentACoder/DotNet/SoftwareCoders/ShowBioInfo.aspx?lngAuthorId=6770066
 
 */

#import "MyUtils.h"
#import <Cocoa/Cocoa.h>

Boolean ComparePaths(Boolean* pbSame, NSString* strPath1, NSString* strPath2) 
{
	Boolean ret = FALSE;
	if (GetAbsoultePath(&strPath1, strPath1) &&
		GetAbsoultePath(&strPath2, strPath2)) {
		*pbSame = ( [strPath1 compare:strPath2] == NSOrderedSame );
		ret = TRUE;
	}
	return ret;
}

Boolean GetAbsoultePath(NSString** pstrAbsPath, NSString* strPath)
{
	Boolean ret = FALSE;
	NSURL* url = [NSURL fileURLWithPath:strPath];
	url = [url absoluteURL];
	url = [url standardizedURL];
	strPath = [url path];
	strPath = [strPath stringByStandardizingPath];
	if (strPath) {
		ret = TRUE;
		*pstrAbsPath = strPath;
	}
	return ret;
}

Boolean IsDirectory(NSString* strPath, Boolean* pbDir) {
	Boolean ret = FALSE;
	BOOL bDir;
	if ( [ [NSFileManager defaultManager] fileExistsAtPath:strPath isDirectory:&bDir] ) {
		*pbDir = bDir;
		ret = TRUE;
	}
	return ret;
}

Boolean IsValidFileName(NSString* strFileName)
{
	const char* psz = [strFileName fileSystemRepresentation];
	NSString* str2 = [NSString stringWithCString:psz encoding:NSUTF8StringEncoding];
	Boolean ret = ( [strFileName compare:str2] == NSOrderedSame );
	return ret;
}

Boolean MakeFSRefFromNSString(FSRef* ref, NSString* str) 
{
	Boolean ret = FALSE;
	NSURL* url = [NSURL URLWithString:
				  [str stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding] ];
	if (url) {
		ret = CFURLGetFSRef( (CFURLRef) url, ref);
	}

	return ret;
}

//Boolean MakeFSRefFromNSString(FSRef* ref, NSString* str) 
//{
//	Boolean ret = FALSE;
//	NSURL* url = [NSURL URLWithString:str];
//	if (url) {
//		ret = CFURLGetFSRef( (CFURLRef) url, ref);
//	}
//	
//	return ret;
//}

NSString* MakeNSStringFromFSRef(FSRef* ref)
{
	NSURL* url = (NSURL*) CFURLCreateFromFSRef(kCFAllocatorDefault, ref);
	NSString* ret = [url path];
	return ret;
}

Boolean ScaleImageToJpg(NSString* strInputImagePath, NSString* strOutputImagePath, double dPct)
{
	Boolean ret = FALSE;
	NSImage* sourceImage = [ [ [NSImage alloc] 
							  initByReferencingFile:strInputImagePath] 
							autorelease];
	if (sourceImage) {
		// FIX DPI / PIXEL SIZE MISMATCH
		[sourceImage setScalesWhenResized: YES];
		NSBitmapImageRep *rep = (NSBitmapImageRep*) [sourceImage bestRepresentationForDevice: nil];
		if (rep) {
			NSSize pixelSize = NSMakeSize([rep pixelsWide],[rep pixelsHigh]);
			[sourceImage setSize: pixelSize];		
			
			NSSize szSourceImage = [sourceImage size];
			NSSize szSmallImage = NSMakeSize(szSourceImage.width * dPct, szSourceImage.height * dPct);
			
			NSImage *smallImage = [[[NSImage alloc] initWithSize:szSmallImage] autorelease];
			if (smallImage) {
				[smallImage lockFocus];
				[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
				[sourceImage setSize:szSmallImage];
				[sourceImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
				[smallImage unlockFocus];	
				
				NSData *imageData = [smallImage  TIFFRepresentation];
				if (imageData) {
					NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
					NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] 
																		   forKey:NSImageCompressionFactor];
					imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
					ret = [imageData writeToFile:strOutputImagePath atomically:TRUE];	
				} else {
					NSLog(@"Error getting TIFF data for thumbnail");
				}
			} else {
				NSLog(@"Error allocating thumbnail image");
			}
		} else {
			NSLog(@"Error getting bitmap representation for image: %W", strInputImagePath);
		}
	} else {
		NSLog(@"Error reading image: %@", strInputImagePath);
	}

	return ret;
}

Boolean ValidateDouble(NSString* str, double* pDoub)
{
	Boolean ret = TRUE;
	str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	const char* psz = [str cStringUsingEncoding:NSASCIIStringEncoding];
	for(int k = 0; psz[k]; ++ k) {
		if ( !isnumber(psz[k]) && psz[k] != '.' && psz[k] != ',' ) {
			ret = FALSE;
			break;
		}
	}
	ret = ret && ( sscanf(psz, "%lf", pDoub) == 1 );
	return ret;
}
