# Contributing Guide

Thank you for your interest in contributing!  
This repository follows a **strict, staged branch workflow** to maintain stability while allowing controlled development and testing.

Please read this document fully before opening a pull request.

---

## 📌 Repository Overview

- **Project type:** Flutter application
- **Primary maintainer:** Solo maintainer
- **Default branch:** `main`

---

## 🌿 Branching Model

This project uses **three long-lived branches**:

### `dev` — Development

- All **active development** happens here
- Used by the maintainer for **manual testing**
- May be unstable or incomplete
- **All pull requests must target `dev`**

✅ This is the **only branch contributors should use**.

---

### `beta` — Pre-release

- Receives changes **only from `dev`**
- Used for wider testing and early access
- Merging into `beta`:
  - Automatically publishes a **beta GitHub release**
  - Version format: `x.y.z-beta.n`

🚫 Contributors should **not** open PRs directly to `beta`.

---

### `main` — Stable

- Production-ready code only
- Receives changes **only from `beta`**
- Merging into `main`:
  - Automatically publishes a **stable GitHub release**
  - Version format: `x.y.z`

🚫 Pull requests to `main` are not accepted.

---

## 🔁 Contribution Workflow

### 1. Fork the Repository

```bash
git clone https://github.com/<your-username>/<repo>.git
cd <repo>
git checkout dev
```

---

### 2. Create a Feature or Fix Branch

```bash
git checkout -b feature/short-description
# or
git checkout -b fix/short-description
```

---

### 3. Make Your Changes

- Keep changes **focused and minimal**
- Follow the existing project structure
- Avoid unrelated refactors or dependency changes

---

### 4. Basic Checks

Before opening a PR, ensure:

```bash
flutter analyze
flutter test
```

> Final testing is performed **manually by the maintainer** on the `dev` branch.

---

### 5. Open a Pull Request

- **Base branch:** `dev`
- **Compare branch:** your feature/fix branch
- Clearly explain:
  - What the change does
  - Why it is needed
  - Any user-facing or breaking changes

🚫 PRs targeting `beta` or `main` will be **closed without review**.

---

## 🚀 Release Flow (For Reference)

| Action | Result |
|------|-------|
| Merge PR → `dev` | Change queued for manual testing |
| Merge `dev` → `beta` | Beta release published |
| Merge `beta` → `main` | Stable release published |

Contributors do **not** need to manage versions, tags, or releases.

---

## 🐞 Issues & Discussions

- **Bug reports & feature requests:** GitHub Issues
- **Questions & general discussion:** GitHub Discussions
- Old or unstructured issues may be closed during maintenance cleanups

---

## 📐 Code Guidelines

- Follow Flutter and Dart best practices
- Prefer clarity over cleverness
- Avoid introducing new dependencies without discussion
- Platform-specific logic should be well-isolated

---

## 🔒 Maintainer Notes

- This is a **solo-maintained project**
- Reviews and merges may take time
- Large or architectural changes should be discussed **before** implementation

---

## ❤️ Thank You

Every contribution—code, issues, or documentation—helps improve the project.

Happy contributing! 🚀
