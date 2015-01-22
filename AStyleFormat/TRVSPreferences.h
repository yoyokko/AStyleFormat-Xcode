//
//  TRVSPreferences.h
//  ClangFormat
//
//  Created by Travis Jeffery on 1/9/14.
//  Modifided by Edward Chen on 1/22/15..
//  Copyright (c) 2014 Travis Jeffery. All rights reserved.
//

#import <Foundation/Foundation.h>

// wrapper for cfpreferences since nsuserdefaults isn't available in plug-ins

@interface TRVSPreferences : NSObject

- (instancetype) initWithApplicationID:(NSString *) applicationID;
- (id) objectForKey:(NSString *) key;
- (void) setObject:(id) object forKey:(NSString *) key;
- (BOOL) synchronize;

@end
