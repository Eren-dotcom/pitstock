# Part-recognition model (optional, makes Photo-ID far more accurate)

The app works **without any model** — it falls back to Google ML Kit's free,
offline generic image labeller. Drop a trained model here to upgrade it to
true **spare-part-specific** recognition.

## What to put here
- `parts_model.tflite`  — a MobileNet-style image classifier (input 224×224×3,
  float 0..1), output = softmax over your classes.
- `parts_labels.txt`    — one class label per line, in the SAME order as the
  model's output. Example:
  ```
  Brakes
  Filters
  Battery
  Tyres
  Spark Plug
  Headlight
  Wiper Blade
  ...
  ```

Once both files exist and are listed under `assets/models/` in `pubspec.yaml`
(already configured), the app auto-detects and uses the custom model. If loading
fails for any reason, it silently falls back to ML Kit.

## How to train one (free, ~30 min)
See `tools/train_parts_model.py` for a ready-to-run Teachable-Machine-style
transfer-learning script using TensorFlow/Keras + MobileNetV2, which exports a
quantised `.tflite` and the matching `parts_labels.txt`.

Fastest no-code option: https://teachablemachine.withgoogle.com → Image Project
→ add a few dozen photos per part category → Export → TensorFlow Lite →
Floating-point → download `model.tflite` + `labels.txt`, rename to
`parts_model.tflite` / `parts_labels.txt`, and place them here.
