//
//  ParseCommandLine.h
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
	eUploadFile,
	eHelp
} CommandType;

typedef enum _A3AccessControl {
	ePublic,
	ePrivate
} A3AccessControl;

typedef struct _HelpCommand {
	
} HelpCommand;

typedef struct _UploadFileCommand {
	char* pszLocalPath;
	char* pszRemotePath;
	char* pszRemoteBucket;
	A3AccessControl a3ac;
	Boolean bDeleteAfter;
} UploadFileCommand;


// THE UNION COULD BE USED IF ADDITIONAL KINDS OF COMMANDS WERE ADDED LATER
typedef struct _Command {
	char* pszSharedKey;
	char* pszSecretKey;
	CommandType ct;
 	Boolean bHumanReadable;
	NSTimeInterval timeIntTimeOut;
	union {
		UploadFileCommand uploadFileCmd;
		HelpCommand helpCmd;
	} u;
} Command;


Boolean ParseCommandLine(Command* pCmd, int argc, char** argv);

void OutputUsage(void);
