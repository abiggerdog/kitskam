/*
 *  ParseCommandLine.h
 *
 */
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
#import <Carbon/Carbon.h>

typedef enum _CommandType {
	eNoCommand,
	eCameraList,
	eDownloadImage,
	eDeleteImage,
	eTakePicture 
} CommandType;


typedef struct _DownloadImageCommand {
	ICAObject objImage;
	char* pszImageFileName;
	char* pszThumFileName;
	Boolean bHasThumPct;
	double dThumPct;
	Boolean bDeleteAfter;
	Boolean bForceDelete;
} DownloadImageCommand;

typedef struct _DeleteImageCommand {
	ICAObject objImage;
} DeleteImageCommand;

typedef struct _TakePictureCommand {
	ICAObject objCamera;
	Boolean bDownloadImage;
	DownloadImageCommand downImgCmd;
} TakePictureCommand;

typedef struct _Command {
	CommandType ct;
 	Boolean bHumanReadable;
	Boolean bPrintHelp;
	NSTimeInterval timeIntTimeOut;
	union {
		TakePictureCommand takePicCmd;
		DownloadImageCommand downImgCmd;
		DeleteImageCommand delImgCmd;
	} u;
} Command;


Boolean ParseCommandLine(Command* pCmd, int argc, char** argv);

DownloadImageCommand* GetDownloadImageCmd(Command* pCmd);

void OutputUsage(void);
