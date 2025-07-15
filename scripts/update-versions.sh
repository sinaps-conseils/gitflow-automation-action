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

# Fonction pour mettre à jour pubspec.yaml (Flutter)
update_pubspec_yaml() {
    local version="$1"
    # Supprimer le 'v' du début
    local version_number="${version#v}"
    
    if [[ -f "pubspec.yaml" ]]; then
        log "Mise à jour de pubspec.yaml"
        
        # Sauvegarde
        cp pubspec.yaml pubspec.yaml.bak
        
        # Mise à jour avec sed
        if sed -i.tmp "s/^version: .*/version: $version_number+1/" pubspec.yaml; then
            rm -f pubspec.yaml.tmp pubspec.yaml.bak
            success "pubspec.yaml mis à jour vers $version_number+1"
        else
            mv pubspec.yaml.bak pubspec.yaml
            error "Échec de la mise à jour de pubspec.yaml"
            return 1
        fi
    else
        warning "pubspec.yaml non trouvé, ignoré"
    fi
}

# Fonction pour mettre à jour pom.xml (Maven)
update_pom_xml() {
    local version="$1"
    # Supprimer le 'v' du début
    local version_number="${version#v}"
    
    if [[ -f "pom.xml" ]]; then
        log "Mise à jour de pom.xml"
        
        # Sauvegarde
        cp pom.xml pom.xml.bak
        
        # Mise à jour avec sed (première occurrence de <version>)
        if sed -i.tmp "0,/<version>/{s/<version>[^<]*<\/version>/<version>$version_number<\/version>/}" pom.xml; then
            rm -f pom.xml.tmp pom.xml.bak
            success "pom.xml mis à jour vers $version_number"
        else
            mv pom.xml.bak pom.xml
            error "Échec de la mise à jour de pom.xml"
            return 1
        fi
    else
        warning "pom.xml non trouvé, ignoré"
    fi
}

# Fonction pour mettre à jour Cargo.toml (Rust)
update_cargo_toml() {
    local version="$1"
    # Supprimer le 'v' du début
    local version_number="${version#v}"
    
    if [[ -f "Cargo.toml" ]]; then
        log "Mise à jour de Cargo.toml"
        
        # Sauvegarde
        cp Cargo.toml Cargo.toml.bak
        
        # Mise à jour avec sed
        if sed -i.tmp "s/^version = .*/version = \"$version_number\"/" Cargo.toml; then
            rm -f Cargo.toml.tmp Cargo.toml.bak
            success "Cargo.toml mis à jour vers $version_number"
        else
            mv Cargo.toml.bak Cargo.toml
            error "Échec de la mise à jour de Cargo.toml"
            return 1
        fi
    else
        warning "Cargo.toml non trouvé, ignoré"
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
    update_pubspec_yaml "$version"
    update_pom_xml "$version"
    update_cargo_toml "$version"
    
    success "Mise à jour des versions terminée pour $version"
    return 0
}

# Exécuter le script
main "$@"
