
# list folders/directories in a given directory
find /path/to/dir -maxdepth 1 -type d

# exclude the current directory
find /path/to/dir -mindepth 1 -maxdepth 1 -type d

# using grep to assist
ls -l /path/to/dir | grep ^d
  # grep ^d filters lines that start with d (AKA Directories)

# bash globbing
for dir in /path/to/dir/*/; do
	echo "$dir"
done

# list directory names only
ls -d */
    # -d: Don’t list contents of directories.
    # */: Only matches directories.

# similar outcome:
find . -maxdepth 1 -type d

# view the size of a directory
du -h -d 1 /path/to/directory
      # du: disk usage command
      # -h: human-readable format (e.g., 1K, 234M, 2G)
      # -d 1: only go 1 level deep (you can change this to a higher number for deeper levels)
      # /path/to/directory: replace this with your target directory path
      # du -h -d 1 . >> this will show the size of the current directory and each within it

# recursive listing by size
du -h /path/to/directory | sort -h

# simply the total size of the directory
du -sh /path/to/directory

