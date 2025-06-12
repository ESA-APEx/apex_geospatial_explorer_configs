import fs from "fs";
import path from "path";

// Input and output file paths
const inputFilePath = "./files/people_ecoschemes_croptype.sld";
const outputFilePath = "./files/colormap.json";

// Function to parse the colormap file
const parseSLD = (filePath) => {
  
  const fileContent = fs.readFileSync(filePath, "utf-8");

  // Match all ColorMapEntry elements and extract attributes
  const entryRegex = /<sld:ColorMapEntry\s+([^>]+?)\/?>/gi;
  const attrRegex = /(\w+)="([^"]*)"/g;

  const entries = [];
  let entryMatch;
  while ((entryMatch = entryRegex.exec(fileContent)) !== null) {
    const attrs = {};
    let attrMatch;
    const attrString = entryMatch[1];
    while ((attrMatch = attrRegex.exec(attrString)) !== null) {
      attrs[attrMatch[1]] = attrMatch[2];
    }
    entries.push({
      color: attrs.color,
      label: attrs.label,
      value: +attrs.quantity,
    });
  }
 
  return entries;
};

// Parse the file and write the JSON output
try {
  const colormap = parseSLD(inputFilePath);
  fs.writeFileSync(outputFilePath, JSON.stringify(colormap, null, 2), "utf-8");
  console.log(`Colormap JSON has been written to ${outputFilePath}`);
} catch (error) {
  console.error("Error parsing colormap file:", error);
}
