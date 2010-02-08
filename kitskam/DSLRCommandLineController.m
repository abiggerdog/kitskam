//
//  DSLRCommandLineController.m
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

#import "SBJsonParser.h"

@interface DSLRCmdInfo : NSObject
{
	NSObject<DSLRCommandLineControllerDelegate>* delegate;
	void* user;
}
@property (retain) NSObject<DSLRCommandLineControllerDelegate>* delegate;
@property (assign) void* user;
@end

@implementation DSLRCmdInfo;
@synthesize delegate;
@synthesize user;

- (DSLRCmdInfo*) init
{
	if (self = [super init]) {
		delegate = NULL;
		user = NULL;
	}
	return self;
}
- (void) dealloc
{
	[delegate release];
	[super dealloc];
}
@end

// ****************************************************************************
// ****************************************************************************
// ****************************************************************************

@implementation DSLRCommandLineController

- (DSLRCommandLineController*) init
{
	if (self = [super init]) {
		NSBundle* nsb = [NSBundle mainBundle];
		mStrCmdLineAppPath = [nsb pathForResource:@"dslr_controller_comand_line" ofType:@""];
		[mStrCmdLineAppPath retain];
		
		mCmdController = [ [ [CommandLineController alloc] init] autorelease];
		[mCmdController retain];
	}
	return self;
}

- (void) dealloc
{
	[mCmdController release];
	[super dealloc];
}

- (Boolean) isCommandInProgress
{
	Boolean ret = [mCmdController isCommandInProgress];
	return ret;
}

- (Boolean) getCameraListWithTimeOut:(NSTimeInterval)timeOut
						withDelegate:(NSObject<DSLRCommandLineControllerDelegate>*)delegate
							userData:(void*) user 
{
	NSMutableArray* arrArgs = [NSMutableArray array];
	[arrArgs addObject:@"--camera-list"];
	Boolean ret = [self doCommandLineWithArgs:arrArgs
								  withTimeOut:timeOut
								 withDelegate:delegate
									 userData:user];
	return ret;
}

- (Boolean) downloadPhotoWithTimeOut:(NSTimeInterval)timeOut
						withDelegate:(NSObject<DSLRCommandLineControllerDelegate>*)delegate
							userData:(void*) user 
							 picPath:(NSString*)strPicPath
							thumPath:(NSString*)strThumPath
							 thumPct:(double)dThmPct
							 withPic:(ICAObject)objPic
						shouldDelete:(Boolean)bShouldDelete
{
	NSMutableArray* arrArgs = [NSMutableArray array];
	[arrArgs addObject:@"--download-image"];
	[arrArgs addObject:[ [NSNumber numberWithUnsignedInt:objPic] stringValue] ];
	[arrArgs addObject:@"--file-name"];
	[arrArgs addObject:strPicPath];
	[arrArgs addObject:@"--thum-file-name"];
	[arrArgs addObject:strThumPath];
	[arrArgs addObject:@"--thum-percent"];
	NSString* strThumPct = [NSString stringWithFormat:@"%lf", dThmPct];
	[arrArgs addObject:strThumPct];
	
	if (bShouldDelete) {
		[arrArgs addObject:@"--delete-image"];
		[arrArgs addObject:@"--force-delete"];
	}
	Boolean ret = [self doCommandLineWithArgs:arrArgs
								  withTimeOut:timeOut
								 withDelegate:delegate
									 userData:user];
	return ret;
}

- (Boolean) takePhotoWithTimeOut:(NSTimeInterval)timeOut
					withDelegate:(NSObject<DSLRCommandLineControllerDelegate>*)delegate
						userData:(void*) user 
					  withCamera:(ICAObject)objCamera
{
	NSMutableArray* arrArgs = [NSMutableArray array];
	[arrArgs addObject:@"--take-picture"];
	[arrArgs addObject:[ [NSNumber numberWithUnsignedInt:objCamera] stringValue] ];
	Boolean ret = [self doCommandLineWithArgs:arrArgs
								  withTimeOut:timeOut
								 withDelegate:delegate
									 userData:user];
	return ret;
}

// **********
// **********  CommandLineControllerDelegate
// **********

- (void) onCommandCompleteWithStdOut:(NSData*)dataStdOut 
							  stdErr:(NSData*)dataStdErr
							 retCode:(int)retCode 
							timedOut:(Boolean)bTimedOut
							userData:(void*)user
{
	DSLRCmdInfo* dci = (DSLRCmdInfo*) user;
	NSObject<DSLRCommandLineControllerDelegate>* delegate = dci.delegate;
	
	NSObject* objRet = NULL;
	if ( ! retCode && ! bTimedOut ) {
		NSString* strStdOut =  [ [ [NSString alloc] 
								  initWithData:dataStdOut 
								  encoding:NSUTF8StringEncoding] autorelease];
		SBJsonParser* json = [ [ [SBJsonParser alloc] init] autorelease];
		objRet = [json objectWithString:strStdOut];
	}
	
	NSString* strStdErr =  [ [ [NSString alloc] 
							  initWithData:dataStdErr encoding:NSUTF8StringEncoding]
							autorelease];
	[delegate onCommandCompleteWithStdOutJSonObj:objRet 
										 withStrErr:strStdErr 
										 retCode:retCode 
										timedOut:bTimedOut 
										userData:dci.user];

	[dci release];
}

// **********
// **********  PRIVATE METHODS
// **********

- (Boolean) doCommandLineWithArgs:(NSArray*)arrArgs
					  withTimeOut:(NSTimeInterval)timeOut
					 withDelegate:(NSObject<DSLRCommandLineControllerDelegate>*)delegate
						 userData:(void*) user 
{
	DSLRCmdInfo* dci = [ [ [DSLRCmdInfo alloc] init] autorelease];
	[dci retain];
	dci.delegate = delegate;
	dci.user = user;
	
	Boolean ret = [mCmdController doCommandLine:mStrCmdLineAppPath 
									   withArgs:arrArgs
									withTimeOut:timeOut 
								   withDelegate:self
									   userData:(void*)dci];
	
	return ret;
}


@end
