# Geospatial Explorer Config Builder Workshop

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

1. **Open the configuration builder** by going to the following URL: https://apex-ge-config-builder.sparkgeo.uk/
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

 ### Did you remember to export?
 
 As we noted earlier, its a good idea to export your config periodically in case you accidentally closed your web browser.  If you haven't now would be a good dime

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

> Have you exported recently?

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
3. Select the toggle on the UI to **Use data values**.  An additional column will appear.
4. Use the UI to change the *colour to* **green**, label to **tree** and value to 10
5. Repeat with a couple of further categories for world cover.  You can use the image below on this page and the colour picker tool to help

<img width="411" height="337" alt="image" src="https://github.com/user-attachments/assets/5586db3b-14a0-4174-b857-b55930acd083" />

6. Continue for as much patience as you have.  If you did them all, the legend when you render it will end up looking like this:

<img width="1072" height="550" alt="image" src="https://github.com/user-attachments/assets/b2782351-3ebf-4806-883e-2d937318e5be" />

#### 3.1.3 Using categories with a COG

We can use the same categories for a COG version

1. Create a new **Layer Card** called *World Cover COG*
2. **Add the following dataset** for a World Cover COG of Austria:
```
https://esa-apex.s3.eu-west-1.amazonaws.com/APEX-example-data/constraints/PowerDensity_100m_Austria_WGS84_COG_clipped_3857_fix-esa_worldcover_2021.tif
```
3.  In the **Layer Card** editor, select **Add Categories** then **Copy from** and use the layer from 3.1.2
4.  Now view the layer and you will see it rendered according to those categories

#### 3.1.4 Popuating from the COG

An alternative approach is populating the categories from the COG.  You would still need to define colours and labels (unless the COG contains colour hints)

1. **Duplicate** the layer you set up in 3.1.3, using the **Copy layer** icon on the layer card
2. **Delete the existing categories**
3. Go to thew **(i)** icon on the dataset, to get to the COG metadata
4. Select **Populate categories**
5. You could complete the editing here


     



 



Rename interface group Biomass and preview
Add a layer called AGB
Fill out description, attribution etc
Add a cog directly
Preview (all white)
COG metadata copy max and min
Add colour map
Preview

### export and import
Quick export
New
Load config

### Tweak some controls - constraints and download

On cog data select copy url
Edit, toggle download and paste url
Toggle constraints
Preview
Don’t forget to export

### add some base maps

Add recommended
Add opentopomap directly

### Add a web map service

Add a layer for world cover
Copy in the WMS layer url and name
View the metadata on the data page
Preview (no legend)
Don’t forget to export

## working with services

### adding a STAC catalogue
Add the PRR STAC catalogue
Add a layer for world soils
Find and add the Cog
Copy min, max and style it

### adding in recommended services
Add all recommended services

### adding in WMS from a service
Add a layer called temp
Add a WMS layer that you find interesting
Now edit the layer card with some more meaningful names

## legends
See if your WMS supported get legend graphic
If not add a legend from a url
Create a temporary legend image on GitHub resource and add it here


## multiple data sources in a group
Add a Portugal LCM layer
Find land cover map in Portugal ldn on PRR
Add the layers in bulk

## categorical data
### setting categories
Populate categories from COG
Edit labels and use color picker
Make a nice category

### copying categories
Copy the categories to world cover for use as a legend

## copying layer definitions
Copy the Portugal ldn
Rename it Uganda
Remove all the data and replace

## basic QA
Bulk attribution
Legend check

## go off piste
20 mins play time

# Part 2 - time series

# key concepts
Some services have time parameters
We can add timestamps to data in config
These can be used for files such as cogs, or services such as WMS
Config timestamps use unix format
Seconds sine 1/1/1970
The temporal control determines the granularity of the UI

# adding a WMS that supports timestamps

Add a new layer for soil moisture
Make sure temporal control is on and set to days
Add the WMS
Check its time parameter
If all good, preview it

# adding time stamps manually
Edit our world soils config to be temporal
Edit the data and add the timestamp
Add the other time period

# timestamps on WMS
Repeat what you did on cogs for world cover

# bulk timestamps
Edit the Portugal lcm to be a year timestamp
Remove all
Add all for one time period
Add all for the next

# go off piste

Part 3 - constraint layers
# concepts
we saw earlier how the constraints toggle … a filter button … was used to filter the layer’s own data
we can use multiple secondary layers to filter the primary layer too
These layers can represent variables such as elevation or categories such as land use
Constraint layers have to have the same CRS, resolution and origin as the primary layer. Effectively under the bonnet we treat them as different bands of a multi band raster
A set of “compatible” constraint layers may therefore need to be built to work with the primary layer
We have identified some use cases where constraints are fixed, without user control and others where the user is in control

# adding a layer we will constrain
add the GTIF layer for power
Style it with a colour map between values x and y
Add constraint toggle for its own data
Preview

# now add the elevation constraint
Add a interactive constraint for elevation
Preview

# now add a fixed constraint
Add distance to grid between 0 and something

# now add an interactive


Part 4 - statistics
