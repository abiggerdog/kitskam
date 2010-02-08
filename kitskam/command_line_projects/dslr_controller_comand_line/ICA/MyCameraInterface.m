//
//  MyCameraInterface.m
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

#import "MyCameraInterface.h"
#import "MyICAUtils.h"
#import "MyUtils.h"

NSArray* GetAttachedCameras(void) 
{
	NSMutableArray* ret = NULL;
	OSErr err;
	
	ICAGetDeviceListPB  pb;
	memset(&pb, 0, sizeof(pb));
	err = ICAGetDeviceList(&pb, NULL);
	if (err == noErr) {
		ICAObject objDevList = pb.object;
		NSDictionary* dictDevListProp = MyICA_GetObjectProperties(objDevList);
		if (dictDevListProp) {
			NSArray* arrDev = [dictDevListProp objectForKey:@"devices"];
			if (arrDev) {
				ret = [NSMutableArray arrayWithCapacity:0];
				
				int n = [arrDev count];
				for(int k = 0; k < n; ++ k) {
					NSDictionary* dictDev = (NSDictionary*) [arrDev objectAtIndex:k];
					ICAObject objDev = MyICA_GetObjectHandle(dictDev);
					if (objDev) {
						Boolean isCamera = MyICA_IsDeviceCamera(objDev);
						if (isCamera) {
							NSDictionary* dictCameraProperties = 
								MyICA_GetObjectProperties(objDev);
							MyCameraInterface* mci = [ [ [MyCameraInterface alloc]
								   initWithPropertyDict:dictCameraProperties] autorelease];
							[ret addObject:mci];
						} // if (isCamera)
					} // if (objDev)
				} // for(int k = 0; k < n; ++ k)
			} // if (arrDev)
		} // if (dictDevListProp)							
	} // if (err == noErr)
	return ret;
} // GetAttachedCameras

#pragma mark -



// **************************************************************************
// **************************************************************************
// **************************************************************************

static void cameraNewObjICACallBack(CFStringRef notificationType, 
									CFDictionaryRef notificationDictionary);

// **** 
// **** 
// **** 

@implementation MyCameraInterface

@synthesize objCamera;
@synthesize strCameraName;
@synthesize bCanTakePicture;
@synthesize bCanDeletePicture;
@synthesize delegate;  

- (MyCameraInterface*) initWithPropertyDict:(NSDictionary*)dict
{
	if (self = [super init]) {
		objCamera = MyICA_GetObjectHandle(dict);
		strCameraName = MyICA_GetCameraName(dict);
		bCanTakePicture = MyICA_CanCameraCaptureNewImage(dict);
		bCanDeletePicture = MyICA_CanCameraDeleteImage(dict);
		delegate = NULL;
	}
	return self;
}

- (MyCameraInterface*) initWithObjHandle:(ICAObject)objHandle
{
	NSDictionary* dict = MyICA_GetObjectProperties(objHandle);
	if (dict) {
		[self initWithPropertyDict:dict];
	} else {
		[self dealloc];
		self = NULL;
	}
	return self;
}

- (void) dealloc
{

	[delegate release];
	[super dealloc];
}

- (Boolean) registerNewObjectCallbackWithUnregister:(Boolean)bUnregister
{
	// http://developer.apple.com/mac/library/samplecode/SampleScannerApp/listing2.html
	ICARegisterForEventNotificationPB pb;
	memset(&pb, 0, sizeof(pb));
	pb.objectOfInterest = objCamera;
	pb.eventsOfInterest = (CFArrayRef) [NSMutableArray arrayWithObjects: 
										(id)kICANotificationTypeObjectAdded,
										(id)kICAErrorKey,
										(id)kICARefconKey,
										(id)kICANotificationICAObjectKey,
										NULL
										];
	pb.notificationProc = (bUnregister ? NULL : cameraNewObjICACallBack);
	pb.header.refcon = (unsigned long) self;
	OSErr err = ICARegisterForEventNotification(&pb, NULL);
	// sleep 2 ?
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

	if (err == noErr) {
		if (bUnregister) {
			[self release];
		} else {
			[self retain];
		}
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	}
	
	return (err == noErr);
}

- (Boolean) takePicture
{
	Boolean ret = MyICA_CameraTakePicture(objCamera);
	// sleep 2 ?
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	
	// SLEEP ??
//	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

	return ret;
}

// ***************************************************************************
// **  PRIVATE METHODS  ******************************************************
// ***************************************************************************

- (void) onNewPictureWithInfo:(ICAObject)objPicture andErrCode:(OSErr)errCode
{
	if (delegate) {
		MyCameraPictureInterface* mcpi = NULL;
		if (errCode == noErr) {
			mcpi = [ [MyCameraPictureInterface alloc]
					initWithPictObj:objPicture camera:self];
		}
		[delegate onNewPicture:mcpi];
	}
	
}

@end
	
static void cameraNewObjICACallBack(CFStringRef notificationType, 
									CFDictionaryRef notificationDictionary)
{
	// SLEEP ??
//	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	// sleep 2 ?
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	
	
	NSDictionary* dict = (NSDictionary*) notificationDictionary;
	unsigned long refcon = [ (NSNumber*) [dict objectForKey:(NSString*)kICARefconKey] unsignedLongValue ];
	OSErr err = [ (NSNumber*) [dict objectForKey:(NSString*)kICAErrorKey] shortValue ];
	
	ICAObject obj = [ (NSNumber*) [dict objectForKey:(NSString*)kICANotificationICAObjectKey] unsignedIntValue ];
	
	MyCameraInterface* mci = (MyCameraInterface*) refcon;
	[mci onNewPictureWithInfo:obj andErrCode:err];
}

#pragma mark -

// **************************************************************************
// **************************************************************************
// **************************************************************************

@implementation MyCameraPictureInterface

@synthesize mci;
@synthesize objPicture;
@synthesize strDateOriginal;
@synthesize strDevFileName;
@synthesize picWidth;
@synthesize picHeight;
@synthesize picBytes;

- (MyCameraPictureInterface*) initWithPictObj:(ICAObject)obj camera:(MyCameraInterface*)_mci
{
	Boolean bErr = TRUE;
	if (self = [super init]) {
		NSDictionary* dictObjectProperties = MyICA_GetObjectProperties(obj);
		if (dictObjectProperties) {
			mci = _mci;
			if (mci) {
				[mci retain];
			}
			objPicture = obj;
			objThumb = MyICA_GetImageThumHandle(dictObjectProperties);
			strDateOriginal = MyICA_GetImageDateOriginal(dictObjectProperties);
			strDevFileName = MyICA_GetImageFileName(dictObjectProperties);
			picWidth = MyICA_GetImageWidth(dictObjectProperties);
			picHeight = MyICA_GetImageHeight(dictObjectProperties);
			picBytes = MyICA_GetImageSizeBytes(dictObjectProperties);

			bErr = FALSE;
		}
	} 
	if (bErr) {
		[self dealloc];
		self = NULL;
	}

	return self;
}

- (void) dealloc
{
	[mci release];
	[super dealloc];
}

- (Boolean) downloadPicToDir:(FSRef*)dirFSRef file:(NSString*)strPicFileName picOSType:(OSType)ostPic
{
	Boolean ret = MyICA_DownloadImageToFile(dirFSRef, strPicFileName, ostPic, objPicture);
	return ret;
}

- (Boolean) downloadPicToDir:(FSRef*)dirFSRef 
						file:(NSString*)strPicFileName 
				   picOSType:(OSType)ostPic
				withThumFile:(NSString*)strThumFileName
					 thumPct:(double)dPct
{
	Boolean ret = MyICA_DownloadImageToFileAndScaleThum(dirFSRef, strPicFileName, 
														ostPic, objPicture,
														strThumFileName, dPct);
	return ret;
}

- (Boolean) downloadThumToDir:(FSRef*)dirFSRef file:(NSString*)strPicFileName picOSType:(OSType)ostPic
{
	Boolean ret = MyICA_DownloadThumToFile(dirFSRef, strPicFileName, ostPic, objPicture);
	return ret;
}

- (Boolean) deletePictureAndThumb
{
	Boolean ret = MyICA_DeleteImage(objPicture);
	return ret;
}

@end





