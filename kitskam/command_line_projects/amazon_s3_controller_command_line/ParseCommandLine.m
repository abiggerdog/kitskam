//
//  ParseCommandLine.m
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

#import "ParseCommandLine.h"
#import "MyAmazonS3Utils.h"
#import "MyUtils.h"

static Boolean GetA3AccessControl(A3AccessControl* pa3ac, char* psz);
static char* GetCommandName(CommandType ct) ;
static Boolean GetTimeOutValue(NSTimeInterval* ptimeIntTimeOut, char* psz);
static Boolean ValidateCommandLine(Command* pCmd);
static Boolean ValidateUploadPathAndKey(UploadFileCommand* pUpCmd);
static Boolean ValidateSharedAndSecretKeys(Command* pCmd);
static void WriteErrArgumentMissing(char* argName);
static void WriteErrConflictingCommands(CommandType ct1, CommandType ct2) ;
static void WriteErrInvalidAmazonS3BucketName(char* bucketName)	;
static void WriteErrInvalidAmazonS3Key(char* psz) ;
static void WriteErrParamaterRequiresCommand(char* paramName, CommandType ct) ;
static void WriteErrParamaterMissing(char* paramName);

// ***********
// ***********
// ***********

Boolean ParseCommandLine(Command* pCmd, int argc, char** argv)
{
	Boolean bParseErr = FALSE;
	for(int k = 1; k < argc; ++ k) {
		if (! strcmp( argv[k], "--shared-key")) {
			if (++ k == argc || argv[k][0] == '-') {
				WriteErrArgumentMissing("--shared-key");
				bParseErr = TRUE;
				break;
			}
			pCmd->pszSharedKey = argv[k];
		} else if (! strcmp( argv[k], "--secret-key")) {
			if (++ k == argc || argv[k][0] == '-') {
				WriteErrArgumentMissing("--secret-key");
				bParseErr = TRUE;
				break;
			}
			pCmd->pszSecretKey = argv[k];
		} else if (! strcmp( argv[k], "--upload-file")) {
			if (pCmd->ct != eNoCommand) {
				WriteErrConflictingCommands(pCmd->ct, eUploadFile);
				bParseErr = TRUE;
				break;
			} else {
				pCmd->ct = eUploadFile;
				pCmd->u.uploadFileCmd.a3ac = ePrivate;
			}
		} else if (! strcmp( argv[k], "--local-path")) {
			if (pCmd->ct != eUploadFile) {
				WriteErrParamaterRequiresCommand("--local-path", eUploadFile);
				bParseErr = TRUE;
				break;
			} else {
				if (++ k == argc || argv[k][0] == '-') {
					WriteErrArgumentMissing("--local-path");
					bParseErr = TRUE;
					break;
				}
				pCmd->u.uploadFileCmd.pszLocalPath = argv[k];
			}
		} else if (! strcmp( argv[k], "--remote-bucket-name")) {
			if (pCmd->ct != eUploadFile) {
				WriteErrParamaterRequiresCommand("--remote-bucket-name", eUploadFile);
				bParseErr = TRUE;
				break;
			} else {
				if (++ k == argc || argv[k][0] == '-') {
					WriteErrArgumentMissing("--remote-bucket-name");
					bParseErr = TRUE;
					break;
				}
				pCmd->u.uploadFileCmd.pszRemoteBucket = argv[k];
			}
		} else if (! strcmp( argv[k], "--remote-path")) {
			if (pCmd->ct != eUploadFile) {
				WriteErrParamaterRequiresCommand("--remote-path", eUploadFile);
				bParseErr = TRUE;
				break;
			} else {
				if (++ k == argc || argv[k][0] == '-') {
					WriteErrArgumentMissing("--remote-path");
					bParseErr = TRUE;
					break;
				}
				pCmd->u.uploadFileCmd.pszRemotePath = argv[k];
			}
		} else if (! strcmp( argv[k], "--remote-access-control")) {
			if (pCmd->ct != eUploadFile) {
				WriteErrParamaterRequiresCommand("--remote-access-control", eUploadFile);
				bParseErr = TRUE;
				break;
			} else {
				if (++ k == argc || argv[k][0] == '-') {
					WriteErrArgumentMissing("--remote-path");
					bParseErr = TRUE;
					break;
				}
				if ( ! GetA3AccessControl( &pCmd->u.uploadFileCmd.a3ac, argv[k] ) ) {
					bParseErr = TRUE;
					break;
				}
			}
		} else if (! strcmp( argv[k], "--delete-after-upload")) {
			if (pCmd->ct != eUploadFile) {
				WriteErrParamaterRequiresCommand("--delete-after-upload", eUploadFile);
				bParseErr = TRUE;
				break;
			} else {
				pCmd->u.uploadFileCmd.bDeleteAfter = TRUE;
			}
		} else if (! strcmp( argv[k], "--human-readable")) {
			pCmd->bHumanReadable = TRUE;
//		} else if (! strcmp( argv[k], "--time-out")) {
//			if (++ k == argc || argv[k][0] == '-') {
//				WriteErrArgumentMissing("--time-out");
//				bParseErr = TRUE;
//				break;
//			}
//			if (! GetTimeOutValue(&pCmd->timeIntTimeOut, argv[k])) {
//				bParseErr = TRUE;
//				break;
//			}
		} else if (! strcmp( argv[k], "--help")) {
			pCmd->ct = eHelp;
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


void OutputUsage(void) {
	printf(
		   "\n"
		   "\n"
		   "USAGE -- amazon_s3_controller_command_line\n"
		   "\n"
		   "Utility for command line access to Amazon S3 storage.\n"
		   "\n"
		   "GENERAL PARAMATERS\n"
		   "       --shared-key <shared key>       USE TO SPECIFY THE AMAZON S3 SHARED KEY\n"
		   "       --secret-key <secret key>       USE TO SPECIFY THE AMAZON S3 SECRET KEY\n"
		   "       --human-readable                CAUSES OUTPUT TO BE WRITTEN IN HUMAN-READABLE FORM\n"
		   "                                       CURRENTLY HAS NO EFFECT, BECAUSE NO JSON OBJECTS ARE WRITTEN \n"
		   "                                       TO STANDARD OUTPUT\n"
		   "\n"
		   "COMMAND --help                         SHOWS THIS USAGE INFORMATION\n"
		   "COMMAND --upload-file                  WILL UPLOAD A LOCAL DISK FILE TO AMAZON S3\n"
		   "       REQUIRES THE --shared-key AND --secret-key PARAMATERES\n"
		   "       REQUIRES\n"
		   "       --local-file <file path>        SPECIFIES THE LOCAL FILE TO UPLOAD\n"
		   "       --remote-bucket-name <bucket>   SPECIFIES THE AMAZON S3 BUCKET TO UPLOAD TO\n"
		   "       --remote-path                   SPECIFIES THE AMAZON S3 OBJECT KEY OR UPLOAD FILE 'NAME' INCLUDING PATH\n"
		   "                                       SHOULD BEGIN WITH A '/'\n"
		   "       OPTIONAL\n"
		   "       --remote-access-control         SPECIFIES THE AMAZON S3 ACCESS CONTROL\n"
		   "                                       CAN BE 'private' OR 'public'\n"
		   "                                       DEFAULT VALUE IS 'private'\n"
		   "       --delete-after-upload           WILL CAUSE THE LOCAL FILE TO BE DELETED AFTER A SUCCESSFUL UPLOAD\n"
		   "\n"
		   "EXAMPLES\n"
		   "\n"
		   "amazon_s3_controller_command_line --shared-key AHAHKJHAKJHA --secrete-key ALKJAOISKJALKJALKJALK --upload-file --local-file test.jpg --remote-bucket-name my_test_bucket --remote-path /testdir/uploadfile.jpg --remote-access-control public --delete-after-upload\n"
		   "\n"
		   "       THIS WILL CAUSE local file 'test.jpg' TO BE UPLOADED TO '/testdir/uploadfile.jpg' IN BUCKET 'my_test_bucket'.  \n"
		   "       THE FILE WILL BE MADE PUBLICLY ACCESSIBLE.  IF THE UPLOAD IS SUCCESSFUL, THE LOCAL FILE IS DELETED.\n"
		   "\n"
		   "       IF '--remote-access-control public' HAD BEEN OMITTED, THE ACCESS WOULD HAVE DEFAULTED TO PRIVATE.\n"
		   "       IF '--delete-after-upload' HAD BEEN OMITTED, THE LOCAL FILE WOULD NOT HAVE BEEN DELETED AFTER SUCCESS.\n"
		   "\n"
		   "       ON SUCCES, NOTHING IS WRITTEN TO STANDARD OUTPUT.\n"
		   "       ON FAILURE, AN ERROR MESSAGE IS WRITTEN TO STANDARD ERROR.\n"
		   );	
	
}

// ****************************************************************************
// **  MODULE PRIVATE FUNCTIONS  **********************************************
// ****************************************************************************

static Boolean GetA3AccessControl(A3AccessControl* pa3ac, char* psz)
{
	Boolean ret = FALSE;
	if (! strcmp(psz, "public")) {
		*pa3ac = ePublic;
		ret = TRUE;
	} else if (! strcmp(psz, "private")) {
		*pa3ac = ePrivate;
		ret = TRUE;
	} else {
		fprintf(stderr, "%s is not an Amazon S3 access control: 'public' or 'private'\n",
				psz);
	}
	return ret;
}

static char* GetCommandName(CommandType ct) 
{
	char* ret = NULL;
	switch (ct) {
		case eNoCommand:
			ret = "No Command";
			break;
		case eUploadFile:
			ret = "Upload File";
			break;
		case eHelp:
			ret = "Help";
			break;
		default:
			assert(FALSE);
			break;
	}
	return ret;
}

static Boolean GetTimeOutValue(NSTimeInterval* ptimeIntTimeOut, char* psz)
{
	Boolean ret = FALSE;
	if ( sscanf(psz, "%lf", ptimeIntTimeOut) == 1 && *ptimeIntTimeOut >= 0.0) {
		ret = TRUE;
	} else {
		fprintf(stderr, "%s is not a valid time-out value \n", psz);
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
		case eUploadFile:
			if (ValidateSharedAndSecretKeys(pCmd)) {
				ret = ValidateUploadPathAndKey(&pCmd->u.uploadFileCmd);
			}
			break;
		case eHelp:
			ret = TRUE;
			break;
		default:
			assert(FALSE);
			break;
	}
	return ret;
}

static Boolean ValidateUploadPathAndKey(UploadFileCommand* pUpCmd)
{
	Boolean ret = FALSE;
	char* pszLocal = pUpCmd->pszLocalPath;
	char* pszRemote = pUpCmd->pszRemotePath;
	char* pszRemoteBucket = pUpCmd->pszRemoteBucket;
	
	if (pszLocal) {
		if (pszRemote) {
			if ( IsValidAmazonS3Key(pszRemote) ) {
				if (pszRemoteBucket) {
					if (IsValidAmazonS3BucketName(pszRemoteBucket)) {
						NSString* strLocal = [NSString stringWithCString:pszLocal
																encoding:NSASCIIStringEncoding];
						
						FSRef localFSRef;
						if (MakeFSRefFromNSString(&localFSRef, strLocal)) {
							if ( [ [NSFileManager defaultManager] isReadableFileAtPath:strLocal]) {
								BOOL bDir;
								if ( [ [NSFileManager defaultManager] fileExistsAtPath:strLocal isDirectory:&bDir] ) {
									if (bDir) {
										fprintf(stderr, "Local file %s is a directory\n", pszLocal); 
									} else {
										if (pUpCmd->bDeleteAfter) {
											if ( [ [NSFileManager defaultManager] isWritableFileAtPath:strLocal]) {
												ret = TRUE;
											} else {
												fprintf(stderr, "You do not have permission to delete local file %s \n", pszLocal);
											}
										} else {										
											ret = TRUE;
										}
									}
								} else {
									fprintf(stderr, "Local file %s does not exist\n", pszLocal); // ACTUALLY CAN'T GET HERE
								}
							} else {
								fprintf(stderr, "Local file %s is not a readable file\n", pszLocal);
							}
						} else {
							fprintf(stderr, "Local file %s not found.\n", pszLocal);
						}
					} else {
						fprintf(stderr, "%s is not a valid Amazon S3 bucket name \n", pszRemoteBucket);
					}
				} else {
					WriteErrParamaterMissing("--remote-bucket-name");
				}
			} else {
				WriteErrInvalidAmazonS3Key(pszRemote);
			}
		} else {
			WriteErrParamaterMissing("--remote-path");
		}
	} else {
		WriteErrParamaterMissing("--local-path");
	}
		
	return ret;
}

static Boolean ValidateSharedAndSecretKeys(Command* pCmd) 
{
	Boolean ret = FALSE;
	
	if (pCmd->pszSharedKey) {
		if (IsValidAmazonS3Key(pCmd->pszSharedKey)) {
			if (pCmd->pszSecretKey) {
				if (IsValidAmazonS3Key(pCmd->pszSecretKey)) {
					ret = TRUE;
				} else {
					WriteErrInvalidAmazonS3Key(pCmd->pszSecretKey);
				}
			} else {
				fprintf(stderr, "Required paramater --secret-key missing. \n");
			}
		} else {
			WriteErrInvalidAmazonS3Key(pCmd->pszSharedKey);
		}
	} else {
		fprintf(stderr, "Required paramater --shared-key missing. \n");
	}
	return ret;
}

static void WriteErrArgumentMissing(char* argName)
{
	fprintf(stderr, "Required argument missing after \"%s\"  \n", argName);
}

static void WriteErrConflictingCommands(CommandType ct1, CommandType ct2) {
	fprintf(stderr, "Error: command \"%s\" cannot come after command \"%s\" \n",
			GetCommandName(ct2), GetCommandName(ct1) );
}

static void WriteErrInvalidAmazonS3BucketName(char* bucketName)	{
	fprintf(stderr, "%s is not a valid Amazon S3 bucket name \n", bucketName);
}

static void WriteErrInvalidAmazonS3Key(char* psz) {
	fprintf(stderr, "%s is not a valid Amazon S3 key\n");
}

static void WriteErrParamaterRequiresCommand(char* paramName, CommandType ct) {
	fprintf(stderr, "Paramater \"%s\" requires command \"%s\" \n",
			paramName, GetCommandName(ct) );
}

static void WriteErrParamaterMissing(char* paramName) {
	fprintf(stderr, "Missing required paramater %s\n", paramName);
}

						
						
