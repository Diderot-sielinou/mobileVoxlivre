# Points d'entrée du projet (calque de cinaf-engine-infra). `make help`.
ENV ?= dev

.PHONY: help hooks get format analyze test check run build-apk

help: ## Liste les commandes
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | sed 's/:.*## /\t/'

hooks: ## Active les hooks git du dépôt (à faire une fois après le clone)
	git config core.hooksPath tool/hooks

get: ## Installe les dépendances
	flutter pub get

format: ## Formate tout le code
	dart format lib test

analyze: ## Analyse stricte, 0 avertissement
	flutter analyze --fatal-infos

test: ## Tests avec couverture
	flutter test --coverage

check: analyze test ## Ce que vérifie la CI

run: ## Lance l'app (ENV=dev par défaut, config/$(ENV).json)
	flutter run --dart-define-from-file=config/$(ENV).json

build-apk: ## APK de l'environnement ENV
	flutter build apk --dart-define-from-file=config/$(ENV).json
