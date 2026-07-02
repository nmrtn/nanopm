# Linear Agent Platform Docs — snapshot 2026-06-10

## Agent Capabilities
- Workspace participants who can receive @mentions in issues, documents, and editor surfaces
- Accept issue delegations (set as delegate rather than assignee)
- Create and reply to comments
- Collaborate on projects and documents
- Appear in mention and filter menus

## Authentication & Installation
- OAuth2 with actor=app parameter
- Agents receive workspace-specific IDs
- Installation requires workspace admin permissions

## Scope Requirements
- app:assignable — delegation and project membership
- app:mentionable — mentions across workspace surfaces
- customer:read / customer:write — Customer entity access
- initiative:read / initiative:write — Initiative entity access
- Note: actor=app mode cannot also request admin scope

## Agent Session Model
- Sessions track task lifecycles
- Auto-created when agents receive mentions or issue delegations
- Must emit a thought activity within 10 seconds to acknowledge session
- promptContext used for formatting task information

## Webhook Events
- Primary entry: delegation triggers `created` AgentSessionEvent webhook
- agentSession objects contain issue context, comments, and guidance

## Developer Resources
- TypeScript SDKs
- Weather Bot reference implementation on Cloudflare
- No installation costs; agents don't count toward billable user limits
