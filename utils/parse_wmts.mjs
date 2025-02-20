import * as convert from "xml-js";
import {writeFileSync} from 'fs';


const getWMTSLayers = async (url) => {
    const response = await fetch(`${url}?request=GetCapabilities&service=WMTS&version=1.0.0`)
    if (response.ok) {
        const layers = JSON.parse(convert.xml2json(await response.text())).elements[0].elements.find(e => e.name.toLowerCase() === 'contents')?.elements || [];
        return layers.map(l => ({
            title: l.elements.find((e) => e.name === 'ows:Title')?.elements[0]?.text || '',
            layer: l.elements.find((e) => e.name === 'ows:Identifier')?.elements[0]?.text || '',

        }))
    } else {
        console.error('Could not fetch layers');
    }
}

(async () => {
    const wmtsUrl = "https://globalland.vito.be/wmts";
    const outputfile = './globalland.config';

    const layers = await getWMTSLayers(wmtsUrl);
    const explorer_layers = layers.map(l => ({
        name: l.title,
        isActive: false,
        layout: {
            layerCard: {
                description: "",
                toggleable: true,
                control: [
                    "zoomToCenter"
                ]
            },
            interfaceGroup: ""
        },
        data: {
            url: "https://globalland.vito.be/wmts",
            layers: l.layer,
            zIndex: 2,
            type: "wmts"
        }
    }));
    writeFileSync(outputfile, JSON.stringify(explorer_layers, null, 4), 'utf8');
})();




