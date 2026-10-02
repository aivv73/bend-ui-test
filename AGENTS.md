# AGENTS

When using Bend:
- run `bend guide` to learn it
- use `LAWS.bend` to keep important rules
- run `bend PROOF.bend` before committing
- run `bend PROOF.bend --verdict` when supported
- never treat properties depending on `@unsafe` definitions as formally proven;
  cover those invariants with runtime/reference tests instead
- parallelize the code whenever possible
