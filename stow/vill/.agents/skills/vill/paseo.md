# /vill in Paseo

Load the paseo skill before using the harness and follow it, except where the
brief overrides it. Workers are Paseo agents; you reach Paseo through its MCP
tools or the `paseo` CLI.

## Launching workers
- `create_agent` in THIS workspace (omit `workspaceId`), provider
  `opencode/opencode-go/<free-model-id>`. Paseo launches any allowed free
  model directly, so pick the model per task.
- Never create a workspace or worktree.

## Waiting
- Leave `notifyOnFinish` on and end your turn; the notification wakes you.
  Never poll `list_agents`, use `sleep`, or create heartbeats to check on work.

## Closing out a worker
- `archive_agent` once you've accepted its result.
- Before ending a turn, `list_agents` and archive every finished one.

## Permissions and questions
- Resolve permission requests through Paseo's permission mechanism and confirm
  the response went through. When I approve something, unblock the worker
  there, not just in chat.

## Naming yourself
- Project name: the Paseo project whose path matches your working directory
  (`paseo project ls`).
- Agent: your ID is `$PASEO_AGENT_ID`; if that's unset (Codex, OpenCode), use
  `paseo ls` to find the one running agent in this directory whose name
  mentions /vill. `paseo agent update <id> --name "<Project> - Orchestrator"`.
- Workspace: the one workspace whose path is your working directory
  (`paseo workspace ls`); `paseo workspace rename <id> "<Project> - Main"`.
  If several match, skip it.
- Check both names stuck; if Paseo overwrote one, rename it once more.

## Handing off
- Use the paseo-handoff skill to start a fresh orchestrator on your model.
