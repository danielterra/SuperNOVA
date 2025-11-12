## Project SuperNOVA

### Objective

SuperNOVA aims to reinvent how people create and organize knowledge by making their data reactive, connected, structured, and truly their own. Inspired by Excel's simplicity, it goes further: allowing anyone to build complete systems with strong data relationships organized around a common, extensible ontology.

This shared semantic foundation serves two crucial purposes: it enables true interoperability — data created in one SuperNOVA instance can be understood and used by any other — and it provides a simple abstraction layer that both humans and AI can work with naturally. Instead of AI generating code from requirements, it collaborates directly with you by modeling entities, relationships, and automations in the same structured way you do.

You can explore and visualize your data to find answers efficiently, and orchestrate automated workflows that respond to every change — all running locally on your machine, with complete ownership and control, without servers or technical expertise.

---

### Why This Project Exists

**The Spreadsheet Paradox**

Spreadsheets are the most popular software in the world. An estimated 1+ billion people use Excel alone[^1], with over 100 million professionals listing it as a core skill[^2]. Businesses of all sizes — from small startups to Fortune 500 companies — depend on spreadsheets for critical operations: 72% of enterprises use them for financial modeling and business intelligence[^3], and over 90% of administrative and managerial jobs require spreadsheet proficiency[^4].

Yet spreadsheets have fundamental limits that make them fragile and difficult to scale:

- **Weak data relationships**: No proper foreign keys, no referential integrity — relationships are just cell references that break when rows move or sheets are reorganized
- **No reactive automation**: Changes don't trigger workflows; there's no event system to automate responses when data changes
- **No validation or constraints**: Anyone can type anything anywhere; there's no way to enforce data types, required fields, or business rules
- **Manual and error-prone**: Copy-paste operations, formula mistakes, and accidental deletions happen constantly with no safeguards
- **Limited scalability**: Performance degrades severely with size; hitting row/column limits breaks critical systems
- **No proper querying**: You can't ask complex questions across multiple sheets or perform relational queries without building elaborate, brittle formulas
- **Flat structure**: Everything lives in rows and columns; you can't model hierarchies, graphs, or complex entity relationships naturally

**And when they fail, the consequences are serious:** JP Morgan Chase lost $6.2 billion due to a copy-paste error in a risk model[^5]. TransAlta Corp lost $24 million when misaligned rows caused bids to match wrong contracts[^6]. Fidelity Investments made a $2.6 billion accounting error from a missing minus sign[^7]. During the COVID-19 pandemic, Public Health England lost track of 15,841 positive cases because Excel hit its row limit[^8]. Studies show that 88% of all spreadsheets contain serious errors[^9] — yet businesses have no better alternative for the flexibility they need.

[^5]: [JPMorgan "London Whale" Excel error - Dear Analyst](https://www.thekeycuts.com/dear-analyst-38-breaking-down-an-excel-error-that-led-to-six-billion-loss-at-jpmorgan-chase/)
[^6]: [TransAlta $24M loss - Excel Disasters](https://sheetcast.com/articles/ten-memorable-excel-disasters)
[^7]: [Fidelity $2.6B error - Biggest Excel Mistakes](https://blog.hurree.co/8-of-the-biggest-excel-mistakes-of-all-time)
[^8]: [COVID-19 data loss - Spreadsheet Disasters](https://gridfox.com/blog/5-spreadsheet-disasters-that-prove-their-risk/)
[^9]: [88% error rate - Wall of Shame for Excel Errors](https://www.solving-finance.com/post/the-wall-of-shame-for-the-worst-excel-errors)

[^1]: [Senacea - How many people use Excel?](https://www.senacea.co.uk/post/excel-users-how-many)
[^2]: [LinkedIn profiles analysis - Excel as listed skill](https://www.senacea.co.uk/post/excel-users-how-many)
[^3]: [Global office software market research - Grand View Research](https://www.grandviewresearch.com/industry-analysis/office-software-market-report)
[^4]: [U.S. Bureau of Labor Statistics - Spreadsheet proficiency requirements](https://www.excel4business.com/resources/research-into-excel-use.php)

**The Fragmentation Problem**

Today, our data lives scattered across hundreds of applications and services. Your contacts are in one place, your projects in another, your finances elsewhere. Each silo has its own interface, its own rules, its own way of doing things. Moving data between them is painful or impossible. You can't create your own connections, your own automations, your own view of how everything relates.

**You Don't Own Your Data**

Most applications store your data on their servers. You access it through their interface, under their terms. If they change their pricing, shut down, or decide to restrict features, you're stuck. Your data — your knowledge, your work, your life — is held hostage by business models you can't control.

**Wasted Computing Power**

Modern personal computers are extraordinarily powerful — multi-core processors, gigabytes of RAM, terabytes of storage. Yet we use them mostly as dumb terminals to access cloud services. All that computing power sits idle while we wait for distant servers to process our requests, subject to their limitations and costs.

**SuperNOVA's Answer**

SuperNOVA brings the power back to your machine. It combines the simplicity of spreadsheets with the sophistication of databases, the automation of modern systems, and the freedom of complete data ownership. Everything runs locally. Everything connects. Everything reacts. Your computer becomes a powerful, autonomous system that works *for you* — not for a service provider's business model.

---

### Vision

SuperNOVA transforms static data into living information. Every change in an entity is a meaningful event: the system reacts, automates, and connects to other systems. Data ceases to be passive records and becomes orchestration points — creating a new form of distributed and transparent intelligence.

---

### Principles and Strategies

1. **Simplicity as Power**
   SuperNOVA must be as intuitive as a spreadsheet. AI acts as an assistant, helping users build structures and automations without writing code.

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