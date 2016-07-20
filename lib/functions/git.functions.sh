#==============================================================================
# Copyright (C) 2015 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# Alces Clusterware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Clusterware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware, please visit:
# https://github.com/alces-software/clusterware
#==============================================================================
GIT="${cw_ROOT}/opt/git/bin/git"

git_update() {
    local clonedir
    clonedir="$1"
    cd "${clonedir}" && \
      "$GIT" pull --ff-only &>/dev/null && \
      cd - &>/dev/null
}

# Update local repo to match particular remote branch, even if they have
# diverged.
git_match_remote() {
    local clonedir branch
    clonedir="$1"
    branch="$2"
    cd "${clonedir}" && \
      "$GIT" fetch origin --quiet && \
      "$GIT" reset --hard "origin/${branch}" --quiet && \
      cd - &>/dev/null
}

git_clone() {
    local repourl clonedir
    repourl="$1"
    clonedir="$2"
    mkdir -p "$(dirname ${clonedir})" && \
      "$GIT" clone "${repourl}" "${clonedir}" &>/dev/null
}

git_clone_rev() {
    local repourl clonedir rev
    repourl="$1"
    clonedir="$2"
    rev="$3"
    git_clone "$repourl" "$clonedir"
    (
	cd "$clonedir"
	if "$GIT" checkout "$rev"; then
	    "$GIT" branch -d master
	    "$GIT" checkout -b master
	    "$GIT" branch --set-upstream-to=origin/master master
	fi
    ) &>/dev/null
}
