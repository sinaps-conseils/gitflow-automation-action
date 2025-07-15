#!/bin/bash
set -e

# Script de détection/validation de version pour GitHub Action GitFlow

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}🔍 $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Fonction pour obtenir le dernier tag
get_last_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo ""
}

# Fonction pour calculer la prochaine version
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
    
    # Analyser les commits depuis le dernier tag
    local last_tag=$(get_last_tag)
    local commits
    if [[ -n "$last_tag" ]]; then
        commits=$(git log --oneline "${last_tag}..HEAD" 2>/dev/null || echo "")
    else
        commits=$(git log --oneline HEAD 2>/dev/null || echo "")
    fi
    
    if [[ -z "$commits" ]]; then
        log "Aucun commit depuis $last_tag, version patch par défaut"
        echo "v$major.$minor.$((patch + 1))"
        return
    fi
    
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

# Fonction pour détecter la version depuis le nom de branche
detect_version_from_branch() {
    local branch_name="$GITHUB_HEAD_REF"
    if [[ -z "$branch_name" ]]; then
        branch_name="$GITHUB_REF_NAME"
    fi
    
    if [[ $branch_name =~ ^release/([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        echo "v${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# Fonction principale
main() {
    log "Détection de la version pour ${PROJECT_NAME:-Project}"
    
    local version="$INPUT_VERSION"
    local version_source="manuel"
    
    # Si aucune version spécifiée, essayer de la détecter
    if [[ -z "$version" ]]; then
        # Essayer depuis le nom de branche
        version=$(detect_version_from_branch)
        if [[ -n "$version" ]]; then
            version_source="branche"
        else
            # Calculer automatiquement
            version=$(get_next_version)
            version_source="automatique"
        fi
    fi
    
    # Valider le format de version
    if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "Format de version invalide: $version (attendu: vX.Y.Z)"
        return 1
    fi
    
    # Vérifier qu'on est dans un repo Git
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Ce script doit être exécuté dans un dépôt Git"
        return 1
    fi
    
    # Afficher les informations
    log "Version détectée: $version (source: $version_source)"
    
    # Informations supplémentaires
    local last_tag=$(get_last_tag)
    if [[ -n "$last_tag" ]]; then
        log "Dernière version: $last_tag"
    else
        log "Première version du projet"
    fi
    
    # Exporter la version
    echo "version=$version" >> $GITHUB_OUTPUT
    echo "version-source=$version_source" >> $GITHUB_OUTPUT
    
    success "Version validée: $version"
    return 0
}

# Exécuter le script
main "$@"
