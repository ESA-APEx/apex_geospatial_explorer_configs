# Geospatial Explorer Config Builder Workshop

## Part 1 - mastering the basics
## key concepts
it’s all JSON
JSON is complicated
Config builder allows people to author configs without knowing json or having to understand the schema
It’s all happening in your web browser
There is no back end or persistent storage at present
Exporting = saving
We have embedded a runtime GE into the builder, multiple versions in fact!
The UI separates out some of the basic stuff from the more technical to allow collaboration on building by people with different levels of expertise
It’s designed to support a very iterative process
It is a WIP. We’d welcome your feedback and ideas

### getting started

### my first layer
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
