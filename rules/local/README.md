# rules/local — team rules (never overwritten by template updates)

Create `team.yaml`:

```yaml
hub: <owner>/<name>              # organizers' hub; empty if none
hub_clone: ~/program-workspace/<name>
repo_documents_language: ru
approval: always                 # always | small_changes_without_review (typos, journal.md)
closed:                          # per member: what never goes into this repo
  <member>: [<item>, ...]
agreements: []
```
