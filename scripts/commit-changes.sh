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

# Fonction principale
main() {
    local version="$VERSION"
    
    if [[ -z "$version" ]]; then
        error "Variable VERSION manquante"
        return 1
    fi
    
    log "Préparation du commit pour $version"
    
    # Configuration Git
    git config --global user.name "${GITHUB_ACTOR}"
    git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
    
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
        
        # Pousser les changements si on est sur une branche
        if [[ -n "$GITHUB_HEAD_REF" ]]; then
            log "Push des changements vers $GITHUB_HEAD_REF"
            if git push origin "$GITHUB_HEAD_REF"; then
                success "Changements poussés vers $GITHUB_HEAD_REF"
            else
                warning "Échec du push, mais commit réussi"
            fi
        else
            log "Pas de branche HEAD détectée, pas de push"
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
