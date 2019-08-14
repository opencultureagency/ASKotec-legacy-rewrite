#!/bin/bash
# Copyright: Public Domain (PD)
# Creates a distribution archive of this repo.

# immediately exit in case of an error
set -o errexit

work_dir=$(pwd)
dist_version=$(git describe --always --tags)
dist_root="${work_dir}/dist"
dist_dir="${dist_root}/$dist_version"

function git-tag-hash() {

	tag="$1"
	git show-ref --tags | grep "$tag\$" | awk -e '{ print $1 }'
}

function git-commit-steps() {

	# git revisions
	local r1="$1"
	local r2="$2"

	if [ -z "$r1" ] || [ -z "$r2" ]
	then
		print_help
		return 1
	fi

	local diff_forward=`git rev-list --count $r1..$r2 2> /dev/null`
	local diff_backward=`git rev-list --count $r2..$r1 2> /dev/null`
	if [ $? -ne 0 ]
	then
		echo "unrelated"
	else
		# NOTE We need the ' || true' here,
		#      because in case of the expr result being 0,
		#      the script woudl otherwise exit because of 'set -e'.
		expr $diff_forward "-" $diff_backward || true
	fi
}

if output=$(git status --untracked-files=no --porcelain) && [ -z "$output" ]
then
	# working directory is clean
	echo "No uncommited changes found."
	echo "NOTE Untracked (uncommitted) files will not make it into the distribution!"
	dist_version=$(git describe --always --tags)
else
	# working directory is unclean (uncommitted changes)
	echo "Uncommitted changes found; aborting build of the distribution archive!" 1>&2
	exit 1
fi

echo
echo "Setup the dist dir ..."
mkdir -p "$dist_dir"
rm -Rf "$dist_dir"/*

echo
echo "Checking out the assets submodule, if not already done so ..."
if $(git submodule status assets/ | grep -q '^-')
then
	git submodule update --init assets/
fi

echo
echo "Linking the git repo and parts of the assets into the dist dir ..."
ln -s .git "$dist_dir/"
mkdir -p "$dist_dir/assets"
ln -s "${work_dir}/assets/thumbs" "$dist_dir/assets/"
hash_v1_0=$(git-tag-hash 'ASKotec-1.0')
hash_cur=$(git rev-parse HEAD)
steps_to_v1_0=$(git-commit-steps $hash_cur $hash_v1_0)
if [ $steps_to_v1_0 -ge 0 ]
then
	# The current commit is an ancestor of or equal to v1.0
	ln -s "${work_dir}/assets/ASKotec-packing-guide.pdf" "$dist_dir/"
	ln -s "${work_dir}/assets/ASKotec_Poster_24_18.pdf" "$dist_dir/"
fi

echo
echo "Generate PDFs from Markdown documents ..."
while read -r md_file
do
	file_path=$(dirname "$md_file")
	file_base=$(basename "$md_file" | sed -e 's/\.[^.]*//')
	pdf_file="${file_base}.pdf"
	pandoc -o "$pdf_file" "$md_file"
	mkdir -p "$dist_dir/$file_path"
	mv "$pdf_file" "$dist_dir/$file_path"
done < <(find . -type f -path '*.md' ! -path './.git*' ! -path './dist*')

echo
echo "Generate PDFs from LibreOffice documents (binary and flat) ..."
while read -r xodx_file
do
	file_path=$(dirname "$xodx_file")
	file_base=$(basename "$xodx_file" | sed -e 's/\.[^.]*//')
	pdf_file="${file_base}.pdf"
	libreoffice --headless --convert-to pdf "$xodx_file"
	mkdir -p "$dist_dir/$file_path"
	mv "$pdf_file" "$dist_dir/$file_path"
done < <(find . -type f -path '*.*od?' ! -path './.git*' ! -path './dist*')

echo
echo "Copy source files to dist dir ..."
while read -r src_file
do
	src_dir=$(dirname "$src_file")
	mkdir -p "$src_dir"
	cp "$src_file" "$dist_dir/$src_file"
done < <(git ls-tree -r HEAD --name-only | grep -v "^assets")

echo
echo "Create the dist archive ..."
dist_archive="${dist_version}.zip"
cd "$dist_root"
zip -r "$dist_archive" "$dist_version"
if false
then
# first archive the generated files
cd dist
zip -r "$dist_archive" *
cd ..
# then the source files
src_lst_file="dist/sources_list.txt"
git ls-tree -r master --name-only > "$src_lst_file"
find . -type f -path '*.fod?' ! -path './.git*'
zip -r "dist/$dist_archive" . -i@"$src_lst_file"
fi

echo
echo "Distribution archive created at 'dist/$dist_archive'"

