import fs from "fs";
import path from "path";

// Input and output file paths
const inputFilePath = "./files/EUNIS2012_legend_level1_2.txt";
const outputFilePath = "./files/colormap.json";

// Function to parse the colormap file
const parseColormap = (filePath) => {
  const data = fs.readFileSync(filePath, "utf-8");
  const lines = data.split("\n");
  const result = [];

  for (const line of lines) {
    // Skip empty lines or lines that don't match the expected format
    if (!line.trim() || line.startsWith("//") || !line.includes(",")) continue;

    const parts = line.split(",");
    if (parts.length < 6) continue;

    const value = parseInt(parts[0].trim(), 10);
    const color = `rgba(${parseInt(parts[1].trim(), 10)},${parseInt(
      parts[2].trim(),
      10
    )},${parseInt(parts[3].trim(), 10)},${parseInt(parts[4].trim(), 10)})`;

    const label = parts.slice(5).join(",").split("-").pop().trim();

    result.push({ value, color, label });
  }

  return result;
};

// Parse the file and write the JSON output
try {
  const colormap = parseColormap(inputFilePath);
  fs.writeFileSync(outputFilePath, JSON.stringify(colormap, null, 2), "utf-8");
  console.log(`Colormap JSON has been written to ${outputFilePath}`);
} catch (error) {
  console.error("Error parsing colormap file:", error);
}
