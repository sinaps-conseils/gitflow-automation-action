#!/bin/bash
set -e

# Script de mise à jour des versions pour GitHub Action GitFlow

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}🔄 $1${NC}"
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

# Fonction pour mettre à jour package.json
update_package_json() {
    local version="$1"
    # Supprimer le 'v' du début pour package.json
    local version_number="${version#v}"
    
    if [[ -f "package.json" ]]; then
        log "Mise à jour de package.json vers $version_number"
        
        # Sauvegarde
        cp package.json package.json.bak
        
        # Mise à jour avec sed (compatible multi-plateforme)
        if sed -i.tmp "s/\"version\": \"[^\"]*\"/\"version\": \"$version_number\"/" package.json; then
            rm -f package.json.tmp package.json.bak
            success "package.json mis à jour vers $version_number"
        else
            mv package.json.bak package.json
            error "Échec de la mise à jour de package.json"
            return 1
        fi
    else
        warning "package.json non trouvé, ignoré"
    fi
}

# Fonction pour mettre à jour app.json (React Native/Expo)
update_app_json() {
    local version="$1"
    # Supprimer le 'v' du début
    local version_number="${version#v}"
    
    if [[ -f "app.json" ]]; then
        log "Mise à jour de app.json"
        
        # Sauvegarde
        cp app.json app.json.bak
        
        # Mettre à jour la version
        if sed -i.tmp "s/\"version\": \"[^\"]*\"/\"version\": \"$version_number\"/" app.json; then
            # Incrémenter le versionCode
            local current_version_code=$(grep -o '"versionCode": [0-9]*' app.json | grep -o '[0-9]*' || echo "1")
            local new_version_code=$((current_version_code + 1))
            
            if sed -i.tmp "s/\"versionCode\": [0-9]*/\"versionCode\": $new_version_code/" app.json; then
                rm -f app.json.tmp app.json.bak
                success "app.json mis à jour vers $version_number (versionCode: $new_version_code)"
                echo "version-code=$new_version_code" >> $GITHUB_OUTPUT
            else
                mv app.json.bak app.json
                error "Échec de la mise à jour du versionCode"
                return 1
            fi
        else
            mv app.json.bak app.json
            error "Échec de la mise à jour de app.json"
            return 1
        fi
    else
        warning "app.json non trouvé, ignoré"
        echo "version-code=0" >> $GITHUB_OUTPUT
    fi
}

# Fonction principale
main() {
    local version="$VERSION"
    
    if [[ -z "$version" ]]; then
        error "Variable VERSION manquante"
        return 1
    fi
    
    log "Mise à jour des versions vers $version"
    
    # Mettre à jour les différents fichiers selon le type de projet
    update_package_json "$version"
    update_app_json "$version"
    
    success "Mise à jour des versions terminée pour $version"
    return 0
}

# Exécuter le script
main "$@"
