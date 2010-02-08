/*
 *  MyICAUtils.c
 *
 */
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

//#include <Foundation/Foundation.h>
#include "MyICAUtils.h"
#import "MyUtils.h"

static Boolean GetThumFormat(OSType* ostThum, OSType ostFileType) ;

static void emptyCallBack(ICAHeader* pb) {
}

Boolean MyICA_CanCameraCaptureNewImage(NSDictionary * dictCameraProperties)
{
	NSArray * capabilities = [dictCameraProperties objectForKey: @"capa"];
	Boolean ret = 
		[capabilities containsObject: 
			[NSNumber numberWithUnsignedLong: kICAMessageCameraCaptureNewImage]];
	return ret;
}

Boolean MyICA_CanCameraDeleteImage(NSDictionary* dictCameraProperties)
{
	NSArray * capabilities = [dictCameraProperties objectForKey: @"capa"];
	Boolean ret = 
	[capabilities containsObject: 
	 [NSNumber numberWithUnsignedLong: kICACapabilityCanCameraDeleteOne]];
	return ret;
}

NSArray* MyICA_GetCameraPictHandles(ICAObject objCamera)
{
	NSArray* ret = NULL;
	NSDictionary* dictCameraProperties = MyICA_GetObjectProperties(objCamera);
	if (dictCameraProperties) {
		ret = MyICA_GetCameraPictHandlesFromPropertiesDict(dictCameraProperties);
	}
	return ret;
}

NSArray* MyICA_GetCameraPictHandlesFromPropertiesDict(NSDictionary* dictCameraProperties)
{
	NSMutableArray* ret = NULL;
	NSArray* arrData = [dictCameraProperties objectForKey: @"data"];
	if (arrData) {
		ret = [NSMutableArray arrayWithCapacity:0];
		int n = [arrData count];
		for(int k = 0; k < n; ++ k) {
			NSDictionary* dictData = [arrData objectAtIndex:k];
			ICAObject obj = MyICA_GetObjectHandle(dictData);
//			NSDictionary* dictTemp =  MyICA_GetObjectProperties(obj);
			[ret addObject:[NSNumber numberWithUnsignedLong:(unsigned long) obj]];
		}
	}
	return ret;
}

NSString* MyICA_GetCameraName(NSDictionary* dictObjectProperties)
{
	NSString* ret =  MyICA_GetImageFileName(dictObjectProperties);
	return ret;
}

Boolean MyICA_IsDeviceCamera(ICAObject objDev)
{
	Boolean ret = FALSE;
    
    ICAGetObjectInfoPB getObjectInfoPB;
    memset(&getObjectInfoPB, 0, sizeof(ICAGetObjectInfo));
    getObjectInfoPB.object = objDev;
	
    OSErr err = ICAGetObjectInfo (&getObjectInfoPB, nil);
    if (noErr == err) {
        ret = (getObjectInfoPB.objectInfo.objectType == kICADevice) && 
		(getObjectInfoPB.objectInfo.objectSubtype == kICADeviceCamera);
    }
    return ret;
}

Boolean MyICA_CameraTakePicture(ICAObject objCamera)
{
	Boolean ret = FALSE;
    ICAObjectSendMessagePB  pb ;
	memset(&pb, 0, sizeof(pb));
    pb.object  				= objCamera;
    pb.message.messageType	= kICAMessageCameraCaptureNewImage;
	
    OSErr err = ICAObjectSendMessage(&pb, emptyCallBack);
	if (err == noErr) {
		ret = TRUE;
	}
	return ret;
}

#pragma mark -

Boolean MyICA_DeleteImage(ICAObject objImage)
{
	Boolean ret = FALSE;
    ICAObjectSendMessagePB  pb ;
	memset(&pb, 0, sizeof(pb));
    pb.object  				= objImage;
    pb.message.messageType	= kICAMessageCameraDeleteOne;
	
    OSErr err = ICAObjectSendMessage(&pb, NULL);
	if (err == noErr) {
		ret = TRUE;
	}
	return ret;
}

Boolean MyICA_DownloadImage(FSRef* fileFSRef, ICAObject objImage, 
							OSType osFileType, FSRef* dirFSRef)
{
	ICADownloadFilePB pb ;
	memset(&pb, 0, sizeof(pb));
	pb.object   = objImage;
	pb.dirFSRef = dirFSRef;
	pb.fileFSRef= fileFSRef;
	pb.fileType = osFileType;
	
	OSErr err = ICADownloadFile(&pb, NULL);
	return ( err == noErr );
}

Boolean MyICA_DownloadImageToFile(FSRef* dirFSRef, NSString* strFileName, 
								  OSType osFileType, ICAObject objImage)
{
	Boolean ret = FALSE;
	NSString* strTempDir = NSTemporaryDirectory();
	FSRef tempDirFSRef;
	if ( MakeFSRefFromNSString(&tempDirFSRef, strTempDir) ) {
		FSRef imageTempFSRef;
		if (MyICA_DownloadImage(&imageTempFSRef, objImage, osFileType, &tempDirFSRef)) {
			OSStatus retCode =
			FSMoveObjectSync(&imageTempFSRef, dirFSRef, (CFStringRef) strFileName, 
							 NULL, kFSFileOperationOverwrite);
			if (retCode == noErr) {
				ret = TRUE;
			}
			if (! ret) {
				FSDeleteObject(&imageTempFSRef);
			}
		}
	}
	
	return ret;
}

Boolean MyICA_DownloadImageToFileAndScaleThum(FSRef* dirFSRef, NSString* strFileName, 
											  OSType osFileType, ICAObject objImage,
											  NSString* strThumName, double dPct)
{
	Boolean ret = FALSE;
	NSString* strTempDir = NSTemporaryDirectory();
	FSRef tempDirFSRef;
	if ( MakeFSRefFromNSString(&tempDirFSRef, strTempDir) ) {
		FSRef imageTempFSRef;
		if (MyICA_DownloadImage(&imageTempFSRef, objImage, osFileType, &tempDirFSRef)) {
			NSString* strTempThumPath = [strTempDir stringByAppendingPathComponent:strThumName];
			NSString* strTempImagePath = MakeNSStringFromFSRef(&imageTempFSRef);
			if (strTempImagePath) {
				if (ScaleImageToJpg(strTempImagePath, strTempThumPath, dPct)) {
					FSRef thumTempFSRef;
					if (MakeFSRefFromNSString(&thumTempFSRef, strTempThumPath)) {
						OSStatus retCode =
						FSMoveObjectSync(&imageTempFSRef, dirFSRef, (CFStringRef) strFileName, 
										 NULL, kFSFileOperationOverwrite);
						if (retCode == noErr) {
							retCode = FSMoveObjectSync(&thumTempFSRef, dirFSRef, (CFStringRef) strThumName, 
													   NULL, kFSFileOperationOverwrite);
							if (retCode == noErr) {
								ret = TRUE;
							} else {
								FSDeleteObject(&thumTempFSRef);
								
								FSRef imageRef;
								if (MakeFSRefFromNSString(&imageRef, 
														  [ MakeNSStringFromFSRef(dirFSRef) 
														   stringByAppendingPathComponent:strFileName])) {
									FSDeleteObject(&imageRef);
								}
							}
						} else {
							FSDeleteObject(&imageTempFSRef);
						}
					} 
				}
			}
		}
	}
	
	return ret;
}

Boolean MyICA_DownloadThumToFile(FSRef* dirFSRef, NSString* strFileName, 
								 OSType osFileType, ICAObject objImage)
{
	Boolean ret = FALSE;
	NSString* strPath = [ MakeNSStringFromFSRef(dirFSRef)
						 stringByAppendingPathComponent:strFileName];
	if (strPath) {
		OSType ostThum;
		if (GetThumFormat(&ostThum, osFileType)) {
			NSData* thumData = NULL;
			ICACopyObjectThumbnailPB  pb;
			memset(&pb, 0, sizeof(pb));
			pb.object          = objImage;
			pb.thumbnailData = (CFDataRef*) &thumData;
			pb.thumbnailFormat = ostThum;
			OSErr err = ICACopyObjectThumbnail( &pb, NULL );
			if (err == noErr) {
				if (thumData) {
					if ( [thumData writeToFile:strPath atomically:TRUE] ) {
						ret = TRUE;
					}
					[thumData release];
				}
			}
		}
	}
	return ret;
}

NSString* MyICA_GetImageDateOriginal(NSDictionary* dictObjectProperties)
{
	NSString* ret = [dictObjectProperties objectForKey:@"9003"];
	return ret;
}

NSString* MyICA_GetImageFileName(NSDictionary* dictObjectProperties)
{
	NSString* ret = (NSString*)  [dictObjectProperties objectForKey:@"ifil"];
	return ret;
}

NSInteger MyICA_GetImageWidth(NSDictionary* dictObjectProperties)
{
	NSInteger ret = (NSInteger) [ [dictObjectProperties objectForKey:@"0100"] integerValue];
	return ret;
}

NSInteger MyICA_GetImageHeight(NSDictionary* dictObjectProperties)
{
	NSInteger ret = (NSInteger) [ [dictObjectProperties objectForKey:@"0101"] integerValue];
	return ret;
}

NSInteger MyICA_GetImageSizeBytes(NSDictionary* dictObjectProperties)
{
	NSInteger ret = (NSInteger) [ [dictObjectProperties objectForKey:@"isiz"] integerValue];
	return ret;
}

ICAObject MyICA_GetImageThumHandle(NSDictionary* dictObjectProperties)
{
	ICAObject ret = (ICAObject) [ [dictObjectProperties objectForKey:@"thum"] unsignedLongValue];
	return ret;
}

#pragma mark -

ICAObject MyICA_GetObjectHandle(NSDictionary* dictObjectProperties)
{
	ICAObject ret = (ICAObject)[[dictObjectProperties objectForKey: @"icao"] unsignedLongValue];
	return ret;
}

NSDictionary* MyICA_GetObjectProperties(ICAObject obj)
{
    NSDictionary* dictProp = NULL;
	
	ICACopyObjectPropertyDictionaryPB pb;
    memset(&pb, 0, sizeof(pb));
	pb.object  = obj;
    pb.theDict = (CFDictionaryRef*) &dictProp;
	
	OSErr err = ICACopyObjectPropertyDictionary(&pb, NULL);
	if (err != noErr) {
		dictProp = NULL;
	}
	return dictProp;
}


// ****************************************************************************
// **  MODULE PRIVATE FUNCTIONS  **********************************************
// ****************************************************************************

static Boolean GetThumFormat(OSType* ostThum, OSType ostFileType) {
	*ostThum = 0;
	switch(ostFileType) {
		case 'JPEG':
		case 'jpeg':
			*ostThum = kICAThumbnailFormatJPEG;
			break;
		case 'PNG ':
		case 'png ':
			*ostThum = kICAThumbnailFormatPNG;
	    case 'TIFF':
		case 'tiff':
			*ostThum = kICAThumbnailFormatTIFF;
		default:
			break;
	}
	return ( *ostThum != 0 );
}
