#!/bin/bash

set -e

# Мапа версий → URL плагина
get_plugin_url() {
    case "$1" in
        "2025.1") echo "https://amplicode.ru/Amplicode/amplicode-2025.1.4-251.zip" ;;
        "2024.3") echo "https://amplicode.ru/Amplicode/amplicode-2025.1.4-243.zip" ;;
        "2024.2") echo "https://amplicode.ru/Amplicode/amplicode-2025.1.4-242.zip" ;;
        "2024.1") echo "https://amplicode.ru/Amplicode/amplicode-2024.3.6-241-EAP.zip" ;;
        "2023.2") echo "https://amplicode.ru/Amplicode/amplicode-2024.1.6-232-EAP.zip" ;;
        *) echo "" ;;
    esac
}

# Каталоги конфигураций
CONFIG_DIRS=(
    "$HOME/Library/Application Support/JetBrains"
    "$HOME/Library/Application Support/GIGAIDE"
    "$HOME/.config/JetBrains"
    "$HOME/.config/GIGAIDE"
)

CACHE_DIR="$HOME/.cache/idea-plugin-installer"
mkdir -p "$CACHE_DIR"

find_ide_folders() {
    for base in "${CONFIG_DIRS[@]}"; do
        if [ -d "$base" ]; then
            ls "$base" | grep -E '^(IntelliJIdea|IdeaIC|IdeaEdu|GIGAIDE-CE)-?[0-9]{4}\.[0-9]$' || true
        fi
    done
}

install_plugin() {
    local ide_name="$1"
    local ide_root=""
    local plugin_dir=""
    local version

    version=$(echo "$ide_name" | grep -oE '[0-9]{4}\.[0-9]')
    if [ -z "$version" ]; then
        echo "❓ Не удалось определить версию для $ide_name"
        return
    fi

    local url
    url=$(get_plugin_url "$version")
    if [ -z "$url" ]; then
        echo "⏭️  Нет подходящего плагина для $ide_name ($version)"
        return
    fi

    for base in "${CONFIG_DIRS[@]}"; do
        full_path="$base/$ide_name"
        if [ -d "$full_path" ]; then
            ide_root="$full_path"
            break
        fi
    done

    if [ -z "$ide_root" ]; then
        echo "⚠️  Не найдена папка для $ide_name"
        return
    fi

    plugin_dir="$ide_root/plugins"
    mkdir -p "$plugin_dir"

    zip_name="$(basename "$url")"
    cached_zip="$CACHE_DIR/$zip_name"

    # Загрузка с кэшем
    download_archive() {
        echo "⬇️  Скачиваем $zip_name для $ide_name ($version)..."
        curl --progress-bar -L "$url" -o "$cached_zip"
    }

    if [ ! -f "$cached_zip" ]; then
        download_archive
    else
        echo "📦 Используем кеш: $cached_zip"
    fi

    echo "📦 Установка в $plugin_dir"
    if unzip -q -o "$cached_zip" -d "$plugin_dir"; then
        echo "✅ Установлено для $ide_name"
    else
        echo "⚠️  Ошибка распаковки. Перекачиваем архив..."
        rm -f "$cached_zip"
        download_archive
        echo "📦 Повторная установка..."
        if unzip -q -o "$cached_zip" -d "$plugin_dir"; then
            echo "✅ Установлено после повторной загрузки"
        else
            echo "❌ Ошибка повторной распаковки. Пропускаем $ide_name"
        fi
    fi
}


main() {
    echo "🔍 Ищем установленные IDE..."
    local folders=()
    while IFS= read -r line; do
        folders+=("$line")
    done < <(find_ide_folders)

    if [ "${#folders[@]}" -eq 0 ]; then
        echo "🚫 Ни одной поддерживаемой IDE не найдено"
        exit 0
    fi

    for ide in "${folders[@]}"; do
        install_plugin "$ide"
    done
}

main
