"""Generate the dependency-free Xcode project deterministically; run after adding Swift files."""

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
objects = {}


def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()


def add(identity, isa, **fields):
    key = uid(identity)
    objects[key] = {"isa": isa, **fields}
    return key


def config_list(name, settings):
    configs = []
    for configuration in ["Debug", "Release"]:
        config = dict(settings)
        config["SWIFT_OPTIMIZATION_LEVEL"] = (
            "-Onone" if configuration == "Debug" else "-O"
        )
        if configuration == "Debug":
            config["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"
            config["ENABLE_TESTABILITY"] = "YES"
        else:
            config["VALIDATE_PRODUCT"] = "YES"
        configs.append(
            add(
                name + configuration,
                "XCBuildConfiguration",
                name=configuration,
                buildSettings=config,
            )
        )
    return add(
        name + "configs",
        "XCConfigurationList",
        buildConfigurations=configs,
        defaultConfigurationIsVisible=0,
        defaultConfigurationName="Release",
    )


app_files, test_files = [], []
app_builds, test_builds = [], []
ui_files, ui_builds = [], []
for folder, files, builds in [
    ("Primal", app_files, app_builds),
    ("PrimalTests", test_files, test_builds),
    ("PrimalUITests", ui_files, ui_builds),
]:
    for path in sorted((ROOT / "ios" / folder).glob("*.swift")):
        ref = add(
            str(path.relative_to(ROOT)),
            "PBXFileReference",
            lastKnownFileType="sourcecode.swift",
            path=path.name,
            sourceTree="<group>",
        )
        files.append(ref)
        builds.append(
            add("build " + str(path.relative_to(ROOT)), "PBXBuildFile", fileRef=ref)
        )
info = add(
    "info",
    "PBXFileReference",
    lastKnownFileType="text.plist.xml",
    path="Info.plist",
    sourceTree="<group>",
)
fixture = add(
    "fixture",
    "PBXFileReference",
    lastKnownFileType="text.json",
    path="../contracts/evaluation.json",
    sourceTree="SOURCE_ROOT",
)
fixture_build = add("fixture build", "PBXBuildFile", fileRef=fixture)
app_product = add(
    "app product",
    "PBXFileReference",
    explicitFileType="wrapper.application",
    path="Primal.app",
    sourceTree="BUILT_PRODUCTS_DIR",
)
test_product = add(
    "test product",
    "PBXFileReference",
    explicitFileType="wrapper.cfbundle",
    path="PrimalTests.xctest",
    sourceTree="BUILT_PRODUCTS_DIR",
)
ui_product = add(
    "ui product",
    "PBXFileReference",
    explicitFileType="wrapper.cfbundle",
    path="PrimalUITests.xctest",
    sourceTree="BUILT_PRODUCTS_DIR",
)
app_group = add(
    "app group",
    "PBXGroup",
    children=app_files + [info],
    path="Primal",
    sourceTree="<group>",
)
test_group = add(
    "test group",
    "PBXGroup",
    children=test_files,
    path="PrimalTests",
    sourceTree="<group>",
)
ui_group = add(
    "ui group",
    "PBXGroup",
    children=ui_files,
    path="PrimalUITests",
    sourceTree="<group>",
)
products = add(
    "products",
    "PBXGroup",
    children=[app_product, test_product, ui_product],
    name="Products",
    sourceTree="<group>",
)
main = add(
    "main",
    "PBXGroup",
    children=[app_group, test_group, ui_group, fixture, products],
    sourceTree="<group>",
)
project_id, app_id, test_id, ui_id = uid("project"), uid("app"), uid("tests"), uid("ui")
proxy = add(
    "proxy",
    "PBXContainerItemProxy",
    containerPortal=project_id,
    proxyType=1,
    remoteGlobalIDString=app_id,
    remoteInfo="Primal",
)
dependency = add("dependency", "PBXTargetDependency", target=app_id, targetProxy=proxy)
common = {
    "SDKROOT": "iphoneos",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1",
    "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
    "CLANG_ENABLE_MODULES": "YES",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "CODE_SIGN_STYLE": "Automatic",
    "PRODUCT_NAME": "$(TARGET_NAME)",
}
app_configs = config_list(
    "app",
    {
        **common,
        "PRODUCT_BUNDLE_IDENTIFIER": "com.example.primal",
        "INFOPLIST_FILE": "Primal/Info.plist",
        "API_BASE_URL": "",
        "CURRENT_PROJECT_VERSION": "1",
        "MARKETING_VERSION": "1.0",
        "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks",
    },
)
test_configs = config_list(
    "tests",
    {
        **common,
        "PRODUCT_BUNDLE_IDENTIFIER": "com.example.primal.tests",
        "GENERATE_INFOPLIST_FILE": "YES",
        "BUNDLE_LOADER": "$(TEST_HOST)",
        "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/Primal.app/Primal",
        "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks @loader_path/Frameworks",
    },
)
ui_configs = config_list(
    "ui",
    {
        **common,
        "PRODUCT_BUNDLE_IDENTIFIER": "com.example.primal.uitests",
        "GENERATE_INFOPLIST_FILE": "YES",
        "TEST_TARGET_NAME": "Primal",
    },
)
for name, target_id, config, builds, resources, product, dependencies, product_type in [
    (
        "Primal",
        app_id,
        app_configs,
        app_builds,
        [],
        app_product,
        [],
        "com.apple.product-type.application",
    ),
    (
        "PrimalTests",
        test_id,
        test_configs,
        test_builds,
        [fixture_build],
        test_product,
        [dependency],
        "com.apple.product-type.bundle.unit-test",
    ),
    (
        "PrimalUITests",
        ui_id,
        ui_configs,
        ui_builds,
        [],
        ui_product,
        [dependency],
        "com.apple.product-type.bundle.ui-testing",
    ),
]:
    sources = add(
        name + " sources",
        "PBXSourcesBuildPhase",
        buildActionMask=2147483647,
        files=builds,
        runOnlyForDeploymentPostprocessing=0,
    )
    frameworks = add(
        name + " frameworks",
        "PBXFrameworksBuildPhase",
        buildActionMask=2147483647,
        files=[],
        runOnlyForDeploymentPostprocessing=0,
    )
    resource_phase = add(
        name + " resources",
        "PBXResourcesBuildPhase",
        buildActionMask=2147483647,
        files=resources,
        runOnlyForDeploymentPostprocessing=0,
    )
    objects[target_id] = {
        "isa": "PBXNativeTarget",
        "buildConfigurationList": config,
        "buildPhases": [sources, frameworks, resource_phase],
        "buildRules": [],
        "dependencies": dependencies,
        "name": name,
        "productName": name,
        "productReference": product,
        "productType": product_type,
    }
project_configs = config_list(
    "project",
    {"CLANG_ENABLE_OBJC_ARC": "YES", "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym"},
)
objects[project_id] = {
    "isa": "PBXProject",
    "attributes": {
        "LastUpgradeCheck": "1600",
        "TargetAttributes": {
            app_id: {"CreatedOnToolsVersion": "16.0"},
            test_id: {"CreatedOnToolsVersion": "16.0", "TestTargetID": app_id},
            ui_id: {"CreatedOnToolsVersion": "16.0", "TestTargetID": app_id},
        },
    },
    "buildConfigurationList": project_configs,
    "compatibilityVersion": "Xcode 14.0",
    "developmentRegion": "en",
    "hasScannedForEncodings": 0,
    "knownRegions": ["en", "Base"],
    "mainGroup": main,
    "productRefGroup": products,
    "projectDirPath": "",
    "projectRoot": "",
    "targets": [app_id, test_id, ui_id],
}


def encode(value, level=0):
    if isinstance(value, dict):
        return (
            "{\n"
            + "".join(
                "\t" * (level + 1)
                + json.dumps(k)
                + " = "
                + encode(v, level + 1)
                + ";\n"
                for k, v in value.items()
            )
            + "\t" * level
            + "}"
        )
    if isinstance(value, list):
        return (
            "("
            + ", ".join(encode(v, level) for v in value)
            + ("," if value else "")
            + ")"
        )
    return str(value) if isinstance(value, int) else json.dumps(value)


project = ROOT / "ios/Primal.xcodeproj"
project.mkdir(exist_ok=True)
(project / "project.pbxproj").write_text(
    "// !$*UTF8*$!\n"
    + encode(
        {
            "archiveVersion": 1,
            "classes": {},
            "objectVersion": 56,
            "objects": objects,
            "rootObject": project_id,
        }
    )
    + "\n"
)
schemes = project / "xcshareddata/xcschemes"
schemes.mkdir(parents=True, exist_ok=True)


def buildable(target, name, product):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:Primal.xcodeproj"/>'


app = buildable(app_id, "Primal", "Primal.app")
tests = buildable(test_id, "PrimalTests", "PrimalTests.xctest")
ui_tests = buildable(ui_id, "PrimalUITests", "PrimalUITests.xctest")
(schemes / "Primal.xcscheme").write_text(f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app}</BuildActionEntry></BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES" codeCoverageEnabled="YES">
    <Testables><TestableReference skipped="NO">{tests}</TestableReference><TestableReference skipped="NO">{ui_tests}</TestableReference></Testables>
  </TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES">
    <BuildableProductRunnable runnableDebuggingMode="0">{app}</BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0">{app}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
""")
print("Generated ios/Primal.xcodeproj")
