# Linear Agents API — fetched 2026-06-15

## Agent capabilities
- `@mention` in issues and documents
- Issue delegation (as delegate, not assignee)
- Create and reply to comments
- Project membership
- Collaborate on projects and documents

## Supported skills
- Custom task execution based on agent design
- Sample: Weather Bot

## API surface
- OAuth2 with `actor=app` parameter
- GraphQL API for workspace identity
- Webhooks: agent session events, inbox notifications, permission changes
- Agent Activities for emitting responses
- Agent Sessions API for task lifecycle tracking

## Named features
- **Agent Sessions** — auto-created when agent is mentioned/delegated; tracks task lifecycle with visible state
- **Agent Session Events** — webhook notifications triggered by delegation
- **promptContext field** — formats session context (issue details, comments, guidance)
- **Thought activity** — required acknowledgment response within 10 seconds
- **Delegate model** — agents assigned while humans maintain ownership

## Scope requirements
- `app:assignable`, `app:mentionable`
- `customer:read`, `customer:write`
- `initiative:read`, `initiative:write`
