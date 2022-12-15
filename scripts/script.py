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

# OPERATION CONSTANTS
FILES_TO_ERASE = ['../android/src/main/java/ly/count/dart/countly_flutter/CountlyMessagingService.java', '../ios/countly_flutter.podspec']  # array of string values. Relative path to the files. Something like: 'android/sth/sth.txt'
FILES_TO_MOVE = [['no-push-files/AndroidManifest.xml','../android/src/main/AndroidManifest.xml'],['no-push-files/build.gradle','../android/build.gradle'],['no-push-files/pubspec.yaml','../pubspec.yaml'],['no-push-files/countly_flutter_np.podspec','../ios/countly_flutter_np.podspec'],['no-push-files/settings.gradle','../android/settings.gradle'],['no-push-files/README.md','../README.md']]  # array of, arrays of string tuples. Relative path to the file and the relative path to the copy directory. Something like ['android/sth/sth.txt','android2/folder']
# fileToModify = [] # write the file name to modify, currently expecting 1 file
# lineToModify = ''  # write the line to modify
# modification = ''  # write what to modify to

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
        shutil.copy(file,folder)

# Modifies a line in a given document
# TODO: Make it so that it can modify multiple lines
def modifyFile(file, varName, replacementName):
    # reading operations
    with open(file, 'r') as f:
        content = f.readlines()
    fileLines = []
    for line in content:
        if varName in line:
            fileLines.append(line.replace(varName, replacementName))
            print("Replacing: "+varName+" with: "+replacementName)
        else:
            fileLines.append(line)
    f.close()

    # writing operations
    finalFile = open(file, 'w')
    finalFile.writelines(fileLines)
    finalFile.close()
    print("Modified the file:"+file)


def main():
    # give info in set constants
    print("Paths to erase:")
    for i in FILES_TO_ERASE:
        print(i, end = '\n')
    print("Paths to copy:")
    for i in FILES_TO_MOVE:
        print(i, end = '\n')
    
    # ask for permission to run the script
    start = input('Do you want to continue? (y/n)')
    if start == 'y' or start == 'Y' or start == 'yes' or start == 'YES':
        cwd = os.getcwd() # get current working directory
        removeFiles(FILES_TO_ERASE, cwd) # remove files
        copyFiles(FILES_TO_MOVE, cwd) # copies a file
        print("Done")
    else:
        print("Aborted")


if __name__ == "__main__":
    main()
