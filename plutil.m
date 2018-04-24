/* Reverse engineered from Erica Sadun's plutil */

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

void WriteMyPropertyListToFile(NSDictionary* plist, NSURL* url)
{
	SInt32 error;
	CFDataRef data;

	data = CFPropertyListCreateXMLData(kCFAllocatorDefault, plist);
	CFURLWriteDataAndPropertiesToResource((CFURLRef)url, data, NULL, &error);
	CFRelease(data);
}

void WriteMyPropertyListToStdOut(CFPropertyListRef plist)
{
	CFWriteStreamRef writeStream = CFWriteStreamCreateWithFile(kCFAllocatorDefault, (CFURLRef)[NSURL fileURLWithPath:@"/dev/stdout"]);
	CFWriteStreamOpen(writeStream);
	CFPropertyListWriteToStream(plist, writeStream, kCFPropertyListXMLFormat_v1_0, NULL);
	CFWriteStreamClose(writeStream);
	CFRelease(writeStream);
}

Boolean WriteMyPropertyListToXMLFile(NSData *data, NSURL *url)
{
	SInt32 errorCode;

	return CFURLWriteDataAndPropertiesToResource((CFURLRef)url, (CFDataRef)data, NULL, &errorCode);
}

void WriteMyPropertyListToBinaryFile(CFPropertyListRef plist, NSURL *url)
{
	CFWriteStreamRef stream;

	stream = CFWriteStreamCreateWithFile(kCFAllocatorDefault, (CFURLRef)url);
	CFWriteStreamOpen(stream);
	CFPropertyListWriteToStream(plist, stream, kCFPropertyListBinaryFormat_v1_0, NULL);
	CFWriteStreamClose(stream);
	CFRelease(stream);
}

CFPropertyListRef readPropertyList(NSString *path)
{
	CFStringRef errorString;

	path = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSData *plistData = [NSData dataWithContentsOfFile:path];
		return CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (CFDataRef)plistData, kCFPropertyListMutableContainers, &errorString);
	} else {
		fprintf(stderr, "Error: File not found at path %s\n", [path UTF8String]);
		return NULL;
	}
}

void showPath(NSString *path)
{
	printf("FILE: %s\n", [path UTF8String]);
}

void dump(NSString *path)
{

	CFPropertyListRef plist = readPropertyList(path);
	if ( plist ) {
		if ( useVerbose )
			showPath(path);

		WriteMyPropertyListToStdOut(plist);
		if ( useVerbose )
			putchar('\n');
	}
}

void show(NSString *a1)
{
	CFPropertyListRef result; // r0

	result = readPropertyList(a1);
	if ( result ) {
		if ( useVerbose )
			showPath(a1);

		CFShow((CFStringRef)[(id)result description]);
		if ( useVerbose )
			putchar('\n');
	}
}

CFTypeRef descend(id container, NSMutableArray *path)
{

	if ( ![path count] )
		return (CFTypeRef)container;

	if ( ![container isKindOfClass:[NSDictionary class]] ) {
		if ( ![container isKindOfClass:[NSArray class]] )
			return 0;
	}
	container = [container objectForKey:[path objectAtIndex:0]];
	path = [NSMutableArray arrayWithArray:path];
	[path removeObjectAtIndex:0];
	return descend(container, path);
}

id objectOfType(NSString *type, NSString *objectString)
{
	id theObject;

	if ( !objectString )
		return nil;
	if ( !type )
		return nil;

	if ( ![type caseInsensitiveCompare:@"string"] )
		return objectString;
	if ( ![type caseInsensitiveCompare:@"int"] )
		theObject = [NSNumber numberWithInt:[objectString intValue]];
	else if ( ![type caseInsensitiveCompare: @"integer"] )
		theObject = [NSNumber numberWithInt:[objectString intValue]];
	else if ( ![type caseInsensitiveCompare: @"float"] )
		theObject = [NSNumber numberWithFloat:[objectString floatValue]];
	else if ( ![type caseInsensitiveCompare: @"real"] )
		theObject = [NSNumber numberWithFloat:[objectString floatValue]];
	else if ( ![type caseInsensitiveCompare: @"double"] )
		theObject = [NSNumber numberWithFloat:[objectString floatValue]];
	else if ( ![type caseInsensitiveCompare: @"bool"] )
		theObject = [NSNumber numberWithBool:[objectString boolValue]];
	else if ( ![type caseInsensitiveCompare: @"boolean"] )
		theObject = [NSNumber numberWithBool:[objectString boolValue]];
	else if ( ![type caseInsensitiveCompare: @"data"] )
		theObject = [objectString dataUsingEncoding:4];
	else if ( ![type caseInsensitiveCompare: @"date"] )
		theObject = [NSDate dateWithNaturalLanguageString:objectString];
	else if ( ![type caseInsensitiveCompare: @"json"] ) {
		id jsonObj = [objectString JSONValue];
		if ( jsonObj ) {
			theObject = jsonObj;
		} else {
			fwrite("Error: could not convert json setvalue argument\n", 1u, 0x30u, stderr);
			fprintf(stderr, "       %s\n", [objectString UTF8String]);
			theObject = nil;
		}
	}
	else
		theObject = nil;
	return theObject;
}

NSString *fetchArg(NSString *arg)
{

	if ( !arg ) {
		fprintf(stderr, "Internal Error: No argument supplied to fetchArg. Bailing.\n");
		exit(-1);
	}
	arg = [[NSUserDefaults standardUserDefaults] objectForKey:[arg substringFromIndex:1]];
	if ( !arg ) {
		fprintf(stderr, "You must supply an argument to -. Bailing.\n"); 
		exit(-1);
	}
	return arg;
}

void usage()
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
	puts("                        files are saved to filename.json");
}

void full()
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
	puts("  -arrayadd            Add value to array at keypath");
}

int main(int argc, const char **argv, const char **envp)
{
	int plistFormat=0;
	bool isSetting=false;
	bool isRemoving=false;
	NSString *rmArg=nil;
	id objectArg=nil;
	bool addingArray=false;
	NSString *objectType;

	bool errorOut=false;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	program_name = argv[0];
	if ( argc == 1 ) {
		usage();
		exit(1);
	}
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF beginswith '-'"];
	NSArray *dashedArgs = [args filteredArrayUsingPredicate:pred];
	int numArgsUsed = 1;
	useDebug = false;
	useVerbose = false;
	NSMutableArray *keyPath = [NSMutableArray array];

	for (NSString *argument in dashedArgs) {
		if ( ![argument caseInsensitiveCompare:@"-help"] ) {
			usage();
			exit(1);
		}
		if ( ![argument caseInsensitiveCompare:@"-full"] ) {
			full();
			exit(1);
		}
		if ( ![argument caseInsensitiveCompare:@"-verbose"]
				|| ![argument caseInsensitiveCompare:@"-v"] ) {
			useVerbose = true;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-useDebug"] ) {
			useDebug = true;
			useVerbose = true;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-remove"] ) {
			isRemoving = true;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-1"]
				|| ![argument caseInsensitiveCompare:@"-yes"]
				|| ![argument caseInsensitiveCompare:@"-true"] ) {
			isSetting = true;
			objectType = @"bool";
			numArgsUsed++;
			objectArg = [NSNumber numberWithBool:true];
		} else if ( ![argument caseInsensitiveCompare:@"-0"]
				|| ![argument caseInsensitiveCompare:@"-no"]
				|| ![argument caseInsensitiveCompare:@"-false"] ) {
			isSetting = true;
			objectType = @"bool";
			numArgsUsed++;
			objectArg = [NSNumber numberWithBool:false];
		} else if ( ![argument caseInsensitiveCompare:@"-now"] ) {
			isSetting = true;
			objectType = @"date";
			numArgsUsed++;
			objectArg = [NSDate date];
		} else if ( ![argument caseInsensitiveCompare:@"-array"] ) {
			isSetting = true;
			objectType = @"array";
			numArgsUsed++;
			objectArg = [NSArray array];
		} else if ( ![argument caseInsensitiveCompare:@"-dict"]
				|| ![argument caseInsensitiveCompare:@"-dictionary"] ) {
			isSetting = true;
			objectType = @"dict";
			numArgsUsed++;
			objectArg = [NSDictionary dictionary];
		} else if ( ![argument caseInsensitiveCompare:@"-arrayadd"] ) {
			isSetting = true;
			addingArray = true;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-dump"]
				|| ![argument caseInsensitiveCompare:@"-show"]
				|| ![argument caseInsensitiveCompare:@"-showjson"]
				|| ![argument caseInsensitiveCompare:@"-keys"]
				|| ![argument caseInsensitiveCompare:@"-full"]
				|| ![argument caseInsensitiveCompare:@"-help"]
				|| ![argument caseInsensitiveCompare:@"-create"]
				|| ![argument caseInsensitiveCompare:@"-backup"] ) {
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-xml"] ) {
			plistFormat = 1;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-binary"] ) {
			plistFormat = 2;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-json"] ) {
			plistFormat = 3;
			numArgsUsed++;
		} else if ( ![argument caseInsensitiveCompare:@"-key"]
				|| ![argument caseInsensitiveCompare:@"-set"] ) {
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-rmkey"] ) {
			isRemoving = true;
			rmArg = fetchArg(argument);
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-setvalue"]
				|| ![argument caseInsensitiveCompare:@"-value"] ) {
			isSetting = true;
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-type"] ) {
			objectType = fetchArg(argument);
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-int"]
				|| ![argument caseInsensitiveCompare:@"-integer"] ) {
			isSetting = true;
			objectType = @"int";
			objectArg = [NSNumber numberWithInt:[fetchArg(argument) intValue]];
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-float"]
				|| ![argument caseInsensitiveCompare:@"-double"]
				|| ![argument caseInsensitiveCompare:@"-real"] ) {
			objectType = @"float";
			isSetting = true;
			objectArg = [NSNumber numberWithFloat:[fetchArg(argument) floatValue]];
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-string"] ) {
			objectType = @"string";
			isSetting = true;
			objectArg = fetchArg(argument);
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-fromnow"]
				|| ![argument caseInsensitiveCompare:@"-beforenow"] ) {
			isSetting = true;
			objectType = @"date";
			NSInteger theInteger = [fetchArg(argument) integerValue];
			if ( ![argument caseInsensitiveCompare: @"-beforenow"] )
				theInteger = -theInteger;
			objectArg = [NSDate dateWithTimeIntervalSinceNow:theInteger];
			numArgsUsed += 2;
		} else if ( ![argument caseInsensitiveCompare:@"-data"] ) {
			isSetting = true;
			objectType = @"data";
			numArgsUsed += 2;
			NSString *dataPath = fetchArg(argument);
			if ( ![[NSFileManager defaultManager] fileExistsAtPath:dataPath] ) {
				fprintf(
						stderr,
						"Error: File with data not found at path: %s. Bailing.\n",
						[dataPath UTF8String]);
				exit(-1);
			}
			objectArg = [NSData dataWithContentsOfFile:dataPath];
			if ( !objectArg ) {
				fprintf(
						stderr,
						"Error: No data available at path: %s. Bailing.\n",
						[dataPath UTF8String]);
				exit(-1);
			}
		} else if ( ![argument caseInsensitiveCompare:@"-convert"] ) {
			NSString* format = fetchArg(argument);
			if ( ![format caseInsensitiveCompare:@"xml1"] )
				plistFormat = 1;
			else if ( ![format caseInsensitiveCompare:@"binary1"])
				plistFormat = 2;
			else if ( ![format caseInsensitiveCompare:@"json"])
				plistFormat = 3;
			else	{
				fprintf(
						stderr,
						"Error: Unrecognized conversion format (%s). Please use xml"
						"1, binary1 or json. Bailing.\n",
						[format UTF8String]);
				exit(-1);
			}
			numArgsUsed += 2;

		} else {
			if ( useDebug )
				printf("Unrecognized flag: %s. Using as key\n", [argument UTF8String]);

			[keyPath addObject:[argument substringFromIndex:1]];
			numArgsUsed++;
		}
	}
	if ( isSetting && isRemoving )
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
		if ( ![argument caseInsensitiveCompare:@"-create"] ) {
			errorOut=true;
			int numPlists=0;
			for (NSString *path in filePaths) {
				if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
					fprintf(stderr, "Error: File already exists at %s. Skipping.\n", [path UTF8String]);
				} else {
					WriteMyPropertyListToFile([NSDictionary dictionary], [NSURL fileURLWithPath:path]);
					if ( useVerbose ) {
						printf("Created new property list at %s\n", [path UTF8String]);
					}
					numPlists++;
				}
			}
			printf("Created %d new property list[s]\n", numPlists);
			continue;
		}
		if ( ![argument caseInsensitiveCompare:@"-dump"] ) {
			errorOut=true;
			for (NSString *path in filePaths) {
				dump(path);
			}
			continue;
		}
		if ( ![argument caseInsensitiveCompare:@"-show"] ) {
			errorOut=true;
			for (NSString *path in filePaths) {
				show(path);
			}
			continue;
		}
		if ( ![argument caseInsensitiveCompare:@"-showjson"] ) {
			errorOut=true;
			for (NSString *path in filePaths) {
				CFPropertyListRef plist = readPropertyList(path);
				if ( plist ) {
					if ( useVerbose )
						showPath(path);
					puts([[JSONHelper jsonWithDict:plist] UTF8String]);
				}
			}
			continue;
		}
		if ( ![argument caseInsensitiveCompare:@"-keys"] ) {
			errorOut=true;
			for (NSString *path in filePaths) {
				CFPropertyListRef plist = readPropertyList(path);
				if ( plist ) {
					if ( [(id)plist isKindOfClass:[NSDictionary class] ] ) {
						if ( useVerbose )
							showPath(path);

						for (NSString *key in [(NSDictionary*)plist allKeys]) {
							id object = [(NSDictionary*)plist objectForKey:key];
							printf("%s", [object UTF8String]);
							if ( useVerbose ) {
								printf(" [%s]", [[[object class] description] UTF8String]);
							}
							putchar('\n');
						}
					}
				}
			}
			continue;
		}
		if ( ![argument caseInsensitiveCompare:@"-backup"] ) {
			errorOut=true;
			for (NSString *path in filePaths) {
				CFPropertyListRef plist = readPropertyList(path);
				if ( plist ) {
					if ( [[[path pathExtension] uppercaseString] isEqualToString:@"PLIST"] ) {
						WriteMyPropertyListToFile(plist, [NSURL fileURLWithPath:[path stringByAppendingPathExtension:@"bak"]]);
					}
				}
			}
		}
		if ( ![argument caseInsensitiveCompare:@"-convert"]
				|| ![argument caseInsensitiveCompare:@"-binary"]
				|| ![argument caseInsensitiveCompare:@"-xml"]
				|| ![argument caseInsensitiveCompare:@"-json"] ) {
			errorOut=true;
			int convertedFilesCount=0;
			for (NSString *path in filePaths) {
				CFPropertyListRef plist = readPropertyList(path);
				if ( plist ) {
					if ( plistFormat == 1 ) {
						WriteMyPropertyListToFile(plist, [NSURL fileURLWithPath:path]);
					}
					else if ( plistFormat == 2 ) {
						WriteMyPropertyListToBinaryFile(plist, [NSURL fileURLWithPath:path]);
					}
					else if ( plistFormat == 3 ) {
						NSString *json = [JSONHelper jsonWithDict:plist];
						if ( !json )
							continue;
						json = [json stringByAppendingString:@"\n"];
						NSError *error;
						if ( ![json writeToFile:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"json"] atomically:YES encoding:4 error:&error])
							fprintf(stderr, "Error writing json file: %s\n", [[error localizedDescription] UTF8String]);
					}

					convertedFilesCount++;
					if ( useVerbose ) {
						printf("CONVERTED ");
						showPath(path);
					}
				}
			}
			char *fileFormat = "XML";
			if ( plistFormat == 2 )
				fileFormat = "binary";
			else if ( plistFormat == 3 )
				fileFormat = "json";
			printf("Converted %d files to %s format\n", convertedFilesCount, fileFormat);
		}
	}
	if (errorOut)
		exit(1);

	bool readingKey=false;
	for (NSString *argument in args) {
		if ( readingKey ) {
			[keyPath addObject:argument];
			readingKey = false;
		} else if ( ![argument caseInsensitiveCompare:@"-key"] || ![argument caseInsensitiveCompare:@"-set"] ) {
			readingKey = true;
		}
	}
	if ( rmArg )
		[keyPath addObject:rmArg];
	id lastKey = 0;
	if ( [keyPath count] ) {
		lastKey = [[[keyPath lastObject] retain] autorelease];
		[keyPath removeLastObject];
	}
	if ( useDebug ) {
		printf("Using key array [%s]\n", [[keyPath componentsJoinedByString:@" > "] UTF8String]);
		printf("Using last key %s\n", [lastKey UTF8String]);
	}
	for (NSString *path in filePaths) {
		if ( useDebug ) {
			printf("\nStarting file %s\n", [path UTF8String]);
		}
		CFPropertyListRef propertyList = readPropertyList(path);
		if ( useDebug && !propertyList ) {
			printf("Property list was not read in properly from %s\n", [path UTF8String]);
		}
		if ( propertyList ) {
			if ( isSetting || isRemoving ) {
				if ( useVerbose )
					showPath(path);
				id currentContainer = descend(propertyList, keyPath);
				if ( [currentContainer isKindOfClass:[NSDictionary class]] || [currentContainer isKindOfClass:[NSArray class]]) {
					if ( isRemoving ) {
						if ( lastKey ) {
							printf("Removing key %s from file %s\n", [lastKey UTF8String], [path UTF8String]);
							[currentContainer removeObjectForKey:lastKey];
							WriteMyPropertyListToFile(propertyList, [NSURL fileURLWithPath:path]);
						} else {
							fwrite("Error: No key or keypath to remove.\n", 1u, 0x24u, stderr);
						}
					} else {
						if ( !objectArg ) {
							if ( !objectType )
								objectType = @"string";
							NSArray *setValueArgs = [args filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[cd] %@", CFSTR("-setvalue")]];
							NSArray *valueArgs = [args filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[cd] %@", CFSTR("-value")]];
							setValueArgs = [setValueArgs arrayByAddingObjectsFromArray:valueArgs];
							if ( ![setValueArgs count] ) {
								fprintf(stderr, "Error: could not recover setting for setvalue (-setvalue not found). Bailing.\n");
								exit(-1);
							}
							id lastSetValueArg = [setValueArgs lastObject];
							if ( [args indexOfObject:lastSetValueArg]  == 0x7FFFFFFF )
							{
								fprintf(stderr, "Error: could not recover setting for setvalue (setvalue object not found). Bailing.\n");
								exit(-1);
							}
							NSUInteger objectIndex = [args indexOfObject:lastSetValueArg] + 1;
							if ( [args count] < objectIndex ) {
								fprintf(stderr, "Error: could not recover setting for setvalue (value not provided). Bailing.\n");
								exit(-1);
							}
							objectArg = objectOfType(objectType, [args objectAtIndex:objectIndex]);
						}
						if ( addingArray ) {
							if ( objectArg ) {
								[keyPath addObject:lastKey];
								id objectAtPath = descend(propertyList, keyPath);
								if ( objectAtPath ) {
									if ( [objectAtPath isKindOfClass:[NSArray class]] ) {
										[objectAtPath addObject:objectArg];
										printf("Adding new array value to keypath \"%s\" in file %s\n", [[keyPath componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
										WriteMyPropertyListToFile(propertyList, [NSURL fileURLWithPath:path]);
									} else {
										fprintf(stderr, "Error: Array not found at keypath \"%s\" in file %s\n", [[keyPath componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
									}
								} else {
									fprintf(stderr, "Error: Object not found at keypath \"%s\" in file %s\n", [[keyPath componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
								}
							} else {
								fprintf(stderr, "Error: Cannot add nil value to array at keypath \"%s\" for file %s\n", [[keyPath componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
							}
						} else if ( objectArg ) {
							if ( !lastKey ) {
								fprintf(stderr, "Error: No key or keypath to set value. Bailing.\n");
								exit(-1);
							}
							if ( [currentContainer isKindOfClass:[NSMutableDictionary class]]
									|| [currentContainer isKindOfClass:[NSMutableArray class]] ) {
								[currentContainer setObject:objectArg forKey:lastKey];
								printf("Writing new value for %s to %s\n", [lastKey UTF8String], [path UTF8String]);
								WriteMyPropertyListToFile(propertyList, [NSURL fileURLWithPath:path]);
							} else {
								fprintf(stderr, "Error: Dictionary or array not found at keypath \"%s\" in file %s\n", [[keyPath componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
							}
						} else {
							fprintf(stderr, "Error: Cannot add nil value to dictionary at keypath \"%s\" for file %s\n", [[keyPath componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
						}
					}
				} else {
					fprintf(stderr, "Error: Object at key path is not a dictionary [%s]\n", [[[currentContainer class] description] UTF8String]);
					fprintf(stderr, "       Dictionary required at key path %s\n", [[keyPath componentsJoinedByString:@" > "] UTF8String]);
				}
			} else {
				NSMutableArray *pathToPrint = [keyPath mutableCopy];
				if ( lastKey )
					[pathToPrint addObject:lastKey];

				id objectAtPath = descend(propertyList, pathToPrint);
				if ( objectAtPath )
				{
					if ( useVerbose )
						showPath(path);
					if ( useVerbose )
					{
						printf("[%s ->] ", [[pathToPrint componentsJoinedByString:@" > "] UTF8String]);
					}
					puts([[objectAtPath description] UTF8String]);
				} else {
					fprintf(stderr, "Error: Object not found at keypath \"%s\" in file %s\n", [[pathToPrint componentsJoinedByString:@" > "] UTF8String], [path UTF8String]);
				}
			}
		}
	}
	[pool drain];
	return 0;
}
