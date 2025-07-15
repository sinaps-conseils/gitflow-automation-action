#!/bin/bash
set -e

# Script de commit des changements pour GitHub Action GitFlow

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}💾 $1${NC}"
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

# Fonction pour obtenir la branche courante
get_current_branch() {
    # Essayer plusieurs méthodes pour obtenir la branche
    local branch=""
    
    # Méthode 1: GITHUB_HEAD_REF (pour les PR)
    if [[ -n "$GITHUB_HEAD_REF" ]]; then
        branch="$GITHUB_HEAD_REF"
        log "Branche détectée via GITHUB_HEAD_REF: $branch"
    
    # Méthode 2: git branch --show-current
    elif command -v git >/dev/null 2>&1; then
        branch=$(git branch --show-current 2>/dev/null || echo "")
        if [[ -n "$branch" ]]; then
            log "Branche détectée via git branch --show-current: $branch"
        fi
    fi
    
    # Méthode 3: git rev-parse --abbrev-ref HEAD
    if [[ -z "$branch" ]] && command -v git >/dev/null 2>&1; then
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
            log "Branche détectée via git rev-parse: $branch"
        else
            branch=""
        fi
    fi
    
    echo "$branch"
}

# Fonction principale
main() {
    local version="$VERSION"
    
    if [[ -z "$version" ]]; then
        error "Variable VERSION manquante"
        return 1
    fi
    
    log "Préparation du commit pour $version"
    
    # Configuration Git
    git config --global user.name "${GITHUB_ACTOR:-github-actions}"
    git config --global user.email "${GITHUB_ACTOR:-github-actions}@users.noreply.github.com"
    
    # Ajouter les fichiers modifiés
    log "Ajout des fichiers modifiés"
    git add . || true
    
    # Vérifier s'il y a des changements à commiter
    if git diff --cached --quiet; then
        log "Aucun changement à commiter"
        echo "committed=false" >> $GITHUB_OUTPUT
        return 0
    fi
    
    # Créer le commit
    local commit_message=":bookmark: release: automated preparation for $version"
    
    log "Commit des changements: $commit_message"
    if git commit -n -m "$commit_message"; then
        success "Changements commités avec succès"
        echo "committed=true" >> $GITHUB_OUTPUT
        
        # Obtenir la branche courante
        local current_branch=$(get_current_branch)
        
        if [[ -n "$current_branch" ]]; then
            log "Push des changements vers $current_branch"
            
            # Vérifier que la branche locale existe
            if git show-ref --verify --quiet "refs/heads/$current_branch"; then
                log "Branche locale $current_branch confirmée"
                
                # Essayer de push
                if git push origin "$current_branch"; then
                    success "Changements poussés vers $current_branch"
                else
                    warning "Échec du push vers $current_branch"
                    
                    # Essayer de push avec --force-with-lease (plus sûr)
                    log "Tentative de push avec --force-with-lease"
                    if git push --force-with-lease origin "$current_branch"; then
                        success "Changements poussés avec --force-with-lease"
                    else
                        error "Échec du push même avec --force-with-lease"
                        warning "Commit réussi localement, mais push échoué"
                    fi
                fi
            else
                warning "Branche locale $current_branch non trouvée"
                log "Tentative de push vers HEAD"
                if git push origin HEAD; then
                    success "Changements poussés vers HEAD"
                else
                    warning "Échec du push vers HEAD"
                fi
            fi
        else
            warning "Impossible de déterminer la branche courante"
            log "Variables d'environnement:"
            log "  GITHUB_HEAD_REF: ${GITHUB_HEAD_REF:-'non défini'}"
            log "  GITHUB_REF: ${GITHUB_REF:-'non défini'}"
            log "  GITHUB_REF_NAME: ${GITHUB_REF_NAME:-'non défini'}"
            
            # Essayer de push vers HEAD comme fallback
            log "Tentative de push vers HEAD comme fallback"
            if git push origin HEAD; then
                success "Changements poussés vers HEAD"
            else
                warning "Échec du push vers HEAD aussi"
            fi
        fi
    else
        error "Échec du commit"
        echo "committed=false" >> $GITHUB_OUTPUT
        return 1
    fi
    
    return 0
}

# Exécuter le script
main "$@"