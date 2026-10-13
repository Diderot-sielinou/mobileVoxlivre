# Points d'entrée du projet (calque de cinaf-engine-infra). `make help`.
ENV ?= dev
# Plancher de couverture des lignes (%) : monte avec les fonctionnalités.
COVERAGE_FLOOR ?= 95

.PHONY: help hooks get format format-check analyze test coverage-gate check run build-apk

help: ## Liste les commandes
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | sed 's/:.*## /\t/'

hooks: ## Active les hooks git du dépôt (à faire une fois après le clone)
	git config core.hooksPath tool/hooks

get: ## Installe les dépendances
	flutter pub get

format: ## Formate tout le code
	dart format lib test

format-check: ## Échoue si un fichier n'est pas formaté (CI)
	dart format --set-exit-if-changed lib test

analyze: ## Analyse stricte, 0 avertissement
	flutter analyze --fatal-infos

test: ## Tests avec couverture
	flutter test --coverage

coverage-gate: ## Échoue sous le plancher de couverture
	tool/coverage_gate.sh $(COVERAGE_FLOOR)

check: format-check analyze test coverage-gate ## Ce que vérifie la CI

run: ## Lance l'app (ENV=dev par défaut, config/$(ENV).json)
	flutter run --dart-define-from-file=config/$(ENV).json

build-apk: ## APK de l'environnement ENV
	flutter build apk --dart-define-from-file=config/$(ENV).json
