#!/usr/bin/with-contenv bashio

set -e

CONFIG_FILE="/data/options.json"

bashio::log.info "Backup beginning at $(date)"

bashio::config.require 'rclone'
bashio::config.require 'rclone_config'

bashio::log.info "Writing config"

# can't use bashio::config here because it eats newlines
jq -r '.rclone_config' "${CONFIG_FILE}" > /tmp/rclone.conf

bashio::config.require 'rclone_remotes'

remote_indexes=$(jq -r '.rclone_remotes | keys[]' "${CONFIG_FILE}")
for index in ${remote_indexes}; do
    config_base="rclone_remotes[${index}]"
    bashio::config.require "${config_base}.definition"
    definition=$(bashio::config "${config_base}.definition")
    extra_args=""
    if bashio::config.has_value "${config_base}.extra_args"; then
        extra_args=$(bashio::config "${config_base}.extra_args")
    fi

    bashio::log.info "Beginning backup to remote ${definition}"

    /usr/local/bin/rclone sync --config /tmp/rclone.conf ${extra_args} /backup ${definition}

    bashio::log.info "Finished backup to remote ${definition}"
done

if bashio::config.has_value 'purge_days'; then
    days=$(bashio::config 'purge_days')
    bashio::log.info "Purging backups older than ${days} from disk..."

    find /backup -type f -mtime +${days} -exec rm {} \;
fi
