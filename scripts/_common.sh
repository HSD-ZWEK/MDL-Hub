#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# Function to clone and install a Moodle plugin from a Git repository
install_plugin() {
    local DIR=$1
    local GIT_URL=$2
    local VERSION=$VERSION
    local GIT_BRANCHES=("MOODLE_${VERSION}_STABLE" "MOODLE_$((${VERSION} - 1))_STABLE" "MOODLE_$((${VERSION} - 2))_STABLE")

    echo "Attempting to install plugin in ${DIR} from ${GIT_URL}"

    # Check if the module is already installed
    if [ ! -d "${install_dir}/${DIR}" ]; then
        # Clone the module from the first available branch
        for BRANCH in "${GIT_BRANCHES[@]}"; do
            if git ls-remote "$GIT_URL" | grep -sw "$BRANCH" > /dev/null 2>&1; then
                echo "Cloning branch '$BRANCH'"
                git clone -b "$BRANCH" "$GIT_URL" "${install_dir}/${DIR}"
                break
            fi
        done

        # If no specific branch was cloned, clone the default branch
        if [ ! -d "${install_dir}/${DIR}" ]; then
            echo "No stable branch found. Cloning default branch."
            git clone "$GIT_URL" "${install_dir}/${DIR}"
        fi

        # Remove .git directory
        rm -rf "${install_dir}/${DIR}/.git"
    else
        echo "Plugin ${DIR} is already installed."
    fi
}

# Function to clone a Moodle theme from a Git repository
install_theme() {
    local DIR=$1
    local GIT_URL=$2
    local BRANCH=$3

    echo "Attempting to install theme in ${install_dir}/${DIR} from ${GIT_URL}"

    # Remove the existing theme directory if it exists
    if [ -d "${install_dir}/${DIR}" ]; then
        echo "Removing existing theme directory: ${install_dir}/${DIR}"
        rm -rf "${install_dir}/${DIR}"
    fi

    # Clone the theme if the specified branch exists in the repository
    if git ls-remote --heads "$GIT_URL" | grep -sw "refs/heads/$BRANCH" > /dev/null 2>&1; then
        echo "Cloning branch '$BRANCH' from $GIT_URL into ${install_dir}/${DIR}"
        git clone -b "$BRANCH" "$GIT_URL" "${install_dir}/${DIR}"
    else
        echo "Error: Branch '$BRANCH' does not exist in the repository."
        return 1
    fi
}

install_moosh() {
    # Check if moosh is already installed
    if command -v moosh > /dev/null 2>&1; then
        echo "moosh is already installed."
        return
    fi

    # Proceed with installation if moosh is not present
    git clone https://github.com/tmuras/moosh.git /opt/moosh
    rm -rf /opt/moosh/.git
    # Setting composer to allow superuser and update dependencies
    export COMPOSER_ALLOW_SUPERUSER=1; composer update --with-dependencies --working-dir=/opt/moosh
    # Installing composer dependencies
    export COMPOSER_ALLOW_SUPERUSER=1; composer install --working-dir=/opt/moosh
    # Creating a symbolic link for moosh
    ln -s /opt/moosh/moosh.php /usr/local/bin/moosh
}

#=================================================
# PERSONAL HELPERS
#=================================================

install_moodle_plugins() {

    # Update plugin list
    moosh -n -p ${install_dir} plugin-list

    # Extract branch from Moodle's version.php
    VERSION=$(grep 'branch' "${install_dir}/version.php" | tail -n 1 | cut -d"'" -f2)
    echo "Moodle branch extracted: $VERSION"

    # Display progress message
    ynh_script_progression --message="Installing plugins from git..." --weight=6

    # Blocks
    install_plugin "blocks/my_external_backup_restore_courses" "https://github.com/cperves/moodle-block-my_external_backup_restore_courses"

    # Filter
    moosh -n -p ${install_dir} plugin-install filter_jsxgraph


    # Course formats
    moosh -n -p ${install_dir} plugin-install format_tiles
    moosh -n -p ${install_dir} plugin-install format_onetopic

    # Local plugins
     moosh -n -p ${install_dir} plugin-install local_invitation

    # Mod plugins
    moosh -n -p ${install_dir} plugin-install mod_publication
    moosh -n -p ${install_dir} plugin-install mod_hvp
    moosh -n -p ${install_dir} plugin-install mod_lightboxgallery
    moosh -n -p ${install_dir} plugin-install mod_pcast
    install_plugin "mod/subpage" "https://github.com/moodleou/moodle-mod_subpage"

    # Microsoft plugins
    moosh -n -p ${install_dir} plugin-install local_o365
    moosh -n -p ${install_dir} plugin-install auth_oidc
    moosh -n -p ${install_dir} plugin-install repository_office365
    moosh -n -p ${install_dir} plugin-install theme_boost_o365teams
    moosh -n -p ${install_dir} plugin-install -f filter_oembed
    moosh -n -p ${install_dir} plugin-install local_office365

    # Question types
    moosh -n -p ${install_dir} plugin-install qtype_stack
    moosh -n -p ${install_dir} plugin-install qbehaviour_adaptivemultipart
    moosh -n -p ${install_dir} plugin-install qbehaviour_dfcbmexplicitvaildate
    moosh -n -p ${install_dir} plugin-install qbehaviour_dfexplicitvaildate
    moosh -n -p ${install_dir} plugin-install qtype_ddmatch
    moosh -n -p ${install_dir} plugin-install qtype_gapfill
    moosh -n -p ${install_dir} plugin-install qtype_answersselect
    moosh -n -p ${install_dir} plugin-install qtype_ordering
    moosh -n -p ${install_dir} plugin-install -f qtype_oumultiresponse
    moosh -n -p ${install_dir} plugin-install -f qtype_multichoiceset

    # Report
    install_plugin "report/allbackups" "https://github.com/catalyst/moodle-report_allbackups"

    # Tool
    moosh -n -p ${install_dir} plugin-install tool_brcli

    # Analytics
    install_plugin "admin/tool/log/store/lanalytics" "https://github.com/rwthanalytics/moodle-logstore_lanalytics.git"
    install_plugin "local/learning_analytics" "https://github.com/rwthanalytics/moodle-local_learning_analytics.git"

    # Boost Union Theme
    moosh -n -p ${install_dir} plugin-install theme_boost_union

    # HSD Theme for Moodle 4
    install_theme "theme/hsd_rot" "git@gitlab.ruhr-uni-bochum.de:moodle-hsd/locally-hosted-submodules/mdl4-themes.git" "hsd_rot"
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
