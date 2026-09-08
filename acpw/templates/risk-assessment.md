# Hard Rule Check
List matching Global or Project Hard Rules and their minimum governance level. If none match, write `None`.

# Weighted Risk Score
| Factor | Score 0-5 | Weight | Contribution |
|---|---:|---:|---:|
| Security |  | 25% |  |
| Data / Production |  | 25% |  |
| Blast Radius |  | 20% |  |
| Reversibility |  | 15% |  |
| Business / Operational Impact |  | 10% |  |
| Complexity |  | 5% |  |

Normalize the total to 0–100. Map 0–29 to Lightweight, 30–64 to Standard, and 65–100 to Enterprise.

# Project Policy Minimum
Record the project-specific minimum if one exists.

# Final Governance Level
Use the maximum of Risk Score Level, Global Hard Rule Minimum, and Project Policy Minimum.

# Reasoning Level
Select Low, Medium, or High based on problem-solving difficulty rather than production consequence.

# Human Decision
Record approval or an upward override. A downward override may not cross the Safety Floor.
