#!/usr/bin/env python3
"""
Train a spare-part image classifier and export it for PitStock.

Outputs:
  assets/models/parts_model.tflite
  assets/models/parts_labels.txt

USAGE
-----
1. Collect images into folders, one folder per class:

   dataset/
     Brakes/        img1.jpg img2.jpg ...
     Filters/       ...
     Battery/       ...
     Tyres/         ...
     Spark Plug/    ...
     Headlight/     ...

   Aim for 30-100+ photos per class, varied angles/lighting/backgrounds.
   Class folder names become the labels (and ideally match PitStock
   categories so matches map straight to inventory).

2. Install deps:
     pip install "tensorflow==2.15.*" pillow

3. Run:
     python tools/train_parts_model.py --data dataset --epochs 15

This uses MobileNetV2 transfer learning (input 224x224x3, normalised 0..1),
which exactly matches the preprocessing in PartRecognitionService.
"""
import argparse
import os
import pathlib

import tensorflow as tf

IMG_SIZE = 224
BATCH = 16


def build_datasets(data_dir):
    train = tf.keras.utils.image_dataset_from_directory(
        data_dir, validation_split=0.2, subset="training", seed=123,
        image_size=(IMG_SIZE, IMG_SIZE), batch_size=BATCH)
    val = tf.keras.utils.image_dataset_from_directory(
        data_dir, validation_split=0.2, subset="validation", seed=123,
        image_size=(IMG_SIZE, IMG_SIZE), batch_size=BATCH)
    class_names = train.class_names
    # normalise to 0..1 (matches the Flutter side)
    norm = tf.keras.layers.Rescaling(1.0 / 255)
    aug = tf.keras.Sequential([
        tf.keras.layers.RandomFlip("horizontal"),
        tf.keras.layers.RandomRotation(0.1),
        tf.keras.layers.RandomZoom(0.1),
    ])
    train = train.map(lambda x, y: (norm(aug(x)), y)).prefetch(tf.data.AUTOTUNE)
    val = val.map(lambda x, y: (norm(x), y)).prefetch(tf.data.AUTOTUNE)
    return train, val, class_names


def build_model(num_classes):
    base = tf.keras.applications.MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3), include_top=False, weights="imagenet")
    base.trainable = False
    return tf.keras.Sequential([
        base,
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(num_classes, activation="softmax"),
    ])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True, help="dataset folder (one subfolder per class)")
    ap.add_argument("--epochs", type=int, default=15)
    ap.add_argument("--out", default="assets/models")
    args = ap.parse_args()

    train, val, class_names = build_datasets(args.data)
    print("Classes:", class_names)

    model = build_model(len(class_names))
    model.compile(optimizer="adam",
                  loss="sparse_categorical_crossentropy",
                  metrics=["accuracy"])
    model.fit(train, validation_data=val, epochs=args.epochs)

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    # Export TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite = converter.convert()
    (out_dir / "parts_model.tflite").write_bytes(tflite)

    # Export labels (same order as model output)
    (out_dir / "parts_labels.txt").write_text("\n".join(class_names))

    print(f"\n✅ Saved {out_dir/'parts_model.tflite'}")
    print(f"✅ Saved {out_dir/'parts_labels.txt'}")
    print("Rebuild the app — PitStock will auto-use the custom model.")


if __name__ == "__main__":
    main()
