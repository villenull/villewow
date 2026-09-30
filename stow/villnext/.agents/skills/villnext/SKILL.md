---
name: villnext
description: Villenull's "what should we work on next" prompt for an orchestrator already running /vill in Orca. Load ONLY when the user explicitly types /villnext. Never load it on your own initiative, and never as a subagent or worker launched by another agent.
disable-model-invocation: true
---

If you are a subagent or worker launched by another agent, stop: this is not
for you. Tell whoever launched you that you were given /villnext by mistake and
do nothing else.

If you haven't loaded the /vill brief in this session, say so in one line and
stop.

As my orchestrator, propose what we should work on now.

1. Work from what you already learned in /vill Step 2. Read more only where a
   proposal needs it, token-conservatively.
2. Favor work that can run in parallel on the free models Orca can launch
   (/vill's orca.md says which): tasks with disjoint files, clear
   scope, and a way to verify them. Serial work is fine where it's genuinely
   needed; say why.
3. Give me one short plan in plain English:
   - Each task: what it is, why now, the files it touches, which model and
     effort level, and how you'll verify it.
   - Which tasks run in parallel, which wait on others, and in what order.
   - Anything blocked on me.
4. Then ask me, in one batched multiple-choice interview, whether to go ahead
   (recommended option first), plus any questions you genuinely have about
   scope, intent, or priority.
5. Don't launch any worker until I approve. After that, run the plan under
   the /vill brief and its orca.md.
