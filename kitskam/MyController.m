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

#import "AppSettings.h"
#import "DSLRCommandLineController.h"
#import "MyUtils.h"
#import "PreferencesController.h"

// *****************************************************************************
// *****************************************************************************
// *****************************************************************************

@interface MyFileInfo : NSObject
{
	NSString* strFilePath;
	NSDate* fileDate;
}
@property (retain) NSString* strFilePath;
@property (retain) NSDate* fileDate;
- (MyFileInfo*) init;
- (void) dealloc;
- (NSComparisonResult) compareTo:(MyFileInfo*)mfi;
@end

// **********
// **********
// **********

@implementation MyFileInfo

@synthesize strFilePath;
@synthesize fileDate;

- (MyFileInfo*) init
{
	if (self = [super init]) {
		strFilePath = NULL;
		fileDate = NULL;
	}
	return self;
}

- (void) dealloc
{
	[strFilePath release];
	[fileDate release];
	[super dealloc];
}

- (NSComparisonResult) compareTo:(MyFileInfo*)mfi
{
	NSComparisonResult ret = [fileDate compare:mfi.fileDate];
	if (ret == NSOrderedSame) {
		ret = [strFilePath compare:mfi.strFilePath];
	}
	return ret;
}

@end

// *****************************************************************************
// *****************************************************************************
// *****************************************************************************

typedef enum _MCDSLRCmdType {
	eCmdTakePic,
	eCmdDownloadPic
} MCDSLRCmdType;

@interface MCDSLRCmdInfo : NSObject
{
	MCDSLRCmdType cmdType;
	Boolean bDelAfter;
	ICAObject objPic;
	NSString* strDownloadPicPath;
	NSString* strDownloadThumPath;
	int picWidth;
	int picHeight;
	NSString* strPicDate;
	unsigned int picBytes;
	
	NSString* strCamera;
	ICAObject objCamera;
}
@property (assign) MCDSLRCmdType cmdType;
@property (assign) Boolean bDelAfter;
@property (assign) ICAObject objPic;
@property (retain) NSString* strDownloadPicPath;
@property (retain) NSString* strDownloadThumPath;
@property (assign) int picWidth;
@property (assign) int picHeight;
@property (retain) NSString* strPicDate;
@property (assign) unsigned int picBytes;
@property (retain) NSString* strCamera;
@property (assign) ICAObject objCamera;
@end

// **********
// **********
// **********

@implementation MCDSLRCmdInfo

@synthesize cmdType;
@synthesize bDelAfter;
@synthesize objPic;
@synthesize strDownloadPicPath;
@synthesize strDownloadThumPath;
@synthesize picWidth;
@synthesize picHeight;
@synthesize strPicDate;
@synthesize picBytes;
@synthesize strCamera;
@synthesize objCamera;

- (MCDSLRCmdInfo*) init 
{
	if (self = [super init]) {
		cmdType = eInvalidState;
		bDelAfter = FALSE;
		objPic = 0;
		strDownloadPicPath = NULL;
		strDownloadThumPath = NULL;
		strCamera = NULL;
		objCamera = 0;
		picWidth = 0;
		picHeight = 0;
		strPicDate = NULL;
		picBytes = 0;
	}
	return self;
}

- (void) dealloc
{
	[strCamera release];
	[strDownloadPicPath release];
	[strDownloadThumPath release];
	[strPicDate release];
	[super dealloc];
}

@end

// *****************************************************************************
// *****************************************************************************
// *****************************************************************************

#pragma mark -

@implementation MyController

@synthesize dslrCmdController;

+ (void) initialize 
{
	NSLog(@"mycontroller initialize");
}

- (MyController*) init
{
	if (self = [super init]) {
		mStrAppTitle = APP_TITLE;
		mPrefController = NULL;
		amazonS3CmdController = NULL;
		dslrCmdController = NULL;
		mPicIntervalTimer = NULL;
		mrCaptureState = eStopped;
		mUploadTimer = NULL;
		mbUploadInProgress = FALSE;
		mUploadDirContents = NULL;
	}
	return self;
}

- (void)awakeFromNib
{
	mLogTextView = (NSTextView*) [mLogScrollView documentView];
	
	amazonS3CmdController = [ [ [AmazonS3UploadCommandLineController 
											   alloc] init] autorelease];
	[amazonS3CmdController retain];
	dslrCmdController = [ [ [DSLRCommandLineController alloc] init] autorelease];
	[dslrCmdController retain];
	mPrefController = [ [ [PreferencesController alloc] init] autorelease];
	[mPrefController retain];
	
	mWindow.delegate = self;
	[mWindow setTitle:mStrAppTitle];
	
	[self onClearLog:NULL];
	[self updateUIFromPreferences];
	
	[self performSelector:@selector(checkFirstRun) withObject:self afterDelay:CHECK_FIRSTRUN_DELAY_SEC];	
		
	mUploadTimer = [NSTimer scheduledTimerWithTimeInterval:UPLOAD_TIMER_INTERVAL_SEC
													target:self 
												  selector:@selector(onUploadTimer:)
												  userInfo:NULL
												   repeats:TRUE];
	[mUploadTimer retain];
}

- (void) dealloc
{
	[mPicIntervalTimer release];
	[mPrefController release];
	[dslrCmdController release];
	[amazonS3CmdController release];
	[mUploadDirContents release];
	
	[super dealloc];
}

#pragma mark PUBLIC METHODS

- (NSString*) getWindowTitleFromSubTitle:(NSString*)strSubTitle
{
	NSString* strTitle = [NSString stringWithFormat:@"%@:  %@", 
						  mStrAppTitle, strSubTitle];
	return strTitle;
}

- (IBAction) onClearLog:(id)sender;
{
	NSTextStorage* stor = [mLogTextView textStorage];
	NSInteger textLength = [stor length];
	[stor beginEditing];
	[stor replaceCharactersInRange:NSMakeRange(0, textLength) withString:@""];
	[stor endEditing];
}

- (IBAction) onPreferencesMenu:(id)sender
{
	[mPrefController showWindow:self]; 
	[NSApp runModalForWindow:[mPrefController window]];
	[self updateUIFromPreferences];
}

- (IBAction) onStartStopButton:(id)sender
{
	Boolean bProceed = TRUE;
	if (mrCaptureState == eStopped && ! [mPrefController validateSavedCaptureValues]) {
		bProceed = [self showOkCancelWarningDialogWithMsg:@"Capture settings are invalid."
			andInfo:@"Please use the 'Preferences' menu to review your settings."
					"  Picture capture will not be possible until errors in preferences are corrected."
												 subTitle:@"Warning" ];
	}
	if (bProceed) {
		[self transitionRunWithTransition:eStartStopButton
							  withCmdInfo:NULL
									  err:FALSE];
	}
}

- (IBAction) onUploadButton:(id)sender
{
	if ( [self shouldUploadPic] ) {
		if ( ! [mPrefController validateSavedUploadValues] ) {
			if ( ! [self 
				  showOkCancelWarningDialogWithMsg:@"There are errors in Amazon S3 Upload preferences" 
				  andInfo:@"Amazon S3 upload may fail unless the errors are corrected" 
				  subTitle:@"Confirm"] ) {
				[mUploadButton setState:NSOffState];
			}
		}
	}
}

- (Boolean) showOkCancelWarningDialogWithMsg:(NSString*)strMsg 
									 andInfo:(NSString*)strInfo
									subTitle:(NSString*)strSubTitle
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	NSString* strTitle = [self getWindowTitleFromSubTitle:strSubTitle];
	[ [alert window] setTitle:strTitle];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:strMsg];
	[alert setInformativeText:strInfo];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	NSInteger retCode = [alert runModal];
	return (retCode == NSAlertFirstButtonReturn);
}

- (void) showOkInfoDialogWithMsg:(NSString*)strMsg 
						 andInfo:(NSString*)strInfo
						subTitle:(NSString*)strSubTitle
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	NSString* strTitle = [self getWindowTitleFromSubTitle:strSubTitle];
	[ [alert window] setTitle:strTitle];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:strMsg];
	[alert setInformativeText:strInfo];
	[alert setAlertStyle: NSInformationalAlertStyle];
	[alert runModal];
}

// ***********
// *********** AmazonS3UploadCommandLineControllerDelegate
// ***********
#pragma mark AmazonS3UploadCommandLineControllerDelegate
- (void) onAamazonS3CommandCompleteWithStdOutJSonObj:(NSObject*)objRet 
										  withStrErr:(NSString*)strErr 
											 retCode:(int)ret 
											timedOut:(Boolean)bTimedOut
											userData:(void*)user
{
	[mUploadLabel setStringValue:@""];
	NSString* strPath = (NSString*) user;
	NSString* strFile = [strPath lastPathComponent];
	
	if (ret == 0 && ! bTimedOut) {
		NSString* strTemp = 
		[NSString stringWithFormat:@"Uploaded %@ to Amazon S3", strFile];
		[self writeToLogString:strTemp isErr:FALSE];
		[self performSelector:@selector(onUploadTimer:)
				   withObject:NULL afterDelay:0.0];
		
		if ( ! [mPrefController amazonS3DeleteAfter] ) {
			Boolean bSavedFile = FALSE;
			FSRef uploadFSRef;
			if (MakeFSRefFromNSString(&uploadFSRef, strPath)) {
				NSString* strSaveDir = [mSaveDirLabel stringValue];
				FSRef saveDirFSRef;
				if (MakeFSRefFromNSString(&saveDirFSRef, strSaveDir)) {
					OSStatus retCode =
					FSMoveObjectSync(&uploadFSRef, &saveDirFSRef, (CFStringRef) strFile,
									 NULL, kFSFileOperationOverwrite);
					if (retCode == noErr) {
						bSavedFile = TRUE;
						NSString* strTemp = 
						[NSString stringWithFormat:@"Stored %@ after Amazon S3 upload", strFile];
						[self writeToLogString:strTemp isErr:FALSE];
					}
				}
			}
			if (!bSavedFile) { 
				NSString* strTemp = 
				[NSString stringWithFormat:@"Error storing %@ after Amazon S3 upload", strFile];
				[self writeToLogString:strTemp isErr:TRUE];
			}
		}
		
	} else {
		if (bTimedOut) {
			NSString* strTemp = 
			[NSString stringWithFormat:@"Error uploading %@ to Amazon S3: Timed Out ( %@ )", strFile, strErr];
			[self writeToLogString:strTemp isErr:TRUE];
		} else {
			NSString* strTemp = 
			[NSString stringWithFormat:@"Error uploading %@ to Amazon S3: %@", strFile, strErr];
			[self writeToLogString:strTemp isErr:TRUE];
		}
	}
	[strPath release];	
//	[strFile release];	
	mbUploadInProgress = FALSE;
}

// ***********
// *********** DSLRCommandLineControllerDelegate
// ***********

#pragma mark DSLRCommandLineControllerDelegate

- (void) onCommandCompleteWithStdOutJSonObj:(NSObject*)objRet 
								 withStrErr:(NSString*)strErr 
									retCode:(int)ret 
								   timedOut:(Boolean)bTimedOut
								   userData:(void*)user
{
	MCDSLRCmdInfo* mcdci = (MCDSLRCmdInfo*) user;
	
	switch(mcdci.cmdType) {
		case eCmdTakePic: {
			if (!bTimedOut && ret == 0) {
				NSDictionary* dict = (NSDictionary*) objRet;
				ICAObject objPic = (ICAObject) [ (NSNumber*) [dict objectForKey:@"icao"] 
												unsignedIntValue ];
				NSString* strPicPath = NULL;
				NSString* strThumPath = NULL;
				if ([self getPictPath:&strPicPath
						  andThumPath:&strThumPath
						   forPicDict:dict
							forCamera:[mCameraLabel stringValue]
							objCamera:[mPrefController cameraObjHandle]]
					) {
					mcdci.objPic = objPic;
					mcdci.strDownloadPicPath = strPicPath;
					mcdci.strDownloadThumPath = strThumPath;
					mcdci.strCamera = [mCameraLabel stringValue];
					mcdci.objCamera = [mPrefController cameraObjHandle];
					mcdci.picWidth = [ (NSNumber*) [dict objectForKey:@"0100"] intValue ];
					mcdci.picHeight = [ (NSNumber*) [dict objectForKey:@"0101"] intValue ];
					mcdci.strPicDate = [dict objectForKey:@"9003"];
					mcdci.picBytes = [ (NSNumber*) [dict objectForKey:@"isiz"] unsignedIntValue];
					[self transitionRunWithTransition:eTimer
										  withCmdInfo:mcdci
												  err:FALSE];
				} else {
					NSString* strLog = [NSString 
										stringWithFormat:@"Take pic (%@) failed: %@", 
										[mCameraLabel stringValue], 
										@"Error determining save path"];
					[self writeToLogString:strLog isErr:TRUE];
					[self transitionRunWithTransition:eTimer
										  withCmdInfo:mcdci
												  err:TRUE];
				}
			} else {
				NSString* strLog = [NSString 
					stringWithFormat:@"Take pic (%@) failed: %@", 
									[mCameraLabel stringValue],
									(bTimedOut ? @"Timed Out" : strErr) ];
				[self writeToLogString:strLog isErr:TRUE];
				
				[mPrefController onReScanCameras:NULL];
				
				[self transitionRunWithTransition:eTimer
									  withCmdInfo:mcdci
											  err:TRUE];
			}
		} break;
		case eCmdDownloadPic:
			if (!bTimedOut && ret == 0) {
				NSString* strLog = [NSString 
					stringWithFormat:@"Saved %@ AND %@", 
									[mcdci.strDownloadPicPath lastPathComponent], 
									[mcdci.strDownloadThumPath lastPathComponent] ];
				[self writeToLogString:strLog isErr:FALSE];
				[self updateUIForImgDownload:mcdci];
				[self transitionRunWithTransition:eTimer 
									  withCmdInfo:mcdci
											  err:FALSE];
				
				[self performSelector:@selector(onUploadTimer:)
						   withObject:NULL afterDelay:0.0];
//				[self onUploadTimer:NULL];
			} else {
				NSString* strLog = [NSString 
					stringWithFormat:@"Save pic (%@) failed: %@", 
									mcdci.strDownloadPicPath, 
									(bTimedOut ? @"Timed Out" : strErr) ];
				[self writeToLogString:strLog isErr:TRUE];
				[self transitionRunWithTransition:eTimer
									  withCmdInfo:mcdci
											  err:TRUE];
			}
			break;
		default:
			assert(FALSE);
			break;
	}
	
	[mcdci release];
}


// ***********
// *********** NSWindowDelegate
// ***********

#pragma mark NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender
{
	BOOL ret = TRUE;
	if (mrCaptureState != eStopped && mrCaptureState != eStarted) {
		ret = [self 
			   showOkCancelWarningDialogWithMsg:@"Continue with application exit?" 
			   andInfo:@"Photo capture in progress.  Exiting application "
			   "may leave photos undeleted on the device." 
			   subTitle:@"Confirm"];
		if (! ret) {
			[self onStartStopButton:NULL];
		}
	}
	return ret;
}

- (void)windowWillClose: (NSNotification *)notification
{
    if ([notification object] == mWindow) {
		[NSApp terminate: self];
	}
}

// **********
// ********** PRIVATE METHODS
// **********

#pragma mark PRIVATE METHODS

- (void) checkFirstRun
{
	if ( [mPrefController isFirstRun] ) {
		[self showOkInfoDialogWithMsg:@"This is the first time you've run this program.  "
		 "The preferences dialog will automatically be displayed."
							  andInfo:@"It will not be possible to peform image capture until "
		 "your preferences have been set." 
							 subTitle:@"Note -- First Run"];
		[self onPreferencesMenu:NULL];
	}
}

- (void) createCaptureTimer
{
	NSTimeInterval dPictInterval = [mPrefController pictInterval];
	[mPicIntervalTimer invalidate];
	[mPicIntervalTimer release];
	mPicIntervalTimer = NULL;
	mPicIntervalTimer = [NSTimer scheduledTimerWithTimeInterval:dPictInterval
														 target:self 
													   selector:@selector(onCaptureTimer:)
													   userInfo:NULL
														repeats:TRUE];
	[mPicIntervalTimer retain];
}

- (Boolean) downloadAndDeletePic:(ICAObject)objPic
					   toPicPath:(NSString*)strPicPath
					  toThumPath:(NSString*)strThumPath
						 thumPct:(double)dThumPct
					 deleteAfter:(Boolean)bDelAfter
					 withTimeOut:(NSTimeInterval)timeOut
						picWidth:(int)picWidth
					   picHeight:(int)picHeight
						 picDate:(NSString*)strPicDate
						picBytes:(unsigned int)picBytes
{
	MCDSLRCmdInfo* mcdci = [ [ [MCDSLRCmdInfo alloc] init] autorelease];
	[mcdci retain];
	mcdci.cmdType = eCmdDownloadPic;
	mcdci.bDelAfter = TRUE;
	mcdci.strDownloadPicPath = strPicPath;
	mcdci.strDownloadThumPath = strThumPath;
	mcdci.picWidth = picWidth;
	mcdci.picHeight = picHeight;
	mcdci.strPicDate = strPicDate;
	mcdci.picBytes = picBytes;

	Boolean ret = [dslrCmdController downloadPhotoWithTimeOut:timeOut
												 withDelegate:self
													 userData:mcdci
													  picPath:strPicPath
													 thumPath:strThumPath
													  thumPct:dThumPct
													  withPic:objPic
												 shouldDelete:bDelAfter];
	return ret;
}

- (MyCaptureState) getNextCaptureState:(MyCaptureStateTransitionType) mrstt
						   err:(Boolean)bErr
{
	static MyCaptureState arNextStateForButtonPress[] = {
		eStarted,				// 0: eStopped
		eStopped,				// 1: eStarted
		eTakingPicStopPending,	// 2: eTakingPic
		eTakingPic,				// 3: eTakePicStopPending
		eSavingPicStopPending,	// 4: eSaving
		eSavingPic				// 5: eSavingPicStopPending
	};
	static MyCaptureState arNextStateForTimer[] = {
		eStopped,				// 0: eStopped
		eTakingPic,				// 1: eStarted
		eSavingPic,				// 2: eTakingPic
		eSavingPicStopPending,	// 3: eTakePicStopPending
		eStarted,				// 4: eSaving
		eStopped				// 5: eSavingPicStopPending
	};
	static MyCaptureState arNextStateForTimerWithErr[] = {
		eStopped,				// 0: eStopped
		eStarted,				// 1: eStarted
		eStarted,				// 2: eTakingPic
		eStopped,				// 3: eTakePicStopPending
		eStarted,				// 4: eSaving
		eStopped				// 5: eSavingPicStopPending
	};
	assert(0 <= mrCaptureState && mrCaptureState <= 5);
	MyCaptureState ret = eInvalidState;
	switch (mrstt) {
		case eStartStopButton:
			assert(! bErr);
			ret = arNextStateForButtonPress[mrCaptureState];
			break;
		case eTimer:
			if ( ! bErr) {
				ret = arNextStateForTimer[mrCaptureState];
			} else {
				ret = arNextStateForTimerWithErr[mrCaptureState];
			}
			break;
		default:
			assert(FALSE);
			break;
	}
	return ret;
}

- (Boolean) getUploadPendingDirectory:(NSString**)pstrUpPendDir
							forCamera:(NSString*)strCamera 
					  cameraObjHandle:(ICAObject)cameraObjHandle
{
	Boolean ret = FALSE;
	NSString* strSaveDir = [mPrefController saveDir];
	NSString* strUploadDirName = UPLOAD_DIRECTORY;
//	NSString* strUploadDirName = [NSString stringWithFormat:@"upload_%@",
//								  [mCameraLabel stringValue] ];
	strUploadDirName = [strUploadDirName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	*pstrUpPendDir = [strSaveDir stringByAppendingPathComponent:strUploadDirName];
	BOOL bDir;
	if ( [ [NSFileManager defaultManager] fileExistsAtPath:*pstrUpPendDir 
											   isDirectory:&bDir] ) {
		if (bDir) {
			ret = TRUE;
		} else {
			NSString* temp = [NSString stringWithFormat:
							  @"Error: %@ is not a directory.", *pstrUpPendDir];
			[self writeToLogString:temp isErr:TRUE];
		}
	} else {
		if ([ [NSFileManager defaultManager] 
			 createDirectoryAtPath:*pstrUpPendDir
			 /*withIntermediateDirectories:FALSE*/ attributes:NULL]) {
			ret = TRUE;
		} else {
			NSString* temp = [NSString stringWithFormat:
							  @"Error: could not create directory %@", *pstrUpPendDir];
			[self writeToLogString:temp isErr:TRUE];
		}
	}
	return ret;
}

- (Boolean) getPictPath:(NSString**)pStrPicPath
			andThumPath:(NSString**)pStrThumPath
			 forPicDict:(NSDictionary*)dict
			  forCamera:(NSString*)strCamera
			  objCamera:(ICAObject)objCamera
{
	Boolean ret = FALSE;
	NSString* strSaveDir = [mPrefController saveDir];
//	NSString* strBaseName = [mPrefController imageBaseName];
	NSString* strDate = [ [dict objectForKey:@"9003"] 
						 stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	
	if (strDate) {
		strDate = [strDate stringByReplacingOccurrencesOfString:@" " withString:@"_"];
		NSString* strPicName = [mPrefController getNameFromPattern:[mPrefController imageNamePat]
															iField:@"pic" 
															dField:strDate
															eField:@"jpg"];
		NSString* strThumName = [mPrefController getNameFromPattern:[mPrefController thumNamePat]
															 iField:@"thum" 
															 dField:strDate
															 eField:@"jpg"];
//		NSString* strPicName = [NSString stringWithFormat:@"%@pic_%@.jpg", strBaseName, strDate];
//		NSString* strThumName = [NSString stringWithFormat:@"%@thum_%@.jpg", strBaseName, strDate];
		//		*pStrPicPath = [strSaveDir stringByAppendingPathComponent:*pStrPicPath];
		
		if ( [self shouldUploadPic] ) {
			NSString* strUploadDir;
			if ( [self getUploadPendingDirectory:&strUploadDir
									   forCamera:strCamera cameraObjHandle:objCamera]) {
				*pStrPicPath = [strUploadDir stringByAppendingPathComponent:strPicName];
				*pStrThumPath = [strUploadDir stringByAppendingPathComponent:strThumName];
				ret = TRUE;
			}
		} else {
			*pStrPicPath = [strSaveDir stringByAppendingPathComponent:strPicName];
			*pStrThumPath = [strSaveDir stringByAppendingPathComponent:strThumName];
			ret = TRUE;
		}
	}
	return ret;
}

- (void) onCaptureTimer:(NSObject*)param
{
	if (mrCaptureState == eStarted) {
		[self transitionRunWithTransition:eTimer
							  withCmdInfo:NULL
									  err:FALSE];
	}
}

- (void) onUploadTimer:(NSObject*)param
{
	if (! mbUploadInProgress &&  [self shouldUploadPic] ) {
		if ( [mUploadDirContents count] == 0 ) {
			[self scanUploadDir];
		}
		
		Boolean bFound = FALSE;
		while( ! bFound && [mUploadDirContents count] > 0) {
			MyFileInfo* mfi = [mUploadDirContents objectAtIndex:0];
			NSString* strPath = mfi.strFilePath;
			NSString* strFile = [strPath lastPathComponent];
			Boolean bIsDir;
			if (IsDirectory(strPath, &bIsDir)) {
				if (!bIsDir) {
					bFound = TRUE;
					
					NSString* strRemotePath = 
					[ [mAmazonS3RemoteUploadDir stringValue] 
					 stringByAppendingPathComponent:strFile];
					
					[strPath retain];
					if (! [amazonS3CmdController 
						   amazonS3UploadFile:strPath
						   toBucket:[mAmazonS3BucketLabel stringValue]
						   toObjectKey:strRemotePath
						   withAccess:[mAmazonS3AccessLabel stringValue]
						   deleteAfterUpload:[mPrefController amazonS3DeleteAfter]
						   forSharedKey:[mPrefController amazonS3SharedKey]
						   forSecretKey:[mPrefController amazonS3SecretKey]
						   userData:(void*)strPath
						   withTimeOut:UPLOAD_TIMEOUT_SEC
						   deletegate:self] ) {
						[strPath release];
						[self writeToLogString:@"Unable to upload to Amazon S3:  "
						 "Error starting upload process." isErr:TRUE];
					} else {
						mbUploadInProgress = TRUE;
						[mUploadLabel setStringValue:strFile];
					}
				}
			} else {
				NSString* strErr = [NSString stringWithFormat:@"Upload to Amazon S3:  "
						  "error getting file attributes for %@", strFile];
				[self writeToLogString:strErr isErr:TRUE];
			}
			[mUploadDirContents removeObjectAtIndex:0];
		}
	} // if (! mbUploadInProgress &&  [self shouldUploadPic] )
}

//- (void) onUploadTimer:(NSObject*)param
//{
//	NSString* strUploadDir = @"???";
//	NSString* strErr = NULL;
//	if (! mbUploadInProgress) {
//		if ( [self shouldUploadPic] ) {
//			if ( [self getUploadPendingDirectory:&strUploadDir
//									   forCamera:[mCameraLabel stringValue]
//								 cameraObjHandle:[mPrefController cameraObjHandle]]) {
//				NSArray* arrDir = [ [NSFileManager defaultManager] 
//								   contentsOfDirectoryAtPath:strUploadDir error:NULL];
//				if (arrDir) {
//					Boolean bFound = FALSE;
//					int nDir = [arrDir count];
//					for(int k = 0; !bFound && k < nDir; ++ k) {
//						NSString* strFile = [arrDir objectAtIndex:k];
//						if ( [ [strFile substringToIndex:1] compare:@"."] != NSOrderedSame ) {
//							NSString* strPath = 
//							[strUploadDir stringByAppendingPathComponent:strFile];
//							Boolean bIsDir;
//							if (IsDirectory(strPath, &bIsDir)) {
//								if ( ! bIsDir) {
//									bFound = TRUE;
//									
//									NSString* strRemotePath = 
//									[ [mAmazonS3RemoteUploadDir stringValue] 
//									 stringByAppendingPathComponent:strFile];
//									
//									[strPath retain];
//									//[strFile retain];
//									if (! [amazonS3CmdController 
//										   amazonS3UploadFile:strPath
//										   toBucket:[mAmazonS3BucketLabel stringValue]
//										   toObjectKey:strRemotePath
//										   withAccess:[mAmazonS3AccessLabel stringValue]
//										   deleteAfterUpload:[mPrefController amazonS3DeleteAfter]
//										   forSharedKey:[mPrefController amazonS3SharedKey]
//										   forSecretKey:[mPrefController amazonS3SecretKey]
//										   userData:(void*)strPath
//										   withTimeOut:UPLOAD_TIMEOUT_SEC
//										   deletegate:self] ) {
//										strErr = @"Error starting upload process.";
//										[strPath release];
//										//[strFile release];
//									} else {
//										mbUploadInProgress = TRUE;
//										[mUploadLabel setStringValue:strFile];
//									}
//								}
//							} else {
//								strErr = 
//								[NSString stringWithFormat:@"Error getting file attributes for %@",
//								 strFile];
//							}
//						}
//					}
//				} else {
//					strErr = @"Error reading contents of upload directory";
//				}
//			} else {
//				strErr = @"Error getting local directory for pics to be uploaded.";
//			}
//		}
//	}
//	
//	if (strErr) {
//		NSString* strTemp = 
//		[NSString stringWithFormat:@"Unable to upload to Amazon S3 (upload director %@):  %@",
//		 strUploadDir, strErr];
//		[self writeToLogString:strTemp];
//	}
//}

- (Boolean) scanUploadDir
{
	Boolean ret = TRUE;
	[mUploadDirContents release];
	mUploadDirContents = NULL;
	mUploadDirContents = [NSMutableArray array];

	if ( [self shouldUploadPic] ) {
		ret = FALSE;
		NSString* strUploadDir = NULL;
		if ( [self getUploadPendingDirectory:&strUploadDir
								   forCamera:[mCameraLabel stringValue]
							 cameraObjHandle:[mPrefController cameraObjHandle]]) {
			NSArray* arrDir = [ [NSFileManager defaultManager] 
							   contentsOfDirectoryAtPath:strUploadDir error:NULL];
			if (arrDir) {
				ret = TRUE;
				for(NSString* strFile in arrDir) {
					if ([ [strFile substringToIndex:1] compare:@"." ] != NSOrderedSame &&
						[ [strFile substringToIndex:1] compare:@"-" ] != NSOrderedSame ) {
						NSString* strPath = [strUploadDir stringByAppendingPathComponent:strFile];
						NSDictionary* dict =
						[ [NSFileManager defaultManager]
						 attributesOfItemAtPath:strPath error:NULL];
						if (dict) {
							NSString* strFileType = [dict objectForKey:NSFileType];
							if (strFileType) {
								if ( [strFileType compare:NSFileTypeRegular] == NSOrderedSame ) {
									NSDate* fileDate = [dict objectForKey:NSFileModificationDate];
									if (fileDate) {
										MyFileInfo* mfi = [ [ [MyFileInfo alloc] init] autorelease];
										mfi.strFilePath = strPath;
										mfi.fileDate = fileDate;
										[mUploadDirContents addObject:mfi];
									} else {
										ret = FALSE;
									}
								}
							} else {
								ret = FALSE;
							}
						} else {
							ret = FALSE;
						}
					}
					if (! ret) {
						break;
					}
				} // for(NSString* strFile in arrDir) 
			}
		}
	}

	NSArray* arrTemp = [mUploadDirContents sortedArrayUsingSelector:@selector(compareTo:)];
	if (arrTemp) {
		mUploadDirContents = [NSMutableArray arrayWithArray:arrTemp];
	} else {
		ret = FALSE;
	}
	
	[mUploadDirContents retain];
	
	return ret;
}

- (Boolean) shouldLogWithIsErr:(Boolean)isErr
{
	Boolean ret = FALSE;
	if ( [mbErrorsOnlyButton state] == NSOffState ) {
		ret = TRUE;
	} else if ( [mbErrorsOnlyButton state] == NSOnState ) {
		ret = isErr;
	} else {
		assert(FALSE);
	}
	return ret;
}

- (Boolean) shouldUploadPic
{
	Boolean ret = FALSE;
	if ( [mUploadButton state] == NSOffState ) {
		ret = FALSE;
	} else if ( [mUploadButton state] == NSOnState ) {
		ret = TRUE;
	} else {
		assert(FALSE);
	}
	return ret;
}

- (Boolean) startTakingPhoto
{
	Boolean ret = FALSE;
	MCDSLRCmdInfo* mcdci = [ [ [MCDSLRCmdInfo alloc] init] autorelease];
	[mcdci retain];
	mcdci.cmdType = eCmdTakePic;
	
	ICAObject objCamera = [mPrefController cameraObjHandle];
	
	ret = [dslrCmdController takePhotoWithTimeOut:DEVICE_OPERATION_TIMEOUT_SEC
									 withDelegate:self 
										 userData:(void*)mcdci
									   withCamera:objCamera] ;
	return ret;
}

- (void) transitionRunWithTransition:(MyCaptureStateTransitionType) mrstt 
						 withCmdInfo:(MCDSLRCmdInfo*)mcdci
								 err:(Boolean)bErr
{
	
	MyCaptureState nextState = [self getNextCaptureState:mrstt err:bErr];
	switch(nextState) {
		case eStopped: {
			[mPicIntervalTimer invalidate];
			[mPicIntervalTimer release];
			mPicIntervalTimer = NULL;
		} break;
		case eStarted: {
			if (mrCaptureState == eStopped) {
				[self createCaptureTimer];
				[mPicIntervalTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.0]];
			}
		} break;
		case eTakingPic:
		case eTakingPicStopPending:
			if (mrCaptureState == eStarted) {
				if (! [self startTakingPhoto]) {
					nextState = (nextState == eTakingPic) ? eStarted : eStopped;
					NSString* strLog = [NSString 
						stringWithFormat:@"Failed to start taking pic for camera %@",
										[mCameraLabel stringValue] ];
					[self writeToLogString:strLog isErr:TRUE];
				} 
			}
			break;
		case eSavingPic:
		case eSavingPicStopPending:
			if (mrCaptureState == eTakingPic || mrCaptureState == eTakingPicStopPending) {
				double dThumPct = [mPrefController thumPct] / 100;
				if (! [self downloadAndDeletePic:mcdci.objPic
									   toPicPath:mcdci.strDownloadPicPath
									  toThumPath:mcdci.strDownloadThumPath
										 thumPct:dThumPct
									 deleteAfter:TRUE
									 withTimeOut:DEVICE_OPERATION_TIMEOUT_SEC
										picWidth:mcdci.picWidth
									   picHeight:mcdci.picHeight
										 picDate:mcdci.strPicDate
										picBytes:mcdci.picBytes] ) {
					nextState = (nextState == eSavingPic) ? eStarted : eStopped;
					NSString* strLog = [NSString 
						stringWithFormat:@"Failed to begin downloading pic (%W) for camera %@",
										mcdci.strDownloadPicPath, [mCameraLabel stringValue] ];
					[self writeToLogString:strLog isErr:TRUE];
				} 
			}
			break;
		default:
			assert(FALSE);
			break;
	}
	mrCaptureState = nextState;
	[self updateUIForCaptureState];
}

- (void) updateUIForImgDownload:(MCDSLRCmdInfo*)mcdci
{
	NSImage* img = [ [ [NSImage alloc] 
					  initByReferencingFile:mcdci.strDownloadPicPath] 
					autorelease];
	[mImageView setImage:img];
	
	NSString* str = [NSString stringWithFormat:@"%@ \nWidth: %d x Height:%d \nBytes:%u \nDate:%@",
					 [mcdci.strDownloadPicPath lastPathComponent],
					 mcdci.picWidth, mcdci.picHeight, 
					 mcdci.picBytes, mcdci.strPicDate];
	[mImageViewLabel setStringValue:str];
	
}

- (void) updateUIForCaptureState
{
	NSString* strStartStopButton = NULL;
	NSString* strLabel = NULL;
	switch(mrCaptureState) {
		case eStopped:
			strStartStopButton = @"START";
			strLabel = @"";
			break;
		case eStarted:
			strStartStopButton = @"STOP";
			strLabel = @"Waiting for timer...";
			break;
		case eTakingPic:
			strStartStopButton = @"STOP";
			strLabel = @"Taking pic...";
			break;
		case eTakingPicStopPending:
			strStartStopButton = @"Stopping ...";
			strLabel = @"Taking pic...";
			break;
		case eSavingPic:
			strStartStopButton = @"STOP";
			strLabel = @"Saving pic...";
			break;
		case eSavingPicStopPending:
			strStartStopButton = @"Stopping ...";
			strLabel = @"Saving pic...";
			break;
		default:
			assert(FALSE);
			break;
	}
	
	[mStartStopLabel setStringValue:strLabel];
	[mStartStopButton setTitle:strStartStopButton];
}

- (void) updateUIFromPreferences
{
	NSString* strAmazonS3Bucket = [mPrefController amazonS3Bucket];
	[mAmazonS3BucketLabel setStringValue:strAmazonS3Bucket];
	NSString* strAmazonS3RemotePath = [mPrefController amazonS3RemotePath];
	[mAmazonS3RemoteUploadDir setStringValue:strAmazonS3RemotePath];
	NSString* strAmazonS3Access = [mPrefController amazonS3Access];
	[mAmazonS3AccessLabel setStringValue:strAmazonS3Access];
	Boolean bDeleteAfter = [mPrefController amazonS3DeleteAfter];
	[mAmazonS3DeleteAfterUploadLabel setStringValue:(bDeleteAfter ? @"YES" : @"no")];
	
	NSString* strCameraName = [mPrefController cameraShownName];
	[mCameraLabel setStringValue:strCameraName];
//	NSString* strCameraName = [mPrefController cameraName];
//	[mCameraLabel setStringValue:strCameraName];
	NSString* strSaveDir = [mPrefController saveDir];
	[mSaveDirLabel setStringValue:strSaveDir];
	NSString* strImageNamePat = [mPrefController imageNamePat];
	[mImageNameLabel setStringValue:strImageNamePat];
	NSString* strThumNamePat = [mPrefController thumNamePat];
	[mThumNameLabel setStringValue:strThumNamePat];
	double dThumPct = [mPrefController thumPct];
	NSString* strThumPct = [NSString stringWithFormat:@"%1.1lf", dThumPct];
	[mThumPercentageTextField setStringValue:strThumPct];
//	NSString* strBaseImageName = [mPrefController imageBaseName];
//	[mBaseImageNameLabel setStringValue:strBaseImageName];
	double dPictInterval = [mPrefController pictInterval];
	NSString* strPictInterval = [NSString stringWithFormat:@"%1.1lf", dPictInterval];
	[mPicIntervalLabel setStringValue:strPictInterval];
	
	if (mPicIntervalTimer) {
		[self createCaptureTimer];
	}
}

- (void) writeToLogString:(NSString*)str isErr:(Boolean)isErr
{
	if ( [self shouldLogWithIsErr:isErr] ) {
		NSDate* dateNow = [NSDate dateWithTimeIntervalSinceNow:0.0];
		str = [NSString stringWithFormat:@"[%@] %@ \n\n", [dateNow description], str];
		
		NSFont *stringFont = [NSFont fontWithName:LOGFONT_NAME size:LOGFONT_SIZE];
		NSDictionary *stringAttributes =  
		[NSDictionary dictionaryWithObject:stringFont 
									forKey:NSFontAttributeName];	
		
		NSMutableAttributedString* attStr = [ [ [NSMutableAttributedString alloc] 
											   initWithString:str 
											   attributes:stringAttributes] autorelease];
		
		NSTextStorage* stor = [mLogTextView textStorage];
		[stor beginEditing];
		[stor appendAttributedString:attStr];
		[stor endEditing];	
		NSInteger textLength = [stor length];
		
		NSPoint bottomOfDocument = {0, 9999999}; 
		bottomOfDocument = [[mLogScrollView contentView] 
							constrainScrollPoint:bottomOfDocument]; 
		[[mLogScrollView contentView] scrollToPoint:bottomOfDocument]; 	
		
		[mLogTextView scrollRangeToVisible:NSMakeRange(textLength-1, 1)];
	}
}

@end














