# VirtualTourist
User can drop a pin on a map view and then see associated pictures to that location that other users have uploaded to Flickr. Persistence using Core Data.

This app allows users specify travel locations around the world, and create virtual photo albums for each location. The locations and photo albums will be stored in Core Data.

The app will have two view controller scenes.

1) Travel Locations Map View: Allows the user to drop pins around the world

2) Photo Album View: Allows the users to download and edit an album for a location

The scenes are described in detail below.

##Works On
Devices running iOS 8.0 or higher.

##Usage

###Travel Locations Map

When the app first starts it will open to the map view. Users will be able to zoom and scroll around the map using standard pinch and drag gestures.

The center of the map and the zoom level is persistent. If the app is turned off, the map returns to the same state when it is turned on again.

Tapping and holding the map drops a new pin. Users can place any number of pins on the map.

When a pin is tapped, the app will navigate to the Photo Album view associated with the pin.

###Photo Album

If the user taps a pin that does not yet have a photo album, the app will download Flickr images associated with the latitude and longitude of the pin.

If no images are found a “No Images” label will be displayed.

If there are images, then they will be displayed in a collection view.

While the images are downloading, the photo album is in a temporary “downloading” state in which the New Collection button is disabled. The app determines how many images are available for the pin location, and display a placeholder image for each.

Once the images have all been downloaded, the app enables the New Collection button at the bottom of the page. Tapping this button empties the photo album and fetch a new set of images. Note that in locations that have a fairly static set of Flickr images, “new” images might overlap with previous collections of images.

Users can remove photos from an album by tapping them. Pictures will flow up to fill the space vacated by the removed photo.

All changes to the photo album are automatically made persistent.

Tapping the back button returns the user to the Map view.

If the user selects a pin that already has a photo album then the Photo Album view displays the album and the New Collection button is enabled.

## Contributing
1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Credits
Jacqueline Sloves

## Contact
e-mail: coderjac@gmail.com

linkedin: https://www.linkedin.com/in/jacquelinesloves
