#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin main;

function doIt() {
	# Create a temporary directory for rsync dry run
	temp_diff=$(mktemp -d)

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
		rm -rf "$temp_diff"
		return
	fi

	# Show files that would be modified/copied
	echo "The following files will be synced:"
	find "$temp_diff" -type f | sed "s|$temp_diff/||"

	# Confirm overall sync
	read -p "Proceed with syncing these files? (y/N) " -n 1 -r
	echo ""
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		rm -rf "$temp_diff"
		return
	fi

	# Perform the actual sync
	rsync --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude "bootstrap.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		-avh --no-perms . ~;

	# Clean up temporary directory
	rm -rf "$temp_diff"

	# Source appropriate shell configuration
	if [ -n "$ZSH_VERSION" ]; then
		source ~/.zshrc;
	elif [ -n "$BASH_VERSION" ]; then
		source ~/.bash_profile;
	else
		echo 'unknown shell'
	fi
}

# Always prompt before syncing
read -p "This may overwrite existing files in your home directory. Are you sure? (y/N) " -n 1 -r;
echo "";
if [[ $REPLY =~ ^[Yy]$ ]]; then
	doIt;
fi;

unset doIt;
