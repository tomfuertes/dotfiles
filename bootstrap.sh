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
	# Create temporary directories for dry run and diff checking
	local temp_diff=$(mktemp -d)
	local temp_home=$(mktemp -d)

	# Perform a dry run to see what would be copied
	rsync --dry-run --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude "bootstrap.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		-avh --no-perms . "$temp_diff"

	# Check if there are any files to be synced
	if [ -z "$(ls -A "$temp_diff")" ]; then
		echo "No files to sync."
		rm -rf "$temp_diff" "$temp_home"
		return
	fi

	# Perform a dry run to home directory for comparison
	rsync --dry-run --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude "bootstrap.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		-avh --no-perms . "$temp_home"

	# Show diffs for each file
	echo "Files to be synced:"
	local files_to_sync=()
	while IFS= read -r -d '' source_file; do
		# Get relative path
		rel_path="${source_file#$temp_diff/}"
		dest_file="$HOME/$rel_path"

		# Print filename
		echo "File: $rel_path"

		# Show diff if file exists
		if [ -f "$dest_file" ]; then
			show_diff "$source_file" "$dest_file"
		else
			echo "New file will be created"
		fi

		# Ask for confirmation for each file
		read -p "Sync this file? (y/N) " -n 1 -r
		echo ""
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			files_to_sync+=("$rel_path")
		fi
	done < <(find "$temp_diff" -type f -print0)

	# Confirm overall sync
	if [ ${#files_to_sync[@]} -eq 0 ]; then
		echo "No files selected for sync."
		rm -rf "$temp_diff" "$temp_home"
		return
	fi

	# Perform sync for selected files
	for file in "${files_to_sync[@]}"; do
		mkdir -p "$(dirname "$HOME/$file")"
		cp "$temp_diff/$file" "$HOME/$file"
	done

	# Clean up temporary directories
	rm -rf "$temp_diff" "$temp_home"

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
