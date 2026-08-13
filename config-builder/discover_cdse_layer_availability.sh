#!/usr/bin/env bash
set -euo pipefail

OUTPUT="${1:-clms-wmts.json}"

python3 - "$OUTPUT" <<'PY'
import concurrent.futures
import datetime as dt
import json
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

OUTPUT = sys.argv[1]
SERVICE_ROOT = "https://land.copernicus.eu/cdse/"
SOURCE_DOC = "https://documentation.dataspace.copernicus.eu/Data/ComplementaryData/CLMS.html"
TIMEOUT = 25
MAX_WORKERS = 10
USER_AGENT = "cdse-wmts-availability/4.0"

DATASETS = [
    "lc_global_100m_yearly_v3",
    "ssm_europe_1km_daily_v1",
    "swi_europe_1km_daily_v1",
    "swi_europe_1km_daily_v2",
    "swi_global_12.5km_daily_v3",
    "swi_global_12.5km_daily_v4",
    "swi-timeseries_global_12.5km_daily_v3",
    "swi-static_global_12.5km_daily_v3",
    "swi_global_12.5km_10daily_v3",
    "swi_global_12.5km_10daily_v4",
    "sce_europe_500m_daily_v1",
    "sce_northernhemisphere_1km_daily_v1",
    "swe_northernhemisphere_5km_daily_v1",
    "swe_northernhemisphere_5km_daily_v2",
    "lst_global_5km_hourly_v1",
    "lst_global_5km_hourly_v2",
    "lst-daily-cycle_global_5km_10daily_v1",
    "lst-daily-cycle_global_5km_10daily_v2",
    "lst-tci_global_5km_10daily_v1",
    "lst-tci_global_5km_10daily_v2",
    "lswt-nrt_global_1km_10daily_v1",
    "lswt-offline_global_1km_10daily_v1",
    "toc_global_300m_daily_v2",
    "ba_global_300m_daily_v3",
    "ba_global_300m_monthly_v3",
    "fcover_global_300m_10daily_v1",
    "fcover_global_1km_10daily_v2",
    "fapar_global_300m_10daily_v1",
    "fapar_global_1km_10daily_v2",
    "lai_global_1km_10daily_v2",
    "lai_global_300m_10daily_v1",
    "ndvi_global_1km_10daily_v3",
    "ndvi_global_1km_10daily_v2",
    "ndvi_global_300m_10daily_v2",
    "ndvi_global_300m_10daily_v1",
    "ndvi-sts_global_1km_10daily_v3",
    "ndvi-lts_global_1km_10daily_v3",
    "ndvi-lts_global_1km_10daily_v2",
    "lsp_global_300m_yearly_v1",
    "dmp_global_300m_10daily_v1",
    "dmp_global_1km_10daily_v2",
    "gdmp_global_300m_10daily_v1",
    "gdmp_global_1km_10daily_v2",
    "npp_global_300m_10daily_v1",
    "gpp_global_300m_10daily_v1",
    "wb_global_100m_monthly_v1",
    "wb_global_1km_10daily_v2",
    "wb_global_300m_monthly_v2",
    "wb_global_300m_10daily_v1",
    "wl-lakes_global_vector_daily_v2",
    "wl-rivers_global_vector_daily_v2",
    "lwq-nrt_global_100m_10daily_v1",
    "lwq-reproc_global_300m_10daily_v1",
    "lwq-nrt_global_300m_10daily_v1",
    "lwq-nrt_global_100m_10daily_v2",
    "lwq-nrt_global_300m_10daily_v2",
    "lie_baltic_250m_daily_v1",
    "lie_global_500m_daily_v2",
    "lie_europe_250m_daily_v2",
    "lcm_global_10m_yearly_v1",
    "tcd_pantropical_10m_yearly_v1",
]

# Theme lookup keyed on the leading token of the dataset identifier.
THEMES = {
    "lc": "Land cover",
    "lcm": "Land cover",
    "tcd": "Land cover",
    "ssm": "Soil moisture",
    "swi": "Soil moisture",
    "sce": "Snow and ice",
    "swe": "Snow and ice",
    "lie": "Snow and ice",
    "lst": "Temperature",
    "lswt": "Temperature",
    "toc": "Surface reflectance",
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


def theme_for(dataset_id):
    prefix = dataset_id.split("_", 1)[0].split("-", 1)[0]
    return THEMES.get(prefix, "Other")


def fallback_title(dataset_id):
    return dataset_id.replace("-", " ").replace("_", " ").strip()


def fetch(url):
    req = urllib.request.Request(
        url,
        headers={"User-Agent": USER_AGENT, "Accept": "application/xml,text/xml,*/*"},
    )
    with urllib.request.urlopen(req, timeout=TIMEOUT, context=ssl_ctx) as r:
        return r.status, dict(r.headers.items()), r.read(), r.geturl()


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


def clean(obj):
    return {k: v for k, v in obj.items() if v not in (None, "", [], {})}


def parse_layer(layer):
    return clean({
        "identifier": child_text(layer, "Identifier"),
        "title": child_text(layer, "Title"),
        "abstract": child_text(layer, "Abstract"),
    })


def parse_capabilities(body):
    root = ET.fromstring(body)
    if local_name(root.tag) != "Capabilities" or "wmts/1.0" not in root.tag:
        raise ValueError("Response is not WMTS 1.0 Capabilities XML")
    service_ident = child(root, "ServiceIdentification")
    contents = child(root, "Contents")
    if contents is None:
        raise ValueError("WMTS capabilities contains no Contents element")
    service_title = child_text(service_ident, "Title") if service_ident is not None else None
    service_abstract = child_text(service_ident, "Abstract") if service_ident is not None else None
    layers = [parse_layer(x) for x in children(contents, "Layer")]
    return service_title, service_abstract, layers


def record(dataset_id, service_url, caps_url, available, title=None,
           abstract=None, layers=None, diagnostics=None):
    entry = {
        "datasetIdentifier": dataset_id,
        "serviceUrl": service_url,
        "getCapabilitiesUrl": caps_url,
        "title": title or fallback_title(dataset_id),
        "theme": theme_for(dataset_id),
        "available": available,
        "layers": layers or [],
    }
    if abstract:
        entry["abstract"] = abstract
    if diagnostics:
        entry["diagnostics"] = clean(diagnostics)
    return entry


def probe(dataset_id):
    service_url = f"{SERVICE_ROOT}{dataset_id}/"
    caps_url = service_url + "?" + urllib.parse.urlencode({
        "SERVICE": "WMTS",
        "REQUEST": "GetCapabilities",
    })
    try:
        status, _headers, body, _final = fetch(caps_url)
        try:
            title, abstract, layers = parse_capabilities(body)
        except Exception as e:
            return record(dataset_id, service_url, caps_url, False,
                          diagnostics={"status": "not_wmts", "httpStatus": status,
                                       "reason": str(e)})
        return record(dataset_id, service_url, caps_url, True,
                      title=title, abstract=abstract, layers=layers)
    except urllib.error.HTTPError as e:
        return record(dataset_id, service_url, caps_url, False,
                      diagnostics={"status": "unavailable", "httpStatus": e.code,
                                   "reason": str(e.reason)})
    except Exception as e:
        return record(dataset_id, service_url, caps_url, False,
                      diagnostics={"status": "error", "reason": str(e)})


print(f"Loaded {len(DATASETS)} CLMS/CDSE dataset identifiers.", file=sys.stderr)
print(f"Probing {SERVICE_ROOT}<dataset>/ as WMTS...", file=sys.stderr)

records = []
with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
    futures = {pool.submit(probe, d): d for d in DATASETS}
    completed = 0
    for future in concurrent.futures.as_completed(futures):
        completed += 1
        rec = future.result()
        records.append(rec)
        print(
            f"[{completed:>3}/{len(DATASETS)}] {rec['datasetIdentifier']}: "
            f"{'available' if rec['available'] else 'unavailable'}",
            file=sys.stderr,
        )

records.sort(key=lambda x: (x["theme"], x["datasetIdentifier"]))
available_count = sum(1 for r in records if r["available"])
unavailable_count = len(records) - available_count

collection = {
    "meta": {
        "title": "Copernicus Land Monitoring Service (CDSE)",
        "description": "CLMS datasets published as WMTS services via the Copernicus Data Space Ecosystem.",
        "provider": "Copernicus Land Monitoring Service",
        "source": SOURCE_DOC,
        "servicesUrl": SERVICE_ROOT,
        "generated": dt.datetime.now(dt.timezone.utc).isoformat(),
    },
    "datasets": records,
}

with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(collection, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"\nWrote {OUTPUT}: {available_count} available, {unavailable_count} unavailable.",
      file=sys.stderr)
PY
