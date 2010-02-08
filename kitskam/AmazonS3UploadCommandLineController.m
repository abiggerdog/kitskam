//
//  AmazonS3UploadCommandLineController.m
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

#import "SBJsonParser.h"

@interface AmazonS3CmdInfo : NSObject
{
	NSObject<AmazonS3UploadCommandLineControllerDelegate>* delegate;
	void* user;
}
@property (retain) NSObject<AmazonS3UploadCommandLineControllerDelegate>* delegate;
@property (assign) void* user;
@end

@implementation AmazonS3CmdInfo;
@synthesize delegate;
@synthesize user;

- (AmazonS3CmdInfo*) init
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

@implementation AmazonS3UploadCommandLineController

- (AmazonS3UploadCommandLineController*) init
{
	if (self = [super init]) {
		NSBundle* nsb = [NSBundle mainBundle];
		mStrCmdLineAppPath = [nsb pathForResource:@"amazon_s3_controller_command_line" ofType:@""];
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

- (Boolean) amazonS3UploadFile:(NSString*)strLocalPath
					  toBucket:(NSString*)strRemoteBucket
				   toObjectKey:(NSString*)strRemotePath
					withAccess:(NSString*)strAccess
			 deleteAfterUpload:(Boolean)bDeleteAfterUpload
				  forSharedKey:(NSString*)strSharedKey
				  forSecretKey:(NSString*)strSecretKey
					  userData:(void*)user
				   withTimeOut:(NSTimeInterval)timeOut
					deletegate:(NSObject<AmazonS3UploadCommandLineControllerDelegate>*)delegate
{
	NSMutableArray* arrArgs = [NSMutableArray array];
	[arrArgs addObject:@"--upload-file"];
	[arrArgs addObject:@"--local-path"];
	[arrArgs addObject:strLocalPath];
	[arrArgs addObject:@"--remote-path"];
	[arrArgs addObject:strRemotePath];
	if (strAccess) {
		[arrArgs addObject:@"--remote-access-control"];
		[arrArgs addObject:strAccess];
	}
	[arrArgs addObject:@"--shared-key"];
	[arrArgs addObject:strSharedKey];
	[arrArgs addObject:@"--secret-key"];
	[arrArgs addObject:strSecretKey];
	[arrArgs addObject:@"--remote-bucket-name"];
	[arrArgs addObject:strRemoteBucket];
	if (bDeleteAfterUpload) {
		[arrArgs addObject:@"--delete-after-upload"];
	}
	
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
	AmazonS3CmdInfo* dci = (AmazonS3CmdInfo*) user;
	NSObject<AmazonS3UploadCommandLineControllerDelegate>* delegate = dci.delegate;
	
	NSObject* objRet = NULL;
	if ( ! retCode && ! bTimedOut ) {
		NSString* strStdOut =  [ [NSString alloc] 
								initWithData:dataStdOut encoding:NSUTF8StringEncoding];
		SBJsonParser* json = [ [ [SBJsonParser alloc] init] autorelease];
		objRet = [json objectWithString:strStdOut];
	}
	
	NSString* strStdErr =  [ [NSString alloc] 
							initWithData:dataStdErr encoding:NSUTF8StringEncoding];
	
	[delegate onAamazonS3CommandCompleteWithStdOutJSonObj:objRet 
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
					 withDelegate:(NSObject<AmazonS3UploadCommandLineControllerDelegate>*)delegate
						 userData:(void*) user 
{
	AmazonS3CmdInfo* aci = [ [ [AmazonS3CmdInfo alloc] init] autorelease];
	[aci retain];
	aci.delegate = delegate;
	aci.user = user;
	
	Boolean ret = [mCmdController doCommandLine:mStrCmdLineAppPath 
									   withArgs:arrArgs
									withTimeOut:timeOut 
								   withDelegate:self
									   userData:(void*)aci];
	
	return ret;
}


@end
