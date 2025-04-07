cwlVersion: v1.0
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.4.1
schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf
$graph:
  - class: Workflow
    id: water-bodies5
    label: Water bodies detection based on NDWI and otsu threshold
    doc: Water bodies detection based on NDWI and otsu threshold
    requirements:
      SchemaDefRequirement:
        types:
        - $import: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml
        - $import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml
    inputs:
      a:
        label: A
        doc: A
        type: int?
      b:
        label: B
        doc: B
        type: float
        default: 4326
      c:
        label: C
        doc: C
        type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#FeatureCollection?
      d:
        label: D
        doc: D
        type: double
      e:
        label: E
        doc: E
        type: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml#BBox
      f:
        label: F
        doc: F
        type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Feature?
      f2:
        label: F2
        doc: F2
        type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#GeometryCollection
      gaoi:
        label: area of interest
        doc: area of interest as a bounding box
        type: string
      gepsg:
        label: EPSG code
        doc: EPSG code
        type: string
        default: EPSG:4326
      gstac_items:
        label: Sentinel-2 STAC items
        doc: list of Sentinel-2 COG STAC items
        type: string[]
      gbands:
        label: bands used for the NDWI
        doc: bands used for the NDWI
        type: string[]
        default:
          - green
          - nir
    outputs:
      - id: stac
        outputSource:
          - node_stac/stac_catalog
        type: Directory
    steps:
      node_water_bodies:
        run: '#detect_water_body'
        in:
          item: gstac_items
          aoi: gaoi
          epsg: gepsg
          bands: gbands
        out:
          - detected_water_body
        scatter: item
        scatterMethod: dotproduct
      node_stac:
        run: '#stac'
        in:
          item: stac_items
          rasters:
            source: node_water_bodies/detected_water_body
        out:
          - stac_catalog
  - class: Workflow
    id: detect_water_body
    label: Water body detection based on NDWI and otsu threshold
    doc: Water body detection based on NDWI and otsu threshold
    requirements:
      - class: ScatterFeatureRequirement
    inputs:
      aoi:
        doc: area of interest as a bounding box
        type: string
      epsg:
        doc: EPSG code
        type: string
        default: EPSG:4326
      bands:
        doc: bands used for the NDWI
        type: string[]
      item:
        doc: STAC item
        type: string
    outputs:
      - id: detected_water_body
        outputSource:
          - node_otsu/binary_mask_item
        type: File
    steps:
      node_crop:
        run: '#crop'
        in:
          item: item
          aoi: aoi
          epsg: epsg
          band: bands
        out:
          - cropped
        scatter: band
        scatterMethod: dotproduct
      node_normalized_difference:
        run: '#norm_diff'
        in:
          rasters:
            source: node_crop/cropped
        out:
          - ndwi
      node_otsu:
        run: '#otsu'
        in:
          raster:
            source: node_normalized_difference/ndwi
        out:
          - binary_mask_item
  - class: CommandLineTool
    id: crop
    requirements:
      InlineJavascriptRequirement: {}
      EnvVarRequirement:
        envDef:
          PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          PYTHONPATH: /app
      ResourceRequirement:
        coresMax: 1
        ramMax: 512
    hints:
      DockerRequirement:
        dockerPull: ghcr.io/terradue/ogc-eo-application-package-hands-on/crop:1.5.0
    baseCommand:
      - python
      - '-m'
      - app
    arguments: []
    inputs:
      item:
        type: string
        inputBinding:
          prefix: '--input-item'
      aoi:
        type: string
        inputBinding:
          prefix: '--aoi'
      epsg:
        type: string
        inputBinding:
          prefix: '--epsg'
      band:
        type: string
        inputBinding:
          prefix: '--band'
    outputs:
      cropped:
        outputBinding:
          glob: '*.tif'
        type: File
  - class: CommandLineTool
    id: norm_diff
    requirements:
      InlineJavascriptRequirement: {}
      EnvVarRequirement:
        envDef:
          PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          PYTHONPATH: /app
      ResourceRequirement:
        coresMax: 1
        ramMax: 512
    hints:
      DockerRequirement:
        dockerPull: ghcr.io/terradue/ogc-eo-application-package-hands-on/norm_diff:1.5.0
    baseCommand:
      - python
      - '-m'
      - app
    arguments: []
    inputs:
      rasters:
        type: File[]
        inputBinding:
          position: 1
    outputs:
      ndwi:
        outputBinding:
          glob: '*.tif'
        type: File
  - class: CommandLineTool
    id: otsu
    requirements:
      InlineJavascriptRequirement: {}
      EnvVarRequirement:
        envDef:
          PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          PYTHONPATH: /app
      ResourceRequirement:
        coresMax: 1
        ramMax: 512
    hints:
      DockerRequirement:
        dockerPull: ghcr.io/terradue/ogc-eo-application-package-hands-on/otsu:1.5.0
    baseCommand:
      - python
      - '-m'
      - app
    arguments: []
    inputs:
      raster:
        type: File
        inputBinding:
          position: 1
    outputs:
      binary_mask_item:
        outputBinding:
          glob: '*.tif'
        type: File
  - class: CommandLineTool
    id: stac
    requirements:
      InlineJavascriptRequirement: {}
      EnvVarRequirement:
        envDef:
          PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          PYTHONPATH: /app
      ResourceRequirement:
        coresMax: 1
        ramMax: 512
    hints:
      DockerRequirement:
        dockerPull: ghcr.io/terradue/ogc-eo-application-package-hands-on/stac:1.5.0
    baseCommand:
      - python
      - '-m'
      - app
    arguments: []
    inputs:
      item:
        type:
          type: array
          items: string
          inputBinding:
            prefix: '--input-item'
      rasters:
        type:
          type: array
          items: File
          inputBinding:
            prefix: '--water-body'
    outputs:
      stac_catalog:
        outputBinding:
          glob: .
        type: Directory