#!/bin/bash
set -e

# Fonction pour valider le format de version
validate_version() {
    local version=$1
    # Accepter les formats : vX.Y.Z, vX.Y.Z-suffix, X.Y.Z, X.Y.Z-suffix
    if [[ $version =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
        return 0
    else
        return 1
    fi
}

# Fonction pour normaliser la version (ajouter v si manquant)
normalize_version() {
    local version=$1
    if [[ $version =~ ^[0-9] ]]; then
        echo "v$version"
    else
        echo "$version"
    fi
}

# Fonction pour détecter la version automatiquement
detect_auto_version() {
    local current_version=""
    
    # Essayer de récupérer depuis package.json
    if [ -f package.json ]; then
        current_version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' package.json | grep -o '[0-9][^"]*')
    fi
    
    # Si pas trouvé, essayer depuis app.json
    if [ -z "$current_version" ] && [ -f app.json ]; then
        current_version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' app.json | grep -o '[0-9][^"]*')
    fi
    
    # Si pas trouvé, essayer depuis le dernier tag git
    if [ -z "$current_version" ]; then
        current_version=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.0.0")
    fi
    
    # Incrémenter la version patch
    local major=$(echo $current_version | cut -d. -f1)
    local minor=$(echo $current_version | cut -d. -f2)
    local patch=$(echo $current_version | cut -d. -f3 | cut -d- -f1)  # Enlever suffix si présent
    
    patch=$((patch + 1))
    echo "v$major.$minor.$patch"
}

# Fonction pour détecter depuis le nom de la branche
detect_branch_version() {
    local branch_name=$(git branch --show-current 2>/dev/null || echo "main")
    
    # Chercher un pattern de version dans le nom de la branche
    if [[ $branch_name =~ (release|hotfix)/(v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?) ]]; then
        local version="${BASH_REMATCH[2]}"
        normalize_version "$version"
    else
        echo "Impossible de détecter la version depuis la branche: $branch_name" >&2
        detect_auto_version
    fi
}

# Main logic
VERSION_INPUT="${INPUT_VERSION:-auto}"

echo "🔍 Détection de version avec input: $VERSION_INPUT"

case $VERSION_INPUT in
    "auto")
        VERSION=$(detect_auto_version)
        echo "Version détectée automatiquement: $VERSION"
        ;;
    "branch")
        VERSION=$(detect_branch_version)
        echo "Version détectée depuis la branche: $VERSION"
        ;;
    *)
        # Version manuelle - normaliser et valider
        VERSION=$(normalize_version "$VERSION_INPUT")
        if validate_version "$VERSION"; then
            echo "Version manuelle validée: $VERSION"
        else
            echo "❌ Format de version invalide: $VERSION_INPUT" >&2
            echo "Formats acceptés: vX.Y.Z, vX.Y.Z-suffix, X.Y.Z, X.Y.Z-suffix" >&2
            echo "Exemples: v1.0.0, v1.0.0-test, v1.0.0-alpha.1, v1.0.0-beta" >&2
            exit 1
        fi
        ;;
esac

# Vérifier que la version finale est valide
if ! validate_version "$VERSION"; then
    echo "❌ Version finale invalide: $VERSION" >&2
    exit 1
fi

echo "✅ Version finale: $VERSION"

# Exporter la version pour les étapes suivantes
echo "version=$VERSION" >> $GITHUB_OUTPUT

# Export pour les scripts suivants
export NEW_VERSION="$VERSION"