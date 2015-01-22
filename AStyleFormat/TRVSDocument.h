//
//  NSDocument+TRVSClangFormat.h
//  ClangFormat
//
//  Created by Travis Jeffery on 1/11/14.
//  Modifided by Edward Chen on 1/22/15..
//  Copyright (c) 2014 Travis Jeffery. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TRVSDocument : NSObject

+ (void) hook;
+ (void) unhook;

+ (BOOL) trvs_formatOnSave;
+ (void) settrvs_formatOnSave:(BOOL) formatOnSave;

+ (BOOL) trvs_shouldFormat:(NSDocument *) document;

@end

@interface IDEWorkspaceTabControllerHook : NSObject

+ (void) hook;
+ (void) unhook;

@end

@interface IDERunPauseContinueToolbarButtonHook : NSObject

+ (void) hook;
+ (void) unhook;

@end