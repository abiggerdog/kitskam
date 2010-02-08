//
//  MyWindowController.h
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

#import "AmazonS3UploadCommandLineController.h"
#import "DSLRCommandLineController.h"

#import <Foundation/Foundation.h>

@class PreferencesController;

#define eInvalidState -1

typedef enum _MyCaptureState {
	eStopped = 0,
	eStarted = 1,
	eTakingPic = 2,
	eTakingPicStopPending = 3,
	eSavingPic = 4, 
	eSavingPicStopPending = 5
} MyCaptureState;

typedef enum _MyCaptureStateTransitionType {
	eStartStopButton,
	eTimer
} MyCaptureStateTransitionType;

// POSSIBLE STATES
// 0: eStopped
// 1: eStarted
// 2: eTakingPic
// 3: eTakingPic stop request pending
// 4: eSaving
// 5: eSavingPic stop request pending

// TRANSITIONS OCCUR WHEN START/STOP BUTTON PRESSED,
// OR A TIMER OR TIMER-SIM SELECTOR CALL OCCUR (BOTH REFERRED TO AS TIMER BELOW)
// 0 -> button press  1   # timer -> 0
// 1 -> button press  0   # timer -> 2 
// 2 -> button press  3   # timer -> 4
// 3 -> button press  2   # timer -> 5
// 4 -> button press  5   # timer -> 1
// 5 -> button press  4   # timer -> 0

@class MCDSLRCmdInfo;

@interface MyController : NSObject 
< DSLRCommandLineControllerDelegate, AmazonS3UploadCommandLineControllerDelegate >
{
	IBOutlet NSWindow* mWindow;
	IBOutlet NSTextField* mAmazonS3BucketLabel;
	IBOutlet NSTextField* mAmazonS3RemoteUploadDir;
	IBOutlet NSTextField* mAmazonS3AccessLabel;
	IBOutlet NSTextField* mAmazonS3DeleteAfterUploadLabel;
	IBOutlet NSTextField* mCameraLabel;
	IBOutlet NSTextField* mSaveDirLabel;
	
	IBOutlet NSTextField* mImageNameLabel;
	IBOutlet NSTextField* mThumNameLabel;
	IBOutlet NSTextField* mThumPercentageTextField;
	
	IBOutlet NSTextField* mBaseImageNameLabel;
	IBOutlet NSTextField* mPicIntervalLabel;
	IBOutlet NSImageView* mImageView;
	IBOutlet NSTextField* mImageViewLabel;
	IBOutlet NSTextField* mStartStopLabel;
	IBOutlet NSButton* mStartStopButton;
	IBOutlet NSButton* mUploadButton;
	IBOutlet NSTextField* mUploadLabel;
	IBOutlet NSScrollView* mLogScrollView;
	
	IBOutlet NSButton* mbErrorsOnlyButton;

	NSTextView* mLogTextView;
	NSString* mStrAppTitle;
	PreferencesController* mPrefController;	
	AmazonS3UploadCommandLineController* amazonS3CmdController;
	DSLRCommandLineController* dslrCmdController;
	NSTimer* mPicIntervalTimer;
	NSTimer* mUploadTimer;
	Boolean mbUploadInProgress;
	MyCaptureState mrCaptureState;
	NSMutableArray* mUploadDirContents;
}

@property (readonly) DSLRCommandLineController* dslrCmdController;

- (MyController*) init;
- (void) awakeFromNib ;
- (void) dealloc;

#pragma mark PUBLIC METHODS

- (NSString*) getWindowTitleFromSubTitle:(NSString*)strSubTitle;

- (IBAction) onClearLog:(id)sender;
- (IBAction) onPreferencesMenu:(id)sender;
- (IBAction) onStartStopButton:(id)sender;
- (IBAction) onUploadButton:(id)sender;

- (Boolean) showOkCancelWarningDialogWithMsg:(NSString*)strMsg 
									 andInfo:(NSString*)strInfo
									subTitle:(NSString*)strSubTitle;

- (void) showOkInfoDialogWithMsg:(NSString*)strMsg 
						 andInfo:(NSString*)strInfo
						subTitle:(NSString*)strSubTitle;

// ***********
// *********** AmazonS3UploadCommandLineControllerDelegate
// ***********
#pragma mark AmazonS3UploadCommandLineControllerDelegate
- (void) onAamazonS3CommandCompleteWithStdOutJSonObj:(NSObject*)objRet 
										  withStrErr:(NSString*)strErr 
											 retCode:(int)ret 
											timedOut:(Boolean)bTimedOut
											userData:(void*)user;

// ***********
// *********** DSLRCommandLineControllerDelegate
// ***********
#pragma mark DSLRCommandLineControllerDelegate

- (void) onCommandCompleteWithStdOutJSonObj:(NSObject*)objRet 
								 withStrErr:(NSString*)strErr 
									retCode:(int)ret 
								   timedOut:(Boolean)bTimedOut
								   userData:(void*)user;

// ***********
// *********** NSWindowDelegate
// ***********
#pragma mark NSWindowDelegate
- (BOOL)windowShouldClose:(id)sender;
- (void)windowWillClose: (NSNotification *)notification;

// **********
// ********** PRIVATE METHODS
// **********
#pragma mark PRIVATE METHODS

- (void) checkFirstRun;

- (void) createCaptureTimer;

- (Boolean) downloadAndDeletePic:(ICAObject)objPic
					   toPicPath:(NSString*)strPicPath
					  toThumPath:(NSString*)strThumPath
						 thumPct:(double)dThumPct
					 deleteAfter:(Boolean)bDelAfter
					 withTimeOut:(NSTimeInterval)timeOut
						picWidth:(int)picWidth
					   picHeight:(int)picHeight
						 picDate:(NSString*)strPicDate
						picBytes:(unsigned int)picBytes;

- (MyCaptureState) getNextCaptureState:(MyCaptureStateTransitionType) mrstt
						   err:(Boolean)bErr;

- (Boolean) getPictPath:(NSString**)pStrPicPath
			andThumPath:(NSString**)pStrThumPath
			 forPicDict:(NSDictionary*)dict
			  forCamera:(NSString*)strCamera
			  objCamera:(ICAObject)objCamera;

- (void) onCaptureTimer:(NSObject*)param;

- (void) onUploadTimer:(NSObject*)param;

- (Boolean) scanUploadDir;

- (Boolean) shouldLogWithIsErr:(Boolean)isErr;

- (Boolean) shouldUploadPic;

- (Boolean) startTakingPhoto;

- (void) transitionRunWithTransition:(MyCaptureStateTransitionType) mrstt 
						 withCmdInfo:(MCDSLRCmdInfo*)mcdci
								 err:(Boolean)bErr;

- (void) updateUIForImgDownload:(MCDSLRCmdInfo*)mcdci;

- (void) updateUIForCaptureState;

- (void) updateUIFromPreferences;

- (void) writeToLogString:(NSString*)str isErr:(Boolean)isErr;

@end
