---
name: villnext
description: Villenull's "what should we work on next" prompt for a Paseo orchestrator already running /vill. Load ONLY when the user explicitly types /villnext. Never load it on your own initiative, and never as a subagent launched by another agent.
disable-model-invocation: true
---

If you are a subagent launched by another agent, stop: this is not for you.
Tell your orchestrator you were given /villnext by mistake and do nothing else.

If you haven't loaded the /vill brief in this session, say so in one line and
stop.

As my orchestrator, select and advance the next useful work toward my authorized
objective under /vill.

1. Work from what you learned in /vill Step 1 and the durable queue. Read more
   only where needed. Reconcile existing workers and resource reservations
   before treating any task as running or launching duplicate work.
2. Build an ordered queue with dependencies, verification, and enough ready work
   to sustain a long autonomous run when the objective supports it. Favor
   disjoint tasks on allowed free models. Use serial work where dependencies or
   exclusive resources require it. Do not manufacture work to fill twelve hours.
3. Give me one short plan in plain English:
   - Each task: what it is, why now, files, starting technical approach, model
     and supported effort level, and how you will verify it.
   - Which tasks run in parallel, which wait, and their execution order.
   - Completion criteria, applicable budgets, and genuine owner-only blockers.
4. If the objective and boundaries are already authorized, announce the plan and
   start without a new approval interview. If authority is missing, prepare one
   batched multiple-choice decision with the recommendation first, asking only
   about the missing scope, intent, priority, or protected boundary. Continue
   work already authorized while awaiting that decision.
5. Authorization covers necessary implementation, review, repairs, integration,
   and subsequent batches toward that objective. Batch completion is a
   checkpoint, not an approval gate. Follow /vill's authority, worker cleanup,
   and execution checks throughout. Preserve the queue and authority across
   handoff; stop when the objective is achieved, an explicit budget is exhausted,
   or all remaining useful work needs an owner decision. Configure a recovery
   heartbeat only when explicitly authorized, as described in /vill.
