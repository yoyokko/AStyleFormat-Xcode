//
//  TRVSCodeFragment.m
//  ClangFormat
//
//  Created by Travis Jeffery on 1/9/14.
//  Modifided by Edward Chen on 1/22/15..
//  Copyright (c) 2014 Travis Jeffery. All rights reserved.
//

#import "TRVSCodeFragment.h"

@interface TRVSCodeFragment()

- (instancetype) initWithBuilder:(TRVSCodeFragmentBuilder *) builder;

@end

@implementation TRVSCodeFragmentBuilder

- (TRVSCodeFragment *) build
{
    return [[TRVSCodeFragment alloc] initWithBuilder:self];
}

@end

@implementation TRVSCodeFragment

+ (instancetype) fragmentUsingBlock:(void (^)(TRVSCodeFragmentBuilder *builder)) block
{
    TRVSCodeFragmentBuilder *builder = [TRVSCodeFragmentBuilder new];
    block(builder);
    return [builder build];
}

- (instancetype) initWithBuilder:(TRVSCodeFragmentBuilder *) builder
{
    if (self = [super init])
    {
        _string = [builder.string copy];
        _range = builder.range;
        _fileURL = builder.fileURL;
    }
    return self;
}

- (void) formatWithStyle:(NSString *) stylePath
usingAStyleFormatAtLaunchPath:(NSString *) launchPath
                   block:(void (^)(NSString *formattedString, NSError *error)) block
{
    NSURL *tmpFileURL = [self.fileURL URLByAppendingPathExtension:@"trvs"];
    [self.string writeToURL:tmpFileURL
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:NULL];
    
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    
    NSTask *task = [[NSTask alloc] init];
    task.standardOutput = outputPipe;
    task.standardError = errorPipe;
    task.launchPath = launchPath;
    task.arguments = @[
                       [NSString stringWithFormat:@"--options=%@", stylePath],
                       [tmpFileURL path],
                       ];
    
    [outputPipe.fileHandleForReading readToEndOfFileInBackgroundAndNotify];
    
    [task launch];
    [task waitUntilExit];
    
    NSData *errorData = [errorPipe.fileHandleForReading readDataToEndOfFile];
    
    self.formattedString = [NSString stringWithContentsOfURL:tmpFileURL
                                                    encoding:NSUTF8StringEncoding
                                                       error:NULL];
    
    block(self.formattedString,
          errorData.length > 0
          ? [NSError errorWithDomain:@"com.travisjeffery.error"
                                code: -99
                            userInfo:@
             {
             NSLocalizedDescriptionKey:[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding]
             }]
          : nil);
    
    [[NSFileManager defaultManager] removeItemAtURL:tmpFileURL error:NULL];
}

@end
