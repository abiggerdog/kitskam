//
//  DSLRCommandLineController.h
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

#import "CommandLineController.h"

#import <Foundation/Foundation.h>


@protocol DSLRCommandLineControllerDelegate

- (void) onCommandCompleteWithStdOutJSonObj:(NSObject*)objRet 
								 withStrErr:(NSString*)strErr 
									retCode:(int)ret 
								   timedOut:(Boolean)bTimedOut
								   userData:(void*)user;

@end


@interface DSLRCommandLineController : NSObject 
< CommandLineControllerDelegate >
{
	NSString* mStrCmdLineAppPath;
	CommandLineController* mCmdController;

}

- (DSLRCommandLineController*) init;
- (void) dealloc;

- (Boolean) isCommandInProgress;

- (Boolean) getCameraListWithTimeOut:(NSTimeInterval)timeOut
						withDelegate:(NSObject<DSLRCommandLineControllerDelegate>*)delegate
							userData:(void*) user ;

- (Boolean) downloadPhotoWithTimeOut:(NSTimeInterval)timeOut
						withDelegate:(NSObject<DSLRCommandLineControllerDelegate>*)delegate
							userData:(void*) user 
							 picPath:(NSString*)strPicPath
							thumPath:(NSString*)strThumPath
							 thumPct:(double)dThmPct
							 withPic:(ICAObject)objPic
						shouldDelete:(Boolean)bShouldDelete;

- (Boolean) takePhotoWithTimeOut:(NSTimeInterval)timeOut
					withDelegate:(NSObject<DSLRCommandLineControllerDelegate>*)delegate
						userData:(void*) user 
					  withCamera:(ICAObject)objCamera;

// **********
// **********  CommandLineControllerDelegate
// **********

- (void) onCommandCompleteWithStdOut:(NSData*)dataStdOut 
							  stdErr:(NSData*)dataStdErr
							 retCode:(int)ret 
							timedOut:(Boolean)bTimedOut
							userData:(void*)user;

// **********
// **********  PRIVATE METHODS
// **********

- (Boolean) doCommandLineWithArgs:(NSArray*)arrArgs
					  withTimeOut:(NSTimeInterval)timeOut
					 withDelegate:(NSObject<DSLRCommandLineControllerDelegate>*)delegate
						 userData:(void*) user;

@end
