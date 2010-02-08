//
//  PreferencesController.h
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

#import "DSLRCommandLineController.h"

#import <Cocoa/Cocoa.h>

@interface PreferencesController :  NSWindowController 
< DSLRCommandLineControllerDelegate >
{
	IBOutlet NSComboBox* mComboCamera;
	IBOutlet NSTextField* mAmazonS3BucketTextField;
	IBOutlet NSTextField* mAmazonS3RemoteUploadDirTextField;
	
	IBOutlet NSTextField* mAmazonS3SharedKeyTextField;
	IBOutlet NSSecureTextField* mAmazonS3SecretKeyTextField;
	IBOutlet NSPopUpButton* mAmazonS3Access;
	IBOutlet NSButton* mAmazonS3DeleteAfterUploadCheckBox;
	IBOutlet NSTextField* mSaveDirectoryLabel;
	IBOutlet NSTextField* mImageNameTextField;
	IBOutlet NSTextField* mThumNameTextField;
	IBOutlet NSTextField* mThumPercentageTextField;
	IBOutlet NSTextField* mPictIntervalTextField;
	
	NSString* mStrWindowSubTitle;
	NSArray* mArrICACameraInfo;
	Boolean mbAwokeFromeNib;
}

+ (void) initialize;

- (PreferencesController*) init;
- (void)awakeFromNib;
- (void) dealloc;

#pragma mark PUBLIC METHODS

- (IBAction) onChooseSaveDirectory:(id)sender;
- (IBAction) onReScanCameras:(id)sender;

- (NSString*) amazonS3Bucket;
- (NSString*) amazonS3RemotePath;
- (NSString*) amazonS3SharedKey;
- (NSString*) amazonS3SecretKey;
- (NSString*) amazonS3Access;
- (Boolean) amazonS3DeleteAfter;
- (NSString*) cameraName;
- (NSString*) cameraShownName;
- (ICAObject) cameraObjHandle;
- (Boolean) isFirstRun;
- (NSString*) saveDir;
//- (NSString*) imageBaseName;
- (NSString*) imageNamePat;
- (NSString*) thumNamePat;
- (double) thumPct;
- (NSTimeInterval) pictInterval;

- (NSString*) getNameFromPattern:(NSString*)strPat
						  iField:(NSString*)strIField
						  dField:(NSString*)dField
						  eField:(NSString*)eField;
- (Boolean) validateSavedCaptureValues;
- (Boolean) validateSavedUploadValues;

// **********
// **********  NSWindowDelegate
// **********
#pragma mark NSWindowDelegate
- (BOOL)windowShouldClose:(id)sender;
- (void)windowWillClose: (NSNotification *)notification;

// **********
// **********  DSLRCommandLineControllerDelegate
// **********
#pragma mark DSLRCommandLineControllerDelegate

- (void) onCommandCompleteWithStdOutJSonObj:(NSObject*)objRet 
								 withStrErr:(NSString*)strErr 
									retCode:(int)ret 
								   timedOut:(Boolean)bTimedOut
								   userData:(void*)user;

// **********
// **********  NSComboBoxDataSource
// **********
#pragma mark NSComboBoxDataSource

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index;
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox;

// *********
// ********* PRIVATE METHODS
// *********
#pragma mark PRIVATE METHODS

- (void) updateCameraComboFromPrefData;
- (void) updateUIFromPrefData;
- (void) validateAmazonS3PrefForBucket:(NSString*) strBucket
							remotePath:(NSString*)strRemotePath
							 sharedKey:(NSString*)strSharedKey
							 secretKey:(NSString*)strSecretKey
							   withErr:(NSMutableArray*)arrErrText;
- (Boolean) validateGetErr:(NSArray**)pArrErrText andSave:(Boolean) bSave;
- (Boolean) validateNamePattern:(NSMutableArray*)arrErrText
					 strPattern:(NSString**)pStrPat
					  fieldName:(NSString*)strFieldName;
//- (Boolean) validateBaseName:(NSMutableArray*)arrErrText
//				 strBaseName:(NSString**)strBaseName;
- (Boolean) validatePictInterval:(NSMutableArray*)arrErrText
				 strPictInterval:(NSString*)strPictInterval
				   dPictInterval:(NSTimeInterval*)pdPictInterval;
- (Boolean) validateSaveDir:(NSMutableArray*)arrErrText
				 strSaveDir:(NSString*)strSaveDir;
- (Boolean) validateThumPercent:(NSString*) strThumPct
						   dPct:(double*)pdPct
							err:(NSMutableArray*)arrErrText;
@end
