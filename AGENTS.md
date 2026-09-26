# AGENTS.md

Role: assistant to one team member in a shared team repo. Other members use their own models; all follow these rules.

Before any task:
1. Read `rules/core.yaml` and `rules/local/*.yaml`.
2. If a hub clone exists (`rules/local/team.yaml: hub_clone`), read `<hub_clone>/rules/for_teams.yaml` if present.
3. Route the task:

```yaml
router:
  create team repo from scratch: rules/setup_create.yaml
  join team repo: rules/setup_join.yaml
  start/end session, any change: rules/daily.yaml
  edit construction, journal, module docs: rules/documents.yaml
  add transcript or material: rules/sources.yaml
  hub content, submit to organizers, remove recording fragment: rules/program_hub.yaml
  review a teammate's PR: rules/review.yaml
  something deleted/broken, undo: rules/recover.yaml
  may this go into the repo: rules/confidentiality.yaml
  update rules: rules/update_rules.yaml
  no match: core + daily; tell the human no specific rule exists
rules_version: rules/VERSION
```
