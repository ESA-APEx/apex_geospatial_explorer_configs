#!/usr/bin/env bash
set -euo pipefail

: <<'DOCSTRING'
discover_cdse_public_layers.sh

Build a compact JSON catalogue of publicly usable Copernicus Land Monitoring
Service (CLMS) datasets exposed through the Copernicus Data Space Ecosystem.

The catalogue is intended for downstream GIS/config-builder tooling. It answers:

  * Is this CLMS dataset available as a public WMTS?
  * If not, is it available as a public WMS?
  * If not, does CDSE catalogue the dataset as COG-backed?
  * If COG-backed, is there an anonymously reachable public HTTP(S) COG URL?

The script deliberately excludes large/debug-oriented metadata such as full OData
query URLs, S3 paths, product IDs, tile matrices, and raw capabilities metadata.

Discovery
---------
Dataset identifiers are discovered dynamically from the current CDSE Sentinel
Hub CLMS documentation index:

  https://documentation.dataspace.copernicus.eu/APIs/SentinelHub/Data/CLMS.html

Service checks
--------------
For each datasetIdentifier:

1. Probe:
     https://land.copernicus.eu/cdse/<datasetIdentifier>/
   as WMTS using GetCapabilities.

2. If WMTS is unavailable, probe the same endpoint as WMS.

3. If neither map service is available, query the CDSE CLMS OData catalogue for
   products whose metadata says:
     fileFormat = cog

4. If such products exist, inspect returned product metadata for a public
   anonymous HTTP(S) asset URL. Any candidate URL must respond to an anonymous
   HTTP range request with 206 Partial Content and identify as TIFF.

Important semantics
-------------------
The top-level "available" field means:
    publicly usable map service available (WMTS or WMS)

"access.cog.catalogueAvailable" means:
    CDSE says COG products exist for the dataset

"access.cog.publicAvailable" means:
    an anonymously reachable, range-readable public TIFF/COG URL was verified

Authenticated OData download URLs and /eodata S3 paths are NOT treated as
public COG URLs.

Output
------
Default output:
    clms-public-layers.json

Usage
-----
    chmod +x discover_cdse_public_layers.sh
    ./discover_cdse_public_layers.sh

or:

    ./discover_cdse_public_layers.sh my-catalogue.json
DOCSTRING

OUTPUT="${1:-clms-public-layers.json}"

python3 - "$OUTPUT" <<'PY'
"""
Discover CLMS dataset identifiers, test public WMTS/WMS availability, and
identify anonymously usable public COG URLs where possible.

The output is intentionally compact for use by a GIS configuration builder.
"""

import concurrent.futures
import datetime as dt
import html
import json
import re
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

OUTPUT = sys.argv[1]

SERVICE_ROOT = "https://land.copernicus.eu/cdse/"
SOURCE_DOC = "https://documentation.dataspace.copernicus.eu/Data/ComplementaryData/CLMS.html"
DISCOVERY_URL = "https://documentation.dataspace.copernicus.eu/APIs/SentinelHub/Data/CLMS.html"
ODATA_PRODUCTS = "https://catalogue.dataspace.copernicus.eu/odata/v1/Products"

TIMEOUT = 30
MAX_WORKERS = 8
USER_AGENT = "cdse-public-layer-discovery/1.0"

DATASET_ID_RE = re.compile(
    r"\b[a-z0-9][a-z0-9_.-]*_[a-z0-9_.-]+_v\d+\b",
    re.IGNORECASE,
)

THEMES = {
    "lc": "Land cover",
    "lcm": "Land cover",
    "tcd": "Land cover",
    "ssm": "Soil moisture",
    "swi": "Soil moisture",
    "sce": "Snow and ice",
    "swe": "Snow and ice",
    "lie": "Snow and ice",
    "fsc": "Snow and ice",
    "gfsc": "Snow and ice",
    "sp": "Snow and ice",
    "sws": "Snow and ice",
    "wds": "Snow and ice",
    "lst": "Temperature",
    "lswt": "Temperature",
    "toc": "Surface reflectance",
    "eta": "Evapotranspiration",
    "hf": "Evapotranspiration",
    "ba": "Burnt area",
    "fcover": "Vegetation properties",
    "fapar": "Vegetation properties",
    "lai": "Vegetation properties",
    "ndvi": "Vegetation properties",
    "lsp": "Vegetation properties",
    "dmp": "Vegetation productivity",
    "gdmp": "Vegetation productivity",
    "npp": "Vegetation productivity",
    "gpp": "Vegetation productivity",
    "wb": "Water bodies",
    "wl": "Water level",
    "lwq": "Water quality",
}

ssl_ctx = ssl.create_default_context()


def clean(obj):
    return {k: v for k, v in obj.items() if v not in (None, "", [], {})}


def theme_for(dataset_id):
    prefix = dataset_id.split("_", 1)[0].split("-", 1)[0]
    return THEMES.get(prefix, "Other")


def fallback_title(dataset_id):
    return dataset_id.replace("-", " ").replace("_", " ").strip()


def fetch(url, accept="*/*", range_header=None):
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": accept,
    }
    if range_header:
        headers["Range"] = range_header

    req = urllib.request.Request(url, headers=headers)

    with urllib.request.urlopen(req, timeout=TIMEOUT, context=ssl_ctx) as response:
        return (
            response.status,
            dict(response.headers.items()),
            response.read(),
            response.geturl(),
        )


def discover_datasets():
    _status, _headers, body, _final = fetch(
        DISCOVERY_URL,
        accept="text/html,*/*",
    )
    text = html.unescape(body.decode("utf-8", errors="replace"))

    dataset_ids = sorted({
        match.group(0).lower()
        for match in DATASET_ID_RE.finditer(text)
    })

    if not dataset_ids:
        raise RuntimeError(
            f"No CLMS dataset identifiers discovered from {DISCOVERY_URL}"
        )

    return dataset_ids


def local_name(tag):
    return tag.split("}", 1)[-1] if "}" in tag else tag


def child(elem, name):
    for node in list(elem):
        if local_name(node.tag) == name:
            return node
    return None


def children(elem, name):
    return [node for node in list(elem) if local_name(node.tag) == name]


def child_text(elem, name):
    node = child(elem, name)
    if node is None:
        return None
    value = (node.text or "").strip()
    return value or None


def parse_wmts_layer(layer):
    return clean({
        "identifier": child_text(layer, "Identifier"),
        "title": child_text(layer, "Title"),
        "abstract": child_text(layer, "Abstract"),
    })


def parse_wmts_capabilities(body):
    root = ET.fromstring(body)

    if local_name(root.tag) != "Capabilities" or "wmts/1.0" not in root.tag:
        raise ValueError("Response is not WMTS 1.0 Capabilities XML")

    service_ident = child(root, "ServiceIdentification")
    contents = child(root, "Contents")

    if contents is None:
        raise ValueError("WMTS capabilities contains no Contents element")

    title = child_text(service_ident, "Title") if service_ident is not None else None
    abstract = (
        child_text(service_ident, "Abstract")
        if service_ident is not None
        else None
    )

    layers = [parse_wmts_layer(node) for node in children(contents, "Layer")]
    return title, abstract, layers


def parse_wms_layers(layer):
    results = []

    name = child_text(layer, "Name")
    if name:
        results.append(clean({
            "identifier": name,
            "title": child_text(layer, "Title"),
            "abstract": child_text(layer, "Abstract"),
        }))

    for sublayer in children(layer, "Layer"):
        results.extend(parse_wms_layers(sublayer))

    return results


def parse_wms_capabilities(body):
    root = ET.fromstring(body)
    root_name = local_name(root.tag)

    if root_name not in ("WMS_Capabilities", "WMT_MS_Capabilities"):
        raise ValueError("Response is not WMS Capabilities XML")

    service = child(root, "Service")
    capability = child(root, "Capability")

    if capability is None:
        raise ValueError("WMS capabilities contains no Capability element")

    title = child_text(service, "Title") if service is not None else None
    abstract = child_text(service, "Abstract") if service is not None else None

    root_layer = child(capability, "Layer")
    layers = parse_wms_layers(root_layer) if root_layer is not None else []

    return title, abstract, layers


def probe_map_service(dataset_id, service_type):
    service_url = f"{SERVICE_ROOT}{dataset_id}/"
    caps_url = service_url + "?" + urllib.parse.urlencode({
        "SERVICE": service_type,
        "REQUEST": "GetCapabilities",
    })

    try:
        status, _headers, body, _final = fetch(
            caps_url,
            accept="application/xml,text/xml,*/*",
        )

        if service_type == "WMTS":
            title, abstract, layers = parse_wmts_capabilities(body)
        else:
            title, abstract, layers = parse_wms_capabilities(body)

        return clean({
            "available": True,
            "serviceUrl": service_url,
            "getCapabilitiesUrl": caps_url,
            "httpStatus": status,
            "title": title,
            "abstract": abstract,
            "layers": layers,
        })

    except urllib.error.HTTPError as exc:
        return clean({
            "available": False,
            "serviceUrl": service_url,
            "getCapabilitiesUrl": caps_url,
            "httpStatus": exc.code,
            "reason": str(exc.reason),
        })

    except Exception as exc:
        return clean({
            "available": False,
            "serviceUrl": service_url,
            "getCapabilitiesUrl": caps_url,
            "reason": str(exc),
        })


def odata_filter(dataset_id):
    return (
        "Collection/Name eq 'CLMS' and "
        "Attributes/OData.CSC.StringAttribute/any("
        "att:att/Name eq 'datasetIdentifier' and "
        f"att/OData.CSC.StringAttribute/Value eq '{dataset_id}') and "
        "Attributes/OData.CSC.StringAttribute/any("
        "att:att/Name eq 'fileFormat' and "
        "att/OData.CSC.StringAttribute/Value eq 'cog')"
    )


def candidate_public_urls_from_product(product):
    urls = []

    for key in ("AssetUrl", "DownloadUrl", "Url", "Href"):
        value = product.get(key)
        if isinstance(value, str) and value.startswith(("http://", "https://")):
            urls.append(value)

    assets = product.get("Assets")
    if isinstance(assets, list):
        for asset in assets:
            if not isinstance(asset, dict):
                continue
            for key in ("href", "Href", "url", "Url"):
                value = asset.get(key)
                if isinstance(value, str) and value.startswith(("http://", "https://")):
                    urls.append(value)

    return list(dict.fromkeys(urls))


def verify_public_cog_url(url):
    try:
        status, headers, body, _final = fetch(
            url,
            accept="image/tiff,application/tiff,*/*",
            range_header="bytes=0-16383",
        )

        content_type = headers.get("Content-Type", "").lower()
        content_range = headers.get("Content-Range")

        is_tiff_magic = body[:4] in (b"II*\x00", b"MM\x00*")
        is_tiff_type = any(
            value in content_type
            for value in ("image/tiff", "application/tiff", "image/geotiff")
        )

        public = (
            status == 206
            and bool(content_range)
            and (is_tiff_magic or is_tiff_type)
        )

        return clean({
            "publicAvailable": public,
            "publicUrl": url if public else None,
            "httpStatus": status,
            "contentType": headers.get("Content-Type"),
            "acceptRanges": headers.get("Accept-Ranges"),
            "contentRange": content_range,
        })

    except urllib.error.HTTPError as exc:
        return {
            "publicAvailable": False,
            "httpStatus": exc.code,
        }

    except Exception:
        return {
            "publicAvailable": False,
        }


def query_cog_access(dataset_id):
    params = {
        "$filter": odata_filter(dataset_id),
        "$top": "3",
        "$count": "true",
    }

    url = ODATA_PRODUCTS + "?" + urllib.parse.urlencode(
        params,
        quote_via=urllib.parse.quote,
        safe="'():/,",
    )

    try:
        status, _headers, body, _final = fetch(
            url,
            accept="application/json,*/*",
        )

        payload = json.loads(body.decode("utf-8"))
        values = payload.get("value") or []
        count = payload.get("@odata.count")

        catalogue_available = bool(values) or (
            isinstance(count, int) and count > 0
        )

        result = {
            "catalogueAvailable": catalogue_available,
            "publicAvailable": False,
            "productCount": count,
        }

        for product in values:
            for candidate_url in candidate_public_urls_from_product(product):
                checked = verify_public_cog_url(candidate_url)
                if checked.get("publicAvailable"):
                    result.update({
                        "publicAvailable": True,
                        "publicUrl": checked.get("publicUrl"),
                    })
                    return clean(result)

        return clean(result)

    except Exception:
        return {
            "catalogueAvailable": False,
            "publicAvailable": False,
        }


def build_record(dataset_id):
    wmts = probe_map_service(dataset_id, "WMTS")

    if wmts["available"]:
        return clean({
            "datasetIdentifier": dataset_id,
            "title": wmts.get("title") or fallback_title(dataset_id),
            "abstract": wmts.get("abstract"),
            "theme": theme_for(dataset_id),
            "available": True,
            "serviceType": "WMTS",
            "serviceUrl": wmts.get("serviceUrl"),
            "getCapabilitiesUrl": wmts.get("getCapabilitiesUrl"),
            "layers": wmts.get("layers") or [],
            "access": {
                "wmts": {
                    "available": True,
                    "getCapabilitiesUrl": wmts.get("getCapabilitiesUrl"),
                }
            },
        })

    wms = probe_map_service(dataset_id, "WMS")

    if wms["available"]:
        return clean({
            "datasetIdentifier": dataset_id,
            "title": wms.get("title") or fallback_title(dataset_id),
            "abstract": wms.get("abstract"),
            "theme": theme_for(dataset_id),
            "available": True,
            "serviceType": "WMS",
            "serviceUrl": wms.get("serviceUrl"),
            "getCapabilitiesUrl": wms.get("getCapabilitiesUrl"),
            "layers": wms.get("layers") or [],
            "access": {
                "wmts": {
                    "available": False,
                },
                "wms": {
                    "available": True,
                    "getCapabilitiesUrl": wms.get("getCapabilitiesUrl"),
                },
            },
        })

    cog = query_cog_access(dataset_id)

    return clean({
        "datasetIdentifier": dataset_id,
        "title": fallback_title(dataset_id),
        "theme": theme_for(dataset_id),
        "available": bool(cog.get("publicAvailable")),
        "serviceType": "COG" if cog.get("publicAvailable") else None,
        "serviceUrl": cog.get("publicUrl"),
        "layers": [],
        "access": {
            "wmts": {
                "available": False,
            },
            "wms": {
                "available": False,
            },
            "cog": cog,
        },
    })


datasets = discover_datasets()

print(
    f"Discovered {len(datasets)} CLMS/CDSE dataset identifiers.",
    file=sys.stderr,
)
print(
    "Checking public WMTS, WMS, and anonymous COG access...",
    file=sys.stderr,
)

records = []

with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
    futures = {
        pool.submit(build_record, dataset_id): dataset_id
        for dataset_id in datasets
    }

    completed = 0
    for future in concurrent.futures.as_completed(futures):
        completed += 1
        record = future.result()
        records.append(record)

        service_type = record.get("serviceType")
        if service_type:
            status_text = service_type
        elif record.get("access", {}).get("cog", {}).get("catalogueAvailable"):
            status_text = "catalogued COG only"
        else:
            status_text = "no public access found"

        print(
            f"[{completed:>3}/{len(datasets)}] "
            f"{record['datasetIdentifier']}: {status_text}",
            file=sys.stderr,
        )

records.sort(key=lambda item: (item["theme"], item["datasetIdentifier"]))

wmts_count = sum(1 for item in records if item.get("serviceType") == "WMTS")
wms_count = sum(1 for item in records if item.get("serviceType") == "WMS")
public_cog_count = sum(1 for item in records if item.get("serviceType") == "COG")
catalogued_cog_only_count = sum(
    1
    for item in records
    if item.get("serviceType") is None
    and item.get("access", {}).get("cog", {}).get("catalogueAvailable")
)
public_count = sum(1 for item in records if item.get("available"))

catalogue = {
    "meta": {
        "title": "Copernicus Land Monitoring Service (CDSE)",
        "description": (
            "Publicly usable CLMS map/data access discovered from CDSE. "
            "WMTS and WMS are verified through GetCapabilities; COG is only "
            "considered public when an anonymous range-readable HTTP(S) URL "
            "is verified."
        ),
        "provider": "Copernicus Land Monitoring Service",
        "source": SOURCE_DOC,
        "servicesUrl": SERVICE_ROOT,
        "generated": dt.datetime.now(dt.timezone.utc).isoformat(),
        "counts": {
            "candidateCount": len(records),
            "publiclyAvailableCount": public_count,
            "wmtsCount": wmts_count,
            "wmsCount": wms_count,
            "publicCogCount": public_cog_count,
            "cataloguedCogOnlyCount": catalogued_cog_only_count,
        },
    },
    "datasets": records,
}

with open(OUTPUT, "w", encoding="utf-8") as handle:
    json.dump(catalogue, handle, indent=2, ensure_ascii=False)
    handle.write("\n")

print(
    f"\nWrote {OUTPUT}: "
    f"{wmts_count} WMTS, "
    f"{wms_count} WMS, "
    f"{public_cog_count} public COG, "
    f"{catalogued_cog_only_count} catalogued COG-only datasets.",
    file=sys.stderr,
)
PY
