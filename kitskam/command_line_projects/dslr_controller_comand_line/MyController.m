//
//  MyController.m
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

#import "MyController.h"

#import "MyCameraInterface.h"
#import "MyICAUtils.h"
#import "MyUtils.h"
#import "SBJsonWriter.h"

#import <Carbon/Carbon.h>

static void WriteJSon(NSObject* obj, Boolean bHumanReadable) ;

// *****************************************************************************
// *****************************************************************************
// *****************************************************************************

@implementation MyController

@synthesize retCode;

- (MyController*) initWithArgc:(int)argc Argv:(char**)argv
{
	if (self = [super init]) {
		retCode = -1;
		memset(&cmd, 0, sizeof(cmd));
		if (! ParseCommandLine(&cmd, argc, argv)) {
			if (cmd.bPrintHelp) {
				OutputUsage();
			}
			
			[self dealloc];
			self = NULL;
		}
	}		
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) doCommandLine
{
	if (cmd.bPrintHelp) {
		OutputUsage();
	}
	
	if (cmd.timeIntTimeOut != 0) {
		[self performSelector:@selector(onTimeOut) withObject:self 
				   afterDelay:cmd.timeIntTimeOut];
	}

	switch(cmd.ct) {
		case eNoCommand:
			assert(FALSE);
			break;
		case eCameraList:
			[self writeCameraList];
			break;
		case eDownloadImage:
			[self downloadImage];
			break;
		case eDeleteImage:
			[self deleteImage];
			break;
		case eTakePicture:
			[self takePicture];
			break;
		default:
			assert(FALSE);
	}
	
}

-(void) deleteImage 
{
	ICAObject objPic = cmd.u.downImgCmd.objImage;
	MyCameraPictureInterface* mcpi = 
		[ [ [MyCameraPictureInterface alloc] initWithPictObj:objPic camera:NULL] autorelease ];
	if ( ! [mcpi deletePictureAndThumb] ) {
		fprintf(stderr, "Error deleting image %u\n", objPic);
	} else {
		retCode = 0;
	}
	QuitApplicationEventLoop();
}

- (void) downloadImage
{
	Boolean bSuccess = FALSE;
	DownloadImageCommand* pDownImgCmd = GetDownloadImageCmd(&cmd);
	ICAObject objPic = pDownImgCmd->objImage;
	MyCameraPictureInterface* mcpi = 
		[ [ [MyCameraPictureInterface alloc] initWithPictObj:objPic camera:NULL] autorelease ];
	NSString* strFilePath = [NSString stringWithCString:pDownImgCmd->pszImageFileName];
	NSString* strThumPath = [NSString stringWithCString:pDownImgCmd->pszThumFileName];
	if (strFilePath && strThumPath) {
		if (GetAbsoultePath(&strFilePath, strFilePath) &&
				GetAbsoultePath(&strThumPath, strThumPath)) {
			NSString* strFileDir = [strFilePath stringByDeletingLastPathComponent];
			NSString* strThumDir = [strThumPath stringByDeletingLastPathComponent];
			FSRef fileDirFSRef;
			FSRef thumDirFSRef;
			if (MakeFSRefFromNSString(&fileDirFSRef, strFileDir) &&
					MakeFSRefFromNSString(&thumDirFSRef, strThumDir) ) {
				NSString* strFile = [strFilePath lastPathComponent];
				NSString* strThum = [strThumPath lastPathComponent];
				if ( pDownImgCmd->bHasThumPct ) {
					if ([mcpi downloadPicToDir:&fileDirFSRef
										  file:strFile
									 picOSType:'JPEG'
								  withThumFile:strThum
									   thumPct:pDownImgCmd->dThumPct]) {
						bSuccess = TRUE;
					}		
				} else {
					if ([mcpi downloadPicToDir:&fileDirFSRef 
										  file:strFile picOSType:'JPEG']) {
						if ( [mcpi downloadThumToDir:&thumDirFSRef 
												file:strThum picOSType:'JPEG'] ) {
							bSuccess = TRUE;
						} else {
							FSRef fileFSRef;
							if ( MakeFSRefFromNSString(&fileFSRef, strFilePath) ) {
								FSDeleteObject(&fileFSRef);
							}
						}
					}
				}
			}
		}
	}
	
	if (! bSuccess) {
		fprintf(stderr, "Error downloading image %u\n", objPic);
	}
	
	if (cmd.u.downImgCmd.bDeleteAfter && (bSuccess || pDownImgCmd->bForceDelete) ) {
		if (! [mcpi deletePictureAndThumb]) {
			bSuccess = FALSE;
			fprintf(stderr, "Error deleting image %u\n", objPic);
		}
	}
	
	if (bSuccess) {
		retCode = 0;
	}
	
	QuitApplicationEventLoop();
}

- (void) onTimeOut
{
	fprintf(stderr, "Time Out %lf occurred\n", cmd.timeIntTimeOut);
	QuitApplicationEventLoop();
}

- (void) takePicture 
{
	// sleep 2 ?
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	
	Boolean bSuccess = FALSE;
	ICAObject objCamera = cmd.u.takePicCmd.objCamera;
	MyCameraInterface* mci = [ [ [MyCameraInterface alloc] 
				initWithObjHandle:objCamera ] autorelease];
	if (mci) {
		mci.delegate = self;
		if ( [mci registerNewObjectCallbackWithUnregister:FALSE] ) {
			if ( [mci takePicture] ) {
				// SLEEP ??
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
				
				bSuccess = TRUE;
			}
		}
	}
	
	if (! bSuccess ) {
		fprintf(stderr, "Error initiating take picture with camera %u\n", 
				objCamera);
		QuitApplicationEventLoop();
	}
}

- (void) writeCameraList
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
				ret =  [NSMutableArray arrayWithCapacity:0];
				
				int n = [arrDev count];
				for(int k = 0; k < n; ++ k) {
					NSDictionary* dictDev = (NSDictionary*) [arrDev objectAtIndex:k];
					ICAObject objDev = MyICA_GetObjectHandle(dictDev);
					if (objDev) {
						Boolean isCamera = MyICA_IsDeviceCamera(objDev);
						if (isCamera) {
							NSDictionary* dictCameraProperties = 
								MyICA_GetObjectProperties(objDev);
							
							[ret addObject:dictCameraProperties ];
						} // if (isCamera)
					} // if (objDev)
				} // for(int k = 0; k < n; ++ k)
			} // if (arrDev)
		} // if (dictDevListProp)							
	} // if (err == noErr)
	
	if (ret) {
		WriteJSon(ret, cmd.bHumanReadable);
		retCode = 0;
	} else {
		fprintf(stderr, "Error reading camera device list\n");
	}
	
	QuitApplicationEventLoop();	
}

// **********
// ********** MyCameraDelegate
// **********

- (void) onNewPicture:(MyCameraPictureInterface*)pic
{
	// SLEEP ??
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	
	ICAObject objPic = (pic ? pic.objPicture : 0);
	ICAObject objCamera = (pic ? pic.mci.objCamera : 0);
	if (pic && objPic) {
		if (cmd.u.takePicCmd.bDownloadImage) {
			cmd.u.takePicCmd.downImgCmd.objImage = objPic;
			[self downloadImage];
		} else {
			NSDictionary* dict = MyICA_GetObjectProperties(objPic);
			if (dict) {
				WriteJSon(dict, cmd.bHumanReadable);
				retCode = 0;
			} else {
				fprintf(stderr, "Error getting picture information for picture %u on camera %u\n",
						objPic, objCamera);
			}
		}
		
		[pic.mci registerNewObjectCallbackWithUnregister:TRUE];
	} else {
		fprintf(stderr, "Error receiving pictuore on camera %u\n", objCamera);
	}
	
	QuitApplicationEventLoop();
}
@end

static void WriteJSon(NSObject* obj, Boolean bHumanReadable) {
	SBJsonWriter* json = [ [ [SBJsonWriter alloc] init ] autorelease];
	json.humanReadable = bHumanReadable;
	NSString* strOut = [json stringWithObject:obj];
	//NSLog( strOut );
	const char* psz = [strOut cStringUsingEncoding:NSUTF8StringEncoding];
	printf(psz);
	//printf( [strOut cStringUsingEncoding:NSASCIIStringEncoding] );
}

















