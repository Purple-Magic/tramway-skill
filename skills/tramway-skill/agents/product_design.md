# Product Design

Guidance for shaping data models and product behavior, not just implementing what's asked literally.

1. Before adding a new attribute (column, `data`/jsonb key, or derived field) to a model, check whether an existing attribute on that model already represents the same or a strongly similar fact (e.g. two booleans/enums that both answer "is this record in state X", a duplicate timestamp, a status mirrored in two places). If one exists, do not add the new attribute. Instead, propose to the user that the existing attribute be reused or the two be merged into one, explain the overlap you found, and wait for their decision before proceeding.
2. When you find two existing attributes that already duplicate each other (not just when adding a new one), flag the overlap to the user and propose consolidating them, even if that wasn't the task you were asked to do.
3. When you do add or keep an attribute, name it and document it (comment, decorator label, locale key) in terms of the concept it represents, not the mechanism that produced it, so future duplication is easier to spot.
