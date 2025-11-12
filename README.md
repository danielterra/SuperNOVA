## Project SuperNOVA

### Objective

SuperNOVA aims to reinvent how people create and organize knowledge. Inspired by Excel’s simplicity, it goes further: allowing anyone to create complete, automated, and decentralized systems without relying on servers or technical expertise.

---

### Vision

SuperNOVA transforms static data into living information. Every change in an entity is a meaningful event: the system reacts, automates, and connects to other systems. Data ceases to be passive records and becomes orchestration points — creating a new form of distributed and transparent intelligence.

---

### Principles and Strategies

1. **Simplicity as Power**
   SuperNOVA must be as intuitive as a spreadsheet. Modeling entities, states, and actions should be visual and natural. AI acts as a modeling assistant, helping users build structures and automations without writing code.

2. **Decentralization and Autonomy**
   Everything runs on the users’ own devices. Each machine is an independent, collaborative node capable of sharing load and data. There are no central servers — computing power and control belong to the users.

3. **Open and Extensible Ontology**
   Knowledge is structured by an ontology composed of **classes** and **relationships**. This foundation can follow standards like RDF and build upon public ontologies to ensure interoperability. Users only create what is specific to their context, extending existing classes.

4. **Total Reactivity**
   Everything in SuperNOVA is a reaction to persisted database changes. The system doesn’t need logs or external events — the database itself *is* the log. Each state modification triggers actions, automatic or manual, turning data into a living process.

5. **Immutable Data**
   No record is directly updated. Each change is the insertion of a new fact that logically replaces the previous one. The history is continuous and traceable, preserving integrity and the complete system timeline.

6. **Origin and Traceability**
   Every piece of information has an origin — whether a user, an external system, or an automation. This traceability ensures transparency and accountability for every event.

7. **Open Source and Collaboration**
   SuperNOVA is an open project built with and by the community. The codebase, base ontology, and documentation will be public, fostering innovation, trust, and collective evolution.

8. **Decentralized Authentication**
   Identity in SuperNOVA is guaranteed through **ECDSA (Elliptic Curve Digital Signature Algorithm)**. Each user shares their public key as a digital calling card, allowing others to verify their identity through data signatures. The private key never leaves the user’s computer — it’s personal, non-transferable, and secure. This approach eliminates dependencies on authentication servers and reinforces individual data sovereignty.

9. **Secure and Distributed Communication**
   Communication between computers in SuperNOVA can occur over local networks or the internet. All interactions between nodes must use **HTTPS connections**, ensuring privacy, mutual authentication, and data integrity. This secure layer is vital for maintaining decentralization without sacrificing trust.

10. **Fork Your Data**
    Just like duplicating a spreadsheet to test new ideas, SuperNOVA allows users to **fork their data**. They can experiment with changes, simulate scenarios, and validate hypotheses without affecting the main environment. Once satisfied, they can apply the modifications to the original system. This freedom fosters safety and continuous innovation.

---

### Work Methodology

SuperNOVA follows a problem-driven, outcome-focused development approach:

#### Quarterly Planning with OKRs

Every quarter, we define **OKRs (Objectives and Key Results)** that are always aligned with the project's core objective and guiding principles. OKRs are documented in `requirements/YYYY/Q[n]/OKRS.md`.

- **Objectives** are user-centered outcomes that deliver clear value
- **Key Results** are measurable indicators of success from the user's perspective
- Technical implementation is a means to achieve user outcomes, not the goal itself

#### Problem-Driven Development

For each Key Result, we identify the **problems** that need to be solved to achieve that result. A problem can be:
- A technical challenge that blocks the outcome
- A knowledge gap that requires research or experimentation
- A design question that needs user validation

Problems are documented in: `requirements/YYYY/Q[n]/O[n]/K[n]/P[n].md`

Each problem document should clearly state:
- **What** we don't know or can't do yet
- **Why** solving it is necessary for the Key Result
- **How** we might approach solving it (hypotheses)
- **Success criteria** - how we'll know the problem is solved

#### From Problems to Solutions

Once problems are identified and understood, we create solutions through iterative development:
1. **Research** - Gather information, prototype, experiment
2. **Implement** - Build the minimal solution that addresses the problem
3. **Validate** - Test with real users or realistic scenarios
4. **Iterate** - Refine based on feedback until success criteria are met

This approach keeps us focused on delivering real value rather than building features for their own sake.

---

### Technology Stack

SuperNOVA is built with a **minimalist, dependency-averse** philosophy: pure Rust with native rendering, rejecting web browsers, JavaScript ecosystems, and alternative runtimes.

**Core Stack:**
- **Language**: Rust (single language, single toolchain)
- **UI Framework**: Slint (declarative markup, <300 KB runtime)
- **Database**: SurrealDB (embedded, reactive, with RocksDB backend)
- **Build System**: Cargo only

**Why This Stack:**

1. **Rust** - Memory safety, performance, cross-platform without compromises
2. **Slint** - Declarative UI perfect for structured interfaces (forms, tables), minimal dependencies
3. **SurrealDB** - Native change observability (Live Queries), perfect for reactive architecture

**Philosophy: Minimal Dependencies**

We explicitly reject:
- ❌ WebView-based frameworks (Tauri, Electron) - avoid browser engine dependencies
- ❌ JavaScript/Node.js ecosystem - avoid npm, bundlers, multiple languages
- ❌ Alternative runtimes (Flutter, .NET) - avoid additional runtime dependencies

**Binary Size**: ~5-10 MB (vs ~200 MB for Electron apps)

**Decision References:**
- Database selection: [P1 - Database Technology Selection](requirements/2026/Q1/O1/K1/P1.md)
- Stack selection: [P2 - Technology Stack Selection](requirements/2026/Q1/O1/K1/P2.md)