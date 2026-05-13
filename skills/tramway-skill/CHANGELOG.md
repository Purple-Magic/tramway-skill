# Changelog

## 1.5.5

- Strengthened state-change recipe routing so show-page buttons that call state-transition methods load the recipe before route or controller design.

## 1.5.4

- Clarified that the state-change recipe applies to button actions that imply a business state transition by calling a record method.

## 1.5.3

- Reverted the expanded state-change recipe trigger for record-page buttons that call object methods.

## 1.5.2

- Expanded the state-change recipe trigger to cover record-page buttons that call methods on the current object.

## 1.5.1

- Refined shared Set Form recipe references, clarified controller assumptions, generalized shared recipe examples, and fixed the state-change recipe typo.

## 1.5.0

- Added an empty state-change recipe and linked it for record state changes triggered by a button.

## 1.3.3

- Added changelog management instructions so every future version bump records what the user asked to change.
- Created this changelog for tracking `tramway-skill` version changes.

## 1.3.2

- Updated the welcome/default prompt to show the active `tramway-skill` version.
- Added an instruction to keep displayed welcome/default-prompt versions synchronized with `VERSION`.

## 1.3.1

- Updated repository instructions to require semantic version increments for every repository-changing task.
- Normalized incomplete semantic versions by treating missing components as `0` before applying the required bump.
