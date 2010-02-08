//
//  MyAmazonS3Utils.m
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

#import "MyAmazonS3Utils.h"

#define IS_LOWER_LETTER(c)				( 'a' <= (c) && (c) <= 'z' )
#define IS_DIGIT(c)						( '0' <= (c) && (c) <= '9' )

// http://awsdocs.s3.amazonaws.com/S3/latest/s3-dg.pdf
Boolean IsValidAmazonS3Key(const char* psz) {
	Boolean ret = FALSE;
	if (psz) {
		NSString* str = [NSString stringWithCString:psz 
										   encoding:NSUTF8StringEncoding];
		ret = IsValidAmazonS3KeyStr(str);
	}
	return ret;
}

Boolean IsValidAmazonS3KeyStr(NSString* str) {
	Boolean ret = FALSE;
	const char* psz = [str cStringUsingEncoding:NSUTF8StringEncoding];
	const char* psz2 = [str cStringUsingEncoding:NSASCIIStringEncoding];
	if (! strcmp(psz, psz2)) {
		int n = [str length];
		if (1 <= n && n <= 1024) {
			ret = TRUE;
		}
	}
	return ret;
}

// http://awsdocs.s3.amazonaws.com/S3/latest/s3-dg.pdf
Boolean IsValidAmazonS3BucketName(const char* psz) {
	Boolean ret = FALSE;
	int n = strlen(psz);
	if (3 <= n && n <= 255) {
		if ( IS_DIGIT(psz[0]) || IS_LOWER_LETTER(psz[0]) ) {
			int k = 0;
			while(k < n) {
				int c = psz[k];
				if ( IS_LOWER_LETTER(c) ||
					IS_DIGIT(c) ||
					c == '.' ||
					c == '_' || 
					c == '-' ) {
					++ k;
				} else {
					break;
				}
			}
			ret = (k == n);
		}
	}
	return ret;
}

Boolean IsValidAmazonS3BucketNameStr(NSString* str) {
	const char* psz = [str cStringUsingEncoding:NSASCIIStringEncoding];
	Boolean ret = IsValidAmazonS3BucketName(psz);
	return ret;
}

Boolean IsValidAmazonS3RemotePathStr(NSString* str) {
	Boolean ret = FALSE;
	if ( [str length] > 0 ) {
		NSString *temp = [str substringToIndex:1];
		if ( [temp compare:@"/"] == NSOrderedSame ) {
			ret = IsValidAmazonS3KeyStr(str);
		}
	}
	return ret;
}