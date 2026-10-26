---
name: see-image
description: "Auto-trigger, no confirmation needed: whenever the user references any image (local file path, screenshot, sprite, mockup, or an http(s) URL) and the active model is not multimodal, invoke this skill immediately. Triggers: user asks to look at / see / describe an image, or what is on a picture, or what text is written in it; needs pixel coordinates of a UI element; needs the background/transparency boundary of a sprite; needs OCR of text in an image; user pastes an http(s) image link; design review / layout QA after building UI (compare to mockup, check what's misaligned); or self-verification of UI work against acceptance criteria."
---

# See Image (vision via opencode run)

When the active model cannot read images (e.g. glm-5.x, deepseek-coder, etc.),
delegate the visual task to a **vision-capable** model through a one-shot
`opencode run` call.

## ⚠ CRITICAL: use `--file`, NOT a path in the prompt text

Older versions of this skill passed the image path inside the prompt string and
relied on the model calling `filesystem_read_media_file` as a tool. **That does
not work with `opencode run`** — `run` is single-turn, so when the model emits a
tool-call the session ends before the tool result is fed back, and you get an
**empty answer**. You may even see the tool-call line printed, then silence.

The fix: pass the image with the **`-f` / `--file`** flag. opencode embeds the
image bytes directly into the message — no tool-call, no second turn needed.

## ⚠ CRITICAL: use `--agent vision`, NOT `-m <model>` directly

`--pure` does **not** disable skills or MCP servers (verified empirically —
`init count=N` / "duplicate skill name" still shows up in `--print-logs` output
even with `--pure`). If you invoke the vision model with a bare `-m`, it still
gets the full agentic toolset: it can (and sometimes does) call the
`see-image` skill on itself, or an unrelated MCP tool (e.g. an `angular-cli`
tool), before answering. Each of those detours adds tens of seconds and can
end the single-turn `run` with a raw `<skill>...</skill>` tag instead of a
real answer — a much longer and flakier failure mode than the old
`filesystem_read_media_file` hang.

The fix: a dedicated `vision` agent (defined in `opencode.json`, see below)
with **every tool disabled** (`tools: {"*": false}`) and `steps: 1`. With no
tools available, the model has no choice but to answer directly from the
image in context. Always invoke it as `--agent vision`, never `-m <model>`.

You still **MUST** pass **`--pure`** as well — it disables plugins, which is a
real (if partial) risk-reduction layer independent of the agent's own tool
list.

You **MUST** put **`--`** before the prompt text. `-f` is an array flag in yargs,
so without `--` the prompt string is consumed as another file path and you get
`Error: File not found: <your prompt text>`.

## Required one-time setup: the `vision` agent

Add this to `opencode.json` (global `~/.config/opencode/opencode.json` or
project-level) if it isn't there already:

```json
{
  "agent": {
    "vision": {
      "model": "lll-dataforseo/Qwen/Qwen3.6-27B-FP8",
      "mode": "primary",
      "steps": 1,
      "tools": { "*": false },
      "permission": {
        "skill": "deny",
        "task": "deny",
        "bash": "deny",
        "webfetch": "deny",
        "websearch": "deny"
      }
    }
  }
}
```

Every recipe below assumes this agent exists. If `opencode run --agent vision`
fails with "unknown agent", add this block first.

## When to Use

- User asks "what's in this picture?" / "describe this screenshot" / "look at this screen"
- You hit `ERROR: ... this model does not support image input`
- Need **pixel coordinates** of a UI element on a screenshot
  (e.g. "where is button X on this screenshot")
- Need the **transparent/background boundary** of a sprite
  (e.g. "at which pixels does the background end")
- OCR of text embedded in an image / mockup / Figma export
- User pastes an **http(s) URL** to an image and asks anything about it — the
  file is NOT local, so download it first (see Recipe 6)
- Verifying generated pixel-art props, sprite sheets, or layout screenshots
- Comparing two images visually
- **Design review / layout QA** — user drops a screenshot of something you (or
  someone) just built and asks what looks wrong: misaligned / off-center
  elements, overlapping text, inconsistent spacing, low contrast, overflow.
- **Self-verification** — after you finish a UI task, proactively run a review
  pass on a screenshot before reporting "done" (see Design Review below).

## The Model

```
lll-dataforseo/Qwen/Qwen3.6-27B-FP8
```

A 27B Qwen 3.6 vision model served via the `lll-dataforseo` provider.
Confirmed working for: object description, sprite analysis, pixel-coordinate
requests, screenshot inspection. No API key juggling — it is already
configured as an opencode provider.

## The Command (canonical form)

```bash
opencode run --pure --agent vision \
  --file /abs/path/to/img.png -- \
  "<YOUR QUESTION>"
```

Rules — all three parts are mandatory:
- **`--pure`** — disables plugins for this call. Reduces surface area, but by
  itself does **not** stop skill/MCP tool access — that's what `--agent vision`
  is for (see above). Use both together.
- **`--agent vision`** — the tools-disabled agent (see setup above). This is
  what actually prevents the model from calling `see-image` on itself or
  reaching for an unrelated MCP tool instead of just answering.
- **`--file /abs/path`** (`-f`) — embeds the image bytes into the message. May be
  repeated for multiple images (Recipe 5). Works with any readable path on disk,
  including paths outside the MCP filesystem allowed-dirs (it is read by the
  opencode core, not by an MCP server). Supports PNG, JPG, and common formats.
- **`--`** — yargs terminator. Required so the prompt text after `--` is treated
  as the message, not as another value for the array `--file` flag. Omitting it
  yields `Error: File not found: <your prompt>`.

Other notes:
- `opencode run` is **non-interactive** — it answers once and exits.
- Set a generous timeout (e.g. 120–180s): vision inference is slower than text.
- **For an http(s) URL**: opencode will NOT auto-fetch it. Download to a temp
  file first (Recipe 6), then pass it with `--file`.
- Always write prompts to the vision model **in English**, regardless of what
  language the user is speaking with you — this keeps behavior consistent
  across sessions and avoids the model degrading on mixed-language input.

## Recipe Patterns

### 1. Describe what's on an image
```bash
opencode run --pure --agent vision \
  --file /abs/path/to/img.png -- \
  "Describe in detail what is shown in this image."
```

### 2. Pixel coordinates of a UI element (for clicking / assertions)
```bash
opencode run --pure --agent vision \
  --file /abs/path/screenshot.png -- \
  "Find the 'Save' button in this screenshot. Return only its center as x,y (pixel coordinates from the top-left corner)."
```

### 3. Background / transparency boundary of a sprite
```bash
opencode run --pure --agent vision \
  --file /abs/path/sprite.png -- \
  "This is an LPC sprite. What are the approximate pixel bounds (X/Y) of the opaque object? Where does the transparent background start?"
```

### 4. OCR text from a screenshot / mockup
```bash
opencode run --pure --agent vision \
  --file /abs/path/mockup.png -- \
  "Transcribe all visible text in this image."
```

### 5. Compare two images (repeat `--file` once per image)
```bash
opencode run --pure --agent vision \
  --file /abs/a.png --file /abs/b.png -- \
  "Compare these two images and describe the differences. The first is /abs/a.png, the second is /abs/b.png."
```
The model sees both images in order; name them in the prompt so it can refer to
each unambiguously. You can attach 3+ images the same way.

### 6. Image given as a URL (download first, then analyze)

opencode cannot fetch a URL itself. Download to a temp file first, then pass it
with `--file`. One bash invocation does both:

```bash
TMP="$(mktemp --suffix=.png)" && \
curl -fsSL "<IMAGE_URL>" -o "$TMP" && \
opencode run --pure --agent vision \
  --file "$TMP" -- \
  "What text is written in this image? Transcribe all visible text." ; \
rm -f "$TMP"
```

Notes:
- The `--suffix` hints the format; some providers sniff by extension. If the
  model returns garbage, mirror the real extension: `TMP="$(mktemp).jpg"`.
- `curl -fsSL` follows redirects and fails fast on a bad link — check the
  bash exit code if nothing comes back.
- Works for any question, not just OCR — swap the prompt (describe, coords,
  compare-with-another-URL by downloading twice, etc.).
- Clean up the temp file (`rm -f "$TMP"`) so `/tmp` doesn't pile up.

## How to Apply Results

- The command prints the model's answer to stdout — read it from the bash output.
- For **coordinate** answers, parse `x,y` from the last line and use them in
  your downstream tool calls (clicks, assertions, crop regions, etc.).
- Vision models can be approximate on exact pixel counts — treat coordinates
  as ±a few px.
- Translate the model's answer into whatever language the user is speaking
  with you when you relay it back — only the prompts sent to the vision model
  itself stay in English.

## Design Review / Layout QA

Use this AFTER you (or someone) has built UI and there is a screenshot to
judge. The vision model is good at **seeing** but bad at **guessing intent** —
so always give it explicit criteria to check against, and ask for a
**structured verdict** (not a free-form description). Otherwise it will just
say "looks fine".

### Core principles for review prompts

1. **State the acceptance criteria explicitly.** "The Save button must be
   horizontally centered; bottom margin 24px; text must not overlap the icon."
   The model judges what you tell it to judge.
2. **Ask for a verdict + a numbered defect list with coordinates.**
   "Answer PASS or FAIL. If FAIL, list the problems, each with coordinates
   (x,y) and what exactly is wrong."
3. **Name the defect categories you care about** so the model scans for them:
   alignment / centering, vertical rhythm (equal spacing between rows),
   overlaps (text-over-icon, text-over-text), contrast (WCAG-ish), text
   overflow / truncation, color consistency vs. a reference, missing assets
   (broken images, empty slots).
4. **Pass a reference when possible** (Figma export, the design mockup, or a
   "known-good" screenshot). Comparing two images is far more reliable than
   judging one in a vacuum — see recipe 9.
5. **For pixel-exact centering**, don't ask "is it centered?". Ask the model
   to return the centers (x,y) of BOTH the container and the element, then
   compare them yourself in code. The model's eye is ±a few px; arithmetic is
   exact.
6. **Constrain output format** to make parsing reliable: "return a JSON array:
   [{issue, x, y, severity}]" or "one problem per line, format:
   `severity | x,y | description`".

### 7. Review a built UI against a textual spec

```bash
opencode run --pure --agent vision \
  --file /abs/path/ui.png -- \
"You are a nitpicky QA layout reviewer. Criteria:
- Title is horizontally centered.
- 'Save' button is right-aligned within the card, bottom margin 16px.
- Equal vertical rhythm between list rows.
- No overlap of text-over-text or text-over-icon anywhere.
Answer on the first line: PASS or FAIL. If FAIL, give a numbered list of
issues, each in the format: severity(CRITICAL|MAJOR|MINOR) | x,y | what's wrong."
```

### 8. Pixel-exact centering check (model returns coords, YOU judge)

```bash
opencode run --pure --agent vision \
  --file /abs/path/ui.png -- \
"Return ONLY JSON:
{\"card_center\":[x,y], \"button_center\":[x,y], \"title_center\":[x,y],
 \"image_w\":w, \"image_h\":h}. Coordinates from the top-left corner in pixels."
```
Then compute `button_center[0] vs card_center[0]` yourself — if they differ
by more than ~2px, it's off-center. This is more trustworthy than asking
"is it centered?".

### 9. Compare built UI vs. design mockup (most reliable review)

```bash
opencode run --pure --agent vision \
  --file /abs/path/design.png --file /abs/path/built.png -- \
"Compare the implementation against the mockup. The first image is the mockup
(reference), the second is the implementation (screenshot). List ONLY the
discrepancies: position, size, color, spacing, missing elements. For each
discrepancy, state which of the two is correct (per the mockup). Ignore minor
anti-aliasing."
```

### 10. Quick "what looks off" pass (no spec available)

When you have no formal criteria, still get a structured answer:

```bash
opencode run --pure --agent vision \
  --file /abs/path/ui.png -- \
"List any visual problems that stand out (overlaps, off-center elements,
inconsistent spacing, truncated text, low contrast, broken images). For each,
give coordinates (x,y) and a short description. If everything looks fine,
answer PASS."
```

### Self-verification workflow (recommended after non-trivial UI work)

1. Take/obtain a screenshot of the result the user provided.
2. Run **Recipe 7** if you have a spec, else **Recipe 10**.
3. If verdict is FAIL, fix the top issues, re-screenshot, re-run.
4. Report "done" only after a PASS (or after explicitly telling the user
   which flagged items you intentionally left as-is and why).

### Known limits to keep in mind

- Coordinates are approximate (±a few px). For sub-pixel layout assertions,
  prefer reading the DOM / computed styles over vision.
- The model can mis-read very small text or thin 1px borders — bump screenshot
  resolution / DPI if a detail matters.
- Color matching is qualitative; for exact color checks use a pixel sampler,
  not vision.
- It will sometimes hallucinate "issues" that are intentional (e.g. a
  deliberate asymmetry). Sanity-check each flagged item against the spec
  before "fixing" it.

## Troubleshooting: empty output / session hangs / very slow

Symptom: `opencode run` prints the model banner, maybe a
`filesystem_read_media_file {...}` line, then nothing — no answer.

Cause: you forgot `--file` (the model tried a tool-call to read the image, but
`run` is single-turn and never feeds the tool result back).

Fix: use the canonical form — `--pure` + `--agent vision` + `--file <path>` +
`--` + prompt. See "The Command" above.

Symptom: the command takes 30–90+ seconds even though a manual test of the
exact same command in a plain terminal was fast, or the output is a raw
`<skill><name>see-image</name></skill>` tag instead of a real answer, or you
see an `Invalid Tool` error mentioning an unrelated MCP tool (e.g.
`angular-cli_...`).

Cause: you invoked with `-m <model>` instead of `--agent vision`. The bare
model has the full toolset (skills + MCP servers) available and occasionally
calls one of them instead of answering directly — each detour costs real
wall-clock time against the remote provider. `--pure` alone does not prevent
this (confirmed via `--print-logs`: skills still load and MCP tools are still
offered even with `--pure`).

Fix: switch to `--agent vision` (see "Required one-time setup" above). With
every tool disabled, the model has nothing to call but the image in context.

Symptom: `Error: File not found: <your prompt text>`.

Cause: you omitted `--` before the prompt, so yargs treated the prompt as
another value for the array `--file` flag.

Fix: add `--` between the last `--file` and the prompt text.

## Verification Snippet

Quick smoke-test that vision still works:

```bash
opencode run --pure --agent vision \
  --file /abs/path/to/any.png -- \
  "What is in this image?"
```

If you see a coherent description → provider is up. If you get an auth error
or empty output, the `lll-dataforseo` provider credentials may have expired;
check `opencode providers`.
