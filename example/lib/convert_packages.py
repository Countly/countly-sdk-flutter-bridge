import os
import fileinput

# version 1.0.0

# This script is used to convert the example app from push to non push version and vice versa
# It helps you to test the example app with both versions of the plugin

# You have to uncomment one of the lines below to use it like:
# python convert_packages.py

# Currently it expects all files to be in the same directory as this script

# What it does is that it replaces the package import statement in the example app
# You can achieve the same result by manually replacing the package import statements yourself


def update_package(directory_path, from_package, to_package):
    for root, dirs, files in os.walk(directory_path):
        for file_name in files:
            file_path = os.path.join(root, file_name)

            # Process only Dart files
            if file_path.endswith('.dart'):
                print(f"Processing file: {file_path}")

                # Read the file content
                with open(file_path, 'r') as file:
                    lines = file.readlines()

                # Process only the first 30 lines as the package import statement is usually in the first 30 lines
                for line_number, line in enumerate(lines[:30], start=1):
                    if from_package in line:
                        lines[line_number -
                              1] = line.replace(from_package, to_package)

                # Write the modified content back to the file
                with open(file_path, 'w') as file:
                    file.writelines(lines)

                print(f"File processed: {file_path}")

if __name__ == "__main__":
    directory_path = "./" # Path to the directory containing the example app
    from_package = 'package:countly_flutter/' # push version
    to_package = 'package:countly_flutter_np/' # non push version

    # Uncomment the line below to: run the NO-PUSH version
    # update_package(directory_path, from_package, to_package)

    # Uncomment the line below to: run the normal version
    # update_package(directory_path, to_package, from_package)
