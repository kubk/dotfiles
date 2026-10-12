---
name: visual-tuner
description: Automatically add live visual-tuning controls, then commit accepted values and remove the temporary panel.
---

# Visual Tuner

Apply this workflow automatically when the user asks to visually tune a page; they do not need to invoke `$visual-tuner` by name. Add a compact floating panel for the relevant page area.

- Use ordinary `input type="number"` fields, not range sliders. Set useful units and steps; use a step of 1 for pixel values so arrow keys adjust by one pixel.
- Bind each field to the page so changes update immediately. Include the relevant values, such as position, padding, gaps, font size, or line height; preserve responsive variants and their starting values.
- Keep the panel focused on the requested area, labeled, keyboard accessible, and out of the way. Show it only in development unless the user asks for it in production.
- Treat a final value (for example, “keep 22”) or a screenshot of the chosen result in the tuning conversation as approval to finish. Apply the visible or stated values to permanent page styles immediately, then remove the temporary panel, state, and helper code without asking again.
- For a screenshot without readable field values, match its appearance as closely as the source styles allow, commit those styles, and remove the temporary controls.
