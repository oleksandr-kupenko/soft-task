# Vision QA prompt templates

Use with `see.sh <image> "<prompt>"`.

## Visual spec (before build)

```
Describe this UI design for a text-only implementer.
Top to bottom: blocks, layout, spacing guesses, reusable components, colours/tokens, states, visible texts.
Copy any exact sizes, gaps, fonts, hex colours you can read.
Do not say "see the image". Words only. No markdown fences around the whole answer.
```

## Visual acceptance (after build)

```
Compare this screenshot to the acceptance criteria below.
Reply with exactly:
VERDICT: PASS | FAIL
FIXES:
- <element> | <what is wrong> | <what it should be>
If PASS, FIXES may be empty. Max 10 fixes. No prose outside that format.

Acceptance criteria:
<paste from ticket / visual/NN.md>
```

## OCR / presence

```
List all readable text in reading order.
Then answer: is <X> present? yes/no.
```
