# DexOS Development & Technical Decisions

This project is a working Pokedex app. You are provided with a grid of Pokemon and a retro LCD screen.

- Clicking on a Pokemon makes it pop up on the screen. The arrows will let you transition the LCD screen to different pages.
- Each page has more detailed information about the Pokemon. There are 3 pages in total.
- There is an initial page with name and sprite, a second page with type, height, weight and a third page with battle statistics and a bar chart illustration of said statistics.
- There's a search bar so you can search for specific Pokemon that you want. For reasons discussed in ##Miscellaneous Thoughts, this is a fairly limited search bar for now; it only searches from within the Pokemon loaded in already on client side due to our pagination.
- This project uses the PokeAPI to fetch all the relevant information about each Pokemon, incluing sprites, name, type and battle statistics.
- The UI is meant to emulate a retro aesthetic. I've added scanlines to the LCD, as well as darkened the centre of the screen with a vignette to give that sort of 'burned in' screen effect. I think it also frames the sprites in a good way! 
- Pressing the Pokemon in the grid has haptic feedback.

Below is a breakdown of the app’s functionality, architectural choices, and how each milestone was implemented. I have structured this to roughly follow some general milestones for structure, and explain how each individual milestone was implemented

---

## Milestone 1: MVP & Grid Implementation

**Requirement:**  
Display a grid of Pokémon that updates a top center detail view when tapped.

### Grid Implementation
- Implemented using `LazyVGrid` in `PokemonDataGrid.swift`
- A lazy container was chosen for performance reasons:
  - Only renders `PokemonChip` views currently on screen
  - Keeps memory usage low as the dataset grows

### Top Center View
- The `LCDScreenView` serves as the detail display
- A `selectedPokemon` state variable is stored in `ContentView`
- When a `PokemonChip` is tapped:
  - `selectedPokemon` updates
  - SwiftUI re-renders `LCDScreenView` with the new data

This keeps the interaction simple while maintaining a clear separation of responsibilities.

---

## Milestone 2: Pagination

**Requirement:**  
Load Pokémon in batches of 20 and fetch additional data as the user scrolls.

### Networking Logic
- Implemented in `PokedexViewModel.swift`
- The `fetchPokemon()` function:
  - Requests a batch of Pokémon
  - Stores the `nextURL` returned by the PokeAPI for subsequent requests

### Triggering Pagination
- Each `PokemonChip` inside the `LazyVGrid` uses an `onAppear` modifier
- When the last rendered Pokémon appears:
  - The ViewModel checks if more data is available
  - A new request is triggered using `nextURL`

### Optimization Safeguards
- `hasMorePages` prevents unnecessary requests when the API is exhausted
- `isLoading` prevents double-fetching during rapid scrolling or slow networks

---

## Milestone 3: Image Caching

**Requirement:**  
Prevent redundant downloads of Pokémon sprites.

I decided to use a two tier caching system. This approach is likely a little overkill for this usecase, but there are a few reasons I used it:
- The idea of a two tier cache system here is just to make sure scrolling stays smooth using memory, while still ensuring that data is persistent so that we aren't unnecessarily redownloading assets. 
- The size of these assets is small enough to where the memory it takes up will be trivial on modern devices.
- In the instance where memory is an issue, or the user is using an older device (Like me, I use an iPhone X!) I did add some cost limits to prevent excessive memory usage
- While PokeAPI is free, the documentation clearly states an IP ban punishment if data is not cached in this manner to prevent superfluous network requests, given their API is both free and very popular.

#### Memory Cache (NSCache)
- Stores images in RAM for immediate reuse
- Configured with a `totalCostLimit` of 100MB
- Prevents the app from being terminated due to excessive memory usage

#### Disk Cache (FileManager)
- Images are saved to the user’s Caches directory after download
- Ensures sprites persist across app launches
- Eliminates repeat network calls for previously seen Pokémon

### Some tradeoffs with this approach
- Disk read/write logic is handled manually
- While `URLCache` is a built in option, `NSCache` provides:
  - Explicit cost control
  - Predictable memory behavior

---
## Extra Credit

I have mentioned all this stuff throughout the document, but thought it would be useful to put in one place the features added that were not necessarily outlined in any milestone.

### 1. Multi-Page LCD Interface
- **Page 1 (Identity):** High resolution sprite with a blinking terminal cursor.  
- **Page 2 (Bio):** Displays ID, Type badges, Height, and Weight.  
- **Page 3 (Battle Stats):** Visualizes base stats using a custom bar chart.

### 2. Retro Rendering (More detail in visual effects section) :
- **Scanline Overlay:** Custom `Path` draws horizontal lines every 4 pixels to simulate old display refresh.  
- **Segmented Stat Bars:** `StatSegmentBar` renders 15 discrete blocks instead of smooth bars.  
- **Monochromatic Logic:** UI uses strict green/black palette with vignette effect to simulate screen depth and burn-in.  
- **Interpolation Control:** Disabled anti-aliasing on images with `.interpolation(.none)` to preserve pixel art.

### 3. Tactical Haptics
- Integrated `UIImpactFeedbackGenerator` for light pulses on interactions like:
  - Tapping a chip
  - Paging the LCD
  - Searching
- Bridges the gap between a glass touchscreen and simulated physical buttons.

### 4. Search & Filtering
- `PokemonSearchBar` filters the loaded list in real time.  
- Styled as an extension of the LCD interface to match the aesthetic.  


## Miscellaneous Technical Issues

### LCD Readability & Scaling

**Text Readability**
- Early iterations of this app suffered from small, unclear text. I still think the LCD a bit too small, but it is readable.
- Resolved by:
  - Using monospaced system fonts
  - Applying `.black` font weights
  - Increasing label sizes for IDs and measurements

**Stat Normalization**
- I had an issue with making the stat bars actually meaningful visually to the user for each Pokemon.
- The theoretical stats range is far greater than where most Pokemon actually land.
- PokeAPI stats range from 0–255
- On a raw scale, average stats (~70) appear nearly empty
- Visual bars are normalized against 160
  - Makes stat comparisons more meaningful
  - High outliers such as Blissey's' HP simply cap the bar, so it still works fine. 


---

## Visual Effects & Rendering

### Scanlines
- To exemplify the retro feel of my screen, I added scanlines.
- Implemented using a `Path` inside a `GeometryReader`
- Draws horizontal lines every 4 pixels
- Achieves a retro LCD effect without large PNG overlays
- Keeps binary size small

### Segmented Stat Bars

- Custom `StatSegmentBar` composed of 15 individual rectangles
- Mimics the discrete segments of a physical LCD
- Avoids modern smooth progress animations
- This does have the issue of obfuscating minor differences in stats in the bar representation (e.g 54 vs 58 the bar looks the same.)
- For such minor differences, it doesn't really matter, however this approach isn't ideal and could use some work
### Image Interpolation
- All sprites use `.interpolation(.none)`
- Prevents anti-aliasing when scaling pixel art
- Preserves crisp sprite edges on the LCD screen

---

## Code Structure

### Architecture
- MVVM pattern
  - Views remain lightweight and declarative
  - Business logic resides in `PokedexViewModel`
  - I will say that my LCDScreenView file is a little bloated. The idea to have multiple screens showing all sorts of information about the Pokemon was a bit of a late addition; a lot of this stuff could be refactored into different files to follow best practices a little better. 

### Service Layer
- `PokemonService.swift` handles all `URLSession` networking
- URLSession is configured with `requestCachePolicy = .returnCacheDataElseLoad`
- Acts as a third layer of caching beneath memory and disk

---

## Miscellaneous Thoughts 

There are certainly things I am unhappy with and would change with more time.

For instance, the arrows to switch between different screens of the LCD are not retro at all. They do not have an 8 bit effect.
In a similar vein, the app outside the LCD screen display section lacks that "retro" gameboy feel. That's not to say that it is bad looking. However the text being crisp and HD actually takes away from the aesthetic a little when it is supposed to emulate a retro vibe
The search bar is not ideal. Since I was doing client side filtering of search results, it only searches through the Pokemon you've actually loaded in. This is fixed by just loading in all of them; the data is so small that this is fairly trivial on most modern devices for this use case at least. As far as I can tell, there is no way to do a search server-side with the PokeAPI.
LCDScreenView needs to be broken up into multiple files for readability and to reduce bloat. I initially kept it all in the same file because it was the same component, however it has so many moving parts at this point that they should be refactored into their own files. 
All of these are changes I'd make for a more long term version of this project. For MVP I'd say this is a good start 
