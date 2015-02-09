//
//  CCBPublisherController_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 21.07.14.
//
//

#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "CCBPublisherController.h"
#import "SBPackageSettings.h"
#import "ProjectSettings.h"
#import "RMPackage.h"
#import "FileSystemTestCase+Images.h"
#import "PublishOSSettings.h"
#import "MiscConstants.h"
#import "CCBPublisherCacheCleaner.h"
#import "NSNumber+ImageResolutions.h"
#import "PublishResolutions.h"

@interface CCBPublisherController_Tests : FileSystemTestCase

@property (nonatomic, strong) CCBPublisherController *publisherController;
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) SBPackageSettings *packageSettings;
@property (nonatomic, strong) RMPackage *package;

@end


@implementation CCBPublisherController_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:@"baa.spritebuilder/publishtest.ccbproj"];
    _projectSettings.publishDirectory = @"../Published-iOS";
    _projectSettings.publishDirectoryAndroid = @"../Published-Android";

    self.publisherController = [[CCBPublisherController alloc] init];
    _publisherController.projectSettings = _projectSettings;

    [CCBPublisherCacheCleaner cleanWithProjectSettings:_projectSettings];
}

- (void)tearDown
{
    self.projectSettings = nil;
    self.package = nil;
    self.packageSettings = nil;
    self.publisherController = nil;

    [super tearDown];
}

- (void)configureSinglePackagePublishSettingCase
{
    [_projectSettings addResourcePath:[self fullPathForFile:@"baa.spritebuilder/Packages/foo.sbpack"] error:nil];

    self.package = [[RMPackage alloc] init];
    _package.dirPath = [self fullPathForFile:@"baa.spritebuilder/Packages/foo.sbpack"];

    self.packageSettings = [[SBPackageSettings alloc] initWithPackage:_package];
    _packageSettings.publishToCustomOutputDirectory = NO;
    _packageSettings.publishToMainProject = NO;
    _packageSettings.publishToZip = YES;

    PublishOSSettings *iosSettings = [_packageSettings settingsForOsType:kCCBPublisherOSTypeIOS];
    iosSettings.resolutions.resolution_4x = YES;
    iosSettings.resolutions.resolution_2x = YES;
    iosSettings.resolutions.resolution_1x = NO;

    PublishOSSettings *androidSettings = [_packageSettings settingsForOsType:kCCBPublisherOSTypeAndroid];
    androidSettings.resolutions.resolution_1x = YES;
    androidSettings.resolutions.resolution_2x = YES;
    androidSettings.resolutions.resolution_4x = NO;

    [self createFolders:@[@"baa.spritebuilder/Packages/foo.sbpack"]];

    _publisherController.packageSettings = @[_packageSettings];
}

- (void)testPackageExportToDefaultDirectory
{
    [self configureSinglePackagePublishSettingCase];

    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-auto/plane.png" width:10 height:2];

    [_publisherController startAsync:NO];

    // Assert that there are actually no directories created with the same name
    [self assertFileDoesNotExist:@"Published-Packages/foo-iOS-2x"];
    [self assertFileDoesNotExist:@"Published-Packages/foo-iOS-4x"];
    [self assertFileDoesNotExist:@"Published-Packages/foo-Android-1x"];
    [self assertFileDoesNotExist:@"Published-Packages/foo-Android-2x"];

    [self assertFilesExistRelativeToDirectory:[@"baa.spritebuilder" stringByAppendingPathComponent:DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES] filesPaths:@[
            @"foo-iOS-2x.zip",
            @"foo-iOS-4x.zip",
            @"foo-Android-1x.zip",
            @"foo-Android-2x.zip"
    ]];

    [self assertFilesDoNotExistRelativeToDirectory:[@"baa.spritebuilder" stringByAppendingPathComponent:DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES] filesPaths:@[
            @"foo-iOS-1x.zip",
            @"foo-Android-4x.zip"
    ]];
}

- (void)testPackageExportToCustomDirectory
{
    [self configureSinglePackagePublishSettingCase];

    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-auto/plane.png" width:10 height:2];

    _packageSettings.publishToMainProject = NO;
    _packageSettings.publishToCustomOutputDirectory = YES;
    _packageSettings.customOutputDirectory = @"../custom";

    PublishOSSettings *iosSettings = [_packageSettings settingsForOsType:kCCBPublisherOSTypeIOS];
    iosSettings.resolutions.resolution_1x = NO;
    iosSettings.resolutions.resolution_2x = NO;
    iosSettings.resolutions.resolution_4x = NO;

    PublishOSSettings *androidSettings = [_packageSettings settingsForOsType:kCCBPublisherOSTypeAndroid];
    androidSettings.resolutions.resolution_1x = NO;
    androidSettings.resolutions.resolution_2x = YES;
    androidSettings.resolutions.resolution_4x = NO;

    [_publisherController startAsync:NO];

    [self assertFilesExistRelativeToDirectory:@"custom" filesPaths:@[
          @"foo-Android-2x.zip"
    ]];

    [self assertFilesDoNotExistRelativeToDirectory:@"custom" filesPaths:@[
            @"foo-Android-1x.zip",
            @"foo-Android-4x.zip",
            @"foo-iOS-1x.zip",
            @"foo-iOS-2x.zip",
            @"foo-iOS-4x.zip"
    ]];

    [self assertFilesDoNotExistRelativeToDirectory:@"Published-iOS" filesPaths:@[
            @"plane-1x.png",
            @"plane-2x.png",
            @"plane-4x.png",
    ]];

    [self assertFilesDoNotExistRelativeToDirectory:@"Published-Android" filesPaths:@[
            @"plane-1x.png",
            @"plane-2x.png",
            @"plane-4x.png"
    ]];
}

- (void)testPublishMainProjectWithSomePackagesNotIncluded
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/Menus.sbpack/resources-auto/button.png" width:4 height:4];
    [self createPNGAtPath:@"baa.spritebuilder/Packages/Characters.sbpack/resources-auto/hero.png" width:4 height:4];
    [self createPNGAtPath:@"baa.spritebuilder/Packages/Backgrounds.sbpack/resources-auto/desert.png" width:4 height:4];

    [_projectSettings addResourcePath:[self fullPathForFile:@"baa.spritebuilder/Packages/Menus.sbpack"] error:nil];
    [_projectSettings addResourcePath:[self fullPathForFile:@"baa.spritebuilder/Packages/Characters.sbpack"] error:nil];
    [_projectSettings addResourcePath:[self fullPathForFile:@"baa.spritebuilder/Packages/Backgrounds.sbpack"] error:nil];
    _projectSettings.publishEnabledIOS = YES;
    _projectSettings.publishEnabledAndroid = YES;

    // Not included, therefor button.png should not be in result
    SBPackageSettings *packageSettingsMenus = [self createSettingsWithPath:@"baa.spritebuilder/Packages/Menus.sbpack"];
    packageSettingsMenus.mainProjectResolutions.resolution_4x = NO;
    packageSettingsMenus.mainProjectResolutions.resolution_2x = YES;
    packageSettingsMenus.mainProjectResolutions.resolution_1x = NO;
    packageSettingsMenus.publishToMainProject = NO;
    packageSettingsMenus.publishToZip = NO;

    SBPackageSettings *packageSettingsCharacters = [self createSettingsWithPath:@"baa.spritebuilder/Packages/Characters.sbpack"];
    packageSettingsCharacters.mainProjectResolutions.resolution_4x = YES;
    packageSettingsCharacters.mainProjectResolutions.resolution_2x = NO;
    packageSettingsCharacters.mainProjectResolutions.resolution_1x = YES;
    packageSettingsCharacters.publishToMainProject = YES;
    packageSettingsCharacters.publishToZip = NO;

    SBPackageSettings *packageSettingsBackgrounds = [self createSettingsWithPath:@"baa.spritebuilder/Packages/Backgrounds.sbpack"];
    packageSettingsBackgrounds.mainProjectResolutions.resolution_4x = NO;
    packageSettingsBackgrounds.mainProjectResolutions.resolution_2x = NO;
    packageSettingsBackgrounds.mainProjectResolutions.resolution_1x = YES;
    packageSettingsBackgrounds.publishToMainProject = YES;
    packageSettingsBackgrounds.publishToZip = NO;

    _publisherController.packageSettings = @[packageSettingsMenus, packageSettingsCharacters, packageSettingsBackgrounds];

    [_publisherController startAsync:NO];

    for (NSString *osSuffix in @[@"iOS", @"Android"])
    {
        [self assertFilesExistRelativeToDirectory:[NSString stringWithFormat:@"Published-%@", osSuffix] filesPaths:@[
                @"hero-1x.png",
                @"hero-4x.png",
                @"desert-1x.png",
        ]];

        [self assertFilesDoNotExistRelativeToDirectory:[NSString stringWithFormat:@"Published-%@", osSuffix] filesPaths:@[
                @"hero-2x.png",
                @"button-1x.png",
                @"button-2x.png",
                @"button-4x.png",
                @"desert-2x.png",
                @"desert-4x.png",
        ]];
    }

    for (NSString *osSuffix in @[@"iOS", @"Android"])
    {
        for (NSString *resolution in @[@"4x", @"2x", @"1x"])
        {
            [self assertFilesDoNotExistRelativeToDirectory:packageSettingsMenus.effectiveOutputDirectory filesPaths:@[
                    [NSString stringWithFormat:@"Menus-%@-%@.zip", osSuffix, resolution]
            ]];
            [self assertFilesDoNotExistRelativeToDirectory:packageSettingsCharacters.effectiveOutputDirectory filesPaths:@[
                    [NSString stringWithFormat:@"Characters-%@-%@.zip", osSuffix, resolution]
            ]];
            [self assertFilesDoNotExistRelativeToDirectory:packageSettingsBackgrounds.effectiveOutputDirectory filesPaths:@[
                    [NSString stringWithFormat:@"Backgrounds-%@-%@.zip", osSuffix, resolution]
            ]];
        }
    }
}

- (void)testNothingToPublish
{
    [self configureSinglePackagePublishSettingCase];

    _packageSettings.publishToZip = NO;
    _packageSettings.publishToMainProject = NO;
    _packageSettings.publishToCustomOutputDirectory = NO;

    [_publisherController startAsync:NO];

    [self assertFileDoesNotExist:@"Published-iOS"];
    [self assertFileDoesNotExist:@"Published-Android"];
    [self assertFileDoesNotExist:DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES];
}


#pragma mark - helpers

- (SBPackageSettings *)createSettingsWithPath:(NSString *)path
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [self fullPathForFile:path];

    return [[SBPackageSettings alloc] initWithPackage:package];
}

@end
