# Repository-wide Copilot instructions

Read and follow [AGENTS.md](../AGENTS.md) before working in this repository.
It defines authentication checks and remote-operation safety requirements,
and directs agents to the Git-ignored repository-root `AGENTS.local.md` file
for the development workspace and intended sign-in account. Keep those local
details out of tracked files.

Do not assume that the current browser session or CLI profile targets that
workspace or account. Verify both before remote actions, and report access
blockers rather than silently switching environments.
