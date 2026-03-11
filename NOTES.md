From my earlier exploration, the axis domain calculations are in two files under scale:

linear.dart — LinearScaleConv constructor (numeric axes)

The key logic (around line 45–65):

Scans all tuples for min/max
Applies a 10% margin on each side: marginMin = range * (spec.marginMin ?? 0.1)
Optionally applies linearNiceRange() if niceRange: true
Then computes ticks via linearNiceNumbers() (Wilkinson Extended algorithm, in util/nice_numbers.dart)
time.dart — TimeScaleConv constructor (DateTime axes)

Same pattern but in microseconds — same 10% margin via Duration arithmetic. No nice range applied (the comment says "This time scale will not apply nice numbers and range").

Supporting utilities:

util/nice_numbers.dart — linearNiceNumbers(): Wilkinson Extended algorithm that picks aesthetically pleasing tick values; the first and last tick define the rendered axis extent
util/nice_range.dart — linearNiceRange(): d3-inspired range snapping, only used when LinearScale(niceRange: true) is set
So the axis domain that ends up painted is [ticks.first, ticks.last] for numeric axes (from linearNiceNumbers) and [min, max] with 10% margins for DateTime axes. That's exactly what our _domainX now replicates.