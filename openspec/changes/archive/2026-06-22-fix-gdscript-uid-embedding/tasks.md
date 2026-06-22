# Tasks: fix-gdscript-uid-embedding

## Implementation Checklist

- [x] **T1** — Audit all `.gd.uid` sidecar files  
  Collect every `.uid` sidecar file across the project and map each to its corresponding `.gd` file.  
  _Validation: 38 script/UID pairs identified._

- [x] **T2** — Prepend UID comment to each `.gd` file  
  Add `# uid://...` as line 1 of every `.gd` file, using the value from its sidecar file.  
  _Validation: First line of each script matches `# uid://...` pattern; no existing code displaced._

- [x] **T3** — Manual verification  
  Reopen project in Godot 4.7; confirm no "invalid UID" warnings appear in the output log.
