# HLSL Lessons

This repository contains a series of lessons for learning HLSL, the High-Level Shading Language, for use in Unity.

## Lessons

*   [Lesson 1: Simple Emission Shader](./lesson-01/README.md)
*   [Lesson 2: Shaded Emission](./lesson-02/README.md)
*   [Lesson 3: Fluorescent Shader](./lesson-03/README.md)

## CI

This repo uses GitHub Actions to validate that all HLSL shaders compile without errors.

On every push or pull request to `master`, Unity runs in batch mode and compiles every `.shader` file under `Assets/Shaders/`. If any shader has compile errors, the CI build fails.

### Required secrets

Add these three secrets in your GitHub repo under **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `UNITY_LICENSE` | Unity license file contents (XML) |
| `UNITY_EMAIL` | Email for your Unity account |
| `UNITY_PASSWORD` | Password for your Unity account |

To obtain a free Unity Personal license for CI, follow the [game-ci activation guide](https://game.ci/docs/github/activation).
