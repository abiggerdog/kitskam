/*
 *  MyICAUtils.h
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
#include <Carbon/Carbon.h>

#define kNoObject		0

#pragma mark -

Boolean MyICA_CanCameraCaptureNewImage(NSDictionary* dictCameraProperties);
Boolean MyICA_CanCameraDeleteImage(NSDictionary* dictCameraProperties);
NSString* MyICA_GetCameraName(NSDictionary* dictObjectProperties);
NSArray* MyICA_GetCameraPictHandles(ICAObject objCamera);
NSArray* MyICA_GetCameraPictHandlesFromPropertiesDict(NSDictionary* dictCameraProperties);
Boolean MyICA_IsDeviceCamera(ICAObject objDev);
Boolean MyICA_CameraTakePicture(ICAObject objCamera);

#pragma mark -

Boolean MyICA_DeleteImage(ICAObject objImage);
Boolean MyICA_DownloadImage(FSRef* fileFSRef, ICAObject objImage, 
							OSType osFileType, FSRef* dirFSRef);
Boolean MyICA_DownloadImageToFile(FSRef* dirFSRef, NSString* strFileName, 
								  OSType osFileType, ICAObject objImage);
Boolean MyICA_DownloadImageToFileAndScaleThum(FSRef* dirFSRef, NSString* strFileName, 
											  OSType osFileType, ICAObject objImage,
											  NSString* strThumName, double dPct);
Boolean MyICA_DownloadThumToFile(FSRef* dirFSRef, NSString* strFileName, 
								 OSType osFileType, ICAObject objImage);
NSString* MyICA_GetImageDateOriginal(NSDictionary* dictObjectProperties);
NSString* MyICA_GetImageFileName(NSDictionary* dictObjectProperties);
NSInteger MyICA_GetImageWidth(NSDictionary* dictObjectProperties);
NSInteger MyICA_GetImageHeight(NSDictionary* dictObjectProperties);
NSInteger MyICA_GetImageSizeBytes(NSDictionary* dictObjectProperties);
ICAObject MyICA_GetImageThumHandle(NSDictionary* dictObjectProperties);

#pragma mark -

ICAObject MyICA_GetObjectHandle(NSDictionary* dictObjectProperties);
NSDictionary* MyICA_GetObjectProperties(ICAObject obj);

