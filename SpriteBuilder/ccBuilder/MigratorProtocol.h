//
// Created by Nicky Weber on 11.02.15.
//

#import <Foundation/Foundation.h>

@class ProjectSettings;

@protocol MigratorProtocol <NSObject>

- (NSString *)htmlInfoText;

- (BOOL)isMigrationRequired;

- (BOOL)migrateWithError:(NSError **)error;

- (void)rollback;

@optional
- (void)tidyUp;

@end
