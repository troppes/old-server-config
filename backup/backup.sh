#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source "${SCRIPT_DIR}/settings.conf" #read from config file

readonly BACKUP_PATH="${SCRIPT_DIR}"/"${backupFolderName}"
readonly LOG_FILE_PATH="${SCRIPT_DIR}/${logName}"

function ok() {
  printf '%s [ OK ] %s\n' "$(date --rfc-3339=seconds)" "$@" | tee -a "${LOG_FILE_PATH}"
}

# logs info messages to stdout and logfile
function info() {
  printf '%s [INFO] %s\n' "$(date --rfc-3339=seconds)" "$@" | tee -a "${LOG_FILE_PATH}"
}

# logs error messages to stdout and logfile
function err() {
  printf '%s [ERR!] %s\n' "$(date --rfc-3339=seconds)" "$@" | tee -a "${LOG_FILE_PATH}" >&2
}

#Delete old Backups
info "Deleting old files"

rm -f "${backupName}"
rm -f "${logName}"

mkdir -p "${BACKUP_PATH}"

info "Log for ${date}"

info "Starting to backup services"

info "Backing up MariaDB"
docker exec mariadb /usr/bin/mysqldump --all-databases --single-transaction --quick --lock-tables=false > "${BACKUP_PATH}"/mariadb-full-backup-"$(date +%F)".sql -u${mariaUser} -p${mariaPassword} && EXIT_CODE=$? || EXIT_CODE=$?
if [ "$EXIT_CODE" != 0 ]; then
	err "Failed to create a backup for MariaDB!"
fi

info "Backing up Bitwarden"
sqlite3 /srv/bitwarden/db.sqlite3 ".backup '${BACKUP_PATH}/bitwarden.sqlite3'" > /dev/null && EXIT_CODE=$? || EXIT_CODE=$?
if [ "$EXIT_CODE" != 0 ]; then
	err "Failed to create a backup for Bitwarden!"
fi

info "Backing up Nextcloud"
info "Turning on maintenance mode for Nextcloud..."
docker exec --user www-data nextcloud php occ maintenance:mode --on > /dev/null
info "Creating backup of the nextcloud configs..."
7z a "${BACKUP_PATH}"/nextcloud.7z /srv/nextcloud/config > /dev/null && EXIT_CODE=$? || EXIT_CODE=$?
if [ "$EXIT_CODE" != 0 ]; then
	err "Failed to create a backup for Nextcloud!"
fi
info "Turning off maintenance mode for Nextcloud..."
docker exec --user www-data nextcloud php occ maintenance:mode --off > /dev/null

info "Finished backup scripts"

info "Zipping backup folder"
7z a  -p"${backupPassword}" "${backupName}" "${BACKUP_PATH}" > /dev/null && EXIT_CODE=$? || EXIT_CODE=$?
if [ "$EXIT_CODE" != 0 ]; then
	err "Failed to create the archive for all backups!"
fi
#info "Deleting local copy of the backup"
rm -r "${BACKUP_PATH}"
