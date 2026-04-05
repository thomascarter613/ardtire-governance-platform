# Out of Scope

The following are explicitly out of scope for the Ardtire Governance Platform.
These exclusions are deliberate and should not be revisited without a formal ADR.

| Item | Reason |
|---|---|
| Native mobile applications | Web-first is sufficient; native adds significant operational burden |
| Public SaaS multi-tenancy | Platform is single-tenant by institutional design |
| Real-time chat as a core product surface | Deliberation is structured and asynchronous by design |
| External federation between sovereign organizations | No current requirement; adds significant complexity |
| AI-driven governance decisioning | Human deliberation and vote is the constitutional authority |
| Cryptocurrency or blockchain voting | No institutional requirement; adds operational risk |
| Broad social-network functionality | Not a social platform |
| Non-English localization in v1 | English is the primary institutional language in v1 |
| General-purpose CMS functionality | CMS is scoped to governance document management only |
| Financial transaction processing | Outside the governance domain |
| Physical or territorial operations support | Outside digital platform scope |
| External communications management | Social media, marketing, physical correspondence — out of scope |

Any item moved from out-of-scope to in-scope requires:
1. A written justification
2. An ADR documenting the decision
3. An assessment of impact on existing architecture
