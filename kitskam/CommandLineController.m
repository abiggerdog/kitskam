//
//  CommandLineController.m
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
#import "SBJsonParser.h"

// ****************************************************************************
// ****************************************************************************
// ****************************************************************************

@interface CmdInfo : NSObject
{
	Boolean bTimeOut;
	NSTimeInterval timeOut;
	NSData* dataStdOut;
	NSFileHandle* pipeStdOut_In;
	NSData* dataStdErr;
	NSFileHandle* pipeStdErr_In;
	NSObject<CommandLineControllerDelegate>* delegate;
	void* user;
	NSTask* task;
	int retCode;
	
	// *****
	Boolean bDidDelegateCallBack;
	NSLock* mLock;
	int delegateCallBackCount; // DEBUG CHECK
}
@property (assign) Boolean bTimeOut;
@property (assign) NSTimeInterval timeOut;
@property (retain) NSData* dataStdOut;
@property (retain) NSFileHandle* pipeStdOut_In;
@property (retain) NSData* dataStdErr;
@property (retain) NSFileHandle* pipeStdErr_In;
@property (retain) NSObject<CommandLineControllerDelegate>* delegate;
@property (assign) void* user;
@property (retain) NSTask* task;
@property (assign) int retCode;
// ***
@property (assign) int delegateCallBackCount;

- (CmdInfo*) init;
- (void) dealloc;

- (Boolean) shouldReadThreadDoDelegateCallBack;

@end

// ********** 
// **********
// **********

@implementation CmdInfo

@synthesize bTimeOut;
@synthesize timeOut;
@synthesize dataStdOut;
@synthesize pipeStdOut_In;
@synthesize dataStdErr;
@synthesize pipeStdErr_In;
@synthesize delegate;
@synthesize user;
@synthesize task;
@synthesize retCode;
// ***
@synthesize delegateCallBackCount;

- (CmdInfo*) init
{
	if (self = [super init]) {
		bTimeOut = FALSE;
		timeOut = 0.0;
		dataStdOut = NULL;
		pipeStdOut_In = NULL;
		dataStdErr = NULL;
		pipeStdErr_In = NULL;
		delegate = NULL;
		user = NULL;
		task = NULL;
		retCode = -1;
		// *****
		mLock = [ [ [NSLock alloc] init] autorelease];
		[mLock retain];
		bDidDelegateCallBack = FALSE;
		delegateCallBackCount = 0;
	}
	return self;
}

- (void) dealloc
{
	[mLock release];
	[dataStdOut release];
	[pipeStdOut_In release];
	[dataStdErr release];
	[pipeStdErr_In release];
	[delegate release];
	[task release];
	[super dealloc];
}

- (Boolean) shouldReadThreadDoDelegateCallBack
{
	[mLock lock];
	Boolean ret = ( ! bDidDelegateCallBack && dataStdOut && dataStdErr );
	if (ret) {
		bDidDelegateCallBack = TRUE;
	}
	[mLock unlock];
	return ret;
}
@end

// ****************************************************************************
// ****************************************************************************
// ****************************************************************************

@implementation CommandLineController

- (CommandLineController*) init
{
	if (self = [super init]) {
		mnCmdInProgressCount = 0;
	}
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (Boolean) isCommandInProgress
{
	Boolean ret = ( mnCmdInProgressCount > 0 );
	return ret;
}

- (Boolean) doCommandLine:(NSString*)strCmd 
				 withArgs:(NSArray*)arrArgs 
			  withTimeOut:(NSTimeInterval)timeOut
			 withDelegate:(NSObject<CommandLineControllerDelegate>*)delegate
				 userData:(void*)user
{
	Boolean ret = FALSE;
	CmdInfo* ci = [ [ [CmdInfo alloc] init] autorelease];

	ci.delegate = delegate;
	ci.user = user;
	ci.timeOut = timeOut;
	
	NSPipe* pipeStdOut = [NSPipe pipe];
	ci.pipeStdOut_In = [pipeStdOut fileHandleForReading];
	
	NSPipe* pipeStdErr = [NSPipe pipe];
	ci.pipeStdErr_In = [pipeStdErr fileHandleForReading];

	NSTask* task = [ [ [NSTask alloc] init] autorelease];
	ci.task =  task;
	[task setLaunchPath:strCmd];
	[task setArguments:arrArgs];
	[task setStandardOutput:pipeStdOut];
	[task setStandardError:pipeStdErr];

	[NSThread detachNewThreadSelector:@selector(threadEntryReadTaskStdOut:) 
							 toTarget:self withObject:ci];
	
	[NSThread detachNewThreadSelector:@selector(threadEntryReadTaskStdErr:) 
							 toTarget:self withObject:ci];
	
	if (timeOut != 0) {
		[NSThread detachNewThreadSelector:@selector(threadEntryTaskAsynchTimeOut:) 
								 toTarget:self withObject:ci];
	}
	
	@try {
		[task launch];
		[ci retain];
		++ mnCmdInProgressCount ;
		ret = TRUE;
	}
	@catch (NSException * e) {
	}
	@finally {
	}
	
	return ret;
}

// ********************
// ******************** PRIVATE METHODS
// ********************

- (void) doDelegateCallBack:(NSObject*)param
{
	CmdInfo* ci = (CmdInfo*) param;
	NSObject<CommandLineControllerDelegate>*delegate = ci.delegate;
	[delegate onCommandCompleteWithStdOut:ci.dataStdOut
								   stdErr:ci.dataStdErr
								  retCode:ci.retCode
								 timedOut:ci.bTimeOut
								 userData:ci.user];
	[ci release];
}

- (void) taskCheckCallDelegate:(CmdInfo*)ci
{
	Boolean bShouldCallDelegate = [ ci shouldReadThreadDoDelegateCallBack ];
	if (bShouldCallDelegate ) {
		++ ci.delegateCallBackCount;
		assert(ci.delegateCallBackCount == 1);
		
		NSTask* task = ci.task;
		ci.task = NULL;
		[task waitUntilExit];
		-- mnCmdInProgressCount ;
		ci.retCode = [task terminationStatus];
		
		[self performSelectorOnMainThread:@selector(doDelegateCallBack:) 
							   withObject:ci waitUntilDone:FALSE];
	}
}

- (void) threadEntryReadTaskStdOut:(NSObject*)param 
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	CmdInfo* ci = (CmdInfo*) param;
	[ci retain];
	@try {
		ci.dataStdOut = [ci.pipeStdOut_In readDataToEndOfFile];
	}
	@catch (NSException * e) {
		ci.dataStdOut = [NSMutableData data];
	}
	@finally {
	}
	[ci release];
	[self taskCheckCallDelegate:ci];
	
	[pool drain];
}

- (void) threadEntryReadTaskStdErr:(NSObject*)param
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	CmdInfo* ci = (CmdInfo*) param;
	[ci retain];
	@try {
		ci.dataStdErr = [ci.pipeStdErr_In readDataToEndOfFile];
	}
	@catch (NSException * e) {
		ci.dataStdErr = [NSMutableData data];
	}
	@finally {
	}
	[ci release];
	[self taskCheckCallDelegate:ci];
	
	[pool drain];
}

- (void) threadEntryTaskAsynchTimeOut:(NSObject*)param
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	CmdInfo* ci = (CmdInfo*) param;
	[ci retain];
	NSTimeInterval timeOut = ci.timeOut;
	[NSThread sleepForTimeInterval:timeOut];
	
	if (ci.task) {
		ci.bTimeOut = TRUE;
		[ci.task terminate];
		[ci.pipeStdOut_In closeFile];
		[ci.pipeStdErr_In closeFile];
	}
	
	[ci release];
	
	[pool drain];
}

@end













































