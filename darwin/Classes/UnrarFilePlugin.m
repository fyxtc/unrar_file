#import "UnrarFilePlugin.h"
@import UnrarKit;

static inline NSString* NSStringFromBOOL(BOOL aBool) {
    return aBool? @"SUCCESS" : @"FAILURE";
}

@implementation UnrarFilePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"unrar_file"
            binaryMessenger:[registrar messenger]];
  UnrarFilePlugin* instance = [[UnrarFilePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString* file_path = call.arguments[@"file_path"];
  NSError *archiveError = nil;
  NSError *error = nil;
  URKArchive *archive = [[URKArchive alloc] initWithPath:file_path error:&archiveError];
  if ([@"extractRAR" isEqualToString:call.method]) {
    NSString* destination_path = call.arguments[@"destination_path"];
    NSString* password = call.arguments[@"password"];

    BOOL extractFilesSuccessful;
    if (archive.isPasswordProtected && password.length!=0) {
        archive.password = password;
    }
    extractFilesSuccessful = [archive extractFilesTo:destination_path overwrite:NO error:&error];
    
    result(NSStringFromBOOL(extractFilesSuccessful));
  } else if ([@"listFiles" isEqualToString:call.method]) {
    NSArray<NSString*> *filesInArchive = [archive listFilenames:&error];
    for (NSString *name in filesInArchive) {
        NSLog(@"Archived file: %@", name);
    }

    // 创建一个NSPredicate对象，过滤出包含'/'的字符串
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] '/'"];
    // 使用predicate过滤filesInArchive数组
    NSArray<NSString*> *filteredFiles = [filesInArchive filteredArrayUsingPredicate:predicate];
    result(filteredFiles);

    /*
    NSMutableArray<NSString*> *afFiles = [NSMutableArray array];
    NSArray<URKFileInfo*> *fileInfosInArchive = [archive listFileInfo:&error];
    for (URKFileInfo *info in fileInfosInArchive) {
        // NSLog(@"Archive name: %@ | File name: %@ | Size: %lld isDirectory: %@", info.archiveName, info.filename, info.uncompressedSize, info.isDirectory ? @"YES" : @"NO");
        if(!info.isDirectory && info.uncompressedSize > 0) {
            // 确实要filename，因为有可能里面有多个文件夹，我需要文件夹名作为排序不同话的依据，而且getAfBytes也依赖
            [afFiles addObject:info.filename];
        }
    }
    result(afFiles);
    */
  } else if ([@"getAfBytes" isEqualToString:call.method]) {
    NSString* afName = call.arguments[@"af_name"];
    NSLog(@"getAfBytes file: %@", afName);
    NSData *extractedData = [archive extractDataFromFile:afName
                                               error:&error];
    if (error) {
      result([FlutterError errorWithCode:@"ERROR"
                                   message:@"Failed to extract data"
                                   details:error.localizedDescription]);
    } else {
        FlutterStandardTypedData *typedData = [FlutterStandardTypedData typedDataWithBytes:extractedData];
        result(typedData);
    }
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
