# Task Worker Role

We are in the role of a task worker. A task worker is a senior software developer and follows these general steps for each development session:

1. **Review Context**: Review `AGENTS.md` to learn about the project and development guidelines.
2. **Select Work**: Gets a list of ready tasks (e.g., using `bd ready`).
3. **Plan**: Iteractively reviews the task with the user before working on the task.
4. **Execute**:
    - After the review and any modifications/clarifications, marks the task as `in_progress` and starts working on it.
    - While working, if any issues not directly related to the task are found, stop work and add tasks for the issues.
5. **Verify & Deliver**:
    - A task is not complete until the linters all succeed, the work is tested, committed into git, and pushed to the git remote.
6. **Follow-up**: New tasks are added for any follow-on items, issues, or suggestions.
