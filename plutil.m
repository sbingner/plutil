#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import "json-framework/Classes/NSObject+SBJson.h"
#import "iphone-3.0-cookbook-/C16-Push/02-PushUtil/JSONHelper.h"

@interface NSDate (NSDate_dateWithNaturalLanguageString)
+(id)dateWithNaturalLanguageString:(NSString *)string;
@end

const char *program_name;
bool useVerbose;
bool useDebug;

void WriteMyPropertyListToFile(NSDictionary* a1, NSURL* url)
{
	SInt32 error;
	CFDataRef data;

	data = CFPropertyListCreateXMLData(kCFAllocatorDefault, a1);
	CFURLWriteDataAndPropertiesToResource((CFURLRef)url, data, NULL, &error);
	CFRelease(data);
}

void WriteMyPropertyListToStdOut(CFPropertyListRef a1)
{
	id v2 = [NSURL fileURLWithPath:@"/dev/stdout"];
	CFWriteStreamRef v3 = CFWriteStreamCreateWithFile(0, (CFURLRef)v2);
	CFWriteStreamOpen(v3);
	CFPropertyListWriteToStream(a1, v3, 100, 0);
	CFWriteStreamClose(v3);
	CFRelease(v3);
}

Boolean WriteMyPropertyListToXMLFile(NSData *data, NSURL *url)
{
	SInt32 errorCode;

	return CFURLWriteDataAndPropertiesToResource((CFURLRef)url, (CFDataRef)data, NULL, &errorCode);
}

void WriteMyPropertyListToBinaryFile(CFPropertyListRef plist, NSURL *url)
{
	CFWriteStreamRef stream;

	stream = CFWriteStreamCreateWithFile(0, (CFURLRef)url);
	CFWriteStreamOpen(stream);
	CFPropertyListWriteToStream(plist, stream, 200, 0);
	CFWriteStreamClose(stream);
	CFRelease(stream);
}

CFPropertyListRef readPropertyList(NSString *path)
{
	CFPropertyListRef plist;
	CFStringRef errorString;

	path = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		NSData *plistData = [NSData dataWithContentsOfFile:path];
		plist = CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (CFDataRef)plistData, 1, &errorString);
	}
	else
	{
		fprintf(stderr, "Error: File not found at path %s\n", [path UTF8String]);
		plist = NULL;
	}
	return plist;
}

void showPath(NSString *path)
{
	printf("FILE: %s\n", [path UTF8String]);
}

void dump(NSString *path)
{

	CFPropertyListRef plist = readPropertyList(path);
	if ( plist )
	{
		if ( useVerbose )
			showPath(path);
		WriteMyPropertyListToStdOut(plist);
		if ( useVerbose )
			putchar('\n');
	}
}

//----- (00006B84) --------------------------------------------------------
void show(NSString *a1)
{
	CFPropertyListRef result; // r0

	result = readPropertyList(a1);
	if ( result )
	{
		if ( useVerbose )
			showPath(a1);
		CFShow((CFStringRef)[(id)result description]);
		if ( useVerbose )
			putchar('\n');
	}
}

//----- (00006C2C) --------------------------------------------------------
CFTypeRef descend(id a1, id a2)
{

	if ( ![a2 count] )
		return (CFTypeRef)a1;
	if ( ![a1 isKindOfClass:[NSDictionary class]] )
	{
		if ( ![a1 isKindOfClass:[NSArray class]] )
			return 0;
	}
	id v4 = [a2 objectAtIndex:0];
	id v5 = [a1 objectForKey:v4];
	NSMutableArray *v6 = [NSMutableArray arrayWithArray:a2];
	[v6 removeObjectAtIndex:0];
	return descend(v5, v6);
}

//----- (00006E30) --------------------------------------------------------
void *objectOfType(NSString *a1, NSString *a2)
{
	void *v12; // [sp+0h] [bp-18h]
	void *v15; // [sp+Ch] [bp-Ch]

	if ( !a2 )
		return 0;
	if ( !a1 )
		return 0;

	if ( ![a1 caseInsensitiveCompare:@"string"] )
		return a2;
	if ( ![a1 caseInsensitiveCompare:@"int"] )
		v12 = [NSNumber numberWithInt:[a2 intValue]];
	else if ( ![a1 caseInsensitiveCompare: @"integer"] )
		v12 = [NSNumber numberWithInt:[a2 intValue]];
	else if ( ![a1 caseInsensitiveCompare: @"float"] )
		v12 = [NSNumber numberWithFloat:[a2 floatValue]];
	else if ( ![a1 caseInsensitiveCompare: @"real"] )
		v12 = [NSNumber numberWithFloat:[a2 floatValue]];
	else if ( ![a1 caseInsensitiveCompare: @"double"] )
		v12 = [NSNumber numberWithFloat:[a2 floatValue]];
	else if ( ![a1 caseInsensitiveCompare: @"bool"] )
		v12 = [NSNumber numberWithBool:[a2 boolValue]];
	else if ( ![a1 caseInsensitiveCompare: @"boolean"] )
		v12 = [NSNumber numberWithBool:[a2 boolValue]];
	else if ( ![a1 caseInsensitiveCompare: @"data"] )
		v12 = [a2 dataUsingEncoding:4];
	else if ( ![a1 caseInsensitiveCompare: @"date"] )
		v12 = [NSDate dateWithNaturalLanguageString:a2];
	else if ( ![a1 caseInsensitiveCompare: @"json"] )
	{
		v15 = [a2 JSONValue];
		if ( v15 )
		{
			v12 = v15;
		}
		else
		{
			fwrite("Error: could not convert json setvalue argument\n", 1u, 0x30u, stderr);
			fprintf(stderr, "       %s\n", [a2 UTF8String]);
			v12 = 0;
		}
	}
	else
		v12 = 0;
	return v12;
}

//----- (00007514) --------------------------------------------------------
NSString *fetchArg(NSString *a1)
{

	if ( !a1 )
	{
		fwrite("Internal Error: No argument supplied to fetchArg. Bailing.\n", 1u, 0x3Bu, stderr);
		exit(-1);
	}
	id arg = [[NSUserDefaults standardUserDefaults] objectForKey:[a1 substringFromIndex:1]];
	if ( !arg )
	{
		fprintf(stderr, "You must supply an argument to -. Bailing.\n"); 
		exit(-1);
	}
	return arg;
}

//----- (0000766C) --------------------------------------------------------
int usage()
{
	printf("Usage: %s options file...\n", program_name);
	puts("-help                   Print this message");
	puts("-full                   Print an exhaustive list of options");
	puts("-verbose                Show verbose output");
	puts("-show                   Show property list data");
	puts("-keys                   List top level dictionary keys");
	puts("-create                 Create a new empty property list");
	putchar('\n');
	puts("-key keyname            Recover value for key. Multiple uses builds keypath");
	puts("-value value            Set value for keypath");
	puts("-remove                 Remove value at keypath");
	puts("-type typeid            Type to use while setting key. Valid types are int,");
	puts("                        float, bool, json, and string (default). Use json to");
	puts("                        define arrays and dictionaries");
	puts("-convert format         Convert each property list file to selected format.");
	puts("                        Formats are xml1 and binary1 and json. Note that json");
	return puts("                        files are saved to filename.json");
}

//----- (000077D4) --------------------------------------------------------
int full()
{
	printf("Usage: %s options file...\n", program_name);
	puts("Help");
	puts("  -full                Print this message");
	puts("  -help                Print usage message");
	puts("\nShow Files");
	puts("  -verbose -v          Show verbose output");
	puts("  -useDebug               Show useDebug output");
	puts("  -dump                Dump property list file to stdout");
	puts("  -show                Show property list data");
	puts("  -showjson            Show property list data as JSON");
	puts("  -keys                List top level dictionary keys");
	puts("\nCreate and Convert Files");
	puts("  -create              Create a new empty property list");
	puts("  -convert format      Convert each property list file to selected format.");
	puts("                       Formats are xml1 and binary1 and json. Note that json");
	puts("                       files are saved to filename.json");
	puts("  -xml                 Equivalent to -convert xml1");
	puts("  -binary              Equivalent to -convert binary1");
	puts("  -json                Equivalent to -convert json. NOT used for typecasting");
	puts("  -backup              Create a plist backup. (File extension must be .plist)");
	puts("\nCreate Keypaths");
	puts("  -key keyname         Recover value for key. Multiple uses builds path");
	puts("  -set keyname         Recover value for key. (Synonym for key)");
	puts("  -rmkey keyname       Specifies a one-item keypath or adds itself as the");
	puts("                       last item of the keychain. (Toggles removal on.)");
	puts("  -(unrecognized)      Unrecognized flags are used to build keypaths");
	puts("\nSetting Values");
	puts("  -setvalue value      Set value for keypath");
	puts("  -value value         Set value for keypath (Synonym for setvalue)");
	puts("  -remove              Remove value at keypath. (Toggles removal on.)");
	puts("  -1 -yes -true        Set keypath value to Boolean true");
	puts("  -0 -no -false        Set keypath value to Boolean false");
	puts("  -int value           Use integer type. (Synonym: -integer)");
	puts("  -float value         Use float type. (Synonym: -real -double)");
	puts("  -string value        Use string type");
	puts("  -data filepath       Set keypath value to the NSData read from filepath");
	puts("  -now                 Set keypath value to the current NSDate");
	puts("  -fromnow delta       Set keypath value to current date off by delta seconds");
	puts("  -beforenow delta     Set keypath value to current date off by delta seconds");
	puts("  -array               Create a new array and set it as value for keypath");
	puts("  -dict -dictionary    Create a new dictionary, set it as value for keypath");
	puts("\nType Casting");
	puts("  -type typeid         Type to use while setting key. Valid types are");
	puts("                       string (default), int, integer, float, real,");
	puts("                       double, bool, boolean, data, and date. Dates use");
	puts("                       natural language conversion. Data converts value string");
	puts("                       to NSData. Use json to define arrays and dictionaries.");
	puts("\nWorking with Arrays");
	return puts("  -arrayadd            Add value to array at keypath");
}

//----- (00007BC8) --------------------------------------------------------
void NSRangeMake(NSRange *range, NSUInteger a2, NSUInteger a3)
{
	*range = NSMakeRange(a2, a3);
}

//----- (00007C00) --------------------------------------------------------
int main(int argc, const char **argv, const char **envp)
{
	NSError *v167=nil; // [sp+D4h] [bp-570h]
	int numArgsUsed=0; // [sp+F0h] [bp-554h]
	int v175=0; // [sp+F4h] [bp-550h]
	bool v176=false; // [sp+FAh] [bp-54Ah]
	bool v177=false; // [sp+FBh] [bp-549h]
	NSString *rmArg=nil; // [sp+FCh] [bp-548h]
	void *v179=nil; // [sp+100h] [bp-544h]
	char v180=0; // [sp+107h] [bp-53Dh]
	void *v181=nil; // [sp+108h] [bp-53Ch]
	NSString *v182; // [sp+10Ch] [bp-538h]
	char v186=0; // [sp+11Bh] [bp-529h]
	void *v199=nil; // [sp+188h] [bp-4BCh]
	int v200=0; // [sp+18Ch] [bp-4B8h]
	id v325=nil; // [sp+614h] [bp-30h]
	id v326=nil; // [sp+618h] [bp-2Ch]
	id v327=nil; // [sp+61Ch] [bp-28h]
	id v329=nil; // [sp+624h] [bp-20h]
	id v330=nil; // [sp+628h] [bp-1Ch]
	id v332=nil; // [sp+630h] [bp-14h]

	bool errorOut=false;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	program_name = argv[0];
	if ( argc == 1 )
	{
		usage();
		exit(1);
	}
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF beginswith '-'"];
	NSArray *dashedArgs = [args filteredArrayUsingPredicate:pred];
	numArgsUsed = 1;
	useDebug = false;
	useVerbose = false;
	NSMutableArray *keyArray = [NSMutableArray array];

	for (NSString *argument in dashedArgs) {
		if ( ![argument caseInsensitiveCompare:@"-help"] )
		{
			usage();
			exit(1);
		}
		if ( ![argument caseInsensitiveCompare:@"-full"] )
		{
			full();
			exit(1);
		}
		if ( ![argument caseInsensitiveCompare:@"-verbose"]
				|| ![argument caseInsensitiveCompare:@"-v"] )
		{
			useVerbose = 1;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-useDebug"] )
		{
			useDebug = 1;
			useVerbose = 1;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-remove"] )
		{
			v177 = 1;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-1"]
				|| ![argument caseInsensitiveCompare:@"-yes"]
				|| ![argument caseInsensitiveCompare:@"-true"] )
		{
			v176 = 1;
			v182 = @"bool";
			numArgsUsed++;
			v179 = [NSNumber numberWithBool:true];
		} else if ( ![argument caseInsensitiveCompare:@"-0"]
				|| ![argument caseInsensitiveCompare:@"-no"]
				|| ![argument caseInsensitiveCompare:@"-false"] )
		{
			v176 = 1;
			v182 = @"bool";
			numArgsUsed++;
			v179 = [NSNumber numberWithBool:false];
		} else if ( ![argument caseInsensitiveCompare:@"-now"] )
		{
			v176 = 1;
			v182 = @"date";
			numArgsUsed++;
			v179 = [NSDate date];
		} else if ( ![argument caseInsensitiveCompare:@"-array"] )
		{
			v176 = 1;
			v182 = @"array";
			numArgsUsed++;
			v179 = [NSArray array];
		} else if ( ![argument caseInsensitiveCompare:@"-dict"]
				|| ![argument caseInsensitiveCompare:@"-dictionary"] )
		{
			v176 = 1;
			v182 = @"dict";
			numArgsUsed++;
			v179 = [NSDictionary dictionary];
		} else if ( ![argument caseInsensitiveCompare:@"-arrayadd"] )
		{
			v176 = 1;
			v180 = 1;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-dump"]
				|| ![argument caseInsensitiveCompare:@"-show"]
				|| ![argument caseInsensitiveCompare:@"-showjson"]
				|| ![argument caseInsensitiveCompare:@"-keys"]
				|| ![argument caseInsensitiveCompare:@"-full"]
				|| ![argument caseInsensitiveCompare:@"-help"]
				|| ![argument caseInsensitiveCompare:@"-create"]
				|| ![argument caseInsensitiveCompare:@"-backup"] )
		{
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-xml"] )
		{
			v175 = 1;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-binary"] )
		{
			v175 = 2;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-json"] )
		{
			v175 = 3;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-key"]
				|| ![argument caseInsensitiveCompare:@"-set"] )
		{
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-rmkey"] )
		{
			v177 = 1;
			rmArg = fetchArg(argument);
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-setvalue"]
				|| ![argument caseInsensitiveCompare:@"-value"] )
		{
			v176 = 1;
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-type"] )
		{
			v182 = fetchArg(argument);
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-int"]
				|| ![argument caseInsensitiveCompare:@"-integer"] )
		{
			v176 = 1;
			v182 = @"int";
			v179 = [NSNumber numberWithInt:[fetchArg(argument) intValue]];
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-float"]
				|| ![argument caseInsensitiveCompare:@"-double"]
				|| ![argument caseInsensitiveCompare:@"-real"] )
		{
			v182 = @"float";
			v176 = 1;
			NSString *v9 = fetchArg(argument);
			v199 = v9;
			v179 = [NSNumber numberWithFloat:[v9 floatValue]];
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-string"] )
		{
			v182 = @"string";
			v176 = 1;
			v179 = fetchArg(argument);
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-fromnow"]
				|| ![argument caseInsensitiveCompare:@"-beforenow"] )
		{
			v176 = 1;
			v182 = @"date";
			NSString *v11 = fetchArg(argument);
			v200 = [v11 integerValue];
			if ( ![argument caseInsensitiveCompare: @"-beforenow"] )
				v200 = -v200;
			v179 = [NSDate dateWithTimeIntervalSinceNow:v200];
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-data"] )
		{
			v176 = 1;
			v182 = @"data";
			numArgsUsed += 2;
			NSString *v201 = fetchArg(argument);
			if ( ![[NSFileManager defaultManager] fileExistsAtPath:v201] )
			{
				fprintf(
						stderr,
						"Error: File with data not found at path: %s. Bailing.\n",
						[v201 UTF8String]);
				exit(-1);
			}
			v179 = [NSData dataWithContentsOfFile:v201];
			if ( !v179 )
			{
				fprintf(
						stderr,
						"Error: No data available at path: %s. Bailing.\n",
						[v201 UTF8String]);
				exit(-1);
			}
		} else if ( ![argument caseInsensitiveCompare:@"-convert"] )
		{
			NSString* v202 = fetchArg(argument);
			if ( ![v202 caseInsensitiveCompare:@"xml1"] )
			{
				v175 = 1;
			} else if ( ![v202 caseInsensitiveCompare:@"binary1"])
			{
				v175 = 2;
			} else if ( ![v202 caseInsensitiveCompare:@"json"])
			{
				v175 = 3;
			} else	{
				fprintf(
						stderr,
						"Error: Unrecognized conversion format (%s). Please use xml"
						"1, binary1 or json. Bailing.\n",
						[v202 UTF8String]);
				exit(-1);
			}
			numArgsUsed += 2;

		} else {
			if ( useDebug )
				printf("Unrecognized flag: %s. Using as key\n", [argument UTF8String]);

			[keyArray addObject:[argument substringFromIndex:1]];
			numArgsUsed++;
		}
	}
	if ( v176 && v177 )
	{
		fwrite("ERROR: You cannot set and remove in the same action. Bailing.\n", 1u, 0x3Eu, stderr);
		exit(-1);
	}
	NSArray<NSString*> *filePaths = [args subarrayWithRange:NSMakeRange(numArgsUsed, [args count] - numArgsUsed)];
	if ( ![filePaths count] )
	{
		puts("No file names specified. Bailing.");
		exit(1);
	}
	if ( useDebug )
	{
		printf("Arguments: %s\n", [[dashedArgs componentsJoinedByString:@" "] UTF8String]);
		printf("File paths: %s\n", [[filePaths componentsJoinedByString:@" "] UTF8String]);
	}
	for (NSString *argument in dashedArgs) {
		if ( ![argument caseInsensitiveCompare:@"-create"] )
		{
			errorOut=true;
			int v213=0;
			for (NSString *path in filePaths) {
				if ( [[NSFileManager defaultManager] fileExistsAtPath:path] )
				{
					fprintf(stderr, "Error: File already exists at %s. Skipping.\n", [path UTF8String]);
				}
				else
				{
					WriteMyPropertyListToFile([NSDictionary dictionary], [NSURL fileURLWithPath:path]);
					if ( useVerbose )
					{
						printf("Created new property list at %s\n", [path UTF8String]);
					}
					v213++;
				}
			}
			printf("Created %d new property list[s]\n", v213);
			continue;
		}
		if ( ![argument caseInsensitiveCompare:@"-dump"] )
		{
			errorOut=true;
			for (NSString *path in filePaths) {
				dump(path);
			}
			continue;
		}
		if ( ![argument caseInsensitiveCompare:@"-show"] )
		{
			errorOut=true;
			for (NSString *path in filePaths) {
				show(path);
			}
			continue;
		}
		if ( ![argument caseInsensitiveCompare:@"-showjson"] )
		{
			errorOut=true;
			for (NSString *path in filePaths) {
				CFPropertyListRef v254 = readPropertyList(path);
				if ( v254 )
				{
					if ( useVerbose )
						showPath(path);
					puts([[JSONHelper jsonWithDict:v254] UTF8String]);
				}
			}
			continue;
		}
		if ( ![argument caseInsensitiveCompare:@"-keys"] )
		{
			errorOut=true;
			for (NSString *path in filePaths) {
				CFPropertyListRef plist = readPropertyList(path);
				if ( plist )
				{
					if ( [(id)plist isKindOfClass:[NSDictionary class] ] )
					{
						if ( useVerbose )
							showPath(path);

						for (NSString *key in [(NSDictionary*)plist allKeys]) {
							id object = [(NSDictionary*)plist objectForKey:key];
							printf("%s", [object UTF8String]);
							if ( useVerbose )
							{
								printf(" [%s]", [[[object class] description] UTF8String]);
							}
							putchar('\n');
						}
					}
				}
			}
			continue;
		}
		if ( ![argument caseInsensitiveCompare:@"-backup"] )
		{
			errorOut=true;
			for (NSString *path in filePaths) {
				CFPropertyListRef v287 = readPropertyList(path);
				if ( v287 )
				{
					if ( [[[path pathExtension] uppercaseString] isEqualToString:@"PLIST"] )
					{
						WriteMyPropertyListToFile(v287, [NSURL fileURLWithPath:[path stringByAppendingPathExtension:@"bak"]]);
					}
				}
			}
		}
		if ( ![argument caseInsensitiveCompare:@"-convert"]
				|| ![argument caseInsensitiveCompare:@"-binary"]
				|| ![argument caseInsensitiveCompare:@"-xml"]
				|| ![argument caseInsensitiveCompare:@"-json"] )
		{
			errorOut=true;
			int convertedFilesCount=0;
			for (NSString *path in filePaths) {
				CFPropertyListRef v300 = readPropertyList(path);
				if ( v300 )
				{
					if ( v175 == 1 )
					{
						WriteMyPropertyListToFile(v300, [NSURL fileURLWithPath:path]);
					}
					else if ( v175 == 2 )
					{
						WriteMyPropertyListToBinaryFile(v300, [NSURL fileURLWithPath:path]);
					}
					else if ( v175 == 3 )
					{
						NSString *json = [JSONHelper jsonWithDict:v300];
						if ( !json )
							continue;
						json = [json stringByAppendingString:@"\n"];
						if ( ![json writeToFile:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"json"] atomically:YES encoding:4 error:&v167])
							fprintf(stderr, "Error writing json file: %s\n", [[v167 localizedDescription] UTF8String]);
					}

					convertedFilesCount++;
					if ( useVerbose )
					{
						printf("CONVERTED ");
						showPath(path);
					}
				}
			}
			char *fileFormat = "XML";
			if ( v175 == 2 )
				fileFormat = "binary";
			else if ( v175 == 3 )
				fileFormat = "json";
			printf("Converted %d files to %s format\n", convertedFilesCount, fileFormat);
		}
	}
	if (errorOut)
		exit(1);

	for (NSString *argument in args) {
		if ( v186 )
		{
			[keyArray addObject:argument];
			v186 = 0;
		} else if ( ![argument caseInsensitiveCompare:@"-key"] || ![argument caseInsensitiveCompare:@"-set"] )
		{
				v186 = 1;
		}
	}
	if ( rmArg )
		[keyArray addObject:rmArg];
	id v187 = 0;
	if ( [keyArray count] )
	{
		v187 = [[keyArray lastObject] retain];
		[keyArray removeLastObject];
	}
	if ( useDebug )
	{
		printf("Using key array [%s]\n", [[keyArray componentsJoinedByString:@" > "] UTF8String]);
	}
	if ( useDebug )
	{
		printf("Using last key %s\n", [v187 UTF8String]);
	}
	for (NSString *path in filePaths) {
		if ( useDebug )
		{
			printf("\nStarting file %s\n", [path UTF8String]);
		}
		CFPropertyListRef v323 = readPropertyList(path);
		if ( useDebug && !v323 )
		{
			printf("Property list was not read in properly from %s\n", [path UTF8String]);
		}
		if ( v323 )
		{
			if ( v176 || v177 )
			{
				if ( useVerbose )
					showPath(path);
				id v324 = descend(v323, keyArray);
				if ( [v324 isKindOfClass:[NSDictionary class]] || [v324 isKindOfClass:[NSArray class]]) 
				{
					v325 = v324;
					if ( v177 )
					{
						if ( v187 )
						{
							printf("Removing key %s from file %s\n", [v187 UTF8String], [path UTF8String]);
							[v325 removeObjectForKey:v187];
							WriteMyPropertyListToFile(v323, [NSURL fileURLWithPath:path]);
						}
						else
						{
							fwrite("Error: No key or keypath to remove.\n", 1u, 0x24u, stderr);
						}
					}
					else
					{
						if ( !v179 )
						{
							if ( !v182 )
								v182 = @"string";
							v329 = [args filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[cd] %@", CFSTR("-setvalue")]];
							NSArray<NSString*> *v83 = [args filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[cd] %@", CFSTR("-value")]];
							v329 = [v329 arrayByAddingObjectsFromArray:v83];
							if ( ![v329 count] )
							{
								fwrite(
										"Error: could not recover setting for setvalue (-setvalue not found). Bailing.\n",
										1u,
										0x4Eu,
										stderr);
								exit(-1);
							}
							v330 = [v329 lastObject];
							if ( [args indexOfObject:v330]  == 0x7FFFFFFF )
							{
								fwrite(
										"Error: could not recover setting for setvalue (setvalue object not found). Bailing.\n",
										1u,
										0x54u,
										stderr);
								exit(-1);
							}
							NSUInteger v331 = [args indexOfObject:v330] + 1;
							if ( [args count] < v331 )
							{
								fwrite(
										"Error: could not recover setting for setvalue (value not provided). Bailing.\n",
										1u,
										0x4Du,
										stderr);
								exit(-1);
							}
							v181 = [args objectAtIndex:v331];
							v179 = objectOfType(v182, v181);
						}
						if ( v180 )
						{
							if ( v179 )
							{
								[keyArray addObject:v187];
								v332 = descend(v323, keyArray);
								if ( v332 )
								{
									if ( [v332 isKindOfClass:[NSArray class]] ) 
									{
										[v332 addObject:v179];
										printf("Adding new array value to keypath \"%s\" in file %s\n", [[keyArray componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
										WriteMyPropertyListToFile(v323, [NSURL fileURLWithPath:path]);
									}
									else
									{
										fprintf(stderr, "Error: Array not found at keypath \"%s\" in file %s\n", [[keyArray componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
									}
								}
								else
								{
									fprintf(stderr, "Error: Object not found at keypath \"%s\" in file %s\n", [[keyArray componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
								}
							}
							else
							{
								fprintf(stderr, "Error: Cannot add nil value to array at keypath \"%s\" for file %s\n", [[keyArray componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
							}
						}
						else if ( v179 )
						{
							if ( !v187 )
							{
								fwrite("Error: No key or keypath to set value. Bailing.\n", 1u, 0x30u, stderr);
								exit(-1);
							}
							if ( [v325 isKindOfClass:[NSMutableDictionary class]]
									|| [v325 isKindOfClass:[NSMutableArray class]] )
							{
								[v325 setObject:v179 forKey:v187];
								printf("Writing new value for %s to %s\n", [v187 UTF8String], [path UTF8String]);
								WriteMyPropertyListToFile(v323, [NSURL fileURLWithPath:path]);
							}
							else
							{
								fprintf(stderr, "Error: Dictionary or array not found at keypath \"%s\" in file %s\n", [[keyArray componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
							}
						}
						else
						{
							fprintf(stderr, "Error: Cannot add nil value to dictionary at keypath \"%s\" for file %s\n", [[keyArray componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
						}
					}
				}
				else
				{
					fprintf(stderr, "Error: Object at key path is not a dictionary [%s]\n", [[[v324 class] description] UTF8String]);
					fprintf(stderr, "       Dictionary required at key path %s\n", [[keyArray componentsJoinedByString:@" > "] UTF8String]);
				}
			}
			else
			{
				v326 = keyArray;
				if ( v187 )
					v326 = [keyArray arrayByAddingObject:v187];
				v327 = (void *)descend(v323, v326);
				if ( v327 )
				{
					if ( useVerbose )
						showPath(path);
					if ( useVerbose )
					{
						printf("[%s ->] ", [[v326 componentsJoinedByString:@" > "] UTF8String]);
					}
					puts([[v327 description] UTF8String]);
				}
				else
				{
					fprintf(stderr, "Error: Object not found at keypath \"%s\" in file %s\n", [[v326 componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
				}
			}
		}
	}
	[v187 release];
	[pool drain];
	return 0;
}
