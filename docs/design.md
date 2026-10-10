# Ora design direction

The supplied Mito reference informed the quiet, one-step-at-a-time intake: an ivory card, restrained typography, soft olive and blue-green background, progress line and short choices. The Thesis reference informed the editorial hierarchy, spacious composition and confident simplicity. The references are inspiration, not embedded or copied product screens.

Ora uses warm ivory, dark olive, sage and soft stone. Georgia supplies expressive serif headlines; locally served DM Sans handles functional copy. The identity is intentionally restrained: a lowercase wordmark, few borders, generous space, natural light, and careful language that puts the person before financing.

The operations workspace uses the same materials and typography, with denser readable records, muted status markers, explicit next steps, and the patient journey as its central object.

## Original hero asset

File: `app/assets/images/ora-editorial.jpg`

Mode: built-in image generation; original image, generated for this project. Converted to an optimised JPEG for browser delivery.

Prompt:

> Use case: photorealistic-natural. Asset type: luxury healthcare brand website hero photograph. Create a refined editorial photograph of a beautiful dark-skinned Nigerian woman in her early thirties, natural skin texture, hair pulled back, wearing an ivory linen sleeveless top, relaxed face eyes gently closed, enjoying warm late afternoon sunlight in an architectural wellness retreat. Waist-up portrait, head and shoulders fully in frame, positioned slightly right of center, gaze turned softly to left. Warm beige travertine wall background with organic large leaf shadow, muted olive foliage at far right, rich tactile film grain, quietly confident and peaceful. Sophisticated fashion editorial photography, natural beauty, no medical equipment, no text, no logos. Vertical portrait composition 1024x1536, usable as a large cropped hero image.

The portrait is an illustrative brand image, not a patient, provider or testimonial. Category glyphs are code-native SVG line icons.

## Landing hero video and comparison still

Files: `public/videos/ora-hero-1080.mp4`, `public/videos/ora-hero-720.mp4`, `app/assets/images/ora-hero-poster.jpg`, `app/assets/images/ora-consultation.jpg`

Source: Pexels video 5356058 (a dentist talks a patient through treatment with a model of the teeth), downloaded in its 1920×1080 and 1280×720 renditions under the Pexels License, which allows free use without attribution. The poster (0.1s) and the comparison still (3.8s) are frames taken from the 1080p file. The videos live in `public/` rather than `app/assets/` because the Propshaft asset server does not answer byte-range requests, which Safari needs for video. The clinic's door signage is cropped out in CSS, and the page footnotes the imagery as illustrative.

Second hero scene: `public/videos/ora-cosmetic-1080.mp4` (2048×1080) and `public/videos/ora-cosmetic-720.mp4` (1366×720), with the poster `app/assets/images/ora-cosmetic-poster.jpg` taken at 0.1s. Source: Pexels video 7581710 (a clinician's gloved hands assessing a patient's face), Pexels License. It is mirrored on wider screens so the face sits clear of the headline. The hero crossfades between the two scenes as the treatment rotator moves: teeth options use the dental scene, and the body and eye options use this one.

## Cosmetic concept images

Files: `app/assets/images/ora-concept-front.jpg` and `app/assets/images/ora-concept-profile.jpg`. Both are original built-in image generation outputs, converted to JPEG for the homepage. They depict fictional adult West African women. They are labeled on the page as AI illustrations, never as patient results or predictions.

Prompts: two matching-pose, matching-light before-and-after editorial diptychs of the same fictional adult Black Nigerian woman, showing only a subtle imagined rhinoplasty refinement. The first uses a front-facing portrait in a black top; the second uses a half-profile in a cream top. Both request natural skin texture and preservation of identity, age, expression, hair, wardrobe, and all non-nose facial features, with no text, logos, beauty filter, or skin lightening. The Magnific stock catalog and the user-provided gallery screenshot informed the presentation, but no third-party portrait was copied into these assets.
