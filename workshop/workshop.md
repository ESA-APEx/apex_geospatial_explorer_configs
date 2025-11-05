# Geospatial Explorer Config Builder Workshop

_Useful links_
* The config builder at [https://apex-ge-config-builder.sparkgeo.uk/](https://apex-ge-config-builder.sparkgeo.uk/)
* View this guide [here](https://raw.githubusercontent.com/ESA-APEx/apex_geospatial_explorer_configs/refs/heads/workshop-notes/workshop/workshop.md)
* Edit this guide [here](https://github.com/ESA-APEx/apex_geospatial_explorer_configs/edit/workshop-notes/workshop/workshop.md)

## About this workshop
### Scope
* This workshop is about the **Geospatial Explorer Configuration Builder** that is used to create configurations for the GE
* **WE WILL** be covering most of its capabilities building a completely new configuration from scratch, connecting to various data sources (e.g. COGS, FlatGeoBuffs etc) and services (WMS / WMTS / STAC)
* **WE WILL NOT** be covering how those data sources and services themselves are created, configured, or managed.
* The APEx interopability guidelines provide details of pre-requisites or best practices for those data sources / services, and existing tools and knowledge of appropriately experience professionals should be able to meet those
* The *only* data type that is a bit more specific to the GE are statistics.  Whilst these use a standard geospatial data format (FlatGeoBuff), the way in which that data is structured within those files _is_ important.  In this workshop we will add some statistics datasets that have been prepared already, but the preparation of those statistics will need to be covered in a separate session.

### Pre-requisites
* There are no specific technical pre-requisites, although a second monitor will be useful to follow along
* In terms of pre-requisite knowledge it is assumed that attendees have some basic knowledge of the concepts of
- Geospatial data, primarily raster (we use COGS, but detailed knowledge of them is) and vector
- Geospatial web serices, such as WMS, WMTS and XYZ services
- Spatio Temporal Asset Catalogues (STAC), and the concepts of *collections, items and assets*
* If delegates are not familiar with the above, the workshop is still applicable, but there may be some areas which might require some more detailed explanation

## Part 1 - Mastering the basics

###  1.1 Key concepts
* The Geospatial Explorer Configuration Builder ("CB") is an authoring tool for the JSON that the Geospatial Explorer uses.
* The JSON itself is complex - the tool intends to reduce the technical barrier required to build GE config environments.
* The CB runs entirely within your web browser.  There is no persistent back end storage of configurations.
* We "save" configurations simply by downloading them locally to our own machinesm and reloading later when we want to continue working with them.
* Configrations can be shared - e.g. just email to a collaborator
* A run-time version of the GE is integrated into the CB. This will include released versions and potentially interim development versions.
* Development versions allows configurations to be built to work with features of the CB which are being delivered in a future release
* The CB itself is a work in progress.  We would welcome your ideas to improve it based on your experences.

### 1.2 Getting started

In this exercise we will start building a new configuration from scratch using the *Forest Carbon* data

#### 1.2.1 Name, interface group and branding

We will start by changing the title, interface group and branding.

1. **Open the configuration builder** by going to the following URL: [https://apex-ge-config-builder.sparkgeo.uk/](https://apex-ge-config-builder.sparkgeo.uk/)
2. On the *home* tab **edit the title** of the configuration to something of your choice
3. Move to the *layers* tab.  **Edit** *Interface group 1* replacing the name with *Forest Carbon*.  **Delete** the other interface groups.
4. Move to the *settings* tab, and **edit** some of the colours to a colour scheme of your choice
5. Select the *preview* tab, and see the changes

Your UI might now look something like this:
<img width="1915" height="917" alt="image" src="https://github.com/user-attachments/assets/c8b9c5c0-305b-43a7-a48c-e53e3b9e7411" />


#### 1.2.2 Exporting and reloading config

**Remember** there is no "saving" of config - simply exporting and importing

1. On the *home* tab select **Export -> Quick Export**.  This will download to your local machine as a file called **config.json**
2. Now select **New Config**.  You will see that your previous changes have been lost
3. Now select **Load Config**.  You will see your previous config has been reinstated.

> As you continue through this workshop **remember to export your config** frequently, in case you accidentally close your browser tab.  You can then reinstate it from your local machine

As you download on multiple occasions your operating system will be treating each file as a copy and may rename them - e.g. *config (1).json*,  *config (2).json* etc

#### 1.2.3 Add in some new base maps

1. On the *Layers Tab* scroll down to *Base maps* and select **Add Recommended Base Maps**.
2. Take a little time to look in the Config Builder at what has been added.  Note things like attribution have automatically been added to the base map cards.  Then go to *Preview* to see the results.  It should look like this.

<img width="1915" height="917" alt="image" src="https://github.com/user-attachments/assets/6bf607e2-2b4f-47c3-a2d2-d19ee9d0362d" />

### 1.3 Adding in your first data

#### 1.3.1 Creating your first layer card

A layer card is a user interface element into which we add content such as descriptions, data, statistics, constraints. 

1. On the *layers* tab select your *Forest Carbon* interface group and select **+ Add Layer**
2. Leave the **default settings** for Layer Type and Layout style
3. Type *Above Ground Biomass* into the **Layer Name** field
4. Enter in a suitable **Description** that will describe the layer.
5. Add *Forest Carbon* into the **Attribution text**.  Add an **Attribution URL** to the Forest Carbon website if you want.
6. Select **Create Layer Card**

You will now have a layer card that looks something like this:

<img width="1915" height="917" alt="image" src="https://github.com/user-attachments/assets/737b1ff7-14de-4b25-a1ab-70ef20042400" />

#### 1.3.2 Add some data to your layer card

You will now add some data to the data sources.

1. In the *Datasets* tab on your layer card, select **+ Add Dataset**

<img width="1390" height="701" alt="image" src="https://github.com/user-attachments/assets/62148be7-4505-4b2f-b570-79191968e02d" />

2. Stay on the *Direct Connection* and *COG* data format, and copy the following into the **Data Source URL** then select **Add Source**
```
https://eoresults.esa.int/d/FCM-AGB-100m/2023/01/01/FCM-AGB-100m-2023/FCM_Europe_demo_2023_AGB.tif
```
3. You will now see the data source listed in the Datasets tab

<img width="1077" height="130" alt="image" src="https://github.com/user-attachments/assets/50e49a31-a397-409e-bdc6-f8960b3898e3" />
   
4. Click on the **(i)** icon on the data source to interrogate metadata about the COG
5. Make mental note of the **min** and **max** values, then close the dialogue.
6. Now select **Edit** icon at the top of the layer card.  This is the pen icon to the right of the **info panel** badge

<img width="1169" height="96" alt="image" src="https://github.com/user-attachments/assets/90a287c9-d928-46cc-9720-1f9a5f1fb198" />
This returns us back to the Edit Layer Card mode

7. Now scroll down and select **Legend Type ->** Gradient.  Enter in the **min** value noted above and the **max** value with colours for each.

<img width="1321" height="330" alt="image" src="https://github.com/user-attachments/assets/474a16af-749f-4faa-8c9d-c9fa7a11dbbe" />

8. **Save Changes** then go to **Preview** and you should see something like this:
<img width="1919" height="905" alt="image" src="https://github.com/user-attachments/assets/3331456d-f15e-4696-9f85-4e222a691d98" />


> **Congratulations.  You've now added your first layer!**

### 1.4 Replacing the gradient with a Colour Map

Gradients are OK for a quick visualisation, but a Colour Map provides more visualisation capability.

1. From the layer card, select **Edit Layer** button
2. Scroll down to **Add Colormaps**, this will pop up the following modal

<img width="685" height="602" alt="image" src="https://github.com/user-attachments/assets/eb73f6b8-11de-4b16-b3d6-296d853af4cf" />

3. **Edit the settings** to style it according to your preferences between the min and max values
4. **Save the colormap** and then **Save the layer card** changes, until you end up back at the read only layer card

<img width="1152" height="658" alt="image" src="https://github.com/user-attachments/assets/c4698088-6d13-498a-9885-fad93c867d19" />

Although the Gradient view will still be visible in the layer card, the Colour Map takes precedence.  Preview your results and you should see something like this.

 <img width="1919" height="911" alt="image" src="https://github.com/user-attachments/assets/b9039d6b-14b9-4eb1-87ec-903f480b7c3e" />

### 1.5 Experimenting with controls

1. Edit your *AGB* Layer Card and scroll down the **Layer Controls** section
2. Change some of the toggle options - e.g. `Zoom to`, `Opacity slider`, `Blend Mode`, `Download`, `Constraint``.  (Don't change Temporal Settings - we will look at that later.

> For Downloads you could either copy in the COG URL above, which will initiate the Download, or another external link (such as the datasets STAC record from the PRR)
 
 ### Did you remember to export?
 
 > As we noted earlier, its a good idea to export your config periodically in case you accidentally closed your web browser.  If you haven't now would be a good time

## Part 2 - Web Services (WMS / WMTS / STAC) and PRR

### 2.1 Adding in WMS directly

#### 2.1.1 Create a layer card with a WMS

Using the steps outlined above:

1. **Add an interface group** called *Land Cover*
2. **Add Layer Card** called *World Cover* with appropriate title, attribution etc
3. Select **Add Dataset** to the layer card
4. Select **Direct Connection -> WMS/WMTS Service**
5. Copy the following URL into the
```
https://services.terrascope.be/wms/v2
```
6. Copy the following **Layer Name** into the WMS 
```
WORLDCOVER_2020_MAP
```
A very basic configuration would look something like this, although hopefully you've added attribution, descriptions etc.

<img width="1916" height="909" alt="image" src="https://github.com/user-attachments/assets/9b058162-d4ee-4dda-b0f9-efa602ac8935" />

#### 2.1.2 Adding Recommended Services

We are now going to work with other services - STAC services and querying WMS / WMTS services directly.  The recommended services are simply a collection of these that people will find useful.

1. Move to the **Services** tab and select **Add Recommended Services**
2. You will now see a list of services, such as the *STAC service for the PRR* and various WMS services.  

<img width="1390" height="897" alt="image" src="https://github.com/user-attachments/assets/ce024a46-1198-45ec-b1dd-d15b0e09ee5a" />

We can use these services when adding data

#### 2.1.3 Adding data from the PRR

1. In the *Layers UI* create a new **Layer Card** as before called *Below Ground Biomass*, populate with relevant details
2. Select **Add Dataset** then select the *From Service* 
3. Select the **Project Results Repository**.  You will see a dialogue like this:

<img width="1390" height="897" alt="image" src="https://github.com/user-attachments/assets/9c66e151-f0a9-4ef3-8686-394fa935eb11" />

4. Spend some time *Browsing the PRR*
5. **Search** for *BGB* to find the *Below Ground Biomass* collection.  Select the *assets* and *items* until you see the COGS listed.  **Add** the most recent COG to your source  
6. Finish setting up the data as you see fit **colour maps** etc

#### 2.1.4 Adding more WMS layers

1. In the *Layers UI* create a new **Layer Card** call it *"temp"* for now
2. Select **Add Dataset** then *From Service* and have a browse through some of the WMS services - e.g. **CLMS** or another service of your choice
3. **Pick a WMS layer** of interest to you and add it to your layer card
4. Now go and **Edit the Layer Card** details changing the name from *"temp"* to a more suitable layer name and configure as you see fit

Here we added one of the **CLMS** datasets for Tree Cover Density

<img width="1916" height="907" alt="image" src="https://github.com/user-attachments/assets/57a8e350-3f10-4092-b026-1cbd5078af79" />

#### 2.1.5 Adding legends for a WMS

Some WMS services may serve up legends using the 

1. User the **(i)** button on the Dataset listing on your layer card to check whether the WMS has a layer graphic
<img width="776" height="568" alt="image" src="https://github.com/user-attachments/assets/bbcddb29-7e26-40f4-a2a8-cc50fa729cea" />

2. If it does, select the **Copy to config** option.  This should add the legend to the layer card.
3. If it does not, then the other option is to edit the layer card and point to a publically accessible legend graphic - e.g. a **png** file.  This is also an option if you want to use a different legend to the one returned from the WMS service.

The dataset we added earlier now looks like this:

<img width="1913" height="915" alt="image" src="https://github.com/user-attachments/assets/6bf4b653-86b7-480a-9520-78e481b25506" />

Overwriting it with a nicely crafted legend might be a good idea!

### Did you remember to export?
 
> As we noted earlier, its a good idea to export your config periodically in case you accidentally closed your web browser.  If you haven't now would be a good time

## Part 3 - Working with Categorical Data

### 3.1  Setting up Categories

#### 3.1.1 Introduction
* Often we are working with categorical data, such as classifications (e.g. Land Cover)
* The data may be provided in a number of ways
* It may be WMS (such as the World Cover data earlier) or some tile service where the data is rendered according to the categories
* It may equally be a COG where the data values in the COG represent categorical values
* In both scenarios we can set up Categories for the GE
* For WMS layers, these will display a legend
* For COGS, these will define how the data is rendered and also display a legend

#### 3.1.2 Setting up Categories for World Cover manually

1. In exercise 2.1.1 you set up World Cover data.  Select **Edit Layer Card** on this.
2. Scroll down and select **Add Categories**.  A UI for setting categories will appear.

<img width="653" height="712" alt="image" src="https://github.com/user-attachments/assets/1079fcfb-a7fc-477c-9aac-d6a71d3b8db8" />

4. Select the toggle on the UI to **Use data values**.  An additional column will appear.
5. Use the UI to change the *colour to* **green**, label to **tree** and value to 10
6. Repeat with another couple of categories for world cover.  You can use the image above on this page and the colour picker tool to get the corrcet colours
6. You only need to do a couple now.  Complete the saves and preview.  If you did them all, the legend when you render would looking like this:

<img width="1072" height="550" alt="image" src="https://github.com/user-attachments/assets/b2782351-3ebf-4806-883e-2d937318e5be" />

#### 3.1.3 Using categories with a COG

We can use the same categories for a COG version

1. Create a new **Layer Card** called *World Cover COG*
2. **Add the following dataset** for a World Cover COG of Austria:
```
https://esa-apex.s3.eu-west-1.amazonaws.com/APEX-example-data/constraints/PowerDensity_100m_Austria_WGS84_COG_clipped_3857_fix-esa_worldcover_2021.tif
```
3. Go to thew **(i)** icon on the dataset, to get to the COG metadata
4. Select **Populate categories**.  You will now see this:

<img width="653" height="712" alt="image" src="https://github.com/user-attachments/assets/5d282f2a-9c16-4901-b305-1548710d1849" />

5. Edit a couple of the cateogry names according to the World Cover data, complete the saves and Preview.  You will see the COG styled with the labels you have added above.

> Note: the categorues displayed are a sample, so it *is possible* that there may be some pixels in other categories that have not been sampled.  Be aware of this!

#### 3.1.4 Use the JSON editor

You may have noticed the JSON editor options.  There is a JSON editor for the entire config (main interface tab) but also a JSON editor specifically for the layer - a small orange JSON icon on the layer card.

1. First **copy the following** JSON to your clipboard:

```json
    "categories": [
      {
        "color": "#006400",
        "label": "Tree cover",
        "value": 10
      },
      {
        "color": "#ffbb22",
        "label": "Shrubland",
        "value": 20
      },
      {
        "color": "#ffff4c",
        "label": "Grassland",
        "value": 30
      },
      {
        "color": "#f096ff",
        "label": "Cropland",
        "value": 40
      },
      {
        "color": "#ff0000",
        "label": "Built-up",
        "value": 50
      },
      {
        "color": "#b4b4b4",
        "label": "Bare",
        "value": 60
      },
      {
        "color": "#f0f0f0",
        "label": "Snow and ice",
        "value": 70
      },
      {
        "color": "#0064c8",
        "label": "Permanent water bodies",
        "value": 80
      },
      {
        "color": "#0096a0",
        "label": "Herbaceous wetland",
        "value": 90
      },
      {
        "color": "#00cf75",
        "label": "Mangroves",
        "value": 95
      },
      {
        "color": "#fae6a0",
        "label": "Moss and lichen",
        "value": 100
      }
    ]
```
3. In the *Layer Card* view select the **JSON Editor**
4. Scroll down to **find the start of the catgories section**

<img width="905" height="680" alt="image" src="https://github.com/user-attachments/assets/c1183cf6-6eb5-4287-b327-057408dc1502" />

5. Use the arrow to collapse it until you just see `categories [ ]` collapsed
6. Highlight and delete up to the closing square bracket, then paste in the categories above.  Apply changes the preview the layer
   
#### 3.1.5 Copying categories between layers

Now we have a full set up on our COG layer, if you didn't complete the World Cover WMS layer, you can user the copy tool in the UI (not the JSON editor)

1. Edit the *World Cover* layer card
2. Edit *Categories*
3. User *Copy from Layer* to copy from the COG
4. Save and preview

### Did you remember to export?
 
> As we noted earlier, its a good idea to export your config periodically in case you accidentally closed your web browser.  If you haven't now would be a good time

## Part 4 - Working with Time Series data

### 4.1 Key concepts
* The Time Series control allows users to step through temporal data
* Temporal data may have different levels of granularity - hours, days, months, years etc
* We specify how the GE displays the UI via configuration
* They may be a continuous time sequence (i.e. no gaps) or be discontinuous (i.e. jump between periods)
* Some services may have time stamp data in them - e.g. WMS / WMTS services - as an integral part of the service.  However this is not a mandatory requirement of these standards.
* STAC catalogues _should_ have time stamps that may provide metadata for the files (e.g. COGS) that they reference as assets
* Finally we can explicitly define time stamps in our configuration.  These use the Unix time stamp format (integer of seconds since 1/1/1970)

### 4.2 The Temporal Control and a manually defined time stamps

1. Edit the Layer Card for the *AGB* layer you added earlier.  Scroll down to the *Controls* section.  Toggle on **Temporal Control**, then set the dropdownn to **Years**.  Save and exit
2. On the *Datasets* tab, **Edit** the AGB dataset.  The UI *should* now include a timestamp option.  Edit this to set the timestamp according to the time of the data.  Alghough a specific day is required - e.g. `1/1/2025` the config in the UI determines that when it is displayed it will just show `2025`.  Save and return to the Layer tab.
3. We will now add another Year.  For the first *AGB* layer, select the **copy** icon on the dataset row (near the **(i)** icon we used before).  This copies the URL for the current AGB COG
4. Add another dataset via the *Direct Connection* for COG, **pasting in** the first URL, and editing the URL string pattern for the previous year (assuming the data exists).  Save.
5. *Optionally* now look at the JSON config for the layer.  You will see that the datasets JSON includes timestamp fields
6. Preview to view your results

### 4.3 Using STAC timestamps

1. On our current AGB layer, select **Add Dataset -> From Service -> PRR**
2. Find the *AGB* layer assets. Note that they have date stamps **Add all 5 assets** to the layer
3. On the *Layer Card Preview* you should now see 7 Datasets - the two you added manually and the 5 you added from the STAC catalogue.  Delete the two you added manually as these are now duplicates.
4. *Optionally* inspect the JSON.  Although we added these from the STAC catalogue, note that this has simply added in the timestamp records to the JSON - copying them across.  The GE **does not** go to the STAC record at runtime, so if the dates on the STAC records were wrong and were later corrected by the STAC catalogue owner, you would need to update the timestamps here (manually or by adding them in again)

### 4.4 Using WMS / WMTS time stamps

1. **Add a new layer** called *Soil moisture index*, and **set temporal controls** to *Day* granularity
2. Select **Add Dataset** of type WMS and add the following layer URL and layer name

```
https://globalland.vito.be/wmts
```

```
clms_global_swi_1km_v1_daily
```
3. Note the **Use TIME PARAM from service** checkbox.  This appears because we set the tempral controls on the layer.  Leave it toggled on.
4. Save and exit.  For interest, click on the **(i)** icon on the layer.  You will see that the WMS metadata that it displays indicate that this WMS layer *DOES HAVE* time parameters
5. Preview your layer and explore the temporal control.

### 4.5 Adding manual time stamps to WMS / WMTS layers

Some layers may be WMS / WMTS but do not have the time parameter set.  The *World Cover* layer added earlier is one such example.
_NOTE: actually, technically this is not the case.  They DO have TIME PARAMS, but each layer is set up as a separate layer in the WMS, rather than (as per Soil Moisture) having a single layer with the TIME PARAM and argument on that layer.  However for now we can use this as an example_

1. Edit the *World Cover* layer card, toggle **Temporal control**, select **Years**
2. Edit the *World Cover* dataset, **uncheck the TIME PARAM** toggle and explicitly add the time in 
3. Add the second WMS layer for the toehr year and set the time.  Note the URLS are:
*Service*:
```
https://services.terrascope.be/wms/v2
```
*Layers*
```
WORLDCOVER_2020_MAP
```
or
```
WORLDCOVER_2021_MAP
```
### Did you remember to export?
 
> As we noted earlier, its a good idea to export your config periodically in case you accidentally closed your web browser.  If you haven't now would be a good time

## Part 5 - Working with Constraints

### 5.1 Key concepts
* Constraints can be applied to data that is in COG format
* A constraint can be thought of as a fiter applied to the data
* We previously used the **Constraint Toggle** on the layer to allow it to be filtered / constrained on its own data values
* However we can use *"secondary layers"* as constraints too - these might be *land use*, *elevation* or some other metric such as *certainty*, or *distance from* a feature
* These secondary layers **MUST** have the same **CRS**, **resolution** and **origin** as the primary layer that they are applied to
* This may require some specific preparation of *"compatible"* constraint layers 

### 5.2 Constraint types
* We have defined three constraint types in the GE
* *"Continuous"* constraints, where a variable (e.g. elevation) covers a full range of values between its minimum and maximum.  These appear as sliders in the GE UI.
* *"Categorical"* constraints, where the data represents specific values (e.g. 10, 20, 30 ..) that represent some category, such as Land User (10 = "Trees", 20 = "Grassland" etc).  These appear as checkboxes in the UI.
* *"Combined"* or maybe better thought of as *"Named range"* constraints where ranges within a continuous variable are assigned labels, and then treated as a categorical constraint. For example you may have an *uncertainty* COG with valyes from 0 to 100, and you might set up ranges such as "Low" from 0 to 30, "Medium" from 30 to 50, "High" from 50 to 75 and "Very High" above 75.   These are then displayed in the UI as check boxes.
* Ohter examples of the combined constraint might be _altitudinal zones_ for elevation; _direction_ for aspect ("south facing"), _risk level_ for a variable representing another metric (e.g. flood return periods) 

### 5.3 Creating a categorical constraint

1. In the _AGB_ layer card, select the Constraints tab
2. Add the World Cover tif that covers this area
```
https://esa-apex.s3.eu-west-1.amazonaws.com/APEX-example-data/constraints/FCM_Europe_demo_2023_AGB-esa_worldcover_2021.tif
```
3. Select **Populate Categories from COG**
4. Edit the catagory labels to align to the World Cover descriptipns

### 5.4 Adding some continuous constraints

In the interests of time we are now going to just add in a layer that already has a load of constratints set up.

1. Add a new Layer Card for a primary layer, just call it "temp"
2. Copy in the entire JSON below

```json
{
  "name": "Austria Wind Power Density at 100m",
  "isActive": false,
  "data": [
    {
      "url": "https://eox-gtif-public.s3.eu-central-1.amazonaws.com/DHI/PowerDensity_100m_Austria_WGS84_COG_clipped_3857_fix.tif",
      "format": "cog",
      "zIndex": 50
    }
  ],
  "constraints": [
    {
      "url": "https://eox-gtif-public.s3.eu-central-1.amazonaws.com/DHI/Copernicus_DSM_COG_10m_3857_fix.tif",
      "format": "cog",
      "label": "Elevation",
      "type": "continuous",
      "interactive": true,
      "min": 0,
      "max": 4000,
      "units": "meters",
      "bandIndex": 2
    },
    {
      "url": "https://eox-gtif-public.s3.eu-central-1.amazonaws.com/DHI/Copernicus_DSM_COG_10m_3857_fix.tif",
      "format": "cog",
      "label": "Altitudinal zones",
      "type": "combined",
      "interactive": true,
      "units": "meters",
      "constrainTo": [
        {
          "label": "0 to 1000",
          "min": 0,
          "max": 1000
        },
        {
          "label": "1001 to 2000",
          "min": 1001,
          "max": 2000
        },
        {
          "label": "2001 to 3000",
          "min": 2001,
          "max": 3000
        },
        {
          "label": "> 3000",
          "min": 3001,
          "max": 4000
        }
      ],
      "bandIndex": 3
    },
    {
      "url": "https://eox-gtif-public.s3.eu-central-1.amazonaws.com/DHI/Copernicus_10m_DSM_COG_Slope_3857_fix.tif",
      "format": "cog",
      "label": "Slope",
      "type": "continuous",
      "interactive": true,
      "min": 0,
      "max": 65,
      "units": "degrees",
      "bandIndex": 4
    },
    {
      "url": "https://eox-gtif-public.s3.eu-central-1.amazonaws.com/DHI/RuggednessIndex_Austria_3857_COG_fix.tif",
      "format": "cog",
      "label": "Ruggedness Index",
      "type": "continuous",
      "interactive": true,
      "min": 0,
      "max": 1,
      "units": "index values",
      "bandIndex": 5
    },
    {
      "url": "https://eox-gtif-public.s3.eu-central-1.amazonaws.com/DHI/PowerLineHigh_EucDist_Austria_3857_COG_fix.tif",
      "format": "cog",
      "label": "Distance to High Power Line",
      "type": "continuous",
      "interactive": true,
      "min": 0,
      "max": 30000,
      "units": "meters",
      "bandIndex": 6
    },
    {
      "url": "https://eox-gtif-public.s3.eu-central-1.amazonaws.com/DHI/WSF_EucDist_Austria_3857_COG_fix.tif",
      "format": "cog",
      "label": "Distance to settlement (WSF)",
      "type": "continuous",
      "interactive": true,
      "min": 0,
      "max": 5500,
      "units": "meters",
      "bandIndex": 7
    },
    {
      "url": "https://esa-apex.s3.eu-west-1.amazonaws.com/APEX-example-data/constraints/PowerDensity_100m_Austria_WGS84_COG_clipped_3857_fix-esa_worldcover_2021.tif",
      "format": "cog",
      "label": "Land Cover (from World Cover)",
      "type": "categorical",
      "interactive": true,
      "constrainTo": [
        {
          "label": "Tree cover",
          "value": 10
        },
        {
          "label": "Shrubland",
          "value": 20
        },
        {
          "label": "Grassland",
          "value": 30
        },
        {
          "label": "Cropland",
          "value": 40
        },
        {
          "label": "Built-up",
          "value": 50
        },
        {
          "label": "Bare",
          "value": 60
        },
        {
          "label": "Snow and ice",
          "value": 70
        },
        {
          "label": "Permanent water bodies",
          "value": 80
        },
        {
          "label": "Herbaceous wetland",
          "value": 90
        },
        {
          "label": "Moss and lichen",
          "value": 100
        }
      ],
      "bandIndex": 8
    }
  ],
  "meta": {
    "description": "The wind power density (w m 2) is a measure of the available wind resource at 100 meters height. Higher wind power density indicates greater wind power potential.  Constraints allow the data to be filtered by multiple criteria.",
    "attribution": {
      "text": "ESA GTIF",
      "url": "https://gtif.esa.int/"
    },
    "categories": [],
    "units": "w / m 2",
    "colormaps": [
      {
        "min": 0,
        "max": 2000,
        "steps": 50,
        "name": "jet",
        "reverse": false
      }
    ]
  },
  "layout": {
    "interfaceGroup": "Energy",
    "contentLocation": "infoPanel",
    "layerCard": {
      "toggleable": true
    },
    "infoPanel": {
      "legend": {
        "type": "swatch"
      },
      "controls": {
        "opacitySlider": true,
        "zoomToCenter": true,
        "temporalControls": false,
        "constraintSlider": true,
        "blendControls": false
      }
    }
  }
}
```
3. You will now have a layer called *"Austria Wind Power Density"*
4. Lets take a look at its constraints set up in the constraints tab, to understand how others work  

### Did you remember to export? 
> As we noted earlier, its a good idea to export your config periodically in case you accidentally closed your web browser.  If you haven't now would be a good time

## Part 6 - Working with Statistics

> In this section we will just follow along in the workshop

### Did you remember to export?
 
> As we noted earlier, its a good idea to export your config periodically in case you accidentally closed your web browser.  If you haven't now would be a good time

## Part 7 - QA and data validation

> In this section we will just follow along in the workshop

### Did you remember to export?
 
> As we noted earlier, its a good idea to export your config periodically in case you accidentally closed your web browser.  If you haven't now would be a good time
