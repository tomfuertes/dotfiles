#!/usr/bin/env bash

# Prevent script from being sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
	echo "Error: This script should be executed, not sourced."
	echo "Use: ./bootstrap.sh instead of source bootstrap.sh"
	return 1
fi

# Check if Homebrew is installed
if ! which brew &>/dev/null; then
	echo "Homebrew is required to run this script."
	echo " - Install from: https://brew.sh/"
	echo " - Then: brew install colordiff"
	exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

git pull origin main

function show_diff() {
	local source_file="$1"
	local dest_file="$2"

	# Check if the file is a text file
	if file "$source_file" | grep -q text; then
		# Use colordiff if available, fall back to regular diff
		if command -v colordiff &>/dev/null; then
			diff -u "$dest_file" "$source_file" | colordiff
		else
			diff -u "$dest_file" "$source_file"
		fi
	else
		echo "Binary file $source_file will be copied"
	fi
}

function doIt() {
	# Exclusion list for files not to be synced
	local exclude_files=(
		".git"
		".DS_Store"
		".osx"
		"bootstrap.sh"
		"README.md"
		"LICENSE-MIT.txt"
	)

	# Build exclude pattern for rsync
	local exclude_args=()
	for file in "${exclude_files[@]}"; do
		exclude_args+=("--exclude=$file")
	done

	# Find files to sync
	local files_to_sync=()
	while IFS= read -r -d '' source_file; do
		# Get relative path
		rel_path="${source_file#./}"
		dest_file="$HOME/$rel_path"

		# Print filename
		echo "Checking file: $rel_path"

		# Show diff if file exists
		if [ -f "$dest_file" ]; then
			if ! cmp -s "$source_file" "$dest_file"; then
				echo "Differences found in $rel_path"
				show_diff "$source_file" "$dest_file"
				files_to_sync+=("$rel_path")
			fi
		else
			echo "New file will be created: $rel_path"
			files_to_sync+=("$rel_path")
		fi
	done < <(find . -type f -print0 "${exclude_args[@]/#/--exclude=}")

	# Confirm overall sync
	if [ ${#files_to_sync[@]} -eq 0 ]; then
		echo "No files to sync."
		return
	fi

	# Confirm sync
	echo "Files to be synced:"
	printf '%s\n' "${files_to_sync[@]}"
	read -p "Proceed with sync? (y/N) " -n 1 -r
	echo ""
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "Sync cancelled."
		return
	fi

	# Perform sync for selected files
	for file in "${files_to_sync[@]}"; do
		mkdir -p "$(dirname "$HOME/$file")"
		cp "$file" "$HOME/$file"
	done

	echo "Sync complete."

	# Source appropriate shell configuration
	if [ -n "$ZSH_VERSION" ]; then
		source ~/.zshrc
	elif [ -n "$BASH_VERSION" ]; then
		source ~/.bash_profile
	else
		echo 'unknown shell'
	fi
}

# Always prompt before syncing
read -p "This may overwrite existing files in your home directory. Are you sure? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
	doIt
fi

unset doIt
