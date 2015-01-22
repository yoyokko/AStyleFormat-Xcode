//
//  TRVSFormatter.h
//  ClangFormat
//
//  Created by Travis Jeffery on 1/9/14.
//  Modifided by Edward Chen on 1/22/15..
//  Copyright (c) 2014 Travis Jeffery. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IDESourceCodeDocument;

@interface TRVSFormatter : NSObject

@property (nonatomic, copy) NSString *styleFilePath;
@property (nonatomic, copy) NSString *executablePath;

+ (instancetype) sharedFormatter;

- (instancetype) initWithStyle:(NSString *) stylePath
                executablePath:(NSString *) executablePath;

- (void) formatActiveFile;
- (void) formatSelectedCharacters;
- (void) formatSelectedFiles;
- (void) formatDocument:(IDESourceCodeDocument *) document;

@end
