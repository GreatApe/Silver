- What tools/libraries have you included in the project and why?
  I used TCA, as specified in the assignment, and this is also my goto option for any more complex project,
  especially when working with many other contributors. For this assignment, if it were a standalone app,
  it would probably be overkill, but I built it as if it were part of a larger project.

  Within the TCA ecosystem, I used Dependencies for an APIClient and Sharing to store the favorites. The latter is
  a nice option because it lets us combine the image information downloaded from the API, with a list of favorited IDs,
  and the library will manage view updates for us. If we later want to drive other changes from the favorites list, it
  also has a publisher, so we could do all the favorite work in the Reducer if we wanted to.

  Another nice aspect is that we can trivially begin to persist the favorites if we ever want to.
  
- What would you improve if you had more time?
  Persist the favourites. Manually download the image data, so we could be more explicit when we fail to download a
  particular image. We can be much more granular than I was in this case, but if we want full control we'd want to
  use the APIRequest I prepared.

  Caching the images would be nice, since AsyncImage doesn't always seem to do a good job of that.

  Store the image info in a database using the new GRDB option for the Sharing library, if there are a lot of images
  and we want to perform advanced searches we can use the upcoming [query builder](https://www.pointfree.co/episodes/ep314-sql-builders-sneak-peek-part-1), which seems awesome.

  Since we have the image thumbnail already, we could scale it up and blur it, and show while we are loading the real image.

  Nicer graphics, animations.

- What would you like to highlight in the code?
  Generally speaking the code is quite neat, pretty close to a real life project in style, I am pretty happy with it. I like
  the APIRequest concept, which also contains the response type.

  Using Shared only for the favorited ids, and combining it with the other data only in the view, is nice I think, since it
  means we don't have to manually go in an update some model list (in this case essentially an array of arrays. Plus we get
  SwiftUI redrawing for free.

  I like the APIClient in general, pretty neat and tidy.
  
- How would you add persistence to the app, given the API constraints and the required functionality?
  First thing is to change the `@Shared` key for `favorites` to use `AppStorage` or some custom strategy, could even be remote.

  Then cache the images themselves, perhaps by switching to KingFisher, or even do it manually, keyed by URL, but then
  we'd probably need to also deal with removing them after a while.

  Store the image details in Shared using GRDB, or using SwiftData

  If there were advanced search filers and similar, that could also be persisted using Shared.
