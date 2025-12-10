#!/usr/bin/env python3
import uuid
import os

# Generate UUIDs for the project
project_uuid = str(uuid.uuid4()).upper().replace('-', '')
target_uuid = str(uuid.uuid4()).upper().replace('-', '')
group_uuid = str(uuid.uuid4()).upper().replace('-', '')

# Create project.pbxproj content (minimal structure)
pbxproj_content = f'''// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
		{target_uuid} /* UptimeMonitorApp.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {group_uuid} /* UptimeMonitorApp.swift */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{group_uuid} /* UptimeMonitorApp.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = UptimeMonitorApp.swift; sourceTree = "<group>"; }};
		{project_uuid} /* UptimeMonitor.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = UptimeMonitor.app; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */

/* Begin PBXGroup section */
		{group_uuid} = {{
			isa = PBXGroup;
			children = (
				{group_uuid} /* UptimeMonitorApp.swift */,
			);
			path = UptimeMonitor;
			sourceTree = "<group>";
		}};
		{project_uuid} = {{
			isa = PBXGroup;
			children = (
				{group_uuid},
			);
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_uuid} /* UptimeMonitor */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {target_uuid} /* Build configuration list for PBXNativeTarget "UptimeMonitor" */;
			buildPhases = (
				{target_uuid} /* Sources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = UptimeMonitor;
			productName = UptimeMonitor;
			productReference = {project_uuid} /* UptimeMonitor.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_uuid} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
			}};
			buildConfigurationList = {project_uuid} /* Build configuration list for PBXProject "UptimeMonitor" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {project_uuid};
			productRefGroup = {project_uuid} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_uuid} /* UptimeMonitor */,
			);
		}};
/* End PBXProject section */

/* Begin PBXSourcesBuildPhase section */
		{target_uuid} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{target_uuid} /* UptimeMonitorApp.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{project_uuid} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
			ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				INFOPLIST_FILE = UptimeMonitor/Info.plist;
				INFOPLIST_KEY_LSUIElement = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.uptimemonitor.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = macosx;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
		{project_uuid} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				INFOPLIST_FILE = UptimeMonitor/Info.plist;
				INFOPLIST_KEY_LSUIElement = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_FAST_MATH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.uptimemonitor.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = macosx;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			}};
			name = Release;
		}};
		{target_uuid} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				DEVELOPMENT_TEAM = "";
			}};
			name = Debug;
		}};
		{target_uuid} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				DEVELOPMENT_TEAM = "";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{project_uuid} /* Build configuration list for PBXProject "UptimeMonitor" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{project_uuid} /* Debug */,
				{project_uuid} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{target_uuid} /* Build configuration list for PBXNativeTarget "UptimeMonitor" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{target_uuid} /* Debug */,
				{target_uuid} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_uuid} /* Project object */;
}}
'''

# Write the project file
os.makedirs('UptimeMonitor.xcodeproj', exist_ok=True)
with open('UptimeMonitor.xcodeproj/project.pbxproj', 'w') as f:
    f.write(pbxproj_content)

print("Minimal Xcode project file created.")
print("Note: This is a basic structure. You may need to add all Swift files manually in Xcode.")
