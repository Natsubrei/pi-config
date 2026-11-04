# Agent Instructions

## Language and wording

- Reply in Chinese. Code, comments, and git history follow the repository language.
- Correct lexical and grammatical errors in the user's English without restating the whole message. If the intended meaning is ambiguous, ask the user.
- No odd metaphors or analogies. Say the thing plainly.
- Define jargon, and spell out every abbreviation and acronym in full, at its first mention. Then keep one term for one concept.
- Write in the style of Simplified Technical English, the ASD-STE100 standard: put the answer first, one idea in each sentence, active voice, no repetition of the question, no closing summary. Apply these rules to Chinese replies too.
- Simplifying means shorter sentences, not fewer facts. Keep every fact, number, condition, and uncertainty from the source. If you are not sure, say so in one plain sentence.

## Code and history

- Do not run `git commit`, `git push`, or any other command that writes to repository history unless the user explicitly asks for it.
- Write a comment only when deleting it would make the next reader decide something wrong; everything else belongs in the commit message.

## Quality

- A check counts only when it ran. Report the commands and what stays uncovered. Without a linter, type checker, or test runner, state the gap instead of adding scaffolding.
- A documentation or configuration change still needs a stated way to check it.
- Never delete, skip, or weaken tests to pass. Every test asserts. Cover boundary values, invalid input, and state transitions; coverage is not correctness.
- Keep core logic in pure functions. Pass time, randomness, and network in as parameters so that runs replay.
- Fix bugs test-first: the regression test fails before the fix and stays in the repository.
- Test modules through their own interfaces; use differential testing against a reference implementation, and fuzzing where the input space is large.

## Parallel work

- Split independent tasks across subagents; keep work that shares state in one session.
- When subagents write code at the same time, give each its own git worktree, so that they do not edit the same files.
- The main agent reviews each subagent's diff and merges the work into the main worktree without committing; subagents never merge into each other. Treat a claimed completion as unverified until reviewed. Committing the result still needs the user's explicit request.

## User interface

- When writing UI, avoid unnecessary secondary labels and descriptions. Let the layout do the explaining.
