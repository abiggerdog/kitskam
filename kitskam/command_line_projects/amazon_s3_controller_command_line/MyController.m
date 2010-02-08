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
#import "ASIS3Request.h"


@implementation MyController

@synthesize retCode;

- (MyController*) initWithArgc:(int)argc Argv:(char**)argv 
{
	if (self = [super init]) {
		memset(&mCmd, 0, sizeof(mCmd));
		if ( ! ParseCommandLine(&mCmd, argc, argv) ) {
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
	retCode = -1;
	
	
	switch (mCmd.ct) {
		case eUploadFile: {
			NSString* strSharedKey = [NSString stringWithCString:mCmd.pszSharedKey
														encoding:NSUTF8StringEncoding];
			NSString* strSecretKey = [NSString stringWithCString:mCmd.pszSecretKey
														encoding:NSUTF8StringEncoding];
			[ASIS3Request setSharedAccessKey:strSharedKey];
			[ASIS3Request setSharedSecretAccessKey:strSecretKey];
			
			char* pszLocalPath = mCmd.u.uploadFileCmd.pszLocalPath;
			NSString* strLocalPath = 
				[NSString stringWithCString:pszLocalPath
								   encoding:NSASCIIStringEncoding];
			
			NSString* strRemotePath = 
				[ [NSString stringWithCString:mCmd.u.uploadFileCmd.pszRemotePath
								   encoding:NSUTF8StringEncoding]
				 stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
			
			NSString* strRemoteBucket = 
				[ [NSString stringWithCString:mCmd.u.uploadFileCmd.pszRemoteBucket
									 encoding:NSASCIIStringEncoding]
				 stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
			
			NSData* fileData = [NSData dataWithContentsOfFile:strLocalPath];
			if (fileData) {
				ASIS3Request* request = 
				[ASIS3Request PUTRequestForData:fileData
									 withBucket:strRemoteBucket
										   path:strRemotePath];
				[request setMimeType:[ASIHTTPRequest mimeTypeForFileAtPath:strLocalPath]];
//			ASIS3Request* request = 
//			[ASIS3Request PUTRequestForFile:strLocalPath
//								 withBucket:strRemoteBucket
//									   path:strRemotePath];
				switch(mCmd.u.uploadFileCmd.a3ac) {
					case ePrivate:
						break;
					case ePublic:
						request.accessPolicy = @"public-read";
						break;
					default:
						assert(FALSE);
						break;
				}
				
				[request startSynchronous];
				if ([request error]) {
					fprintf(stderr,
							[ [[request error] localizedDescription] 
							 cStringUsingEncoding:NSASCIIStringEncoding]);
					//				NSLog(@"%@",[[request error] localizedDescription]);
				} else {
					retCode = 0;
					if (mCmd.u.uploadFileCmd.bDeleteAfter) {
						BOOL bDir;
						if ( [ [NSFileManager defaultManager] fileExistsAtPath:strLocalPath 
																   isDirectory:&bDir] ) {
							if (bDir) {
								retCode = -1;
								fprintf(stderr, "Not willing to delete directory %s \n", 
										pszLocalPath);
							} else {
								NSError* err = NULL;
								if (! [ [NSFileManager defaultManager]
									   removeItemAtPath:strLocalPath error:&err]) {
									retCode = -1;
									fprintf(stderr, "An error occurred removing local file %s after upload\n", 
											pszLocalPath);
								}
							}
						} // else { IF IT DOESNT EXIST ALREADY, THAT'S OK }
					}
				}
			} else {
				fprintf(stderr, "Error readong in contents of file %s\n", pszLocalPath);
			}
			
		} break;
			
		case eHelp:
			OutputUsage();
			break;
		default:
			assert(FALSE);
			break;
	}
	
	QuitApplicationEventLoop();
}

@end
