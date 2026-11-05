# Link Shortener Service - Planning Document

**Prepared for:** Call Center Team  
**Date:** November 5, 2026  
**Document Purpose:** Specification, architecture, rollout plan, and cost estimate

---

## Executive Summary

This document proposes a **phased approach** to building a link shortener service for Call Center operations. The focus is on delivering a working minimum viable product (MVP) quickly, then expanding based on validated business requirements.

**Recommended Approach:**
- **MVP (2-3 weeks):** Core link shortening with basic management
- **Estimated effort:** 10-15 engineering days
- **Preliminary cost estimate:** $7,000-13,000 (based on planning assumptions below)
- **Infrastructure:** Estimated at $20-75/month for the assumed MVP deployment

**Important:** This is a preliminary estimate based on the planning assumptions in Section 2. Scope and cost will be refined after open requirements are confirmed.

**Key Principle:** Start minimal, validate with real usage, expand incrementally based on actual needs rather than anticipated features.

---

## 1. Current Understanding

Based on the brief provided:

**What we know:**
- Call Center team needs a link shortener
- Primary users will be Call Center agents
- Links will be shared with customers (presumably via phone, email, or chat)
- Team wants to understand scope and cost before committing

**What we don't know yet:**
- Number of agents and expected link volume
- Integration requirements with existing systems
- Analytics depth required
- Compliance or security constraints
- Whether this is internal-only or customer-facing infrastructure

These unknowns significantly impact architecture and cost. See [Open Questions](#13-open-questions) section.

---

## 2. Planning Assumptions

**These assumptions shape the proposal below. Corrections will adjust scope and cost accordingly.**

1. **Scale Assumption:** Initial deployment for internal Call Center use with 20-100 agents creating 100-1000 links/day and 1000-10,000 clicks/day. This is small-to-medium scale.

2. **Infrastructure Assumption:** The service can leverage existing company authentication, hosting, and monitoring infrastructure where practical. If full greenfield deployment is required, cost and timeline will increase.

3. **Analytics Assumption:** Basic analytics (click counts, creation date, creator) are sufficient for MVP. Detailed analytics (geography, devices, referrers) are deferred until validated as requirements.

4. **Integration Assumption:** Initial version is standalone web application. CRM or call center software integration is future scope pending confirmation of systems and workflows.

5. **Security Assumption:** Standard web application security (HTTPS, authentication, authorization) is sufficient. No special compliance requirements (GDPR, HIPAA, PCI) unless specified.

6. **Availability Assumption:** Standard PaaS uptime (99%+) is acceptable. If higher availability or multi-region deployment is required, architecture and cost will change.

**These assumptions must be validated before development starts.**

---

## 3. Proposed MVP Scope

### Core Features (Must Have)

**Link Shortening:**
- Generate short URL from long URL with auto-generated code (e.g., `yourdomain.com/abc123`)
- Redirect `/:short_code` to destination URL (< 100ms response time)
- Set optional expiration date on link
- Deactivate link manually (stops redirects)

**User Interface:**
- Agent dashboard showing "My Recent Links" (last 50)
- Simple "Create Link" form (URL + optional expiration)
- Copy-to-clipboard button for generated short URL
- Desktop-first interface (mobile responsiveness conditional on confirmed agent workflow)

**Authentication & Access:**
- Authentication: Reuse existing company authentication where available; otherwise basic email/password authentication
- All authenticated users can view and manage their own links
- Admin/supervisor functionality deferred to future phase

**Analytics (Basic):**
- Total click count per link
- Link creation date and creator name

**Initial Engineering Targets** (subject to confirmation):
- Link creation: < 500ms
- Redirect: < 100ms  
- Support 50+ concurrent agents

### Conditional Features (Included only if confirmed as operational requirements)

- **Mobile-responsive interface** - Included if agents frequently work from mobile devices
- **Admin role** - Included if centralized link management is required
- **CSV export** - Included if reporting/auditing requires offline link data

### Explicitly Out of MVP Scope

To keep MVP minimal and validate core value quickly, these are **intentionally excluded:**

- ❌ Custom aliases (e.g., `/winter-promo`)
- ❌ Edit destination URL after creation
- ❌ Link tags/categories
- ❌ Advanced search and filters
- ❌ Geographic/device analytics
- ❌ QR code generation
- ❌ Team/department grouping
- ❌ CRM integration
- ❌ SSO
- ❌ Bulk link creation
- ❌ API for external systems

**Rationale:** These features add complexity but haven't been validated as requirements. We include them in "Potential Future Enhancements" below and can prioritize based on actual usage patterns.

---

## 4. Potential Future Capabilities

Once MVP is deployed and validated, we can expand based on demonstrated needs. The following capabilities are **intentionally not estimated or scheduled** until actual requirements are confirmed:

**Enhanced Management:**
- Edit destination URL without changing short code
- Custom aliases for memorable links
- Link tagging and advanced search
- Link templates for common resources
- Enhanced analytics with time-series charts

**Team & Collaboration:**
- Team/department grouping
- Supervisor role with team-level analytics
- Bulk link creation and management
- QR code generation

**Integration:**
- SSO integration (provider-dependent complexity)
- CRM integration (system-dependent complexity)
- REST API for external systems
- Webhooks for event notifications

**Advanced Analytics & Features:**
- Geographic and device-based analytics
- Custom short domains
- Branded landing pages with company assets
- A/B testing and link rotation

**Approach:** Each capability should be scoped and estimated only when business requirements validate the need. This prevents investing in features that may not provide value.

---

## 5. Non-Functional Requirements

**Performance Targets** (initial engineering targets, subject to confirmation):
- Link redirect: < 100ms (95th percentile)
- Link creation: < 500ms (95th percentile)
- Support 50+ concurrent agents
- Support 10,000+ redirects/day

**Security:**
- HTTPS-only
- Secure password hashing if local authentication is used
- CSRF protection
- SQL injection protection (parameterized queries)
- Configurable rate limiting (thresholds to be agreed based on expected traffic patterns and infrastructure topology)

**Availability:**
- 99%+ uptime (PaaS standard SLA)
- Analytics failures must not block redirects
- Database backups (daily)

**Usability:**
- Desktop-first interface; mobile responsiveness conditional on confirmed agent workflow
- Works on modern browsers (Chrome, Firefox, Safari, Edge - last 2 versions)
- Accessible (WCAG 2.1 AA basic compliance)

**Maintainability:**
- Clean, tested codebase (>80% test coverage)
- Standard Rails conventions
- Documented setup and deployment
- Reversible database migrations

---

## 6. Proposed Architecture

### Technology Stack

**Core Stack:**
- **Ruby on Rails** (current stable supported version) - Web framework
  - Mature framework with strong conventions
  - The team can deliver and maintain the service efficiently using a mature Rails stack
  - Well-suited for rapid MVP development and incremental scaling
- **PostgreSQL** (current stable version) - Primary database
  - Handles millions of links easily
  - Unique index on `short_code` enables fast redirect lookups
  - Rich feature set for future expansion
- **Redis** - Redirect caching and rate limiting
  - Reduces database load on repeated redirects
  - Supports configurable rate limiting
  - PostgreSQL remains the source of truth
  - Redirects fall back to PostgreSQL if Redis is unavailable

**Optional Components (add only if validated as necessary):**
- **Sidekiq** - For background job processing (if analytics processing becomes bottleneck)

**Testing & Quality:**
- **RSpec** - Testing framework with >80% coverage target
- **RuboCop** - Code style enforcement
- **Brakeman** - Security vulnerability scanning

**Deployment:**
- **Heroku** or **Render** - PaaS deployment (zero DevOps overhead)
- **GitHub Actions** - CI/CD pipeline
- **Sentry** - Error tracking (Phase 2+)

### System Architecture

```
                 ┌─────────────────┐
                 │  Load Balancer  │
                 │   (PaaS built-in)│
                 └────────┬────────┘
                          │
                 ┌────────▼────────┐
                 │  Rails Web App  │
                 │                 │
                 │ • Link CRUD     │
                 │ • Redirect      │
                 │ • Analytics     │
                 │ • Auth          │
                 └───┬─────────┬───┘
                     │         │
         ┌───────────▼───┐ ┌──▼──────────┐
         │  PostgreSQL   │ │   Redis     │
         │               │ │             │
         │ • links       │ │ • Cache     │
         │ • clicks      │ │ • Rate      │
         │ • users       │ │   Limiting  │
         └───────────────┘ └─────────────┘

Optional (if needed):
  ┌──────────┐
  │ Sidekiq  │
  │ (jobs)   │
  └──────────┘
```

**Rationale:** The MVP intentionally keeps the architecture small: Rails, PostgreSQL, and Redis. PostgreSQL remains the source of truth, while Redis supports redirect caching and rate limiting. Additional components such as background workers or CDN should only be introduced if usage measurements justify them.

---

## 7. Key Technical Decisions & Trade-offs

### Decision 1: Redis Caching for Redirects

**Decision:** Use Redis for cache-aside redirect lookups with PostgreSQL as source of truth.

**Rationale:**
- PostgreSQL remains the authoritative data store for all links
- Redis provides cache-aside lookup for `short_code → destination_url` mappings
- Cache hits avoid database round trips, reducing database load and redirect latency
- Redis also provides rate limiting infrastructure
- Cache can be fully rebuilt from PostgreSQL if needed
- Redis failure mode: redirect falls back to PostgreSQL queries (service remains available)
- Operational overhead is minimal

**Trade-off:** Adds infrastructure dependency, but the combined benefit of redirect caching and rate limiting justifies the additional component with relatively low operational overhead.

**Implementation:**
- Cache TTL: Set based on link expiration or 1 hour, whichever is shorter
- Cache entries include destination URL, status, and expiration timestamp
- Cache eviction: Explicit eviction when links are deactivated or modified
- Expiration handling: Cache respects `expires_at` independently of TTL to prevent expired links from working past their expiration

**When to reconsider:** If Redis becomes an operational burden disproportionate to the benefit, or if traffic remains low enough that PostgreSQL alone meets performance targets.

### Decision 2: Synchronous Click Recording (No Background Jobs for MVP)

**Decision:** Record clicks synchronously in the redirect controller.

**Rationale:**
- Synchronous click recording is acceptable at the assumed MVP volume
- Expected volume (10K clicks/day) doesn't warrant async processing complexity
- Simpler architecture, fewer moving parts
- Click-recording failures are logged but do not prevent the redirect (analytics must not block core functionality)

**Trade-off:** If click recording slows redirects or traffic spikes cause issues, move to async background jobs.

**When to reconsider:** If redirect latency measurements show click recording is a bottleneck, or traffic grows significantly.

### Decision 3: Base62 Short Codes with Database Constraint

**Approach:** Generate random 6-character Base62 string (a-z, A-Z, 0-9).

**Collision Handling Algorithm:**
1. Generate random Base62 code
2. Attempt database insert with unique constraint
3. If uniqueness violation occurs, retry with new code
4. Database constraint enforces uniqueness, preventing race conditions

**Rationale:**
- 62^6 ≈ 56.8 billion possible codes provides ample headroom
- Database unique constraint handles race conditions correctly
- No "check then insert" race condition vulnerability
- Code length can increase as dataset grows (7 chars = 62^7 ≈ 3.5 trillion)

**Trade-off:** Slightly more retries as dataset grows, but negligible until millions of links.

### Decision 4: 302 (Temporary) Redirects

**Decision:** Use HTTP 302 (Found) instead of 301 (Moved Permanently).

**Rationale:**
- 301 causes browsers and proxies to cache permanently, bypassing our server on subsequent clicks
- 302 ensures every visit reaches the service, enabling analytics and control
- Required for key service features: click counting, link expiration, deactivation

**Trade-off:** 302 redirects cause each visit to reach the service, which increases request volume compared with cacheable permanent redirects, but preserves control over destination changes, expiration, deactivation, and click analytics. This trade-off aligns with the service requirements.

### Decision 5: Phased Delivery over Big Bang

**Decision:** Deliver working MVP in 2-3 weeks, expand based on feedback.

**Rationale:**
- Validates core value quickly
- Reduces risk of building unwanted features
- Allows budget flexibility
- Enables learning from real usage

**Trade-off:** Some features may require rework if requirements change significantly.

---

## 8. Data Model

### Core Tables

```ruby
# users
id                  : bigint (PK)
email               : string (unique, indexed)
encrypted_password  : string
created_at          : datetime
updated_at          : datetime

# Note: All authenticated users have equal access (Call Center agents).
# Admin/supervisor roles deferred to future phase when management features are added.

# links
id                  : bigint (PK)
short_code          : string(6) (unique, indexed)
destination_url     : text
user_id             : bigint (FK to users, indexed)
expires_at          : datetime (nullable, indexed)
status              : enum [active, inactive]
created_at          : datetime
updated_at          : datetime

# clicks (source of truth for click counts)
id                  : bigint (PK)
link_id             : bigint (FK to links, indexed)
clicked_at          : datetime (indexed)
created_at          : datetime

# Note: Click counts are derived via COUNT(*) queries on the clicks table.
# Future optimization: add denormalized counter to links table if performance requires.
# Future enhancement: add ip_address, user_agent, referrer columns for detailed analytics.
```

**Key Indexes:**
- `links.short_code` (unique) - Critical for fast redirects
- `links.user_id` - Fast "my links" queries
- `links.expires_at` - Fast expired link cleanup
- `clicks.link_id` - Fast click count queries
- `clicks.clicked_at` - Time-series analytics (future)

---

## 9. Testing Strategy

**Framework:** RSpec with FactoryBot, Capybara for system tests.

**Coverage Target:** >80% overall for MVP. Critical redirect and generation logic should be comprehensively covered.

**Test Types:**
- **Unit/Service Tests:** Models, service objects, business logic
  - Link model validations
  - Short code generation with collision handling
  - Expiration logic
- **Request/Integration Tests:** Controllers, API endpoints, workflows
  - Link creation flow
  - Redirect handling
  - Authentication and authorization
- **System Tests:** Browser-driven critical workflows
  - Agent creates and uses link
  - Admin views all links (if admin role included)

**CI/CD:** GitHub Actions runs tests on every PR. No merge if tests fail or coverage drops.

---

## 10. Delivery & Rollout Plan

### Week 1: Core Functionality

**Days 1-2:**
- Rails application setup
- Database schema and migrations
- Authentication integration (reuse existing company auth if available, otherwise basic email/password)

**Days 3-4:**
- Link model and short code generation
- Redirect endpoint `/:short_code`
- Basic click recording

**Day 5:**
- Agent dashboard UI
- "Create Link" form
- Deploy to staging

**Friday Demo:** Working link shortener - agents can create and share links

### Week 2: Management & Polish

**Days 1-2:**
- "My Links" list with click counts
- Link deactivation
- Expiration handling

**Days 3-4:**
- Conditional features (if confirmed as requirements)
- UI polish and error handling
- Performance optimization

**Day 5:**
- Integration tests
- Production environment setup

**Friday Demo:** Full MVP ready for UAT

### Week 3: Launch (Optional Buffer)

**Days 1-2:**
- UAT with 5-10 pilot agents
- Bug fixes from feedback

**Days 3-4:**
- Production deployment
- Monitoring setup
- Documentation

**Day 5:**
- Phased rollout to all agents
- Post-launch support

### Deployment Strategy

**Staging:** Deploy continuously for testing  
**Production:** Soft launch with 5-10 agents, expand gradually  
**Rollback:** Production deployments should support fast rollback if issues arise

---

## 11. Effort and Cost Estimate

### Effort Estimate

**MVP Development:**
- Core functionality: 5-7 days
- UI and polish: 3-4 days
- Testing and deployment: 2-3 days
- **Total: 10-14 engineering days**

**Buffer for unknowns:** +2-3 days (requirements clarification, unexpected issues)

**Realistic total: 12-17 engineering days over 2-3 weeks** (includes meetings, reviews, UAT)

### Cost Estimate

**Illustrative calculation assuming senior Ruby developer:**
- **Rate assumption:** $600-800/day or $75-100/hour
- **MVP effort:** 12-17 days
- **Estimated development cost: $7,200 - $13,600**

**Important Notes:**
1. This estimate assumes the planning assumptions in Section 2 are correct
2. Significant unknowns (complex integrations, compliance requirements, high-scale needs) will increase cost
3. This covers development only; see infrastructure costs below
4. Final cost will be refined after open requirements are confirmed

### Infrastructure Cost (Ongoing)

**MVP Infrastructure:**
- Basic PaaS deployment: approximately $20-75/month depending on provider and tier
- Includes: web tier, PostgreSQL database, Redis cache, domain, SSL
- **Estimated: ~$240-900/year**

**Scaled Production Infrastructure (if usage grows):**
- Professional-tier PaaS deployment with redundancy and monitoring
- **Estimated: ~$2,000-4,000/year**

**Note:** These are illustrative PaaS costs. Using existing company infrastructure may significantly reduce or eliminate these costs. See [Open Questions](#13-open-questions).

### Cost Summary Table

| Item | Effort | Cost Range |
|------|--------|------------|
| MVP Development | 12-17 days | $7,200 - $13,600 |
| Infrastructure (Year 1, MVP tier) | - | $240 - $900 |
| **Total Year 1 (MVP)** | - | **$7,450 - $14,500** |

**Future Enhancement Capabilities:** Excluded from the current estimate and should be estimated separately once requirements are confirmed (see Section 4).  
**Infrastructure Scaling:** If usage grows significantly, infrastructure costs may increase to ~$2,000-4,000/year.

**This estimate will be revised after open requirements are confirmed.**

---

## 12. Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Link abuse / malicious destinations** | High | Medium | Authentication required, auditability (all links tracked to creator), optional URL validation against allow/deny lists, malware scanning can be added if needed. |
| **Unclear integration requirements** | High | Medium | Start standalone MVP, design integration points for future. Early stakeholder sync to clarify systems. |
| **Underestimated scale** | Medium | Low | Assumptions section makes expected scale explicit. Architecture can scale up if needed. |
| **Security vulnerability** | High | Low | Standard Rails security practices, Brakeman scanning, security code review. |
| **User adoption issues** | Medium | Low | Simple UI, pilot with 5-10 agents before full rollout, training materials. |
| **Performance issues** | Medium | Low | Performance targets defined, load testing before launch, PostgreSQL handles expected scale. |
| **Cache availability** | Low | Low | Redis failure must not make existing links unavailable; redirect lookup falls back to PostgreSQL. Graceful degradation built into design. |
| **Scope creep** | Medium | Medium | MVP explicitly defines in/out of scope. Change requests go through prioritization. |
| **Infrastructure cost overruns** | Low | Low | PaaS costs predictable, can optimize later if needed. |

---

## 13. Open Questions

**Answers to these questions will refine the estimate and may change scope/cost.**

### Critical (Must answer before starting)

1. **Volume & Scale:**
   - How many Call Center agents will use the system?
   - Expected links created per day/week?
   - Expected clicks per day/week?

2. **Infrastructure:**
   - Can the service use existing company infrastructure (hosting, authentication, monitoring)?
   - Is there a preferred deployment platform?
   - Is there a domain available for short links (e.g., `go.company.com`)?

3. **Timeline:**
   - When do you need this deployed?
   - Is 2-3 weeks acceptable, or is there urgency?

4. **MVP Scope Confirmation:**
   - Is the proposed MVP feature set sufficient to start?
   - Are any MVP features missing that are absolute requirements?
   - Are any MVP features unnecessary?

5. **Budget:**
   - Is the estimated MVP cost ($7,200-13,600) within budget?
   - Budget constraints that would affect scope?

### Important (Should answer before future enhancements)

6. **Integration:**
   - Which CRM system do you use? Is integration required?
   - Should links be created from within CRM/call center software?
   - Is SSO required? Which provider (Okta, Google, Azure AD)?

7. **Analytics:**
   - What analytics depth is required? (Basic click counts vs. geographic/device details)
   - Who needs access to analytics? (agents, supervisors, management)
   - Any specific reports required?

8. **Security & Compliance:**
   - Any compliance requirements? (GDPR, SOC2, HIPAA, etc.)
   - Should we validate destination URLs against malware databases?
   - Data retention policy for click data?

### Nice to Know (Can decide later)

9. **Advanced Features:**
   - Are custom aliases required? (e.g., `/winter-promo`)
   - Are QR codes required for MVP or can they wait?
   - Multiple short domains for different teams?

10. **Workflow:**
    - Do agents create links during live calls or between calls?
    - How are links shared with customers? (email, chat, SMS, verbally)
    - Are there common link templates that would save time?

---

## 14. Next Steps

### Recommended Process

**Phase 1: Requirements Confirmation**
1. Review this document and confirm planning assumptions (Section 2)
2. Answer critical questions (Section 13, questions 1-5)
3. Refine scope and cost estimate based on answers

**Phase 2: Kickoff**
4. Schedule kickoff meeting (30-60 min) to align on approach
5. Establish communication channels and weekly demo schedule
6. Confirm development environment and deployment access

**Phase 3: Development & Delivery**
7. Weekly rhythm:
   - Monday: Quick sync (15 min) on week's priorities
   - Wednesday: Async check-in on blockers
   - Friday: Demo working software, collect feedback
8. Deliverables:
   - Week 1: Staging environment with core redirect working
   - Week 2: Full MVP on staging for UAT
   - Week 3: Production deployment

**Phase 4: Launch & Validation**
9. UAT with 5-10 pilot agents
10. Phased rollout to all agents
11. Monitor usage, collect feedback, fix issues

**Phase 5: Decision Point**
- Evaluate MVP performance and usage
- Prioritize future capabilities based on validated needs
- Decide on enhancement phases or maintain MVP as-is

---

## 15. Why This Approach?

Three principles guide this proposal:

**1. Minimize Waste:**  
Building features before validating they're needed wastes time and money. MVP proves core value quickly.

**2. Manage Uncertainty:**  
The requirements have many unknowns. Rather than guess, we make assumptions explicit, deliver quickly, and refine based on reality.

**3. Maintain Simplicity:**  
The design intentionally avoids unnecessary complexity: a small Rails/PostgreSQL/Redis stack with pragmatic patterns appropriate for the expected workload, synchronous processing before background jobs, and incremental scaling based on measured needs rather than anticipated scale.

This approach maximizes learning and minimizes risk.

---

## Appendix A: Redirect Flow Diagram

```
User Request
     │
     ▼
┌─────────────────────┐
│   Rails Controller  │
│   GET /:short_code  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Redis Cache       │
│   Lookup short_code │
│   (fast cache hit)  │
└──────────┬──────────┘
           │
      ┌────┴────┐
   Hit│         │Miss
      ▼         ▼
   Found   ┌────────────────┐
           │ PostgreSQL     │
           │ SELECT dest_url│
           │ → Populate     │
           │    Cache       │
           └────────┬───────┘
                    │
           ┌────────▼────────┐
           │  Record Click   │
           │  (synchronous)  │
           └────────┬────────┘
                    │
                    ▼
           ┌─────────────────┐
           │ HTTP 302 Redirect│
           └─────────────────┘

Performance: Cache hits avoid database queries.
Target: p95 redirect latency < 100ms
```

---

**Document Version:** 1.0  
**Last Updated:** November 5, 2026  
**Next Review:** Upon receiving stakeholder feedback

---

*This is a living document. Questions and feedback are welcome.*
