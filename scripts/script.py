import os

# operation constants
filesToErase = [] # write file names to erase
fileToModify= [] # write the file name to modify, currently expecting 1 file
lineToModify = '' # write the line to modify 
modification = '' # write what to modify to

# walks through the all files in the project and writes down the paths of the ones you are looking for
def findFilesTo(src, array):
    paths = []
    for root, dirs, files in os.walk(src):
        for file in files:
            for fileName in array:
                if file == fileName:
                    path = os.path.join(root, file)
                    paths.append(path)
    return paths

def removeFiles(paths):
    for path in paths:
        if os.path.exists(path):
         print("removing:"+path)
         os.remove(path)

 
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
    cwd = os.getcwd()
    pathsToErase = findFilesTo(cwd, filesToErase)
    print("Paths to erase:")
    print(pathsToErase)
    pathsToModify = findFilesTo(cwd, fileToModify)
    print("Paths to modify:")
    print(pathsToModify)
    removeFiles(pathsToErase)
    modifyFile(pathsToModify[0], lineToModify, modification)
    print("Done")

if __name__ == "__main__":
    main()
