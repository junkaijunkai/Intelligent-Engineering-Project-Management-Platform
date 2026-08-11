# Reproducible screen-only App Demo

This renderer follows the same evidence-video approach used by the reference internship project: clean browser screenshots are converted into a deterministic video with human-eased cursor motion and click-driven camera zooms. It does not use macOS screen recording, a microphone, or a camera.

## Render

Requirements: Node.js, FFmpeg, and FFprobe.

```bash
npm run demo:record
```

The default output is `output/pmhub-app-demo-screen-only.mp4`, with a matching timing/probe manifest. The video is 1920×1080 at 30 fps, lasts 4 minutes 30 seconds, and contains a silent AAC track so it can be imported directly into common editors.

The captured screenshot assets are deterministic local-demo states:

1. dashboard;
2. full project portfolio;
3. archived project filter;
4. task execution;
5. pending approvals;
6. completed approval audit trail;
7. dashboard close.

The narration remains in `docs/app-demo-script.md` and can be recorded separately if required.

Generated based on `@pmhub-ui`, `@docs/app-demo-script.md`, and the reference internship commit `d547337` (`feat(recording): add click-driven App Demo motion preview`).
