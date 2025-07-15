#!/bin/bash

# Script pour générer automatiquement le CHANGELOG depuis les commits gitmoji
# Usage: ./scripts/generate-changelog.sh [from_tag] [to_tag]

set -e
set -o pipefail

# Activer le mode debug si DEBUG=1
if [[ "${DEBUG:-0}" == "1" ]]; then
    set -x
fi

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHANGELOG_FILE="CHANGELOG.md"
TEMP_FILE=$(mktemp)
PROJECT_NAME="${PROJECT_NAME:-'GitFlow Automation Action'}"

# Fonction d'affichage
log() {
    echo -e "${BLUE}📝 $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Fonction pour obtenir la date actuelle
get_current_date() {
    date "+%Y-%m-%d"
}

# Fonction pour obtenir le dernier tag
get_last_tag() {
    git describe --tags --abbrev=0 --match "v*" 2>/dev/null || echo ""
}

# Fonction pour valider le format de version
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
        error "Format de version invalide: $version"
        error "Formats acceptés: v1.0.0, 1.0.0, v1.0.0-alpha"
        return 1
    fi
    return 0
}

# Fonction pour déterminer si un commit doit être inclus
should_include_commit() {
    local commit="$1"
    # Exclure les commits de merge
    if [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+Merge ]]; then
        return 1
    fi
    return 0
}

# Fonction pour catégoriser les commits
categorize_commit() {
    local commit="$1"
    # Convertir en minuscules pour la comparaison
    local commit_lower=$(echo "$commit" | tr '[:upper:]' '[:lower:]')
    
    case "$commit" in
        *:sparkles:*|*:rocket:*|*:tada:*|*" feat:"*)
            echo "✨ Nouvelles fonctionnalités"
            ;;
        *:bug:*|*:ambulance:*|*:adhesive_bandage:*|*" fix:"*)
            echo "🐛 Corrections"
            ;;
        *:boom:*|*:fire:*|*"BREAKING CHANGE"*)
            echo "💥 Changements incompatibles"
            ;;
        *:memo:*|*:bulb:*|*" docs:"*)
            echo "📚 Documentation"
            ;;
        *:art:*|*:lipstick:*|*" style:"*)
            echo "🎨 Style"
            ;;
        *:recycle:*|*" refactor:"*)
            echo "♻️ Refactoring"
            ;;
        *:white_check_mark:*|*:test_tube:*|*" test:"*)
            echo "🧪 Tests"
            ;;
        *:zap:*|*" perf:"*)
            echo "⚡ Performance"
            ;;
        *:lock:*|*" security:"*)
            echo "🔒 Sécurité"
            ;;
        *:wrench:*|*:package:*|*:arrow_up:*|*" chore:"*|*" build:"*|*" ci:"*)
            echo "🔧 Maintenance"
            ;;
        *)
            echo "📝 Autres"
            ;;
    esac
}

# Fonction pour extraire le message du commit
extract_commit_message() {
    local commit="$1"
    # Supprimer le hash et ne garder que le message
    echo "$commit" | sed 's/^[a-f0-9]\+ //'
}

# Fonction pour générer le changelog
generate_changelog() {
    local from_tag="$1"
    local to_tag="$2"
    local version="$3"
    
    log "Génération du CHANGELOG pour $version..."
    
    # === CORRECTION DU RANGE ===
    # Obtenir les commits avec le range corrigé
    local git_range
    if [[ -n "$from_tag" ]]; then
        git_range="$from_tag..HEAD"
    else
        # Chercher le dernier tag automatiquement
        local last_tag=$(get_last_tag)
        if [[ -n "$last_tag" ]]; then
            git_range="$last_tag..HEAD"
            log "Utilisation du dernier tag trouvé: $last_tag"
        else
            # Si pas de tag, limiter aux commits récents
            git_range="HEAD~20..HEAD"
            warning "Aucun tag trouvé, limitation aux 20 derniers commits"
        fi
    fi
    
    log "Recherche des commits avec range: $git_range"
    
    # Récupérer les commits
    local commits=$(git log --oneline --no-merges $git_range 2>/dev/null || echo "")
    
    if [[ -z "$commits" ]]; then
        warning "Aucun commit trouvé pour générer le changelog"
        return 0
    fi
    
    local commit_count=$(echo "$commits" | wc -l)
    log "Nombre de commits trouvés: $commit_count"
    
    # Validation du nombre de commits
    if [[ $commit_count -gt 100 ]]; then
        warning "Nombre de commits suspect ($commit_count), cela peut indiquer un problème de range"
        warning "Limitation aux 50 derniers commits pour éviter les problèmes"
        commits=$(git log --oneline --no-merges -50)
    fi
    
    # Créer les catégories (compatible macOS)
    local cat_feat=""
    local cat_fix=""
    local cat_breaking=""
    local cat_docs=""
    local cat_style=""
    local cat_refactor=""
    local cat_test=""
    local cat_perf=""
    local cat_security=""
    local cat_chore=""
    local cat_other=""
    
    log "Classification des commits..."
    
    # Classer les commits par catégorie
    while IFS= read -r commit; do
        if [[ -n "$commit" ]] && should_include_commit "$commit"; then
            local category=$(categorize_commit "$commit")
            local message=$(extract_commit_message "$commit")
            case "$category" in
                "✨ Nouvelles fonctionnalités")
                    cat_feat="$cat_feat\n- $message"
                    ;;
                "🐛 Corrections")
                    cat_fix="$cat_fix\n- $message"
                    ;;
                "💥 Changements incompatibles")
                    cat_breaking="$cat_breaking\n- $message"
                    ;;
                "📚 Documentation")
                    cat_docs="$cat_docs\n- $message"
                    ;;
                "🎨 Style")
                    cat_style="$cat_style\n- $message"
                    ;;
                "♻️ Refactoring")
                    cat_refactor="$cat_refactor\n- $message"
                    ;;
                "🧪 Tests")
                    cat_test="$cat_test\n- $message"
                    ;;
                "⚡ Performance")
                    cat_perf="$cat_perf\n- $message"
                    ;;
                "🔒 Sécurité")
                    cat_security="$cat_security\n- $message"
                    ;;
                "🔧 Maintenance")
                    cat_chore="$cat_chore\n- $message"
                    ;;
                "📝 Autres")
                    cat_other="$cat_other\n- $message"
                    ;;
            esac
        fi
    done <<< "$commits"
    
    log "Génération du fichier CHANGELOG..."
    
    # Créer l'entrée du changelog
    local date=$(get_current_date)
    local changelog_entry="## [$version] - $date"
    
    # Ajouter les catégories non vides
    if [[ -n "$cat_breaking" ]]; then
        changelog_entry="$changelog_entry\n\n### 💥 Changements incompatibles"
        changelog_entry="$changelog_entry$cat_breaking"
    fi
    
    if [[ -n "$cat_feat" ]]; then
        changelog_entry="$changelog_entry\n\n### ✨ Nouvelles fonctionnalités"
        changelog_entry="$changelog_entry$cat_feat"
    fi
    
    if [[ -n "$cat_fix" ]]; then
        changelog_entry="$changelog_entry\n\n### 🐛 Corrections"
        changelog_entry="$changelog_entry$cat_fix"
    fi
    
    if [[ -n "$cat_perf" ]]; then
        changelog_entry="$changelog_entry\n\n### ⚡ Performance"
        changelog_entry="$changelog_entry$cat_perf"
    fi
    
    if [[ -n "$cat_refactor" ]]; then
        changelog_entry="$changelog_entry\n\n### ♻️ Refactoring"
        changelog_entry="$changelog_entry$cat_refactor"
    fi
    
    if [[ -n "$cat_security" ]]; then
        changelog_entry="$changelog_entry\n\n### 🔒 Sécurité"
        changelog_entry="$changelog_entry$cat_security"
    fi
    
    if [[ -n "$cat_docs" ]]; then
        changelog_entry="$changelog_entry\n\n### 📚 Documentation"
        changelog_entry="$changelog_entry$cat_docs"
    fi
    
    if [[ -n "$cat_style" ]]; then
        changelog_entry="$changelog_entry\n\n### 🎨 Style"
        changelog_entry="$changelog_entry$cat_style"
    fi
    
    if [[ -n "$cat_test" ]]; then
        changelog_entry="$changelog_entry\n\n### 🧪 Tests"
        changelog_entry="$changelog_entry$cat_test"
    fi
    
    if [[ -n "$cat_chore" ]]; then
        changelog_entry="$changelog_entry\n\n### 🔧 Maintenance"
        changelog_entry="$changelog_entry$cat_chore"
    fi
    
    if [[ -n "$cat_other" ]]; then
        changelog_entry="$changelog_entry\n\n### 📝 Autres"
        changelog_entry="$changelog_entry$cat_other"
    fi
    
    # Créer ou mettre à jour le changelog
    if [[ -f "$CHANGELOG_FILE" ]]; then
        log "Mise à jour du CHANGELOG existant..."
        
        # Chercher la ligne [Unreleased]
        if grep -q "## \[Unreleased\]" "$CHANGELOG_FILE"; then
            # Insérer après la section Unreleased
            local line_num=$(grep -n "## \[Unreleased\]" "$CHANGELOG_FILE" | head -1 | cut -d: -f1)
            
            # Créer le nouveau contenu
            head -n $((line_num + 1)) "$CHANGELOG_FILE" > "$TEMP_FILE"
            echo "" >> "$TEMP_FILE"
            echo -e "$changelog_entry" >> "$TEMP_FILE"
            echo "" >> "$TEMP_FILE"
            tail -n +$((line_num + 2)) "$CHANGELOG_FILE" >> "$TEMP_FILE"
            
            mv "$TEMP_FILE" "$CHANGELOG_FILE"
        else
            # Insérer au début
            echo -e "$changelog_entry\n" > "$TEMP_FILE"
            cat "$CHANGELOG_FILE" >> "$TEMP_FILE"
            mv "$TEMP_FILE" "$CHANGELOG_FILE"
        fi
    else
        log "Création d'un nouveau CHANGELOG..."
        cat > "$CHANGELOG_FILE" << EOF
# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Versioning Sémantique](https://semver.org/lang/fr/).

## [Unreleased]

$(echo -e "$changelog_entry")
EOF
    fi
    
    success "CHANGELOG généré avec succès !"
    success "CHANGELOG mis à jour dans $CHANGELOG_FILE"
    
    # Exports pour GitHub Actions
    if [[ -n "$GITHUB_OUTPUT" ]]; then
        echo "changelog-updated=true" >> "$GITHUB_OUTPUT"
        echo "version=$version" >> "$GITHUB_OUTPUT"
    fi
    
    success "Version: $version"
    
    log "Aperçu du changelog:"
    echo "===================="
    if [[ -f "$CHANGELOG_FILE" ]]; then
        # Utiliser head de manière plus robuste
        if command -v head >/dev/null 2>&1; then
            head -n 20 "$CHANGELOG_FILE" 2>/dev/null || {
                log "Impossible d'afficher l'aperçu avec head, utilisation de sed"
                sed -n '1,20p' "$CHANGELOG_FILE" 2>/dev/null || echo "Impossible d'afficher l'aperçu"
            }
        else
            sed -n '1,20p' "$CHANGELOG_FILE" 2>/dev/null || echo "Impossible d'afficher l'aperçu"
        fi
    else
        error "Fichier CHANGELOG.md non trouvé après génération"
        return 1
    fi
    echo "===================="
    echo ""
    
    warning "N'oubliez pas de:"
    echo "1. Réviser le CHANGELOG.md"
    echo "2. Commiter les changements"
    echo "3. Créer le tag: git tag $version"
    echo "4. Pousser: git push origin $version"
    
    log "Fonction generate_changelog terminée avec succès"
    return 0
}

# Fonction principale
main() {
    local from_tag="$1"
    local to_tag="$2"
    local version="$3"
    
    log "🚀 Génération du CHANGELOG pour $PROJECT_NAME"
    log "Début de la génération du changelog..."
    
    # Paramètres par défaut
    if [[ -z "$version" ]]; then
        version="auto"
    fi
    
    # Valider la version si elle n'est pas "auto"
    if [[ "$version" != "auto" ]]; then
        if ! validate_version "$version"; then
            return 1
        fi
    fi
    
    # Générer le changelog
    if generate_changelog "$from_tag" "$to_tag" "$version"; then
        success "Génération du changelog terminée avec succès"
        log "Fonction main terminée avec succès"
        log "Fonction main terminée avec exit code: 0"
        success "Script terminé avec succès"
        return 0
    else
        error "Échec de la génération du changelog"
        return 1
    fi
}

# Nettoyage en cas d'interruption
cleanup() {
    local exit_code=$?
    if [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
        log "Fichier temporaire nettoyé: $TEMP_FILE"
    fi
    if [[ $exit_code -ne 0 ]]; then
        error "Script interrompu avec exit code: $exit_code"
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM

# Vérifier qu'on est dans un repo Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error "Ce script doit être exécuté dans un dépôt Git"
    exit 1
fi

# Exécuter le script
log "Début de l'exécution du script avec arguments: $@"
main "$@"
main_exit_code=$?

log "Fonction main terminée avec exit code: $main_exit_code"
if [[ $main_exit_code -eq 0 ]]; then
    success "Script terminé avec succès"
else
    error "Script terminé avec des erreurs"
fi
exit $main_exit_code