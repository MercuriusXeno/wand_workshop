Workshop 3.0 - Other Stuff Edition

CHANGES
=======
3.0 IS NOT COMPATIBLE WITH SAVES USING 2.5 OR EARLIER.
DO NOT USE BOTH MODS AT ONCE.

FEATURES
========

* Wand merging, simplified:
1. Put the wand you want to keep on the floating altar.
2. Put wands you're sacrificing on the big altar below it. 
3. Pick up the wand you want to keep, now enhanced.

FLASK MERGING
=============
Place a flask on the altar and then offer the rest of the recipe.

Any Flask <- Any Empty Flask = Kept Flask with combined capacity
Any Flask <- 1000 Ambrosia Flask = Kept Flask with "Tempered", becoming unbreakable.
Any Flask <- 1000 Oil Flask = Kept Flask with "Inert", decreases reactivity within.
Any Flask <- 1000 Toxic Sludge = Kept Flask with "Reactive", increases reactivity within. (Cancels out inert)
Any Flask <- 1000 Teleportatium Flask = Kept Flask with "Remote", the mouth of the flask is also the mouse cursor.

(I may expand upon this list, if I get the urge. This felt like a good place to stop and test.)

WAND MERGING
============
1. Spread, cast delay and reload are set to the lowest among all wands.
2. Capacity is set to the highest among all wands.  
3. Shuffle and spells cast are left alone. The kept wand determines these.
4. Mana regen and capacity use an iterative formula:
  Sort list, take worst (w) and next worst (n) wand stat (including formula results)
  result = n + (w/n)^0.5 * w (REPEAT UNTIL LIST EMPTY)

CREDITS
=======
I didn't come up with the workshop concept originally. You can find the original versions still:
1.0 by Megacrafter127
2.0 by Gladious
2.5 is by me, but don't use it. It's a mess.