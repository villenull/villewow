---
name: villnext
description: Villenull's "what should we work on next" prompt for an orchestrator already running /vill. Load ONLY when the user explicitly types /villnext. Never load it on your own initiative, and never as a subagent launched by another agent.
disable-model-invocation: true
---

If you are a subagent launched by another agent, stop: this is not for you.
Tell your orchestrator you were given /villnext by mistake and do nothing else.

If you haven't loaded the /vill brief in this session, say so in one line and
stop.

As my orchestrator, select and advance the next useful work toward my
authorized objective under /vill.

1. Work from what you learned in /vill Step 1 and the durable queue. Read more
   only where needed. Reconcile what is actually running before treating any
   task as in progress or launching duplicate work.
2. Build an ordered queue with dependencies and verification. Fill useful
   capacity where the objective supports it, batching disjoint tasks and
   serializing only real conflicts. Don't manufacture work.
3. Give me one short plan in plain English: each task's what, why now, files,
   starting approach, model and effort, and how you'll verify it; what runs
   in parallel versus what waits; completion criteria, budgets, and genuine
   owner-only blockers.
4. If the objective and boundaries are already authorized, announce the plan and
   start without a new approval interview. Launch the first ready worker,
   prepare and launch the next while it runs, and keep filling capacity under
   /vill's pipeline rules. If authority is missing, prepare one batched
   multiple-choice decision with the recommendation first, asking only about
   the missing scope, intent, priority or protected boundary, and keep working
   on what is already authorized meanwhile.
5. Authorization covers implementation, review, repairs, integration and
   further batches toward that objective. Stop when the objective is achieved,
   an explicit budget is exhausted, or everything left needs a decision only I
   can make. Configure a recovery heartbeat only when explicitly authorized,
   as described in /vill.