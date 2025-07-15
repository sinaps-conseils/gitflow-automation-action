# 🚀 GitFlow Automation Action

Une GitHub Action personnalisée pour automatiser le workflow GitFlow avec génération de changelog et gestion des versions.

## 🎯 Fonctionnalités

- ✅ **Détection automatique de version** depuis la branche ou calcul intelligent
- ✅ **Mise à jour multi-plateforme** (package.json, app.json, pubspec.yaml, pom.xml, Cargo.toml)
- ✅ **Génération de changelog** avec catégorisation des commits
- ✅ **Support multi-package-manager** (npm, yarn, pnpm)
- ✅ **Tests et formatage** automatiques
- ✅ **Génération de documentation** optionnelle
- ✅ **Commit automatique** des changements

## 🔧 Utilisation

### Utilisation Basique

```yaml
- name: 🚀 Prepare Release
  uses: ./.github/actions/gitflow-automation
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Utilisation Avancée

```yaml
- name: 🚀 Prepare Release
  uses: ./.github/actions/gitflow-automation
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    version: 'v2.3.0'              # Version spécifique (optionnel)
    node-version: '18'             # Version Node.js (défaut: 18)
    package-manager: 'npm'         # npm, yarn, ou pnpm (défaut: npm)
    project-name: 'Mon Projet'    # Nom du projet (défaut: Project)
    run-tests: 'true'              # Exécuter les tests (défaut: true)
    format-code: 'true'            # Formater le code (défaut: true)
    generate-docs: 'true'          # Générer la doc (défaut: true)
    commit-changes: 'true'         # Commiter les changements (défaut: true)
```

## 📋 Inputs

| Input | Description | Requis | Défaut |
|-------|-------------|--------|--------|
| `github-token` | Token GitHub pour les opérations Git et API | ✅ | - |
| `version` | Version à créer (format vX.Y.Z) | ❌ | Auto-détectée |
| `node-version` | Version de Node.js à utiliser | ❌ | `18` |
| `package-manager` | Package manager (npm, yarn, pnpm) | ❌ | `npm` |
| `project-name` | Nom du projet pour les messages | ❌ | `Project` |
| `run-tests` | Exécuter les tests | ❌ | `true` |
| `format-code` | Formater le code | ❌ | `true` |
| `generate-docs` | Générer la documentation | ❌ | `true` |
| `commit-changes` | Commiter les changements | ❌ | `true` |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `version` | Version créée ou utilisée |
| `changelog-updated` | Indique si le changelog a été mis à jour |
| `changes-committed` | Indique si des changements ont été commités |
| `version-code` | Nouveau versionCode (pour React Native/Expo) |

## 🎭 Détection de Version

L'action détecte automatiquement la version selon cette priorité :

1. **Input manuel** : Version spécifiée dans `version`
2. **Branche release** : Extrait depuis `release/X.Y.Z`
3. **Calcul automatique** : Analyse les commits pour déterminer le type de version
   - 💥 **Breaking changes** → Version majeure
   - ✨ **Features** → Version mineure  
   - 🐛 **Fixes** → Version patch

## 📝 Génération de Changelog

Le changelog est généré automatiquement avec catégorisation :

- **💥 Changements incompatibles** (:boom:, :fire:, BREAKING CHANGE)
- **✨ Nouvelles fonctionnalités** (:sparkles:, :rocket:, :tada:, feat:)
- **🐛 Corrections** (:bug:, :ambulance:, :adhesive_bandage:, fix:)
- **⚡ Performance** (:zap:, perf:)
- **🔒 Sécurité** (:lock:, security:)
- **♻️ Refactoring** (:recycle:, refactor:)
- **📚 Documentation** (:memo:, :bulb:, docs:)
- **🎨 Style** (:art:, :lipstick:, style:)
- **🧪 Tests** (:white_check_mark:, :test_tube:, test:)
- **🔧 Maintenance** (:wrench:, :package:, :arrow_up:, chore:, build:, ci:)

## 🗂️ Fichiers Supportés

L'action met à jour automatiquement les fichiers de version selon le type de projet :

- **Node.js/React** : `package.json`
- **React Native/Expo** : `app.json` (version + versionCode)
- **Flutter** : `pubspec.yaml`
- **Maven/Java** : `pom.xml`
- **Rust** : `Cargo.toml`

## 🔄 Workflow Exemple

```yaml
name: 🚀 Release Automation
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main]

jobs:
  prepare-release:
    if: startsWith(github.head_ref, 'release/')
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.head_ref }}
          fetch-depth: 0
      
      - name: 🚀 Prepare Release
        uses: ./.github/actions/gitflow-automation
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          project-name: 'Mon Projet'
          package-manager: 'npm'
```

## 🛠️ Développement

### Structure

```
.github/actions/gitflow-automation/
├── action.yml                    # Configuration de l'action
├── README.md                     # Documentation
└── scripts/
    ├── detect-version.sh         # Détection de version
    ├── update-versions.sh        # Mise à jour des fichiers
    ├── generate-changelog.sh     # Génération du changelog
    └── commit-changes.sh         # Commit des changements
```

### Contribution

1. Modifier les scripts dans `scripts/`
2. Tester avec un workflow local
3. Mettre à jour la documentation
4. Créer une PR avec les changements

---

**Créé avec ❤️ par SINAPS Conseils**
