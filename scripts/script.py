import os
import shutil

#   README
#   This script should be run from the root of the project with the command:
#   python script.py
#
#   It will check operation constants, provided below, for information regarding what to erase or where to copy
#   That information must be filles before running the script
#
#   Versions
#   0.1
#       - can remove files if relative path to the script is provided
#       - can copy files if file and copy directory information is provided
#   0.2
#       - can modify files

# OPERATION CONSTANTS
FILES_TO_ERASE = [
    '../android/src/main/java/ly/count/dart/countly_flutter/CountlyMessagingService.java',
    '../ios/countly_flutter.podspec',
    '../ios/Classes/CountlyFLPushNotifications.h',
    '../ios/Classes/CountlyFLPushNotifications.m'
]  # array of string values. Relative path to the files. Something like: 'android/sth/sth.txt'
FILES_TO_MOVE = [
    [
        'no-push-files/AndroidManifest.xml',
        '../android/src/main/AndroidManifest.xml'
    ],
    [
        'no-push-files/build.gradle',
        '../android/build.gradle'
    ],
    [
        'no-push-files/pubspec.yaml',
        '../pubspec.yaml'
    ],
    [
        'no-push-files/countly_flutter_np.podspec',
        '../ios/countly_flutter_np.podspec'
    ],
    [
        'no-push-files/settings.gradle',
        '../android/settings.gradle'
    ],
    [
        'no-push-files/README.md',
        '../README.md'
    ]
]  # array of, arrays of string tuples. Relative path to the file and the relative path to the copy directory. Something like ['android/sth/sth.txt','android2/folder']
modPathAndroid = "../android/src/main/java/ly/count/dart/countly_flutter/CountlyFlutterPlugin.java"
modPathIos = "../ios/Classes/CountlyFlutterPlugin.m"
modPathCountly = "../lib/countly_flutter.dart"
objectOfComModification = {
    modPathAndroid: {
        "modifications": {
            'import com.google.firebase.iid.FirebaseInstanceId;': "remove",
            'import com.google.firebase.iid.InstanceIdResult;': "remove",
            'import com.google.android.gms.tasks.Task;': "remove",
            'import com.google.android.gms.tasks.OnCompleteListener;': "remove",
            'import com.google.firebase.FirebaseApp;': "remove",
            "private final boolean BUILDING_WITH_PUSH_DISABLED = false;": "private final boolean BUILDING_WITH_PUSH_DISABLED = true;"
        },
        "consecutiveOmits": [
            "FirebaseApp.initializeApp(context);",
            "FirebaseInstanceId.getInstance().getInstanceId()",
            ".addOnCompleteListener(new OnCompleteListener<InstanceIdResult>() {",
            "@Override",
            "public void onComplete(@NonNull Task<InstanceIdResult> task) {",
            "if (!task.isSuccessful()) {",
            'log("getInstanceId failed", task.getException(), LogLevel.WARNING);',
            "return;",
            "}",
            "String token = task.getResult().getToken();",
            "CountlyPush.onTokenRefresh(token);",
            "}",
            "});"
        ]
    },
    modPathIos: {
        "modifications": {
            "BOOL BUILDING_WITH_PUSH_DISABLED = false;": "BOOL BUILDING_WITH_PUSH_DISABLED = true;",
            "// #define COUNTLY_EXCLUDE_PUSHNOTIFICATIONS": "#define COUNTLY_EXCLUDE_PUSHNOTIFICATIONS"
        },
        "consecutiveOmits": []
    },
    modPathCountly: {
        "modifications": {
            "import 'package:countly_flutter/countly_config.dart';": "import 'package:countly_flutter_np/countly_config.dart';",
            "import 'package:countly_flutter/countly_state.dart';": "import 'package:countly_flutter_np/countly_state.dart';",
            "import 'package:countly_flutter/remote_config.dart';": "import 'package:countly_flutter_np/remote_config.dart';",
            "import 'package:countly_flutter/remote_config_internal.dart';": "import 'package:countly_flutter_np/remote_config_internal.dart';",
            "export 'package:countly_flutter/countly_config.dart';": "export 'package:countly_flutter_np/countly_config.dart';",
            "export 'package:countly_flutter/remote_config.dart';": "export 'package:countly_flutter_np/remote_config.dart';",
            "static const bool BUILDING_WITH_PUSH_DISABLED = false;": "  static const bool BUILDING_WITH_PUSH_DISABLED = true;"
        },
        "consecutiveOmits": []
    }
}  # 'modifications' is a map with keys are the lines to remove or modify. 'consecutiveOmits' are a block of lines to remove.

# walks through all files in the project and writes down the paths of the ones you are looking for. Can only work for unique files.
# TODO: Refactor so that it checks only the specified folder and files, like ['android-app', 'gradle']. Makes it easy to find files without the need of relative path information.


def findFilesTo(src, array):
    paths = []
    for root, dirs, files in os.walk(src):
        for file in files:
            for fileName in array:
                if file == fileName:
                    path = os.path.join(root, file)
                    paths.append(path)
    return paths

# loops through the provided array of relative paths and erases each file that exists


def removeFiles(paths, cwd):
    for path in paths:
        path = os.path.join(cwd, path)
        if os.path.exists(path):
            print("Removing:"+path)
            os.remove(path)

# loops through the provided array of relative paths and copies each file that exists


def copyFiles(arrays, cwd):
    for tuple in arrays:
        file = os.path.join(cwd, tuple[0])
        folder = os.path.join(cwd, tuple[1])
        shutil.copy(file, folder)

# Modifies a given document
# (String) filePath - relative path to the file to modify
# (Obj) modificationInfo - object that contains file path as keys and modification and omittance info as values
# (String) modificationType - 'bloc' for block removal, 'mod' for modification


def modifyFile(filePath, modificationInfo, modificationType):
    # reading operations
    with open(filePath, 'r') as f:
        content = f.readlines()
    fileLines = []
    for line in content:
        if modificationType == 'mod':
            if line.strip("\n") in modificationInfo[filePath]['modifications']:
                if modificationInfo[filePath]['modifications'][line.strip("\n")] == 'remove':
                    print("Removing line: ", line)
                else:
                    fileLines.append(
                        modificationInfo[filePath]['modifications'][line.strip("\n")] + "\n")
                    print("Replacing: ["+line+"] with: ["+modificationInfo[filePath]
                          ['modifications'][line.strip("\n")]+"]")
            else:
                fileLines.append(line)
        elif modificationType == 'bloc':
            if modificationInfo[filePath]['consecutiveOmits']:
                if modificationInfo[filePath]['consecutiveOmits'][0] in line.strip("\n"):
                    modificationInfo[filePath]['consecutiveOmits'].pop(0)
                    print("Removing line: ", line)
                else:
                    fileLines.append(line)
            else:
                fileLines.append(line)
    f.close()

    # writing operations
    finalFile = open(filePath, 'w')
    finalFile.writelines(fileLines)
    finalFile.close()
    print("Modified the file:"+filePath)


def main():
    # give info about set constants
    print("Paths to erase:")
    for i in FILES_TO_ERASE:
        print(i, end='\n')
    print("Paths to copy:")
    for i in FILES_TO_MOVE:
        print(i, end='\n')
    print('Paths to modify:')
    print(modPathAndroid)
    print(modPathIos)
    print(modPathCountly)

    # ask for permission to run the script
    start = input('Do you want to continue? (y/n)')
    if start == 'y' or start == 'Y' or start == 'yes' or start == 'YES':
        cwd = os.getcwd()  # get current working directory
        removeFiles(FILES_TO_ERASE, cwd)  # remove files
        copyFiles(FILES_TO_MOVE, cwd)  # copies a file
        modifyFile(modPathAndroid, objectOfComModification, 'mod')
        modifyFile(modPathAndroid, objectOfComModification, 'bloc')
        modifyFile(modPathIos, objectOfComModification, 'mod')
        modifyFile(modPathCountly, objectOfComModification, 'mod')
        print("Done")
    else:
        print("Aborted")


if __name__ == "__main__":
    main()
