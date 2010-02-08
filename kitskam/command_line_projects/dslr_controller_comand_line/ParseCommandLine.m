/*
 *  ParseCommandLine.c
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

#include "ParseCommandLine.h"
#import "MyUtils.h"

static char* GetCommandName(CommandType ct) ;
static Boolean GetICAObjectHandle(ICAObject* pObj, char* psz);
static Boolean GetThumPercent(double* pdThumPercent, char* psz);
static Boolean GetTimeOutValue(NSTimeInterval* ptimeIntTimeOut, char* psz);
static Boolean HasDownloadCommand(Command* pCmd);
static Boolean ValidateDownloadFileNames(Command* pCmd);
static Boolean ValidateCommandLine(Command* pCmd);
static Boolean ValidateFileName(char* pszParamName, char* pszFileName);
static void WriteErrConflictingCommands(CommandType ct1, CommandType ct2) ;
static void WriteErrParamaterRequiresCommand(char* paramName, CommandType ct) ;
static void WriteErrParamaterMissing(char* paramName);

// ***********
// ***********
// ***********

Boolean ParseCommandLine(Command* pCmd, int argc, char** argv)
{
	Boolean bParseErr = FALSE;
	for(int k = 1; k < argc; ++ k) {
		if (! strcmp( argv[k], "--camera-list")) {
			if (pCmd->ct != eNoCommand) {
				WriteErrConflictingCommands(pCmd->ct, eCameraList);
				bParseErr = TRUE;
				break;
			} else {
				pCmd->ct = eCameraList;
			}
		} else if (! strcmp( argv[k], "--take-picture")) {
			if (pCmd->ct != eNoCommand) {
				WriteErrConflictingCommands(pCmd->ct, eTakePicture);
				bParseErr = TRUE;
				break;
			} else {
				pCmd->ct = eTakePicture;
				if (++ k == argc || argv[k][0] == '-') {
					WriteErrParamaterMissing("--take-picture");
					bParseErr = TRUE;
					break;
				}
				if (! GetICAObjectHandle( &pCmd->u.takePicCmd.objCamera, argv[k])) {
					bParseErr = TRUE;
					break;
				}
			}
		} else if (! strcmp( argv[k], "--download-image")) {
			if (pCmd->ct != eNoCommand && pCmd->ct != eTakePicture) {
				WriteErrConflictingCommands(pCmd->ct, eDownloadImage);
				bParseErr = TRUE;
				break;
			} else {
				if (pCmd->ct == eTakePicture) {
					pCmd->u.takePicCmd.bDownloadImage = TRUE;
				} else {
					if (++ k == argc || argv[k][0] == '-') {
						WriteErrParamaterMissing("--download-image");
						bParseErr = TRUE;
						break;
					}
					if (! GetICAObjectHandle( &pCmd->u.downImgCmd.objImage, argv[k])) {
						bParseErr = TRUE;
						break;
					}
					pCmd->ct = eDownloadImage;
				}
			}
		} else if (! strcmp( argv[k], "--delete-image")) {
			if (pCmd->ct != eNoCommand && pCmd->ct != eTakePicture && pCmd->ct != eDownloadImage) {
				WriteErrConflictingCommands(pCmd->ct, eDeleteImage);
				bParseErr = TRUE;
				break;
			} else {
				if (pCmd->ct == eTakePicture) {
					pCmd->u.takePicCmd.downImgCmd.bDeleteAfter = TRUE;
				} else if (pCmd->ct == eDownloadImage) {
					pCmd->u.downImgCmd.bDeleteAfter = TRUE;
				} else {
					if (++ k == argc || argv[k][0] == '-') {
						WriteErrParamaterMissing("--delete-image");
						bParseErr = TRUE;
						break;
					}
					if (! GetICAObjectHandle( &pCmd->u.delImgCmd.objImage, argv[k])) {
						bParseErr = TRUE;
						break;
					}
					pCmd->ct = eDeleteImage;
				}
			}
		} else if (! strcmp( argv[k], "--file-name")) {
			if (! HasDownloadCommand(pCmd) ) {
				WriteErrParamaterRequiresCommand("--file-name", eDownloadImage);
				bParseErr = TRUE;
				break;
			} else {
				if (++ k == argc || argv[k][0] == '-') {
					WriteErrParamaterMissing("--file-name");
					bParseErr = TRUE;
					break;
				}
				GetDownloadImageCmd(pCmd) -> pszImageFileName = argv[ k ];
			}
		} else if (! strcmp( argv[k], "--thum-file-name")) {
			if (! HasDownloadCommand(pCmd) ) {
				WriteErrParamaterRequiresCommand("--thum-file-name", eDownloadImage);
				bParseErr = TRUE;
				break;
			} else {
				if (++ k == argc || argv[k][0] == '-') {
					WriteErrParamaterMissing("--thum-file-name");
					bParseErr = TRUE;
					break;
				}
				GetDownloadImageCmd(pCmd) -> pszThumFileName = argv[ k ];
			}
		} else if (! strcmp( argv[k], "--thum-percent")) {
			if (! HasDownloadCommand(pCmd) ) {
				WriteErrParamaterRequiresCommand("--thum-percent", eDownloadImage);
				bParseErr = TRUE;
				break;
			} else {
				if (++ k == argc || argv[k][0] == '-') {
					WriteErrParamaterMissing("--thum-percent");
					bParseErr = TRUE;
					break;
				}
				GetDownloadImageCmd(pCmd) -> bHasThumPct = TRUE;
				if (! GetThumPercent( & GetDownloadImageCmd(pCmd) -> dThumPct, argv[k]) ) {
					bParseErr = TRUE;
					break;
				}
			}
		} else if (! strcmp( argv[k], "--delete-image")) {
			if (pCmd->ct == eNoCommand || HasDownloadCommand(pCmd)) {
				if (pCmd->ct != eNoCommand) {
					GetDownloadImageCmd(pCmd) -> bDeleteAfter = TRUE;
				} else {
					if (++ k == argc || argv[k][0] == '-') {
						WriteErrParamaterMissing("--delete-image");
						bParseErr = TRUE;
						break;
					}
					if (! GetICAObjectHandle(&pCmd->u.delImgCmd.objImage, argv[k] ) )  {
						bParseErr = TRUE;
						break;
					}
				}
			} else {
				if (pCmd->ct != eNoCommand) {
					fprintf(stderr, "The \"Delete Image\" command can only occur as the sole command, or "
							"follow the \"Download Image\" command \n");
					bParseErr = TRUE;
					break;
				}
			}
		} else if (! strcmp( argv[k], "--force-delete")) {
			if ( HasDownloadCommand(pCmd) && GetDownloadImageCmd(pCmd) -> bDeleteAfter ) {
				GetDownloadImageCmd(pCmd) -> bForceDelete = TRUE;
			} else {
				fprintf(stderr, "The Force Delete paramater must be preceded by both the Download Image command and the Delete Image command\n.");
				bParseErr = TRUE;
				break;
			}
		} else if (! strcmp( argv[k], "--human-readable")) {
			pCmd->bHumanReadable = TRUE;
		} else if (! strcmp( argv[k], "--time-out")) {
			if (++ k == argc || argv[k][0] == '-') {
				WriteErrParamaterMissing("--time-out");
				bParseErr = TRUE;
				break;
			}
			if (! GetTimeOutValue(&pCmd->timeIntTimeOut, argv[k])) {
				bParseErr = TRUE;
				break;
			}
		} else if (! strcmp( argv[k], "--help")) {
			pCmd->bPrintHelp = TRUE;
		} else {
			fprintf(stderr, "Unrecognized command line argument %s \n", argv[k]);
			bParseErr = TRUE;
			break;
		}
	}
	
	Boolean ret = FALSE;
	if (! bParseErr) {
		ret = ValidateCommandLine(pCmd);
	}
	
	return ret;
}

DownloadImageCommand* GetDownloadImageCmd(Command* pCmd)
{
	DownloadImageCommand* ret = NULL;
	switch(pCmd->ct) {
		case eNoCommand:
			break;
		case eCameraList:
			break;
		case eDownloadImage:
			ret = &pCmd->u.downImgCmd;
			break;
		case eDeleteImage:
			ret = FALSE;
			break;
		case eTakePicture:
			if (pCmd->u.takePicCmd.bDownloadImage) {
				ret = &pCmd->u.takePicCmd.downImgCmd;
			}
			break;
		default:
			assert(FALSE);
			break;
	}
	assert( ret != NULL);
	return ret;
}

void OutputUsage(void) {
	printf(
		   "\n"
		   "\n"
		   "USAGE -- dslr_controller_command_line\n"
		   "\n"
		   "Utility for command line operation of a DSLR camera.\n"
		   "Provides ability to list available cameras, pictures on a camera,\n"
		   "to delete or download a picture from camera storage, and to take\n"
		   "a new picture, with the optional ability to immediately download\n"
		   "the picture without storing it on the device.\n"
		   "\n"
		   "GENEREAL PARAMATERS\n"
		   "	--human-readable		CAUSES OUTPUT TO BE WRITTEN IN \n"
		   "					HUMAN-READABLE FORM (JSON OBJECTS)\n"
		   "	--time-out			MAXIMUM TIME ALLOWED FOR OPERATION\n"
		   "					IN SECONDS.  ONLY IMPLEMENTED FOR\n"
		   "					--take-picture COMMAND\n"
		   "\n"
		   "COMMAND --camera-list			WRITES JSON OBJECT DESCRIBING ALL CAMERAS\n"
		   "					ATTACHED TO THE MACHINE, AND THE PICTURES\n"
		   "					STORED ON EACH CAMERA.  THE JSON OBJECT IS\n"
		   "					AN ARRAY IN WHICH EACH ELEMENT IS A DICTIONARY\n"
		   "					GIVING INFORMATION FOR AN ATTACHED CAMERA.\n"
		   "\n"
		   "COMMAND --delete-image <img handle>	DELETES AN IMAGE FROM CAMERA STORAGE.\n"
		   "					REQUIRES ARGUMENT 'img handle' WHICH IS\n"
		   "					AN INTEGER WHICH UNIQUELY DETERMINES THE\n"
		   "					IMAGE TO BE DELETED, AND THE CAMERA ON\n"
		   "					WHICH IT RESIDES.\n"
		   "\n"
		   "COMMAND --download-image <img handle>	DOWNLOADS AN IMAGE AND ITS THUMBNAIL FROM\n"
		   "					CAMERA STORAGE\n"
		   "	REQUIRES\n"
		   "	--file-name <fname>		'fname' NAME OF IMAGE SAVE FILE\n"
		   "	--thum-file-name <tname>	'tname' NAME OF THUMBNAIL SAVE FILE\n"
		   "	OPTIONAL\n"
		   "	--thum-percent <pct>		'pct' IS LINEAR SCALE FACTOR\n"
		   "					IN THIS CASE, THUMBNAIL IS CREATED\n"
		   "					BY SCALING THE IMAGE, RATHER THAN \n"
		   "					DOWNLOADING  'pct' MUST BE BETWEEN\n"
		   "					0.01 AND 1.0\n"
		   "	--delete-image			CAUSES THE IMAGE AND THUMBNAIL TO BE\n"
		   "					DELETED FROM CAMERA STORAGE ON SUCCESSFUL\n"
		   "					DOWNLOAD\n"
		   "	--force-delete			THE IMAGE AND THUMBNAIL ARE DELETED FROM\n"
		   "					CAMERA STORAGE EVEN IF AN ERROR OCCURS\n"
		   "					DOWNLOADING THEM\n"
		   "\n"
		   "COMMAND --take-picture <cam handle>	TAKES A PICTURE WITH THE CAMERA SPECIFIED\n"
		   "					BY 'cam handle'\n"
		   "	OPTIONAL\n"
		   "		Can be followed by --download-image in which case\n"
		   "		paramaters must follow --download-image as described above,\n"
		   "		WITH THE EXCEPTION that the 'img handle' argument is omitted\n"
		   "		after --download-image, because the 'img handle' will be that\n"
		   "		of the newly taken picture.  In this case, --download-image\n"
		   "		can take any of its optional paramaters, as described above.\n"
		   "\n"
		   "	This command will output a JSON dictionary giving information about\n"
		   "	the new picture taken, UNLESS it is followed by the --download-image\n"
		   "	command.\n"
		   "\n"
		   "\n"
		   "A USEFUL REFERENCE IN UNDERSTANDING THE JSON OUTPUT\n"
		   "Image Capture SDK for Mac OS X v10.4 (DMG) \n"
		   "       Documentation:  Image Capture Architecture.pdf \n"
		   "       http://developer.apple.com/sdk/  \n"
		   "       ftp://ftp.apple.com/developer/Development_Kits/ImageCapture_Tiger_SDK.dmg  \n"
		   "\n"
		   "SOME KEYS IN THE OUTPUT JSON DICTIONARY\n"
		   "	'icao'		INTEGER OBJECT HANDLE, FOR BOTH CAMERAS AND IMAGES\n"
		   "	'ifil'		NAME OF CAMERA.  INTERNAL STORAGE NAME OF A PICTURE\n"
		   "	'9003'		DATE OF PICTURE\n"
		   "	'0100'		WIDTH OF PICTURE IN PIXELS\n"
		   "	'0101'		HEIGHT OF PICTURE IN PIXELS\n"
		   "	'isiz'		SIZE OF PICTURE IMAGE IN BYTES\n"
		   "\n"
		   "EXAMPLES\n"
		   "\n"
		   "dslr_controller_command_line --camera-list --human-readable\n"
		   "	WILL OUTPUT JSON OBJECT LISTING ATTACHED CAMERAS, AND PICTURES STORED\n"
		   "	ON EACH OF THESE CAMERAS, AS WELL AS WIDTH, HEIGHT, SIZE INFORMATION ON\n"
		   "	EACH PICTURE.  THIS INFORMATION ALLOWS USE OF ALL THE OTHER COMMANDS. \n"
		   "	--human-readable CAUSES THE OUTPUT TO BE NICELY INDENTED FOR READABILITY.\n"
		   "\n"
		   "\n"
		   "dslr_controller_command_line --take-picture 10789103 --download-image --file-name img.jpg --thum-file-name thum.jpg --thum-percent 0.1 --delete-image --force-delete\n"
		   "	WILL TAKE A NEW PICTURE, DOWNLOAD IT TO img.jpg AND thum.jpg WITH\n"
		   "	THE THUMBNAIL SCALED AS 10 PERCENT THE IMAGE SIZE.  IT WILL DELETE\n"
		   "	THE NEW PICTURE FROM THE CAMERA'S STORAGE, EVEN IF THE DOWNLOAD FOR SOME\n"
		   "	REASON FAILS.  HERE '10789103' SPECIFIES THE CAMERA TO  USE, AND MAY\n"
		   "	HAVE BEEN DETERMINED BY FIRST USING THE --camera-list COMMAND.\n"
		   "\n"
		   "REQUIRES\n"
		   "	OS X 10.5\n"
		   "\n"
		   "DATE\n"
		   "	1/24/10\n"
		   "\n"
		   );
}


// ****************************************************************************
// **  MODULE PRIVATE FUNCTIONS  **********************************************
// ****************************************************************************

static char* GetCommandName(CommandType ct) 
{
	char* ret = NULL;
	switch (ct) {
		case eNoCommand:
			ret = "No Command";
			break;
		case eCameraList:
			ret = "Camera List";
			break;
		case eDownloadImage:
			ret = "Download Image";
			break;
		case eDeleteImage:
			ret = "Delete Image";
			break;
		case eTakePicture:
			ret = "Take Picture";
			break;
		default:
			assert(FALSE);
			break;
	}
	return ret;
}

static Boolean GetICAObjectHandle(ICAObject* pObj, char* psz)
{
	Boolean ret = FALSE;
	if (sscanf(psz, "%d", pObj) == 1 && *pObj != 0) {
		ret = TRUE;
	} else {
		fprintf(stderr, "\"%s\" is not a valid ICAObject handle \n", psz);
	}
	return ret;
}

static Boolean GetThumPercent(double* pdThumPercent, char* psz)
{
	Boolean ret = FALSE;
	if ( sscanf(psz, "%lf", pdThumPercent) == 1 && *pdThumPercent >= 0.01 && *pdThumPercent <= 1.0) {
		ret = TRUE;
	} else {
		fprintf(stderr, "%s is not a valid thumbnail percentage value \n", psz);
	}
	return ret;
}

static Boolean GetTimeOutValue(double* ptimeIntTimeOut, char* psz)
{
	Boolean ret = FALSE;
	if ( sscanf(psz, "%lf", ptimeIntTimeOut) == 1 && *ptimeIntTimeOut >= 0.0) {
		ret = TRUE;
	} else {
		fprintf(stderr, "%s is not a valid time-out value \n", psz);
	}
	return ret;
}

static Boolean HasDownloadCommand(Command* pCmd)
{
	Boolean ret = FALSE;
	switch(pCmd->ct) {
		case eNoCommand:
			break;
		case eCameraList:
			break;
		case eDownloadImage:
			ret = TRUE;
			break;
		case eDeleteImage:
			ret = FALSE;
			break;
		case eTakePicture:
			ret = pCmd->u.takePicCmd.bDownloadImage;
			break;
		default:
			assert(FALSE);
			break;
	}
	return ret;
}

static Boolean ValidateCommandLine(Command* pCmd)
{
	Boolean ret = FALSE;
	switch(pCmd->ct) {
		case eNoCommand:
			fprintf(stderr, "No command \n");
			break;
		case eCameraList:
			ret = TRUE;
			break;
		case eDownloadImage:
			if (ValidateDownloadFileNames(pCmd)) {
				ret = TRUE;
			}
			break;
		case eDeleteImage:
			ret = TRUE;
			break;
		case eTakePicture:
			if (pCmd->u.takePicCmd.bDownloadImage) {
				if (ValidateDownloadFileNames(pCmd)) {
					ret = TRUE;
				}
			} else {
				ret = TRUE;
			}
			break;
		default:
			assert(FALSE);
			break;
	}
	return ret;
}

static Boolean ValidateDownloadFileNames(Command* pCmd)
{
	Boolean ret = FALSE;
	DownloadImageCommand* pDownImgComd = GetDownloadImageCmd(pCmd);
	if ( ValidateFileName("--file-name", pDownImgComd->pszImageFileName) ) {
		if ( ValidateFileName("--thum-file-name", pDownImgComd->pszThumFileName) ) {
			Boolean bPathsEqual;
			Boolean temp = ComparePaths( &bPathsEqual,
										[NSString stringWithCString:pDownImgComd->pszImageFileName], 
										[NSString stringWithCString:pDownImgComd->pszThumFileName] );
			assert(temp);
			if (bPathsEqual) {
				fprintf(stderr, "The image and thum files cannot be the same. \n");
			} else {
				ret = TRUE;
			}
		}
	}
	return ret;
}

static Boolean ValidateFileName(char* pszParamName, char* pszFileName)
{
	Boolean ret = TRUE;
	if (pszFileName) {
		NSString* strFileName = NULL;
		Boolean temp = GetAbsoultePath(&strFileName, [NSString stringWithCString:pszFileName]);
		assert(temp);
		NSString* strDirectory = [strFileName stringByDeletingLastPathComponent];
		FSRef ref;
		if (! MakeFSRefFromNSString(&ref, strDirectory)) {
			ret = FALSE;
			fprintf(stderr, "The directory %s for file %s does not exist. \n",
					[strDirectory fileSystemRepresentation] , pszFileName);
		} else if ( ! [ [NSFileManager defaultManager] isWritableFileAtPath:strDirectory ] ) {
			ret = FALSE;
			fprintf(stderr, "You do not have permission to write to the directory %s \n.",
					[strDirectory fileSystemRepresentation] );
		} else if ( MakeFSRefFromNSString(&ref, strFileName) ) {
			if ( ! [ [NSFileManager defaultManager] isWritableFileAtPath:strFileName ] ) {
				ret = FALSE;
				fprintf(stderr, "You do not have permission to write to the file %s \n.",
						pszFileName);
			}
		}
	} else {
		fprintf(stderr, "Paramater %s not found. \n", pszParamName);
		ret = FALSE;
	}
	return ret;
}

static void WriteErrConflictingCommands(CommandType ct1, CommandType ct2) {
	fprintf(stderr, "Error: command \"%s\" cannot come after command \"%s\" \n",
			GetCommandName(ct2), GetCommandName(ct1) );
}

static void WriteErrParamaterRequiresCommand(char* paramName, CommandType ct) {
	fprintf(stderr, "Paramater \"%s\" requires command \"%s\" \n",
			paramName, GetCommandName(ct) );
}

static void WriteErrParamaterMissing(char* paramName)
{
	fprintf(stderr, "Required paramater missing after \"%s\"  \n", paramName);
}

