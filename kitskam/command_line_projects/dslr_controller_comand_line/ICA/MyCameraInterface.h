//
//  MyCameraInterface.h
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


#import <Carbon/Carbon.h>
//#import <Cocoa/Cocoa.h>

@class MyCameraPictureInterface;
@class TakingPicInfo;

@protocol MyCameraDelegate

- (void) onNewPicture:(MyCameraPictureInterface*)pic;

@end


@interface MyCameraInterface : NSObject {
	ICAObject objCamera;
	NSString* strCameraName;
	Boolean bCanTakePicture;
	Boolean bCanDeletePicture;

	NSObject<MyCameraDelegate>* delegate;
	
    // POSSIBLY CAN ADD CAMERA ICON AND FREE STORAGE SPACE INFO
}

@property (readonly) ICAObject objCamera;
@property (readonly) NSString* strCameraName;
@property (readonly) Boolean bCanTakePicture;
@property (readonly) Boolean bCanDeletePicture;
@property (retain) NSObject<MyCameraDelegate>* delegate;

- (MyCameraInterface*) initWithPropertyDict:(NSDictionary*)dict;
- (MyCameraInterface*) initWithObjHandle:(ICAObject)objHandle;

- (void) dealloc;

- (Boolean) registerNewObjectCallbackWithUnregister:(Boolean)bUnregister;

- (Boolean) takePicture;

// ***********************
// **  PRIVATE METHODS  **
// ***********************

- (void) onNewPictureWithInfo:(ICAObject)objPicture andErrCode:(OSErr)errCode;

@end

@interface MyCameraPictureInterface : NSObject
{
	MyCameraInterface* mci;
	ICAObject objPicture;
	ICAObject objThumb;
	NSString* strDateOriginal;
	NSString* strDevFileName;
	NSInteger picWidth;
	NSInteger picHeight;
	NSInteger picBytes;	
}

@property (readonly) MyCameraInterface* mci;
@property (readonly) ICAObject objPicture;
@property (readonly) NSString* strDateOriginal;
@property (readonly) NSString* strDevFileName;
@property (readonly) NSInteger picWidth;
@property (readonly) NSInteger picHeight;
@property (readonly) NSInteger picBytes;

- (MyCameraPictureInterface*) initWithPictObj:(ICAObject)obj camera:(MyCameraInterface*)_mci;
- (void) dealloc;

- (Boolean) downloadPicToDir:(FSRef*)dirFSRef file:(NSString*)strPicFileName picOSType:(OSType)ostPic;
- (Boolean) downloadPicToDir:(FSRef*)dirFSRef 
						file:(NSString*)strPicFileName 
				   picOSType:(OSType)ostPic
				withThumFile:(NSString*)strThumFileName
					 thumPct:(double)dPct;

- (Boolean) downloadThumToDir:(FSRef*)dirFSRef file:(NSString*)strPicFileName picOSType:(OSType)ostPic;
- (Boolean) deletePictureAndThumb;

// ***********************
// **  PRIVATE METHODS  **
// ***********************

@end

NSArray* GetAttachedCameras(void);
