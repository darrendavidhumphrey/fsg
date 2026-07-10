#target photoshop

function main() {
    if (app.documents.length === 0) {
        alert("No document open.");
        return;
    }

    var doc = app.activeDocument;
    var docName = doc.name.replace(/\.[^\.]+$/, '');
    
    var exportFolder = Folder.selectDialog("Select a folder to export assets and XML:");
    if (!exportFolder) return;

    var framesFolder = new Folder(exportFolder + "/frames");
    if (!framesFolder.exists) framesFolder.create();

    var docWidth = doc.width.as("px");
    var docHeight = doc.height.as("px");

    var textureNodes = [];
    var objectNodes = [];
    var usedFonts = {};

    processLayers(doc.layers, framesFolder, textureNodes, objectNodes, docHeight, usedFonts);

    var xmlStr = '<?xml version="1.0" encoding="utf-8"?>\n';
    xmlStr += '<frameScene version="1.0" width="' + docWidth + '" height="' + docHeight + '" assetsPath="frames">\n';
    
    xmlStr += '    <textures>\n';
    for (var i = 0; i < textureNodes.length; i++) {
        xmlStr += textureNodes[i];
    }
    xmlStr += '    </textures>\n\n';

    xmlStr += '    <fonts>\n';
    for (var fontId in usedFonts) {
        if (usedFonts.hasOwnProperty(fontId)) {
            var f = usedFonts[fontId];
            xmlStr += '        <font id="' + fontId + '" fntFile="' + f.name + f.size + '.fnt" texture="' + f.name + f.size + '.png" />\n';
        }
    }
    xmlStr += '    </fonts>\n\n';

    xmlStr += '    <!-- Start of SCENE  -->\n';
    xmlStr += '    <objects>\n';
    for (var j = 0; j < objectNodes.length; j++) {
        xmlStr += objectNodes[j];
    }
    xmlStr += '    </objects>\n\n';
    xmlStr += '</frameScene>';

    var xmlFile = new File(exportFolder + "/" + docName + ".xml");
    xmlFile.encoding = "UTF-8";
    xmlFile.open("w");
    xmlFile.write(xmlStr);
    xmlFile.close();

    alert("Export completed successfully!");
}

function processLayers(layers, framesFolder, textureNodes, objectNodes, docHeight, usedFonts) {
    for (var i = layers.length - 1; i >= 0; i--) {
        var layer = layers[i];

        if (layer.typename === "LayerSet") {
            processLayers(layer.layers, framesFolder, textureNodes, objectNodes, docHeight, usedFonts);
            continue;
        }

        var layerName = layer.name.replace(/[:\/\\*\?"<>\|]/g, "_");
        
        // Reverted to original working bounds measurement method
        var bounds = layer.bounds;
        var x = parseInt(bounds[0].as("px"));
        var topY = parseInt(bounds[1].as("px"));
        var w = parseInt(bounds[2].as("px")) - x;
        var h = parseInt(bounds[3].as("px")) - topY;
        var isVisible = layer.visible ? "true" : "false";
        
        // Get Layer Opacity (0.0 to 1.0)
        var layerOpacityNormalized = layer.opacity / 100.0;

        // Reversed Y-axis calculation
        var reversedY = docHeight - (topY + h);

        if (layer.kind === LayerKind.TEXT) {
            var textItem = layer.textItem;
            var fontName = textItem.font;
            var fontSize = Math.round(textItem.size.as("pt"));
            var fontId = fontName + fontSize;
            
            usedFonts[fontId] = { name: fontName, size: fontSize };

            // Calculate text alpha based on Photoshop layer opacity
            var calculatedAlpha = Math.round(layerOpacityNormalized * 255);
            var hexColor = "#FFFFFFFF"; 
            try {
                var pColor = textItem.color.rgb;
                hexColor = rgbToHexWithAlpha(pColor.red, pColor.green, pColor.blue, calculatedAlpha);
            } catch(e) {
                hexColor = rgbToHexWithAlpha(255, 255, 255, calculatedAlpha);
            }

            var textStr = '        <text id="' + layerName + '" font="' + fontId + '" text="' + textItem.contents + '"\n';
            textStr += '            screenRect="{{' + x + ', ' + reversedY + '}, {' + w + ', ' + h + '}}" hJustify="center" vJustify="bottom" visible="' + isVisible + '" textColor="' + hexColor + '" />\n\n';
            objectNodes.push(textStr);
        } else {
            exportPngLayer(layer, layerName, framesFolder);

            var texStr = '        <texture id="' + layerName + '" file="' + layerName + '.png" />\n';
            textureNodes.push(texStr);

            // Format float to 2 decimal places max
            var opacityAttr = layerOpacityNormalized.toFixed(2).replace(/\.?0+$/, '');

            var quadStr = '        <quad id="' + layerName + '" texture="' + layerName + '" screenRect="{{' + x + ', ' + reversedY + '}, {' + w + ', ' + h + '}}" visible="' + isVisible + '" opacity="' + opacityAttr + '" />\n\n';
            objectNodes.push(quadStr);
        }
    }
}

function exportPngLayer(layer, filename, folder) {
    var doc = app.activeDocument;
    var rememberState = doc.activeHistoryState;
    
    layer.copy();
    var width = layer.bounds[2] - layer.bounds[0];
    var height = layer.bounds[3] - layer.bounds[1];
    var newDoc = app.documents.add(width, height, doc.resolution, filename, NewDocumentMode.RGB, DocumentFill.TRANSPARENT);
    newDoc.paste();

    var saveFile = new File(folder + "/" + filename + ".png");
    var exportOptions = new ExportOptionsSaveForWeb();
    exportOptions.format = SaveDocumentType.PNG;
    exportOptions.PNG8 = false; 
    exportOptions.transparent = true;

    newDoc.exportDocument(saveFile, ExportType.SAVEFORWEB, exportOptions);
    newDoc.close(SaveOptions.DONOTSAVECHANGES);
    
    doc.activeHistoryState = rememberState;
}

function rgbToHexWithAlpha(r, g, b, a) {
    return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b) + componentToHex(a);
}

function componentToHex(c) {
    var hex = Math.round(c).toString(16).toUpperCase();
    return hex.length == 1 ? "0" + hex : hex;
}

main();
