# Nuclei count: Fiji/ImageJ batch macro

A Fiji/ImageJ macro that segments and counts nuclei in a folder of JPG images using a fixed (manual) threshold, and writes a CSV summary plus a binary mask for each image.

Built by Virginia Silio (nice commenting from Claude)

  > **Note:** Always keep the original files in the microscope's proprietary format (e.g. .czi, .nd2, .lif). JPGs are lossy and should only be used for quick counts like this.

## What it does

For every `.jpg`/`.jpeg` image in the folder you choose:

1. Converts to 8-bit grayscale
2. Subtracts background (rolling ball, radius 50 px)
3. Applies a manual threshold (raw 8-bit range 18-255)
4. Converts to a binary mask (white nuclei on black)
5. Applies a morphological Close to fill small gaps
6. Counts particles (min area 15 px², circularity 0.50-1.00, edge-touching nuclei excluded)
7. Saves the mask as `<name>_processed.png`

At the end it saves `Nuclei_Count_Summary.csv` in the same folder.

## Requirements

- [Fiji](https://fiji.sc/) (or ImageJ 1.x)
- JPG/JPEG images with **bright nuclei on a dark background** (e.g. DAPI/Hoechst fluorescence)

## Usage

1. Open Fiji.
2. Drag `count_nuclei_manual_threshold.ijm` onto the Fiji window (or **Plugins → Macros → Run...**).
3. Choose the folder containing your images.
4. Wait for "DONE" in the Log window.

The macro can safely be re-run on the same folder: files ending in `_processed` are skipped and old results tables are cleared.

## Output

| File | Description |
|---|---|
| `<name>_processed.png` | Binary mask for each input image (lossless PNG) |
| `Nuclei_Count_Summary.csv` | One row per image |

CSV columns: `Slice` (image filename), `Count`, `Total Area`, `Average Size`, `%Area`, `Mean`.

## Adapting it to your images

> **The threshold is hardcoded for my images (18).** Always check it on a few of your own images before batch-processing, and re-tune it for different stains, exposures or microscopes.

All parameters are in the macro; the main ones to edit:

| What | Where in the macro |
|---|---|
| Threshold | `setThreshold(18, 255, "raw")` |
| Background subtraction | `rolling=50` |
| Nucleus size (px²) | `size=15-Infinity pixel` |
| Shape filter | `circularity=0.50-1.00` |
| Output folder | uncomment the `outputDir = getDirectory(...)` line |

## Limitations

- **Touching nuclei are counted as one.** There is no watershed step. To split them, add `run("Watershed");` after the `Close-` line.
- **Edge-touching nuclei are excluded**, so counts are not comparable with whole-field counts.
- Assumes a dark background. For light backgrounds, add `light` to the Subtract Background options and adjust the threshold.
- RGB images are converted to 8-bit grayscale, which can dim single-channel stains (e.g. blue only). Check the threshold if you use these.
- JPG compression introduces artefacts into the input data itself; use lossless formats (TIFF/PNG) for quantitative work where possible.

## Citation / licence

Released under the MIT licence (see `LICENSE`). If you use this macro in a publication, please cite the repository URL.
