/*
 * ============================================================================
 * NUCLEUS SEGMENTATION AND COUNTING - BATCH PROCESSING MACRO
 * ============================================================================
 * This macro uses manual thresholding
 * 
 * Virginia Silio (2026), with Claude (Anthropic)
 * 
 * ============================================================================
 * WORKFLOW:
 * ============================================================================
 * 1. User selects input folder containing JPG/JPEG images
 * 2. For each image, the macro:
 *    a. Converts to 8-bit grayscale
 *    b. Subtracts background (rolling ball radius = 50 pixels)
 *    c. Applies manual threshold
 *    d. Converts to binary mask (black background, white nuclei)
 *    e. Applies morphological Close operation to fill small gaps in nuclei
 *    f. Analyzes particles (nuclei) with size and circularity filters
 *    g. Saves processed mask image with "_processed" suffix (PNG)
 * 3. Generates summary table with image names and nucleus counts
 * 4. Saves results as CSV file in the same folder
 * 
 * ============================================================================
 * INPUT REQUIREMENTS:
 * ============================================================================
 * - Image format: JPG or JPEG files
 * - Bright nuclei on a dark background (e.g. DAPI/Hoechst fluorescence).
 *   Background subtraction assumes a dark background; for light backgrounds
 *   add "light" to the Subtract Background options and invert the threshold logic.
 * - RGB images are converted to 8-bit grayscale. For single-channel stains
 *   (e.g. blue only) this can reduce intensity, so check the threshold.
 * - Files already ending in "_processed" are skipped, so the macro can be
 *   safely re-run on the same folder.
 * 
 * ============================================================================
 * PARAMETERS:
 * ============================================================================
 * Background Subtraction:
 *   - Rolling ball radius: 50 pixels (adjust for different image scales)
 * 
 * Thresholding:
 *   - Method: MANUAL, fixed raw 8-bit range 18-255
 * 
 * Binary operations:
 *   - Close-: 1 iteration, count 1 (set explicitly so results do not depend
 *     on each user's Process > Binary > Options settings)
 * 
 * Particle Analysis Filters:
 *   - Size: 15-Infinity pixels² (minimum area to count as nucleus; the
 *     "pixel" keyword makes this independent of any image calibration)
 *   - Circularity: 0.50-1.00 (0.50 = elongated, 1.00 = perfect circle)
 *   - Excludes particles touching the edges of the image
 * 
 * ============================================================================
 * OUTPUT:
 * ============================================================================
 * Generated Files (saved in input folder):
 *   1. [imagename]_processed.png - Binary mask for each input image
 *      (PNG, lossless; JPG would add compression artefacts to the mask)
 *   2. Nuclei_Count_Summary.csv - Table containing:
 *      - Slice: Original image filename
 *      - Count: Number of nuclei detected
 *      - Total Area: Sum of all nucleus areas
 *      - Average Size: Mean nucleus size
 *      - %Area: Percentage of image covered by nuclei
 *      - Mean: Mean grey value of the mask (255 = nuclei; derived from %Area)
 * 
 * ============================================================================
 * LIMITATIONS:
 * ============================================================================
 * - No watershed step: touching nuclei merge and are counted as one.
 *   To split them, add run("Watershed"); after the Close- line.
 * - Nuclei touching the image edge are excluded, so counts are not
 *   comparable with whole-field counts.
 * 
 * ============================================================================
 * CUSTOMIZATION:
 * ============================================================================
 * To modify output location:
 *   - Uncomment line and change: outputDir = getDirectory("Choose folder for results");
 * 
 * To change background subtraction:
 *   - Modify "rolling=50" - larger values for larger background variations
 *   
 * To use a different threshold:
 *   - Threshold is hardcoded, needs to be adapted to your images
 *   - Edit the setThreshold(18, 255, "raw") line, e.g. setThreshold(25, 255, "raw")
 * 
 * To adjust for different nucleus sizes:
 *   - Modify "size=15-Infinity" to your min-max pixel area
 *   - Example: "size=25-500" for medium-sized nuclei only
 * 
 * To adjust shape filtering:
 *   - Modify "circularity=0.50-1.00"
 *   - Example: "circularity=0.70-1.00" for rounder nuclei only
 * 
 * ============================================================================
 */

// Close everything first
run("Close All");
print("\\Clear");

// Close tables left over from a previous run (Close All does not close them),
// otherwise new results would be appended to old ones
if (isOpen("Summary")) { selectWindow("Summary"); run("Close"); }
if (isOpen("Results")) { selectWindow("Results"); run("Close"); }

// Ask user for input directory (output will be the same)
inputDir = getDirectory("Choose the folder with your images");
// Uncomment next line if you want a different output folder:
// outputDir = getDirectory("Choose the folder for results");
outputDir = inputDir; 

print("Input folder: " + inputDir);
print("Output folder: " + outputDir);

// Get list of files
list = getFileList(inputDir);
print("Found " + list.length + " files in input folder");

if (list.length == 0) {
    exit("No files found in input directory!");
}

setBatchMode(true);  // faster, no image windows flashing open

// Process each file
count = 0;
for (i = 0; i < list.length; i++) {
    filename = list[i];
    lower = toLowerCase(filename);
    
    // Check if it's a JPG file (case-insensitive) and not one of our own masks
    if ((endsWith(lower, ".jpg") || endsWith(lower, ".jpeg")) 
        && indexOf(lower, "_processed") < 0) {
        
        print("Processing file " + (count+1) + ": " + filename);
        
        // Open image
        path = inputDir + filename;
        open(path);
        
        // Get name without extension for saving
        dotIndex = lastIndexOf(filename, ".");
        basename = substring(filename, 0, dotIndex);
        
        // Processing steps
        run("8-bit");
        run("Subtract Background...", "rolling=50");
        setThreshold(18, 255, "raw");  // <-------MANUAL THRESHOLD, CHANGE
        setOption("BlackBackground", true);
        run("Convert to Mask");
        run("Options...", "iterations=1 count=1 black do=Nothing");  // fix Close- settings
        run("Close-");  // Morphological close operation to fill gaps
        run("Analyze Particles...", "size=15-Infinity pixel circularity=0.50-1.00 exclude summarize");
        
        // Save processed image (PNG = lossless, keeps mask strictly 0/255)
        saveAs("PNG", outputDir + basename + "_processed.png");
        close();  // Close the image window
        
        count++;
    }
}

setBatchMode(false);

print("Processed " + count + " images");

// Save Summary table (contains image name and count)
if (isOpen("Summary")) {
    selectWindow("Summary");
    saveAs("Results", outputDir + "Nuclei_Count_Summary.csv");
    print("Summary saved successfully");
} else {
    print("WARNING: No Summary window found!");
}

print("===================================");
print("DONE! Processed " + count + " JPG images");
print("Nuclei counts saved to: " + outputDir + "Nuclei_Count_Summary.csv");
print("===================================");