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
PROJECT_NAME="Showroom"

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
    git describe --tags --abbrev=0 2>/dev/null || echo ""
}

# Fonction pour obtenir la prochaine version
get_next_version() {
    local current_version=$(get_last_tag)
    if [[ -z "$current_version" ]]; then
        echo "v1.0.0"
        return
    fi
    
    # Supprimer le 'v' du début
    current_version=${current_version#v}
    
    # Séparer major.minor.patch
    IFS='.' read -r major minor patch <<< "$current_version"
    
    # Analyser les commits depuis le dernier tag pour déterminer le type de version
    local commits=$(git log --oneline $(get_last_tag)..HEAD 2>/dev/null || git log --oneline)
    
    local has_breaking=false
    local has_feat=false
    local has_fix=false
    
    while IFS= read -r commit; do
        if [[ $commit =~ :boom:|:fire: ]] || [[ $commit =~ "BREAKING CHANGE" ]]; then
            has_breaking=true
        elif [[ $commit =~ :sparkles:|:rocket:|:tada: ]] || [[ $commit =~ " feat:" ]]; then
            has_feat=true
        elif [[ $commit =~ :bug:|:ambulance:|:adhesive_bandage: ]] || [[ $commit =~ " fix:" ]]; then
            has_fix=true
        fi
    done <<< "$commits"
    
    # Déterminer le type de version
    if $has_breaking; then
        echo "v$((major + 1)).0.0"
    elif $has_feat; then
        echo "v$major.$((minor + 1)).0"
    elif $has_fix; then
        echo "v$major.$minor.$((patch + 1))"
    else
        echo "v$major.$minor.$((patch + 1))"
    fi
}

# Fonction pour catégoriser les commits
categorize_commit() {
    local commit="$1"
    
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
    
    # Obtenir les commits
    local git_range
    if [[ -n "$from_tag" ]]; then
        git_range="$from_tag..HEAD"
    else
        git_range="HEAD"
    fi
    
    log "Recherche des commits avec range: $git_range"
    
    # Récupérer les commits
    local commits=$(git log --oneline --no-merges $git_range 2>/dev/null || echo "")
    
    if [[ -z "$commits" ]]; then
        warning "Aucun commit trouvé pour générer le changelog"
        return 0
    fi
    
    log "Nombre de commits trouvés: $(echo "$commits" | wc -l)"
    
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
        if [[ -n "$commit" ]]; then
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
    
    # Créer le fichier temporaire
    if ! touch "$TEMP_FILE"; then
        error "Impossible de créer le fichier temporaire: $TEMP_FILE"
        return 1
    fi
    
    # Générer le changelog
    {
        echo "# Changelog"
        echo ""
        echo "Toutes les modifications notables de ce projet seront documentées dans ce fichier."
        echo ""
        echo "Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),"
        echo "et ce projet adhère au [Versioning Sémantique](https://semver.org/lang/fr/)."
        echo ""
        
        # Ajouter la nouvelle version
        echo "## [$version] - $(get_current_date)"
        echo ""
        
        # Ajouter les catégories non vides
        local categories_order=(
            "breaking:💥 Changements incompatibles"
            "feat:✨ Nouvelles fonctionnalités"
            "fix:🐛 Corrections"
            "perf:⚡ Performance"
            "security:🔒 Sécurité"
            "refactor:♻️ Refactoring"
            "docs:📚 Documentation"
            "style:🎨 Style"
            "test:🧪 Tests"
            "chore:🔧 Maintenance"
            "other:📝 Autres"
        )
        
        for cat_info in "${categories_order[@]}"; do
            local cat_key="${cat_info%:*}"
            local cat_title="${cat_info#*:}"
            local cat_content=""
            
            # Récupérer le contenu selon la catégorie
            case "$cat_key" in
                "breaking") cat_content="$cat_breaking" ;;
                "feat") cat_content="$cat_feat" ;;
                "fix") cat_content="$cat_fix" ;;
                "perf") cat_content="$cat_perf" ;;
                "security") cat_content="$cat_security" ;;
                "refactor") cat_content="$cat_refactor" ;;
                "docs") cat_content="$cat_docs" ;;
                "style") cat_content="$cat_style" ;;
                "test") cat_content="$cat_test" ;;
                "chore") cat_content="$cat_chore" ;;
                "other") cat_content="$cat_other" ;;
            esac
            
            if [[ -n "$cat_content" ]]; then
                echo "### $cat_title"
                echo ""
                echo -e "$cat_content"
                echo ""
            fi
        done
        
        # Ajouter l'ancien changelog s'il existe
        if [[ -f "$CHANGELOG_FILE" ]]; then
            # Trouver la ligne après l'en-tête et ajouter le contenu existant
            sed -n '/^## \[/,$p' "$CHANGELOG_FILE" 2>/dev/null || true
        fi
    } > "$TEMP_FILE"
    
    # Vérifier que le fichier temporaire a été créé correctement
    if [[ ! -f "$TEMP_FILE" ]] || [[ ! -s "$TEMP_FILE" ]]; then
        error "Erreur lors de la création du fichier temporaire"
        return 1
    fi
    
    # Remplacer le fichier
    if ! mv "$TEMP_FILE" "$CHANGELOG_FILE"; then
        error "Impossible de remplacer le fichier CHANGELOG.md"
        return 1
    fi
    
    success "CHANGELOG généré avec succès !"
    return 0
}

# Fonction principale
main() {
    local from_tag="$1"
    local to_tag="$2"
    local version="$3"
    
    log "🚀 Génération du CHANGELOG pour $PROJECT_NAME"
    
    # Si aucune version spécifiée, calculer la prochaine
    if [[ -z "$version" ]]; then
        version=$(get_next_version)
        log "Version calculée automatiquement: $version"
    fi
    
    # Générer le changelog
    log "Début de la génération du changelog..."
    generate_changelog "$from_tag" "$to_tag" "$version"
    local generate_exit_code=$?
    
    if [[ $generate_exit_code -ne 0 ]]; then
        error "Erreur lors de la génération du changelog (exit code: $generate_exit_code)"
        return $generate_exit_code
    fi
    
    echo ""
    success "CHANGELOG mis à jour dans $CHANGELOG_FILE"
    success "Version: $version"
    
    # Afficher un aperçu
    echo ""
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
    
    log "Fonction main terminée avec succès"
    return 0
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
    exit 0
else
    error "Script terminé avec erreur (exit code: $main_exit_code)"
    exit $main_exit_code
fi
