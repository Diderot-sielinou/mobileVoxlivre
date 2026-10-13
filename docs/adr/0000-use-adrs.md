# 0000. Consigner les décisions d'architecture (ADR)

- Statut : accepted
- Date : 2026-10-12

## Contexte

L'app est développée par une seule personne avec l'aide d'agents IA, en
parallèle du backend qui tient déjà ses décisions en ADR (0000 → 0028). Sans
trace écrite, un choix (gestion d'état, stockage, navigation) se rediscute à
chaque session.

## Décision

Toute décision structurante est écrite **avant** le code dans
`docs/adr/NNNN-titre.md` : contexte, options, décision, conséquences. Une
décision remplacée n'est pas effacée : un nouvel ADR la remplace et le dit.

## Conséquences

- `AGENTS.md` renvoie aux ADR ; un agent qui trouve un choix étrange lit l'ADR
  avant de le changer.
- Numérotation propre à l'app mobile (indépendante du backend).
