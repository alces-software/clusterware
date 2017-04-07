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
    local repourl clonedir track depth_arg
    repourl="$1"
    clonedir="$2"
    track="${3:-master}"
    if [ "$4" ]; then
        depth_arg=(--depth $4)
    fi
    mkdir -p "$(dirname ${clonedir})" && \
      "$GIT" clone "${depth_arg[@]}" -b "${track}" "${repourl}" "${clonedir}" &>/dev/null
}

git_shallow_clone() {
    git_clone "$@" 1
}

git_clone_rev() {
    local repourl clonedir rev track
    repourl="$1"
    clonedir="$2"
    rev="$3"
    track="${4:-master}"
    if [ "${rev}" == "HEAD" ]; then
        git_shallow_clone "$repourl" "$clonedir" "$track"
    else
        git_clone "$repourl" "$clonedir" "$track"
        (
	    cd "$clonedir"
	    if "$GIT" checkout "$rev"; then
	        "$GIT" branch -d "${track}"
	        "$GIT" checkout -b "${track}"
	        "$GIT" branch --set-upstream-to=origin/"${track}" "${track}"
	    fi
        ) &>/dev/null
    fi
}
