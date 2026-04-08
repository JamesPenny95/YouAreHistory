# Story Asset Guide (Plain English)

This guide explains how to build new story content for YouAreHistory without touching game code.

## 1. Quick Summary

A story is a folder with:
- one `story.json` file (the flow + text)
- video/image assets used by that JSON

The game reads `story.json`, then moves through states in order.

## 2. Folder Layout

Create a folder per story under `data/stories`:

```text
res://data/stories/
  healer_2/
    story.json
    healer_intro.ogv
    healer_decision_1_wrong.ogv
    healer_decision_1_correct.ogv
    decision_background.png
    Garlic.png
    Garlic_Text.png
    Ladle.png
    Ladle_Text.png
    end_screen.png
```

## 3. Video Format (What To Export)

Use `.ogv` videos (Theora) for story clips.

Recommended target settings:
- Container: `Ogg`
- Video codec: `Theora`
- File extension: `.ogv`
- Audio codec: `Vorbis` (or no audio if silent)
- Resolution: `1920x1080` (recommended baseline)
- Frame rate: `30 fps` (keep consistent across all clips)
- Pixel aspect ratio: `1:1`
- Display aspect ratio: `16:9`

Why this matters:
- mixed resolutions/fps/aspect values cause visual jumps between states
- browser exports (HTML5) are more sensitive to odd encodes

## 4. Metadata To Check In VLC

In VLC, open clip -> `Tools` -> `Codec Information`.

Record these values for each clip:
- Width / Height
- Frame rate (fps)
- Pixel aspect ratio (SAR)
- Display aspect ratio (DAR)
- Audio sample rate/channels (if using audio)

All clips in one story should match these as closely as possible.

## 5. State Types (How Story Flow Works)

Main state types you will use:
- `SCENE`: plays a video, then auto-moves to `next_state`
- `DECISION`: asks a question with 2 options (binary choice)
- `CONSEQUENCE`: plays wrong-answer outcome, then rewinds
- `FINAL`: ends story and shows score screen

Important:
- Current authoring style uses `DECISION` with either:
  - `background` image, or
  - `video` clip
- Do not set both `background` and `video` on the same `DECISION` (or `FINAL`) state.

## 6. Decision States (Options + Art)

Each decision has exactly 2 options.

Per option you can provide:
- `label`: text fallback
- `label_image`: image for label text (if present, this is shown instead of label text)
- `image`: the main choice icon/image
- `prompt`: short helper text value

Example option object:

```json
{ "label": "Garlic?", "label_image": "res://data/stories/healer_2/Garlic_Text.png", "prompt": "Garlic", "image": "res://data/stories/healer_2/Garlic.png" }
```

## 7. Rewind Behavior (Wrong Answers)

For a wrong answer:
1. game jumps to `consequence_state`
2. consequence video plays
3. game rewinds to `rewind_to` (usually the decision state id)

Score rule:
- player only gets the point if their first answer was correct

## 8. Minimal Story JSON Template

Use this as a starter:

```json
{
  "title": "Story Title",
  "period": "Time Period",
  "character": "Who the player is",
  "states": [
    {
      "id": "intro",
      "type": "SCENE",
      "video": "res://data/stories/my_story/intro.ogv",
      "next_state": "decision_1"
    },
    {
      "id": "decision_1",
      "type": "DECISION",
      "background": "res://data/stories/my_story/decision_bg.png",
      "prompt": "Which option should they choose?",
      "options": [
        { "label": "Option A", "image": "res://data/stories/my_story/option_a.png" },
        { "label": "Option B", "image": "res://data/stories/my_story/option_b.png" }
      ],
      "correct_option": 0,
      "consequence_state": "decision_1_wrong",
      "next_state": "decision_1_correct"
    },
    {
      "id": "decision_1_wrong",
      "type": "CONSEQUENCE",
      "video": "res://data/stories/my_story/decision_1_wrong.ogv",
      "rewind_to": "decision_1"
    },
    {
      "id": "decision_1_correct",
      "type": "SCENE",
      "video": "res://data/stories/my_story/decision_1_correct.ogv",
      "next_state": "final"
    },
    {
      "id": "final",
      "type": "FINAL",
      "background": "res://data/stories/my_story/end_screen.png"
    }
  ]
}
```

## 9. Authoring Rules Checklist

Before testing, check all of these:
- every state has a unique `id`
- all `next_state`, `consequence_state`, and `rewind_to` ids exist
- every `DECISION` has exactly 2 options
- `correct_option` is `0` or `1`
- `DECISION` and `FINAL` use only one media source: `background` OR `video`
- all `res://...` file paths are correct and case-safe
- all videos in the story share the same fps/resolution/aspect

## 10. Naming Tips (Keep It Predictable)

Recommended names:
- `intro.ogv`
- `decision_1_wrong.ogv`
- `decision_1_correct.ogv`
- `decision_background.png`
- `end_screen.png`
- `OptionA.png`, `OptionA_Text.png`

Consistency is more important than the exact naming style.

## 11. Common Problems and Fixes

Problem: video and decision screen do not line up
- Fix: make sure decision background art uses the same framing as video (same target aspect and safe zones)

Problem: choice label image not showing
- Fix: check `label_image` path and file exists; if missing, game falls back to `label`

Problem: story does not start or freezes
- Fix: verify all state ids and transitions are valid; check for typos in `next_state` or `rewind_to`

Problem: black bars differ between clips
- Fix: re-export clips to same DAR/SAR and resolution

## 12. Suggested Workflow

1. Create story folder and put placeholder assets in place
2. Write `story.json` with full state flow
3. Add decision/background images
4. Add final videos and check VLC metadata
5. Run in engine and exported HTML5 build
6. Fix framing first, then polish text/images

---

If you want, this guide can be followed by a one-page "story.json validator" checklist for producers (non-technical) before handing assets to dev.
