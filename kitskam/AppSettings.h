//
//  AppSettings.h
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

#import <Foundation/Foundation.h>

#define APP_TITLE								@"KitsKam"
#define UPLOAD_DIRECTORY						@"kitskam_upload"


#define CHECK_FIRSTRUN_DELAY_SEC				0.5

//#define DEVICE_OPERATION_TIMEOUT_SEC			10.0
#define DEVICE_OPERATION_TIMEOUT_SEC			150.0
#define LOGFONT_NAME							@"Arial"
#define LOGFONT_SIZE							10.0

#define DEFAULT_SAVE_DIR                        @"~/Pictures"
#define DEFAULT_IMAGEBASENAME                   @"kitskam_"
#define DEFAULT_IMAGENAMEPAT					@"%i_%d.%e"
#define DEFAULT_THUMNAMEPAT						@"%i_%d.%e"
#define DEFAULT_THUMPCT							10.0

#define DEFAULT_PICTINTERVAL                    60.0

#define UPLOAD_TIMER_INTERVAL_SEC				2.0
#define UPLOAD_TIMEOUT_SEC						300.0