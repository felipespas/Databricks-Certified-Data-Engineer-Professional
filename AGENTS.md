# Repository instructions for agents

These instructions apply to the entire repository.

## Development environment

Before working with remote resources, read the repository-root
`AGENTS.local.md` file for the default development workspace and intended
sign-in account. That file is local-only and ignored by Git.

If it is missing, ask the user for the development environment before remote
actions; do not guess a workspace or account. Local work can continue without
it. Never copy local environment or account details into tracked files,
commits, logs, or responses unless the user explicitly requests it. Do not
force-add the local file to Git.

## Authentication and remote operations

- Reuse an existing authenticated session or an approved interactive sign-in
  flow for the account in `AGENTS.local.md`. If sign-in or MFA requires user interaction, ask
  the user to complete it.
- Before running remote commands, verify that the active workspace host and
  authenticated identity match the local development environment. Do not
  assume that the default CLI profile, browser session, or Azure subscription
  targets the correct workspace.
- If access is unavailable or the active identity does not match, report the
  blocker and request guidance rather than silently using another environment
  or account.
- Never store passwords, access tokens, client secrets, or authenticated session
  data in this repository or include them in logs or responses. Use the
  authentication tool's secure credential storage.
- Do not infer a cluster, SQL warehouse, catalog, schema, storage location, job,
  or pipeline from the workspace URL. Discover the resources needed for the
  task, and ask the user when the intended target is ambiguous.

## Working safely

- Treat this as a shared development environment, not an isolated sandbox.
- This default environment is not blanket authorization to execute notebooks,
  deploy changes, or modify remote resources. Keep remote actions within the
  user's requested scope.
- Obtain explicit confirmation before destructive operations such as dataset
  resets, dropping tables, deleting files, or replacing jobs and pipelines.
- Obtain confirmation before creating or starting compute that incurs cost,
  unless the user has already authorized that action.
- Never switch to production or another workspace without an explicit user
  instruction.
- Preserve the repository's Databricks notebook source format when editing
  notebooks. Validate runtime-dependent behavior in the development workspace
  when access and execution are authorized; local checks alone do not prove
  Databricks runtime compatibility.
- Report what was actually validated and distinguish local checks from remote
  execution. Do not claim workspace access or successful execution without
  verifying it.
