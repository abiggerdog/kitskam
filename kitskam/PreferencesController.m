//
//  PreferencesController.m
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

#import "PreferencesController.h"

#import "AppSettings.h"
#import "MyAmazonS3Utils.h"
#import "MyController.h"
#import "MyUndocumented.h"
#import "MyUtils.h"

#import <Carbon/Carbon.h>

@implementation PreferencesController

#define PREF_AMAZONS3_BUCKET_KEY		@"azs3bucket"
#define PREF_AMAZONS3_REMOTEPATH_KEY	@"azs3remotepath"
#define PREF_AMAZONS3_SHARED_KEY		@"azs3sharedkey"
#define PREF_AMAZONS3_SECRET_KEY		@"azs3secretkey"
#define PREF_AMAZONS3_ACCESS_KEY		@"azs3accesskey"
#define PREF_AMAZONS3_DELETEAFTER_KEY	@"azs3deleteafter"

#define PREF_CAMERA_KEY					@"objCamera"
#define PREF_CAMERANAME_KEY				@"camera name"
#define PREF_CAMERASHOWNNAME_KEY		@"camera shown name"
#define PREF_SAVEDIR_KEY				@"save directory"
//#define PREF_IMAGEBASENAME_KEY			@"image base name"
#define PREF_IMAGENAMEPAT_KEY			@"imagenamepat"
#define PREF_THUMNAMEPAT_KEY			@"thumnamepat"
#define PREF_THUMPCT_KEY				@"thumpct"
#define PREF_PICTINTERVAL_KEY			@"picture interval"

#define PREF_FIRSTRUN_KEY				@"first run - 2"

+ (void) initialize 
{
	if (self == [PreferencesController class]) {
		NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary]; 	
		
		[defaultValues setObject:@"" forKey:PREF_AMAZONS3_BUCKET_KEY];
		[defaultValues setObject:@"/" forKey:PREF_AMAZONS3_REMOTEPATH_KEY];
		[defaultValues setObject:@"" forKey:PREF_AMAZONS3_SHARED_KEY];
		[defaultValues setObject:@"" forKey:PREF_AMAZONS3_SECRET_KEY];
		[defaultValues setObject:@"private" forKey:PREF_AMAZONS3_ACCESS_KEY];
		[defaultValues setObject:[NSNumber numberWithInt:NSOffState] 
						  forKey:PREF_AMAZONS3_DELETEAFTER_KEY];
		
		[defaultValues setObject:[NSNumber numberWithUnsignedInt:0] 
						  forKey:PREF_CAMERA_KEY];
		[defaultValues setObject:@"" forKey:PREF_CAMERANAME_KEY];
		[defaultValues setObject:@"" forKey:PREF_CAMERASHOWNNAME_KEY];
		[defaultValues setObject:DEFAULT_SAVE_DIR forKey:PREF_SAVEDIR_KEY];
		[defaultValues setObject:DEFAULT_IMAGENAMEPAT forKey:PREF_IMAGENAMEPAT_KEY];
		[defaultValues setObject:DEFAULT_THUMNAMEPAT forKey:PREF_THUMNAMEPAT_KEY];
		[defaultValues setObject:[NSNumber numberWithDouble:DEFAULT_THUMPCT]
						  forKey:PREF_THUMPCT_KEY];

		//[defaultValues setObject:DEFAULT_IMAGEBASENAME forKey:PREF_IMAGEBASENAME_KEY];
		[defaultValues setObject:[NSNumber numberWithDouble:DEFAULT_PICTINTERVAL] 
						  forKey:PREF_PICTINTERVAL_KEY];
		
		[defaultValues setObject:[NSNumber numberWithInt:0] 
						  forKey:PREF_FIRSTRUN_KEY];		
		
		[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues]; 
	}
}

- (PreferencesController*) init
{
	if (self == [super initWithWindowNibName:@"preferences"]) {
		mStrWindowSubTitle = @"Preferences";
		mArrICACameraInfo = NULL;
		mbAwokeFromeNib = FALSE;
	}
	return self;
}

- (void) dealloc
{
	[mArrICACameraInfo release];
	[super dealloc];
}

- (void)awakeFromNib
{
	mbAwokeFromeNib = TRUE;
	[ [self window] setDelegate:self];
	MyController* mc = (MyController*) [NSApp delegate];
	NSString* strWndTitle = [mc getWindowTitleFromSubTitle:mStrWindowSubTitle];
	[ [self window] setTitle:strWndTitle];
	[mComboCamera setDataSource:self];
	[mComboCamera setUsesDataSource:TRUE];
	
	[mAmazonS3Access addItemWithTitle:@"Private"];
	[mAmazonS3Access addItemWithTitle:@"Public"];
	
	[self updateUIFromPrefData];
	
	if (mArrICACameraInfo) {
		[mComboCamera reloadData];	
		[self updateCameraComboFromPrefData];
	} else {
		[self onReScanCameras:NULL];
	}
}

#pragma mark PUBLIC METHODS

- (IBAction) onReScanCameras:(id)sender
{
	MyController* mc = (MyController*) [NSApp delegate];
	DSLRCommandLineController* dslrCmdController = mc.dslrCmdController;
	if ( ! [dslrCmdController isCommandInProgress] ) {
		[dslrCmdController getCameraListWithTimeOut:DEVICE_OPERATION_TIMEOUT_SEC
									   withDelegate:self userData:NULL];
	} else {
//		[mc showOkInfoDialogWithMsg:@"Error scanning cameras." 
//							andInfo:@"Camera scan facility busy.  Try again after a few seconds." 
//						   subTitle:@"Preferences"];
	}
}

- (IBAction) onChooseSaveDirectory:(id)sender
{
	NSLog(@"doOpen");	
	NSOpenPanel *op = [NSOpenPanel openPanel];
	op.canChooseFiles = FALSE;
	op.canChooseDirectories = TRUE;
    [op _setIncludeNewFolderButton:TRUE];
	
	NSInteger retCode = [op runModalForTypes:nil];
	switch(retCode) {
		case NSOKButton: {
			NSString * strDir = [op directory];
			[mSaveDirectoryLabel setStringValue: strDir];
		} break;
		case NSCancelButton:
		default:
			break;
	}
}

- (NSString*) amazonS3Bucket
{
	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_AMAZONS3_BUCKET_KEY];
	return ret;
}

- (NSString*) amazonS3RemotePath
{
	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_AMAZONS3_REMOTEPATH_KEY];
	return ret;
}

- (NSString*) amazonS3SharedKey
{
	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_AMAZONS3_SHARED_KEY];
	return ret;
}

- (NSString*) amazonS3SecretKey
{
	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_AMAZONS3_SECRET_KEY];
	return ret;
}

- (NSString*) amazonS3Access
{
	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_AMAZONS3_ACCESS_KEY];
	return ret;
}

- (Boolean) amazonS3DeleteAfter
{
	Boolean ret = FALSE;
	NSInteger kDeleteAfter =  [[NSUserDefaults standardUserDefaults] 
							   integerForKey:PREF_AMAZONS3_DELETEAFTER_KEY];
	switch (kDeleteAfter) {
		case NSOffState:
			ret = FALSE;
			break;
		case NSOnState:
			ret = TRUE;
			break;
		default:
			assert(FALSE);
			break;
	}
	return ret;
}

- (NSString*) cameraName
{
	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_CAMERANAME_KEY];
	return ret;
}

- (NSString*) cameraShownName
{
	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_CAMERASHOWNNAME_KEY];
	return ret;
}

- (ICAObject) cameraObjHandle
{
	ICAObject ret = (ICAObject) [[NSUserDefaults standardUserDefaults] integerForKey:PREF_CAMERA_KEY];
	return ret;
}

- (Boolean) isFirstRun
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];		
	NSInteger temp = [defaults integerForKey:PREF_FIRSTRUN_KEY];
	if (! temp) {
		[defaults setInteger:1 forKey:PREF_FIRSTRUN_KEY];
	}
	return (temp == 0);
}

- (NSString*) saveDir
{
	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_SAVEDIR_KEY];
	ret = [ret stringByExpandingTildeInPath];
	return ret;
}

//- (NSString*) imageBaseName
//{
//	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_IMAGEBASENAME_KEY];
//	return ret;
//}

- (NSString*) imageNamePat
{
	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_IMAGENAMEPAT_KEY];
	return ret;
}

- (NSString*) thumNamePat
{
	NSString* ret = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_THUMNAMEPAT_KEY];
	return ret;
}

- (double) thumPct
{
	NSTimeInterval ret = [[NSUserDefaults standardUserDefaults] 
						  doubleForKey:PREF_THUMPCT_KEY];
	return ret;
}

- (NSTimeInterval) pictInterval
{
	NSTimeInterval ret = [[NSUserDefaults standardUserDefaults] doubleForKey:PREF_PICTINTERVAL_KEY];
	return ret;
}

- (NSString*) getNameFromPattern:(NSString*)strPat
						  iField:(NSString*)strIField
						  dField:(NSString*)strDField
						  eField:(NSString*)strEField
{
	NSString* ret = [strPat stringByReplacingOccurrencesOfString:@"%i" 
													  withString:strIField];
	ret = [ret stringByReplacingOccurrencesOfString:@"%d" 
										 withString:strDField];
	ret = [ret stringByReplacingOccurrencesOfString:@"%e"
										 withString:strEField];
	return ret;
}

- (Boolean) validateSavedCaptureValues
{
	Boolean ret = TRUE;
	NSMutableArray* arrErrText = [NSMutableArray array];
	
	ICAObject objCamera = [self cameraObjHandle];
	ret = (objCamera != 0);
	ret = ret && [self validateSaveDir:arrErrText strSaveDir:[self saveDir]];
	NSString* strImageNamePat = [self imageNamePat];
	ret = ret && [self validateNamePattern:arrErrText 
								strPattern:&strImageNamePat
								 fieldName:@""];
	NSString* strThumNamePat = [self thumNamePat];
	ret = ret && [self validateNamePattern:arrErrText 
								strPattern:&strThumNamePat
								 fieldName:@""];
	
	ret = ret && ( [arrErrText count] == 0 );
	return ret;
}

- (Boolean) validateSavedUploadValues
{
	NSMutableArray* arrErrText = [NSMutableArray array];
	[self validateAmazonS3PrefForBucket:[self amazonS3Bucket]
							 remotePath:[self amazonS3RemotePath]
							  sharedKey:[self amazonS3SharedKey]
							  secretKey:[self amazonS3SecretKey]
								withErr:arrErrText];
	return ( [arrErrText count] == 0 );
}


// **********
// **********  NSWindowDelegate
// **********
#pragma mark NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender
{
	BOOL bCloseWindow = TRUE;
	NSArray* arrErrText = NULL;
	
	if (! [self validateGetErr:&arrErrText andSave:FALSE] ) {
		NSMutableString* strErrMsg = [NSMutableString string];
		BOOL bFirst = TRUE;
		for(NSString*strErr in arrErrText) {
			if (! bFirst) {
				[strErrMsg appendString:@"  "];
			}
			[strErrMsg appendString:strErr];
			bFirst = FALSE;
		}
		
		MyController* mc = (MyController*) [NSApp delegate];
		bCloseWindow = [mc showOkCancelWarningDialogWithMsg:strErrMsg 
			andInfo:@"Picture capture will not be possible until errors in preferences are corrected."
												   subTitle:mStrWindowSubTitle ];
	}
	
	if (bCloseWindow) {
		[self validateGetErr:&arrErrText andSave:TRUE];
	}
	
	return bCloseWindow;
}

- (void)windowWillClose: (NSNotification *)notification
{
    if ([notification object] == [self window]) {
		[NSApp stopModal];
	}
}

// **********
// **********  DSLRCommandLineControllerDelegate
// **********
#pragma mark DSLRCommandLineControllerDelegate

- (void) onCommandCompleteWithStdOutJSonObj:(NSObject*)objRet 
								 withStrErr:(NSString*)strErr 
									retCode:(int)ret 
								   timedOut:(Boolean)bTimedOut
								   userData:(void*)user
{
	if (ret == 0 && ! bTimedOut) {
		[mArrICACameraInfo release];
		mArrICACameraInfo = (NSArray*) objRet;
		[mArrICACameraInfo retain];
	
		if (mbAwokeFromeNib) {
			[mComboCamera reloadData];	
		}
		[self updateCameraComboFromPrefData];
	} else {
//		MyController* mc = (MyController*) [NSApp delegate];
//		NSString* strInfo = (bTimedOut) ?  @"Operation timed out." : strErr ;
//		[mc showOkInfoDialogWithMsg:@"Error scanning cameras." 
//							andInfo:strInfo
//						   subTitle:@"Preferences"];
	}
}

// **********
// **********  NSComboBoxDataSource
// **********
#pragma mark NSComboBoxDataSource

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	NSObject* ret = NULL;
	if ( mArrICACameraInfo ) {
		NSDictionary* dict = [mArrICACameraInfo objectAtIndex:index];
		ret = [dict objectForKey:@"ifil"];
	}
	return ret;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	int ret = 0;
	if ( mArrICACameraInfo ) {
		ret = [mArrICACameraInfo count];
	}
	return ret;
}

// *********
// ********* PRIVATE METHODS
// *********
#pragma mark PRIVATE METHODS

- (void) updateCameraComboFromPrefData
{
	if (mArrICACameraInfo) {
		NSString* strCameraName = [self cameraName];
		
		int n = [mArrICACameraInfo count];
		int k;
		for(k = 0; k < n; ++ k) {
			NSDictionary* dict = (NSDictionary*) [mArrICACameraInfo objectAtIndex:k];
			NSString* strTemp = (NSString*) [dict objectForKey:@"ifil"];
			if ([strCameraName compare:strTemp] == NSOrderedSame) {
				ICAObject objCamera = [ (NSNumber*) [dict objectForKey:@"icao"] unsignedIntValue ];
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
				[defaults setInteger:(NSInteger)objCamera forKey:PREF_CAMERA_KEY];
				if (mbAwokeFromeNib) {
					[mComboCamera selectItemAtIndex:k];
					[mComboCamera setStringValue:
					 [self comboBox:mComboCamera objectValueForItemAtIndex:k]];
				}
				break;
			}
		}
		if (k == n) {
			//  DON'T KNOW A BETTER WAY TO SET SELECTED ITEM TO NOTHING FOR COMBOBOX -- CAUSES A WARNING IN THE LOG
			if (mbAwokeFromeNib) {
				[mComboCamera selectItemWithObjectValue:@""];
				[mComboCamera setStringValue:@""];
			}
		}
	}
}

//- (void) updateCameraComboFromPrefData
//{
//	if (mArrICACameraInfo) {
//		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//		ICAObject objCamera = (ICAObject) [defaults integerForKey:PREF_CAMERA_KEY];
//		
//		int n = [mArrICACameraInfo count];
//		int k;
//		for(k = 0; k < n; ++ k) {
//			NSDictionary* dict = (NSDictionary*) [mArrICACameraInfo objectAtIndex:k];
//			ICAObject obj = [ (NSNumber*) [dict objectForKey:@"icao"] unsignedIntValue ];
//			if (objCamera == obj) {
//				break;
//			}
//		}
//		if (k != n) {
//			[mComboCamera selectItemAtIndex:k];
//			[mComboCamera setStringValue:[self comboBox:mComboCamera objectValueForItemAtIndex:k]];
//		} else {
//			//  DON'T KNOW A BETTER WAY TO SET SELECTED ITEM TO NOTHING FOR COMBOBOX -- CAUSES A WARNING IN THE LOG
//			[mComboCamera selectItemWithObjectValue:@""];
//			[mComboCamera setStringValue:@""];
//		}
//		
//	}
//}

- (void) updateUIFromPrefData
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* strAmazonS3Bucket = (NSString*) [defaults objectForKey:PREF_AMAZONS3_BUCKET_KEY];
	NSString* strAmazonS3RemotePath = (NSString*) [defaults objectForKey:PREF_AMAZONS3_REMOTEPATH_KEY];
	NSString* strAmazonS3SharedKey = (NSString*) [defaults objectForKey:PREF_AMAZONS3_SHARED_KEY];
	NSString* strAmazonS3SecretKey = (NSString*) [defaults objectForKey:PREF_AMAZONS3_SECRET_KEY];
	NSString* strAmazonS3Access = (NSString*) [defaults objectForKey:PREF_AMAZONS3_ACCESS_KEY];
	NSInteger kDeleteAfter = [ (NSNumber*) [defaults objectForKey:PREF_AMAZONS3_DELETEAFTER_KEY]
							  intValue];
	
	NSString* strImagePat = [self imageNamePat];
	NSString* strThumPat = [self thumNamePat];
	NSString* strThumPct = [NSString stringWithFormat:@"%1.1lf", [self thumPct]];
//	NSString* strBaseName = (NSString*) [defaults objectForKey:PREF_IMAGEBASENAME_KEY];
	double dPictInterval = [defaults doubleForKey:PREF_PICTINTERVAL_KEY];
	NSString* strPictInterval = (NSString*) [NSString stringWithFormat:@"%1.1lf", dPictInterval];
	NSString* strSaveDir = [defaults objectForKey:PREF_SAVEDIR_KEY];

	
	[mAmazonS3BucketTextField setStringValue:strAmazonS3Bucket];
	[mAmazonS3RemoteUploadDirTextField setStringValue:strAmazonS3RemotePath];
	[mAmazonS3SharedKeyTextField setStringValue:strAmazonS3SharedKey];
	[mAmazonS3SecretKeyTextField setStringValue:strAmazonS3SecretKey];
	[mAmazonS3DeleteAfterUploadCheckBox setState:kDeleteAfter];

	if ( [strAmazonS3Access compare:@"private"] == NSOrderedSame ) {
		[mAmazonS3Access selectItemAtIndex:0];
	} else if ( [strAmazonS3Access compare:@"public"] == NSOrderedSame ) {
		[mAmazonS3Access selectItemAtIndex:1];
	} else {
		assert(FALSE);
	}
	
	[mSaveDirectoryLabel setStringValue:strSaveDir];
	[mImageNameTextField setStringValue:strImagePat];
	[mThumNameTextField setStringValue:strThumPat];
	[mThumPercentageTextField setStringValue:strThumPct];
//	[mBaseImageNameTextField setStringValue:strBaseName];
	[mPictIntervalTextField setStringValue:strPictInterval];
	
	[self updateCameraComboFromPrefData];
}

- (void) validateAmazonS3PrefForBucket:(NSString*) strBucket
							   remotePath:(NSString*)strRemotePath
								sharedKey:(NSString*)strSharedKey
								secretKey:(NSString*)strSecretKey
								  withErr:(NSMutableArray*)arrErrText
{
	if ( ! IsValidAmazonS3BucketNameStr(strBucket) ) {
		[arrErrText addObject:@"Amazon S3 bucket name is not valid (refer to Amazon docs)."];
	}
	
	if ( ! IsValidAmazonS3RemotePathStr(strRemotePath) ) {
		[arrErrText addObject:@"Amazon S3 remote path is not valid (must start with '/', and refer to Amazon docs)."];
	}
	
	if ( ! IsValidAmazonS3KeyStr(strSharedKey)) {
		[arrErrText addObject:@"Amazon S3 shared key is not valid (refer to Amazon docs)."];
	}
	
	if ( ! IsValidAmazonS3KeyStr(strSecretKey)) {
		[arrErrText addObject:@"Amazon S3 secret key is not valid (refer to Amazon docs)."];
	}
}

- (Boolean) validateNamePattern:(NSMutableArray*)arrErrText
					 strPattern:(NSString**)pStrPat
					  fieldName:(NSString*)strFieldName
{
	Boolean ret = FALSE;
	NSString* strPat = *pStrPat;
    strPat = [strPat
			  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString* strFileName = [self getNameFromPattern:strPat
											  iField:@"pic"
											  dField:@"2010-01-22_09-12-23"
											  eField:@"jpg"];
	if ([strFileName length] > 0 && 
		IsValidFileName(strFileName) &&
		IsValidAmazonS3KeyStr(strFileName) ) {
		if ( [ [strFileName substringToIndex:1] compare:@"."] == NSOrderedSame ) {
			[arrErrText addObject:[NSString stringWithFormat:@"%@ \"%@\" cannot start with a '.'",
								   strFieldName, strPat]];
		} else if ( [ [strFileName substringToIndex:1] compare:@"-"] == NSOrderedSame ) {
			[arrErrText addObject:[NSString stringWithFormat:@"%@ \"%@\" cannot start with a '-'",
								   strFieldName, strPat]];
		} else {
			ret = TRUE;
		}
	} else {
		[arrErrText addObject:[NSString stringWithFormat:@"%@ \"%@\" contains illegal special characters.",
							   strFieldName, strPat]];
	} 
	*pStrPat = strPat;
	return ret;
}

- (Boolean) validateGetErr:(NSArray**)pArrErrText andSave:(Boolean) bSave
{
	NSMutableArray* arrErrText = [NSMutableArray array];
	
	[self validateAmazonS3PrefForBucket:[mAmazonS3BucketTextField stringValue]
							 remotePath:[mAmazonS3RemoteUploadDirTextField stringValue]
							  sharedKey:[mAmazonS3SharedKeyTextField stringValue]
							  secretKey:[mAmazonS3SecretKeyTextField stringValue]
								withErr:arrErrText];
	
	NSInteger kAccess = [mAmazonS3Access indexOfSelectedItem];
	NSString* strAccess = NULL;
	switch (kAccess) {
		case 0:
			strAccess = @"private";
			break;
		default:
			strAccess = @"public";
			break;
	}
	
	NSInteger kDeleteAfter = [mAmazonS3DeleteAfterUploadCheckBox state];
	
	NSString* strPictInterval = [mPictIntervalTextField stringValue];
	NSTimeInterval dPictInterval;
	[self validatePictInterval:arrErrText
			   strPictInterval:strPictInterval
				 dPictInterval:&dPictInterval];
	
	NSInteger iCamera = [mComboCamera indexOfSelectedItem];
	if (iCamera == -1) {
		[arrErrText addObject:@"No camera is selected."];
	}
	
	NSString* strSaveDir = [mSaveDirectoryLabel stringValue];
	[self validateSaveDir:arrErrText
			   strSaveDir:strSaveDir];
	
	NSString* strImageNamePat = [mImageNameTextField stringValue];
	[self validateNamePattern:arrErrText
				   strPattern:&strImageNamePat
					fieldName:@"Image Name Pattern"];
	NSString* strThumNamePat = [mThumNameTextField stringValue];
	[self validateNamePattern:arrErrText
				   strPattern:&strThumNamePat
					fieldName:@"Thumbnail Name Pattern"];
	
	NSString* strThumPct = [mThumPercentageTextField stringValue];
	double dThumPct;
	[self validateThumPercent:strThumPct
						 dPct:&dThumPct
						  err:arrErrText];
	
//	NSString* strBaseName = [mBaseImageNameTextField stringValue];
//	[self validateBaseName:arrErrText
//			   strBaseName:&strBaseName];
	
	Boolean ret = TRUE;
	if ( [arrErrText count] > 0) {
		*pArrErrText = arrErrText;
		ret = FALSE;
	} 
	
	if (bSave) {
		NSDictionary* dictCamera = (iCamera != -1) ?
			(NSDictionary*) [mArrICACameraInfo objectAtIndex:iCamera] : NULL;
		ICAObject objCamera = (iCamera != -1) ?
			[(NSNumber*) [dictCamera objectForKey:@"icao"] unsignedIntValue] : 0;
		NSString* strCameraName = (iCamera != -1) ?
			[dictCamera objectForKey:@"ifil"] : @"";
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
		
		[defaults setObject:[mAmazonS3BucketTextField stringValue] forKey:PREF_AMAZONS3_BUCKET_KEY];
		[defaults setObject:[mAmazonS3RemoteUploadDirTextField stringValue] forKey:PREF_AMAZONS3_REMOTEPATH_KEY];
		[defaults setObject:[mAmazonS3SharedKeyTextField stringValue] forKey:PREF_AMAZONS3_SHARED_KEY];
		[defaults setObject:[mAmazonS3SecretKeyTextField stringValue] forKey:PREF_AMAZONS3_SECRET_KEY];
		[defaults setObject:strAccess forKey:PREF_AMAZONS3_ACCESS_KEY];
		[defaults setObject:[NSNumber numberWithInt:kDeleteAfter] 
					 forKey:PREF_AMAZONS3_DELETEAFTER_KEY];
		
		[defaults setInteger:(NSInteger)objCamera forKey:PREF_CAMERA_KEY];
		if (iCamera != -1) {
			[defaults setObject:strCameraName forKey:PREF_CAMERANAME_KEY];
		}
		[defaults setObject:strCameraName forKey:PREF_CAMERASHOWNNAME_KEY];
		[defaults setObject:strSaveDir forKey:PREF_SAVEDIR_KEY];
		[defaults setObject:strImageNamePat forKey:PREF_IMAGENAMEPAT_KEY];
		[defaults setObject:strThumNamePat forKey:PREF_THUMNAMEPAT_KEY];
		[defaults setObject:[NSNumber numberWithDouble:dThumPct]
					 forKey:PREF_THUMPCT_KEY];
//		[defaults setObject:strBaseName forKey:PREF_IMAGEBASENAME_KEY];
		[defaults setObject:[NSNumber numberWithDouble:dPictInterval] 
					 forKey:PREF_PICTINTERVAL_KEY];
		
		[self updateUIFromPrefData];
	}
	
	return ret;
}

- (Boolean) validatePictInterval:(NSMutableArray*)arrErrText
				 strPictInterval:(NSString*)strPictInterval
				   dPictInterval:(NSTimeInterval*)pdPictInterval
{
	Boolean ret = FALSE;
	double dPictInterval = [self pictInterval];
	if (! ValidateDouble(strPictInterval, &dPictInterval) ) {
		[arrErrText addObject:@"The Picture Interval is not a valid floating point number."];
	} else if (dPictInterval < 0) {
		[arrErrText addObject:@"The Picture Interval cannot be negative."];
	} else {
		ret = TRUE;
	}
	*pdPictInterval = dPictInterval;
	return ret;
}

- (Boolean) validateSaveDir:(NSMutableArray*)arrErrText
				 strSaveDir:(NSString*)strSaveDir
{
	Boolean ret = FALSE;
	FSRef saveDirFSRef;
	strSaveDir = [strSaveDir stringByExpandingTildeInPath];
	if (! MakeFSRefFromNSString(&saveDirFSRef, strSaveDir) ) {
		[arrErrText addObject:@"The Save Directory does not exist."];
	} else if ( ! [ [NSFileManager defaultManager] isWritableFileAtPath:strSaveDir ]) {
		[arrErrText addObject:@"You don't have permission to write files to the Save Directory."];
	} else {
		ret = TRUE;
	}
	return ret;
}

- (Boolean) validateThumPercent:(NSString*) strThumPct
						   dPct:(double*)pdPct
							err:(NSMutableArray*)arrErrText
{
	Boolean ret = FALSE;
	double dPct = [self pictInterval];
	if (! ValidateDouble(strThumPct, &dPct) ) {
		[arrErrText addObject:@"The Thumbnail percent is not a valid floating point number."];
	} else if (dPct < 10 || dPct > 100) {
		[arrErrText addObject:@"The Thumbnail percent must be between 10 and 100"];
	} else {
		ret = TRUE;
	}
	*pdPct = dPct;
	return ret;
	
}


@end



















