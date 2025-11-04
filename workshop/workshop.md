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

#### 1.2.2 Exporting and reloading config

**Remember** there is no "saving" of config - simply exporting and importing

1. On the *home* tab select **Export -> Quick Export**.  This will download to your local machine as a file called **config.json**
2. Now select **New Config**.  You will see that your previous changes have been lost
3. Now select **Load Config**.  You will see your previous config has been reinstated.

> As you continue through this workshop **remember to export your config** frequently, in case you accidentally close your browser tab.  You can then reinstate it from your local machine

As you download on multiple occasions your operating system will be treating each file as a copy and may rename them - e.g. *config (1).json*,  *config (2).json* etc

### 1.2.3 Creating your first layer card

A layer card is a user interface element into which we add content such as descriptions, data, statistics, constraints. 

1. On the *layers* tab select your *Forest Carbon* interface group and select **+ Add Layer**
2. Leave the **default settings** for Layer Type and Layout style
3. Type *Above Ground Biomass* into the **Layer Name** field
4. Enter in a suitable **Description** that will describe the layer.
5. Add *Forest Carbon* into the **Attribution text**.  Add an **Attribution URL** to the Forest Carbon website if you want.
6. Select **Create Layer Card**

### 1.2.4 Add some data to your layer card

1. 




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
