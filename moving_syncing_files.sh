# When specific cases are used, it is my own file organization system

# merge contents of one folder into another, removing originals in folder 1
rsync -avh --remove-source-files folder_1/ folder_2/
    # rsync: The command.
    # -a: Archive mode (preserves permissions, timestamps, etc.).
    # -v: Verbose (shows progress).
    # -h: Human-readable (sizes in KB, MB, etc.).
    # --remove-source-files: Deletes files from folder_1 after they’ve been copied.


# also remove empty folders from folder1
rsync -avh --remove-source-files folder_1/ folder_2/ && find folder_1 -type d -empty -delete

# removing everything from folder_1
rsync -avh --remove-source-files folder_1/ folder_2/ && find folder_1 -type d -empty -delete

# test it out with a dry-run first (skip the -delete)
rsync -avh --remove-source-files --dry-run folder_1/ folder_2/

# look for files (not folders) starting with "Soundgarden" (case-insensitive).
# Move them into a folder named soundgarden (lowercase), creating it if needed.
mkdir -p /mnt/user/media/media_files/music/merged_music/soundgarden
find /mnt/user/media/media_files/music/merged_music -maxdepth 1 -type f -iname "Soundgarden*" -exec mv {} /mnt/user/media/media_files/music/merged_music/soundgarden/ \;

# preview above before moving (add -print)
find /mnt/user/media/media_files/music/merged_music -maxdepth 1 -type f -iname "Soundgarden*" -print

# takes all files in a directory and creates a folder with the same name & places files into folders
#!/bin/bash

# Set your target directory or use current directory
  TARGET_DIR="${1:-.}"

  # Loop over all files in the directory (excluding hidden files)
  for filepath in "$TARGET_DIR"/*; do
    # Skip if not a regular file
    [ -f "$filepath" ] || continue

    # Get the base filename and extension
    filename=$(basename -- "$filepath")
    name="${filename%.*}"

    # Create a folder with the base name
    mkdir -p "$TARGET_DIR/$name"

    # Move the file into the new folder
    mv "$filepath" "$TARGET_DIR/$name/"
  done

# find and delete all files of a given extension
find /path/to/your/directory -name '.fileExtension' -type f -delete
      # example: find . -name '.DS_Store' -type f -delete

# files into folders
      # Scans the directory media/books/audiobooks
      # Looks for only files, not folders
      # Moves each file into a new folder named after the file (without extension)
#!/bin/bash

cd "media/books/audiobooks" || exit 1

# Loop through all items in the directory
for file in *; do
	# Check if it's a regular file (not a directory)
	if [ -f "$file" ]; then
		# Get the base name without the extension
		filename="${file%.*}"

		# Make the folder if it doesn't exist
		mkdir -p "$filename"

		# Move the file into the folder
		mv "$file" "$filename/"
	fi
done

##################################

# basic rsync
rsync -av Folder1/ Folder2/
      # does not remove source files

# find and delete empty folders in a given directory
find Folder1 -type d -empty -delete
