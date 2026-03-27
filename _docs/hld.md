# YouAreHistory — High-Level Design

## 1. Overview

YouAreHistory is an interactive edutainment application built in **Godot 4 (GDScript)**. Players inhabit a character from history and experience a scene from that character's life through pre-rendered animation. At key moments they are asked to make decisions that reflect real historical constraints—forcing engagement with the period rather than passive observation.

**Target audience:** Early secondary students (ages 10–15) and general visitors in informal educational settings such as museum exhibits  
**Platform:** Godot 4 — exported to Web (HTML5) and Windows executable  
**Deployment:** Initially a local web server; also packaged as a standalone `.exe` for deployment on museum media computers as a permanent exhibit

---

## 2. Core Concepts

### 2.1 Stories
Each story is a self-contained experience set in a specific historical period and focused on a single character archetype (e.g. a mediaeval healer, a Renaissance sailor, a Regency servant). A story consists of a linear sequence of video segments punctuated by decision points.

### 2.2 Decision Points
At defined moments the story pauses and presents the player with a **binary choice**. Each option is educational—the correct answer reflects something historically accurate or significant about the period.

- Choices are **binary** (exactly two options per decision point).
- Each choice has a designated **correct** or **incorrect** outcome.
- Incorrect choices are not necessarily dead-ends (see §2.4 Rewind Mechanic).
- A choice may be marked **final**, meaning it ends the story regardless of correctness.

### 2.3 Advisors
Each story may feature up to **three advisors**. While a decision is pending, the player can consult any available advisor to gain additional context (historical, religious, scientific, social, etc.) relevant to the choice.

- Advisor responses are presented as text in the UI sidebar.
- Advisors are passive—they inform but do not make the decision for the player.
- Each advisor has a single static response per decision point; their text does not change if consulted multiple times at the same decision.
- Advisors are available at every decision point throughout the story.

### 2.4 Rewind Mechanic
If the player selects an **incorrect, non-final** choice:
1. An animation plays showing the consequence of that choice.
2. The story automatically "rewinds" to the decision point.
3. The player must then choose again.

The rewind allows players to progress but **does not award a point** for that decision — only the initial choice is scored.

### 2.5 Scoring
At the end of a story (when a **final** state is reached) the player is shown a summary of their decisions and a score (e.g. *2 out of 3*). Points are awarded only for decisions where the **first** choice made was correct.

---

## 3. System Architecture

### 3.1 High-Level Components

Communication between the state machine and UI follows Godot's **signal** pattern: the `StoryController` autoload emits signals and UI nodes connect to them. UI nodes never call each other directly.

```
┌─────────────────────────────────────────────────────┐
│                  Godot Application                   │
│                                                      │
│  ┌───────────────── Main Scene ─────────────────┐   │
│  │  ┌────────────────┐   ┌─────────────────────┐│   │
│  │  │ VideoStream-   │   │   AdvisorSidebar    ││   │
│  │  │ Player (node)  │   │   (Control scene)   ││   │
│  │  └────────────────┘   └─────────────────────┘│   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │      DecisionBar (Control scene)       │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │      ScoreScreen (Control scene)       │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  └──────────────┬──────────────────────────┬────┘   │
│    signals ▲▼   │                          │         │
│  ┌──────────▼───────────┐                  │         │
│  │  StoryController     │  (Autoload /     │         │
│  │  - state machine     │   Singleton)     │         │
│  │  - score tracking    │                  │         │
│  └──────────┬───────────┘                  │         │
│             │ loads on startup             │         │
│  ┌──────────▼───────────┐                  │         │
│  │  Story JSON config   │  (res:// in PCK) │         │
│  └──────────────────────┘                  │         │
└─────────────────────────────────────────────────────┘
```

### 3.2 Scene & Node Structure

Godot best practice is to compose the application from small, reusable scenes. The expected scene hierarchy is:

```
res://
├── main.tscn                  # Root scene; owns VideoStreamPlayer; connects signals
├── scenes/
│   ├── decision_bar.tscn      # HBoxContainer with two Buttons + Label
│   ├── advisor_sidebar.tscn   # VBoxContainer; advisor list + ScrollContainer for text
│   └── score_screen.tscn      # TextureRect (bg image) + Label (score)
├── autoload/
│   └── story_controller.gd    # Autoload singleton — state machine + score
└── data/
    └── stories/
        └── healer/
            ├── story.json
            └── *.ogv
```

`StoryController` is registered as an **Autoload** in Project Settings, making it accessible to all scenes without needing node path references.

### 3.3 State Machine

`StoryController` implements a simple GDScript state machine using an **enum** for state types and a **Dictionary array** (loaded from JSON) as the state list. It emits signals that UI nodes connect to in `_ready()`.

**State types (GDScript enum):**

| State Type | Description |
|---|---|
| `SCENE` | Plays a `.ogv` clip; advances automatically when `VideoStreamPlayer` emits `finished`. |
| `LOOP` | Plays a `.ogv` clip in a loop (`loop = true`); held until the player makes a decision. |
| `DECISION` | No video change; activates `DecisionBar` and `AdvisorSidebar`. Transitions on player input. |
| `CONSEQUENCE` | Plays a `.ogv` clip; on `finished` rewinds to the originating `DECISION` state. |
| `FINAL` | Terminal state; hides all gameplay UI and shows `ScoreScreen`. |

**Signals emitted by `StoryController`:**

| Signal | Payload | Purpose |
|---|---|---|
| `state_changed(state)` | current state dict | Drives video swap, UI visibility |
| `decision_required(options, advisors)` | option data, advisor data | Populates `DecisionBar` and `AdvisorSidebar` |
| `story_finished(score, total)` | ints | Triggers `ScoreScreen` |

**State transitions:**

- `SCENE` → next state (on `VideoStreamPlayer.finished`)
- `LOOP` → `DECISION` (immediately; loop plays until player acts)
- `DECISION` → `CONSEQUENCE` (wrong answer) or next `SCENE`/`FINAL` (correct)
- `CONSEQUENCE` → originating `DECISION` (on `VideoStreamPlayer.finished`)
- `FINAL` → score screen (via `story_finished` signal)

### 3.4 Story Configuration

Each story is defined as a `story.json` file loaded at runtime using Godot 4's `FileAccess` + `JSON.parse_string()`. The file lives at `res://data/stories/<story_id>/story.json` inside the PCK.

The JSON structure defines:
- Story metadata (title, period, character)
- An ordered array of states, each with a `type` and asset filename
- For each `DECISION` state: the two options, which is correct, the index of the associated `CONSEQUENCE` state, and whether it is `final`
- An array of advisor definitions (name, role, avatar filename, and per-decision response text keyed by decision index)

TODO — write and publish the full JSON schema

### 3.5 Asset Pipeline

All video is **pre-rendered `.ogv` (Theora)** files with audio baked in. Godot's `VideoStreamPlayer` node natively supports Theora across all export targets, making `.ogv` the single format needed for both Web and Windows exports. No runtime audio mixing is required for the initial version.

Video files live alongside `story.json` inside the PCK at `res://data/stories/<story_id>/`. Asset filenames are referenced directly in the story config. The naming convention for the initial example story is:

```
healer_intro
healer_decision_1_loop
healer_decision_1_wrong
healer_decision_1_correct
healer_decision_2_loop
healer_decision_2_wrong
healer_decision_2_correct
healer_final
```

TODO — define canonical asset naming convention for future stories  
TODO — specify video resolution, bitrate, and frame rate targets

---

## 4. User Interface

### 4.1 Layout

```
┌──────────────────────────┬──────────┐
│                          │          │
│       Video Player       │ Advisor  │
│        (~75% width)      │ Sidebar  │
│                          │          │
├──────────────────────────┴──────────┤
│         Decision Bar                │
│  [Option A]  prompt text  [Option B]│
└─────────────────────────────────────┘
```

- **Video player** — top-left, approximately 3/4 of the window width. Fills available height above the decision bar.
- **Advisor sidebar** — top-right, remainder of window width. Shows the selected advisor's response text.
- **Decision bar** — full-width strip along the bottom. Contains the two choice buttons and short supplementary text.

### 4.2 States and UI Behaviour

| Application State | Video | Decision Bar | Advisor Sidebar |
|---|---|---|---|
| Playing a scene | Playing (auto-advance) | Hidden | Hidden |
| At a decision | Looping | Visible | Available |
| Playing consequence | Playing | Hidden | Hidden |
| Score screen | Hidden | Hidden | Hidden |

### 4.3 Advisor Sidebar
- Displays a list of available advisors for the current story. Each advisor entry shows their **avatar image**, **name**, and **role label**.
- Selecting an advisor replaces the sidebar content with that advisor's static response text for the current decision.
- If no advisor is selected the sidebar content area is empty.
- The response text area is a scrollable container; text that exceeds the visible area can be scrolled without resizing the sidebar.
- Sidebar is only active during decision states.

### 4.4 Score Screen
Displayed when the final state is reached. Consists of:
- A **static background image** that fills the window.
- The score rendered in **large font**, overlaid on the image. Font colour is determined by the player's score as a percentage of total decisions:

| Score % | Colour |
|---|---|
| 100% | Green |
| 50% | Yellow |
| 0% | Red |

Intermediate percentages interpolate between these three values (e.g. 75% → yellow-green, 25% → yellow-red).

TODO — confirm whether linear colour interpolation is wanted or fixed bands (e.g. ≥67% green, ≥34% yellow, else red)  
TODO — replay / next story options?

---

## 5. Example Story — The Mediaeval Healer

The initial example story to validate the framework.

**Character:** A mediaeval healer woman  
**Decisions:** 2  
**Advisors:** TODO — define up to 3 (e.g. local priest, monastic scholar, village elder?)

### Story Flow

```
healer_intro (scene)
    ↓
healer_decision_1_loop (loop) ← rewind target
    ↓ [decision 1]
    ├─ Wrong → healer_decision_1_wrong (consequence) → rewind
    └─ Correct → healer_decision_1_correct (scene)
                     ↓
         healer_decision_2_loop (loop) ← rewind target
                     ↓ [decision 2]
                     ├─ Wrong → healer_decision_2_wrong (consequence) → rewind
                     └─ Correct → healer_decision_2_correct (scene)
                                       ↓
                                  healer_final (final)
```

TODO — write the actual decision scenarios (historically grounded choice prompts, option text, correct answer rationale)  
TODO — write advisor response text for each decision  
TODO — produce or source video assets

---

## 6. Out of Scope (Initial Version)

- Branching story paths (all stories are linear with rewind; true branching is a future consideration)
- More than two choices per decision point
- Runtime audio mixing or text-to-speech
- User accounts or persistent progress
- Analytics or learning outcome tracking
- Accessibility features (captions, screen reader support)

TODO — confirm which of these are planned for future iterations and prioritise accordingly
