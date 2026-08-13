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

The output is intentionally compact for use by a GIS configuration builder.\nGeneric Sentinel Hub service abstracts are ignored; dataset titles come from\nthe CLMS documentation index and layer descriptions come from GetCapabilities.
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
USER_AGENT = "cdse-public-layer-discovery/1.9"

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


def strip_html(value):
    value = re.sub(r"<[^>]+>", " ", value)
    value = html.unescape(value)
    return re.sub(r"\\s+", " ", value).strip()


def discover_catalogue_metadata():
    """
    Discover dataset identifiers, human-friendly titles and product
    documentation URLs from the current Sentinel Hub CLMS documentation index.

    The dataset identifier is taken only from the final .html path segment.
    This avoids partial matches such as "m_10daily_v1" that can occur when a
    regex starts in the middle of a longer identifier.
    """
    _status, _headers, body, _final = fetch(
        DISCOVERY_URL,
        accept="text/html,*/*",
    )
    page = html.unescape(body.decode("utf-8", errors="replace"))

    metadata = {}

    anchor_re = re.compile(
        r'<a\b[^>]*href=["\'](?P<href>[^"\']+\.html(?:#[^"\']*)?)["\'][^>]*>(?P<title>.*?)</a>',
        re.IGNORECASE | re.DOTALL,
    )

    for match in anchor_re.finditer(page):
        href = html.unescape(match.group("href"))
        documentation_url = urllib.parse.urljoin(DISCOVERY_URL, href)

        parsed = urllib.parse.urlparse(documentation_url)
        filename = parsed.path.rsplit("/", 1)[-1]

        if not filename.lower().endswith(".html"):
            continue

        dataset_id = filename[:-5].lower()

        if not DATASET_ID_RE.fullmatch(dataset_id):
            continue

        title = strip_html(match.group("title"))
        item = metadata.setdefault(dataset_id, {})

        if title and not item.get("title"):
            item["title"] = title

        item["documentationUrl"] = documentation_url

    if not metadata:
        raise RuntimeError(
            f"No CLMS dataset identifiers discovered from {DISCOVERY_URL}"
        )

    return metadata


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




GITHUB_SCRIPT_INDEX = None
GITHUB_ARCHIVE_ERROR = None


def github_repo_path_from_tree_url(url):
    """
    Parse a GitHub tree URL such as:

      https://github.com/eu-cdse/sentinel-hub-custom-scripts/tree/main/<path>

    and return (owner, repo, branch, path).
    """
    match = re.match(
        r"https://github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.*)",
        url,
    )
    if not match:
        return None

    owner, repo, branch, path = match.groups()
    return owner, repo, branch, path.strip("/")


def load_github_archive_index():
    """
    Download the public sentinel-hub-custom-scripts repository ZIP archive once
    and build an in-memory index of all JavaScript files.

    This avoids GitHub API rate limits entirely.
    """
    global GITHUB_SCRIPT_INDEX, GITHUB_ARCHIVE_ERROR

    if GITHUB_SCRIPT_INDEX is not None or GITHUB_ARCHIVE_ERROR is not None:
        return GITHUB_SCRIPT_INDEX

    archive_url = (
        "https://github.com/eu-cdse/"
        "sentinel-hub-custom-scripts/archive/refs/heads/main.zip"
    )

    try:
        status, _headers, body, _final = fetch(
            archive_url,
            accept="application/zip,application/octet-stream,*/*",
        )

        import io
        import zipfile

        scripts = []

        with zipfile.ZipFile(io.BytesIO(body)) as zf:
            for info in zf.infolist():
                if info.is_dir():
                    continue

                path = info.filename

                # Archive paths are prefixed by repository-name-branch/.
                prefix = "sentinel-hub-custom-scripts-main/"
                if path.startswith(prefix):
                    repo_path = path[len(prefix):]
                else:
                    repo_path = path

                if not repo_path.lower().endswith(".js"):
                    continue

                try:
                    content = zf.read(info.filename).decode(
                        "utf-8",
                        errors="replace",
                    )
                except Exception:
                    content = None

                name = repo_path.rsplit("/", 1)[-1]
                raw_url = (
                    "https://raw.githubusercontent.com/"
                    "eu-cdse/sentinel-hub-custom-scripts/main/"
                    + repo_path
                )

                scripts.append({
                    "name": name,
                    "path": repo_path,
                    "url": raw_url,
                    "content": content,
                })

        GITHUB_SCRIPT_INDEX = scripts
        return GITHUB_SCRIPT_INDEX

    except urllib.error.HTTPError as exc:
        GITHUB_ARCHIVE_ERROR = (
            f"GitHub archive HTTP {exc.code}: {exc.reason}"
        )
        return None

    except Exception as exc:
        GITHUB_ARCHIVE_ERROR = f"GitHub archive error: {exc}"
        return None


def github_scripts_for_directory(directory_url):
    """
    Return all JavaScript files below one official CLMS custom-script directory
    using the cached public repository archive.
    """
    parsed = github_repo_path_from_tree_url(directory_url)
    if not parsed:
        return {
            "scripts": [],
            "status": "invalid_directory_url",
            "error": "Could not parse GitHub tree URL",
        }

    _owner, _repo, _branch, root_path = parsed
    index = load_github_archive_index()

    if index is None:
        return {
            "scripts": [],
            "status": "github_archive_error",
            "error": GITHUB_ARCHIVE_ERROR,
        }

    prefix = root_path.rstrip("/") + "/"

    scripts = [
        item
        for item in index
        if item.get("path", "").startswith(prefix)
    ]

    return {
        "scripts": sorted(
            scripts,
            key=lambda item: item.get("path") or item.get("name") or "",
        ),
        "status": "ok",
        "archiveUrl": (
            "https://github.com/eu-cdse/"
            "sentinel-hub-custom-scripts/archive/refs/heads/main.zip"
        ),
    }


def extract_evalscript_links(documentation_url):
    """
    Follow a CLMS product documentation page, find its official custom-script
    directory, then enumerate JavaScript files from the cached recursive GitHub
    repository tree.
    """
    if not documentation_url:
        return None, [], {
            "status": "no_documentation_url",
            "error": None,
            "archiveUrl": None,
        }

    try:
        _status, _headers, body, _final = fetch(
            documentation_url,
            accept="text/html,*/*",
        )
    except Exception as exc:
        return None, [], {
            "status": "documentation_fetch_error",
            "error": str(exc),
            "archiveUrl": None,
        }

    page = html.unescape(body.decode("utf-8", errors="replace"))

    github_links = re.findall(
        r'href=["\'](https://github\.com/eu-cdse/sentinel-hub-custom-scripts/[^"\']+)["\']',
        page,
        re.IGNORECASE,
    )

    directory_url = None
    for link in github_links:
        if "/tree/" in link and "/clms/" in link:
            directory_url = link
            break

    if not directory_url:
        return None, [], {
            "status": "no_evalscript_directory",
            "error": None,
            "archiveUrl": None,
        }

    listing = github_scripts_for_directory(directory_url)

    return (
        directory_url,
        listing.get("scripts", []),
        {
            "status": listing.get("status"),
            "error": listing.get("error"),
            "archiveUrl": listing.get("archiveUrl"),
        },
    )


def rgb_to_hex(rgb):
    try:
        values = [max(0, min(255, int(round(float(v))))) for v in rgb]
    except Exception:
        return None
    if len(values) != 3:
        return None
    return "#{:02X}{:02X}{:02X}".format(*values)



KNOWN_COLORMAPS = {
    # sampled anchor colours sufficient for conservative exact recognition
    "viridis": ["#440154", "#21918C", "#FDE725"],
    "magma": ["#000004", "#B5367A", "#FCFDBF"],
    "plasma": ["#0D0887", "#CC4778", "#F0F921"],
    "inferno": ["#000004", "#BC3754", "#FCFFA4"],
    "turbo": ["#30123B", "#28BBEC", "#A4FC3C", "#FB7E21", "#7A0403"],
}


def extract_units_from_layer(layer):
    """
    Extract genuine measurement units from layer metadata.

    This is deliberately strict so parenthesised abbreviations/flags such as
    (LAI), (FCOVER), (WB), (0), or (<0) are not mistaken for units.
    """
    candidates = []

    for value in (layer.get("abstract"), layer.get("title")):
        if not value:
            continue
        candidates.extend(
            match.group(1).strip()
            for match in re.finditer(r'\(([^()]{1,32})\)', value)
        )

    exact_units = {
        "%", "K", "°C", "C", "mm", "mm/day", "mm/d", "m", "cm", "km",
        "days", "day", "hours", "hour", "W/m²", "W/m2", "W m-2",
        "kg/m²", "kg/m2", "m³/m³", "m3/m3", "1", "fraction",
    }

    unit_patterns = [
        re.compile(r'^[munpkMG]?m(?:/day|/d)?$'),
        re.compile(r'^[munpkMG]?g/(?:m2|m²)$'),
        re.compile(r'^[munpkMG]?g/(?:m2|m²)/(?:day|d)$'),
        re.compile(r'^[Ww]/(?:m2|m²)$'),
        re.compile(r'^(?:m3|m³)/(?:m3|m³)$'),
        re.compile(r'^%$'),
        re.compile(r'^(?:K|°C|degC)$'),
        re.compile(r'^(?:day|days|hour|hours)$', re.IGNORECASE),
    ]

    for unit in candidates:
        if unit in exact_units:
            return unit
        if any(pattern.fullmatch(unit) for pattern in unit_patterns):
            return unit

    return None


def infer_named_colormap(entries):
    """
    Conservatively recognise a few standard named ramps from anchor colours.
    Returns (name, reverse) or (None, None).
    """
    if not entries or len(entries) < 3:
        return None, None

    colors = [entry.get("color", "").upper() for entry in entries if entry.get("color")]
    if len(colors) < 3:
        return None, None

    first = colors[0]
    middle = colors[len(colors) // 2]
    last = colors[-1]

    for name, anchors in KNOWN_COLORMAPS.items():
        a0 = anchors[0]
        am = anchors[len(anchors) // 2]
        a1 = anchors[-1]

        if first == a0 and last == a1:
            # middle exactness is optional because sampled tables can vary.
            return name, False
        if first == a1 and last == a0:
            return name, True

    return None, None


def split_no_data(entries, layer=None):
    """
    Separate sentinel/no-data values from continuous ramp entries when this can
    be done conservatively.

    Rules:
      * negative values preceding a non-negative data range are treated as
        no-data/sentinel values;
      * for "day of burn" style layers, zero is also treated as a sentinel when
        the real data range begins at 1.
    """
    if not entries:
        return [], []

    sorted_entries = sorted(entries, key=lambda item: item["value"])
    no_data = []
    data = []

    non_negative = [e["value"] for e in sorted_entries if e["value"] >= 0]
    min_non_negative = min(non_negative) if non_negative else None

    title = (layer or {}).get("title", "")
    identifier = (layer or {}).get("identifier", "")
    abstract = (layer or {}).get("abstract", "")
    layer_text = " ".join([title, identifier, abstract]).lower()

    for entry in sorted_entries:
        value = entry["value"]

        if min_non_negative is not None and value < 0:
            no_data.append(entry)
            continue

        if value == 0 and "day of burn" in layer_text:
            # DOB explicitly documents no burn (0); real values are 1-366.
            no_data.append(entry)
            continue

        data.append(entry)

    return data, no_data


def enrich_discrete_labels(legend, script_text):
    """
    Add labels only when the Evalscript itself contains a recoverable
    value-to-label mapping. No synthetic class names are invented.
    """
    entries = legend.get("entries") or []
    if not entries:
        return legend

    labels = {}

    # Common object-map patterns:
    # 20: "Shrubland"
    # "20": "Shrubland"
    for match in re.finditer(
        r'["\']?(-?\d+(?:\.\d+)?)["\']?\s*:\s*["\']([^"\']{1,120})["\']',
        script_text,
    ):
        try:
            value = float(match.group(1))
        except Exception:
            continue
        labels[value] = match.group(2).strip()

    if labels:
        for entry in entries:
            if entry.get("value") in labels:
                entry["label"] = labels[entry["value"]]

    return legend



def extract_official_value_labels(documentation_url):
    """
    Extract value/class labels from official CLMS documentation conservatively.

    A table is only accepted when its header row explicitly identifies:
      * a numeric code/value/class column, and
      * a descriptive label/name/description column.

    This avoids false positives from unrelated numeric tables such as temporal
    resolution, scale factors, date ranges, or sampling metadata.
    """
    if not documentation_url:
        return {}

    try:
        _status, _headers, body, _final = fetch(
            documentation_url,
            accept="text/html,*/*",
        )
    except Exception:
        return {}

    page = html.unescape(body.decode("utf-8", errors="replace"))
    labels = {}

    tables = re.findall(
        r'<table\b[^>]*>(.*?)</table>',
        page,
        re.IGNORECASE | re.DOTALL,
    )

    value_header_terms = {
        "value", "code", "class", "class value", "class code",
        "pixel value", "category value", "category code",
    }
    label_header_terms = {
        "label", "name", "description", "class name",
        "category", "category name", "meaning",
    }

    def normalise_header(value):
        value = strip_html(value).strip().lower()
        value = re.sub(r'\s+', ' ', value)
        return value

    for table in tables:
        rows = re.findall(
            r'<tr\b[^>]*>(.*?)</tr>',
            table,
            re.IGNORECASE | re.DOTALL,
        )
        if not rows:
            continue

        header_cells = re.findall(
            r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
            rows[0],
            re.IGNORECASE | re.DOTALL,
        )
        headers = [normalise_header(cell) for cell in header_cells]

        if not headers:
            continue

        value_idx = None
        label_idx = None

        for idx, header in enumerate(headers):
            if value_idx is None and (
                header in value_header_terms
                or any(term in header for term in ("class value", "class code", "pixel value"))
            ):
                value_idx = idx

            if label_idx is None and (
                header in label_header_terms
                or any(term in header for term in ("class name", "category name"))
            ):
                label_idx = idx

        # Do not trust the table unless both semantic columns are explicit.
        if value_idx is None or label_idx is None or value_idx == label_idx:
            continue

        for row in rows[1:]:
            cells = [
                strip_html(cell).strip()
                for cell in re.findall(
                    r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
                    row,
                    re.IGNORECASE | re.DOTALL,
                )
            ]

            if max(value_idx, label_idx) >= len(cells):
                continue

            value_text = cells[value_idx]
            label_text = cells[label_idx]

            if not re.fullmatch(r'-?\d+(?:\.\d+)?', value_text):
                continue

            if not label_text or len(label_text) > 160:
                continue

            if "http://" in label_text or "https://" in label_text:
                continue

            try:
                value = float(value_text)
            except Exception:
                continue

            labels[value] = label_text

    return labels


def apply_official_labels(legend, official_labels):
    """
    Add labels to discrete entries only when an official documentation mapping
    supplies the corresponding value.
    """
    if legend.get("type") != "discrete":
        return legend

    entries = legend.get("entries") or []
    if not entries or not official_labels:
        return legend

    for entry in entries:
        value = entry.get("value")
        if value in official_labels:
            entry["label"] = official_labels[value]

    return legend


def parse_evalscript_legend(script_text, layer=None):
    """
    Conservatively extract legend-like colour definitions from common
    Sentinel Hub Evalscript patterns.

    Priority:
      1. Detect explicit ColorRampVisualizer / ColorMapVisualizer usage.
      2. Prefer compact source control points over mechanically expanded ramps.
      3. Fall back to generic value->colour extraction only when necessary.

    The parser intentionally returns nothing rather than guessing when a script
    uses complex procedural styling.
    """
    legend_type = None
    if "ColorRampVisualizer" in script_text:
        legend_type = "continuous"
    elif "ColorMapVisualizer" in script_text:
        legend_type = "discrete"

    # Try to isolate the first array passed to a visualizer. This often keeps
    # only the authored ramp/control points and avoids serialising generated
    # interpolation tables.
    visualizer_var = None
    vis_match = re.search(
        r'new\s+(ColorRampVisualizer|ColorMapVisualizer)\s*\(\s*([A-Za-z_$][A-Za-z0-9_$]*)\s*\)',
        script_text,
    )
    if vis_match:
        visualizer_var = vis_match.group(2)

    source_block = None
    if visualizer_var:
        var_match = re.search(
            rf'(?:const|let|var)\s+{re.escape(visualizer_var)}\s*=\s*(\[[\s\S]*?\])\s*;',
            script_text,
        )
        if var_match:
            source_block = var_match.group(1)

    search_text = source_block or script_text
    entries = []

    # [value, "#RRGGBB"]
    for match in re.finditer(
        r'\[\s*(-?\d+(?:\.\d+)?)\s*,\s*["\'](#[0-9A-Fa-f]{6})["\']\s*\]',
        search_text,
    ):
        entries.append({
            "value": float(match.group(1)),
            "color": match.group(2).upper(),
        })

    # [value, 0xRRGGBB]
    for match in re.finditer(
        r'\[\s*(-?\d+(?:\.\d+)?)\s*,\s*0x([0-9A-Fa-f]{6})\s*\]',
        search_text,
    ):
        entries.append({
            "value": float(match.group(1)),
            "color": "#" + match.group(2).upper(),
        })

    # [value, [r,g,b]]
    for match in re.finditer(
        r'\[\s*(-?\d+(?:\.\d+)?)\s*,\s*\[\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*\]\s*\]',
        search_text,
    ):
        color = rgb_to_hex(match.groups()[1:])
        if color:
            entries.append({
                "value": float(match.group(1)),
                "color": color,
            })

    # Object/map pattern: 1: [r,g,b]
    for match in re.finditer(
        r'(?:^|[,{]\s*)(-?\d+(?:\.\d+)?)\s*:\s*\[\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*\]',
        search_text,
        re.MULTILINE,
    ):
        color = rgb_to_hex(match.groups()[1:])
        if color:
            entries.append({
                "value": float(match.group(1)),
                "color": color,
            })

    dedup = {}
    for entry in entries:
        dedup[(entry["value"], entry["color"])] = entry

    entries = sorted(
        dedup.values(),
        key=lambda item: item["value"],
    )

    result = {}
    if legend_type:
        result["type"] = legend_type
    elif entries:
        # Small lookup tables are generally categorical. Dense ordered numeric
        # tables are treated as continuous ramps when no visualizer class is
        # explicitly present.
        if len(entries) <= 32:
            result["type"] = "discrete"
        else:
            values = [entry["value"] for entry in entries]
            if values == sorted(values):
                result["type"] = "continuous"

    if entries:
        units = extract_units_from_layer(layer or {})
        if units:
            result["units"] = units

        if result.get("type") == "discrete":
            # Never sample categorical classes.
            result["entries"] = entries
            result["sampled"] = False
            result = enrich_discrete_labels(result, script_text)
        else:
            data_entries, no_data = split_no_data(entries, layer=layer)

            if no_data:
                result["noData"] = no_data

            if data_entries:
                result["min"] = min(item["value"] for item in data_entries)
                result["max"] = max(item["value"] for item in data_entries)

                cmap_name, reverse = infer_named_colormap(data_entries)
                if cmap_name:
                    result["colormapName"] = cmap_name
                    result["reverse"] = bool(reverse)

                max_entries = 16
                if len(data_entries) <= max_entries:
                    result["entries"] = data_entries
                    result["sampled"] = False
                else:
                    indices = sorted({
                        round(i * (len(data_entries) - 1) / (max_entries - 1))
                        for i in range(max_entries)
                    })
                    result["entries"] = [data_entries[i] for i in indices]
                    result["sampled"] = True
                    result["sourceEntryCount"] = len(data_entries)

                result["steps"] = len(result["entries"])

    return result


def script_name_from_url(url):
    return urllib.parse.unquote(url.rsplit("/", 1)[-1])


def normalise_token(value):
    return re.sub(r"[^a-z0-9]+", "", (value or "").lower())


def canonical_text(value):
    return normalise_token(value or "")


def tokenise_words(value):
    """
    Split text into conservative semantic tokens for fallback style matching.

    Examples:
      "PermanentWater_Cover_Fraction" -> {"permanent","water","cover","fraction"}
      "Fractional Cover: Permanent Water" -> {"fractional","cover","permanent","water"}
    """
    if not value:
        return set()

    # Separate camelCase/PascalCase before stripping punctuation.
    value = re.sub(r'([a-z0-9])([A-Z])', r'\1 \2', value)
    value = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1 \2', value)
    parts = re.split(r'[^A-Za-z0-9]+', value.lower())

    stop = {
        "", "the", "of", "and", "or", "from", "for", "at", "to", "a", "an",
        "map", "layer", "indicator",
    }

    tokens = {p for p in parts if p not in stop}

    # Normalise common morphology used between script names and human titles.
    normalised = set()
    for token in tokens:
        aliases = {
            "fractional": "fraction",
            "probability": "probability",
            "classification": "classification",
            "builtup": "builtup",
            "burned": "burn",
            "burnt": "burn",
        }
        normalised.add(aliases.get(token, token))

    return normalised


def layer_match_keys(layer):
    """
    Build conservative canonical keys from both identifier and title.

    For sequencing-style identifiers such as A_ET_ENSEMBLE, strip the leading
    ordering prefix only when the stripped identifier agrees with the title.
    """
    identifier = layer.get("identifier") or ""
    title = layer.get("title") or ""

    keys = set()

    identifier_key = canonical_text(identifier)
    title_key = canonical_text(title)

    if identifier_key:
        keys.add(identifier_key)
    if title_key:
        keys.add(title_key)

    stripped = re.sub(r'^[A-Z]{1,2}_', '', identifier)
    stripped_key = canonical_text(stripped)

    if stripped_key and title_key and stripped_key == title_key:
        keys.add(stripped_key)

    return keys


def canonical_script_name(script):
    """
    Canonicalise a script filename/path without the .js suffix.
    """
    name = script.get("name") or ""
    name = re.sub(r'\.js$', '', name, flags=re.IGNORECASE)
    return canonical_text(name)


def shared_style_aliases(layer):
    """
    Return explicit shared-style aliases.

    ET/E/T standard-deviation bands all use STD.js in the official repository.
    """
    aliases = set()
    title_key = canonical_text(layer.get("title"))
    identifier_key = canonical_text(layer.get("identifier"))

    if title_key.endswith("std") or identifier_key.endswith("std"):
        aliases.add("std")

    return aliases


def explicit_style_aliases(layer):
    """
    Return high-confidence one-to-one aliases for abbreviated CLMS layer names
    whose official script names cannot be recovered reliably from token overlap.

    These mappings are intentionally narrow and only cover abbreviations that
    are unambiguous in the current official CLMS products.
    """
    identifier = (layer.get("identifier") or "").upper()
    title = (layer.get("title") or "").upper()

    aliases = {
        "BF": {"burnedfraction"},
        "CP": {"classificationprobability"},
        "DOB": {"dayofburn"},
        "LFP": {"largefractionprobability"},
    }

    keys = set()
    if identifier in aliases:
        keys |= aliases[identifier]
    if title in aliases:
        keys |= aliases[title]

    return keys


def token_match_score(layer, script):
    """
    Compute a conservative semantic overlap score.

    Exact token-set equivalence scores highest. Abstract matching is used only
    to support abbreviated layer identifiers/titles.
    """
    script_name = re.sub(r'\.js$', '', script.get("name") or "", flags=re.IGNORECASE)
    script_tokens = tokenise_words(script_name)

    title_tokens = tokenise_words(layer.get("title"))
    identifier_tokens = tokenise_words(layer.get("identifier"))
    abstract_tokens = tokenise_words(layer.get("abstract"))

    identifier_tokens = {
        t for t in identifier_tokens
        if not (len(t) == 1 and t.isalpha())
    }

    for candidate in (title_tokens, identifier_tokens):
        if script_tokens and candidate:
            if script_tokens == candidate:
                return 100

            overlap = len(script_tokens & candidate)
            union = len(script_tokens | candidate)
            if union:
                jaccard = overlap / union
                if jaccard >= 0.8 and overlap >= 2:
                    return 90

    if script_tokens and abstract_tokens and len(script_tokens) >= 2:
        overlap = script_tokens & abstract_tokens
        if overlap == script_tokens:
            return 80

        jaccard = len(overlap) / len(script_tokens | abstract_tokens)
        if len(overlap) >= 2 and jaccard >= 0.5:
            return 70

    return 0


def style_refs_for_layer(layer, scripts):
    """
    Match scripts to a WMTS/WMS layer deterministically.

    Matching order:
      1. exact canonical match against identifier/title
      2. explicit one-to-one aliases for known abbreviations
      3. explicit shared-style aliases (e.g. *-STD -> STD.js)
      4. conservative semantic token matching, choosing one best script
      5. single-layer fallback to all scripts

    Except for explicit shared-style aliases and single-layer products, at most
    one script is attached to each layer.
    """
    keys = layer_match_keys(layer)

    exact = [
        script
        for script in scripts
        if canonical_script_name(script) in keys
    ]
    if exact:
        return [exact[0]]

    explicit_aliases = explicit_style_aliases(layer)
    if explicit_aliases:
        alias_matches = [
            script
            for script in scripts
            if canonical_script_name(script) in explicit_aliases
        ]
        if alias_matches:
            return [alias_matches[0]]

    shared_aliases = shared_style_aliases(layer)
    if shared_aliases:
        shared_matches = [
            script
            for script in scripts
            if canonical_script_name(script) in shared_aliases
        ]
        if shared_matches:
            return shared_matches

    scored = []
    for script in scripts:
        score = token_match_score(layer, script)
        if score:
            scored.append((score, script))

    if scored:
        scored.sort(
            key=lambda item: (
                -item[0],
                canonical_script_name(item[1]),
            )
        )
        best_score, best_script = scored[0]
        if best_score >= 70:
            return [best_script]

    if layer.get("_singleLayer") and scripts:
        return scripts[:]

    return []


def discover_style_metadata(documentation_url, layers):
    """
    Retrieve official CLMS Evalscript references via the GitHub Contents API
    and extract simple legend definitions where possible.

    Styles are attached directly to matching layers as layers[].styles.

    Complex procedural Evalscripts remain represented by their official URL
    even when no structured legend can be safely extracted.
    """
    directory_url, script_entries, discovery = extract_evalscript_links(
        documentation_url
    )

    result = {}

    official_value_labels = extract_official_value_labels(documentation_url)

    if documentation_url:
        result["documentationUrl"] = documentation_url

    result["evalscriptDiscovered"] = bool(directory_url)

    if directory_url:
        result["evalscriptDirectoryUrl"] = directory_url

    if discovery.get("archiveUrl"):
        result["githubArchiveUrl"] = discovery.get("archiveUrl")

    result["styleDiscoveryStatus"] = discovery.get("status") or "unknown"

    if discovery.get("error"):
        result["styleDiscoveryError"] = discovery.get("error")

    scripts = []

    for script_entry in script_entries:
        script_url = script_entry.get("url")
        item = {
            "name": script_entry.get("name"),
            "url": script_url,
            "path": script_entry.get("path"),
            "_content": script_entry.get("content"),
        }

        try:
            script_text = script_entry.get("content")
            if script_text is None:
                _status, _headers, body, _final = fetch(
                    script_url,
                    accept="text/plain,*/*",
                )
                script_text = body.decode("utf-8", errors="replace")

            item["_content"] = script_text
        except Exception:
            pass

        scripts.append(clean(item))

    result["scriptCount"] = len(scripts)

    if official_value_labels:
        result["officialClassLabelCount"] = len(official_value_labels)

    if scripts:
        result["scripts"] = [
            clean({
                "name": script.get("name"),
                "url": script.get("url"),
                "path": script.get("path"),
            })
            for script in scripts
        ]

    # Mark whether there is a single advertised layer so unmatched scripts can
    # still be assigned sensibly.
    single_layer = len(layers) == 1

    for layer in layers:
        layer["_singleLayer"] = single_layer
        matched = style_refs_for_layer(layer, scripts)
        layer.pop("_singleLayer", None)

        if not matched:
            continue

        layer_styles = []

        for script in matched:
            style_item = {
                "name": script.get("name"),
                "evalscriptUrl": script.get("url"),
            }

            script_text = script.get("_content")
            if script_text:
                layer_legend = parse_evalscript_legend(
                    script_text,
                    layer=layer,
                )
                if layer_legend:
                    layer_legend = apply_official_labels(
                        layer_legend,
                        official_value_labels,
                    )
                    style_item["legend"] = layer_legend

            layer_styles.append(clean(style_item))

        if layer_styles:
            layer["styles"] = layer_styles

    return result


def dataset_abstract_from_layers(layers):
    """
    Return a dataset-level abstract only when one specific layer description
    can unambiguously represent the dataset. Multi-layer products retain their
    descriptions only at layer level.
    """
    specific = [layer.get("abstract") for layer in layers if layer.get("abstract")]
    return specific[0] if len(specific) == 1 else None

def build_record(dataset_id, catalogue_meta):
    wmts = probe_map_service(dataset_id, "WMTS")

    if wmts["available"]:
        layers = wmts.get("layers") or []
        style = discover_style_metadata(
            catalogue_meta.get("documentationUrl"),
            layers,
        )
        return clean({
            "datasetIdentifier": dataset_id,
            "title": catalogue_meta.get("title") or fallback_title(dataset_id),
            "abstract": dataset_abstract_from_layers(layers),
            "theme": theme_for(dataset_id),
            "available": True,
            "serviceType": "WMTS",
            "serviceUrl": wmts.get("serviceUrl"),
            "getCapabilitiesUrl": wmts.get("getCapabilitiesUrl"),
            "layers": layers,
            "style": style,
            "access": {
                "wmts": {
                    "available": True,
                    "getCapabilitiesUrl": wmts.get("getCapabilitiesUrl"),
                }
            },
        })

    wms = probe_map_service(dataset_id, "WMS")

    if wms["available"]:
        layers = wms.get("layers") or []
        style = discover_style_metadata(
            catalogue_meta.get("documentationUrl"),
            layers,
        )
        return clean({
            "datasetIdentifier": dataset_id,
            "title": catalogue_meta.get("title") or fallback_title(dataset_id),
            "abstract": dataset_abstract_from_layers(layers),
            "theme": theme_for(dataset_id),
            "available": True,
            "serviceType": "WMS",
            "serviceUrl": wms.get("serviceUrl"),
            "getCapabilitiesUrl": wms.get("getCapabilitiesUrl"),
            "layers": layers,
            "style": style,
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
        "title": catalogue_meta.get("title") or fallback_title(dataset_id),
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


catalogue_metadata = discover_catalogue_metadata()
datasets = sorted(catalogue_metadata)

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
        pool.submit(build_record, dataset_id, catalogue_metadata.get(dataset_id, {})): dataset_id
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
