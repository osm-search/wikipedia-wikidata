Version 3

Version 2 as part of Google Summer of Code 2019 was full refactor of the processing
script and added many more languages and wikidata. The output works sufficiently but
the execution was never automated, e.g. run monthly or quarterly.

The main indentified drawbacks are:
- It requires too much resources, the disc space alone 1TB
- The database import is slow, no amount of optimization, e.g. unlogged tables or
   configuration parameters helped.
- Not easy to run for one country
- The project's hardware was a very powerful server with lots of CPU cores, RAM and
   fast NVMe drives
- No logging
- Many hardcoded file paths

Version 3 starts with a couple of new approaches
- Split download, processing and importing into separate scripts
- use a working directory with downloaded/<language>, converted/<language>/ subdirectories
- Avoid database import and instead use CSV as much as possible
- Filter (remove CSV rows and columns) input database as soon as
   possible.
- Avoid reading full files (sometimes several gigabyte) into memory
- Keep data compressed on disk (higher CPU usage but less disc usage). Goal to stay
   below 100GB.

The downloaded data is 35GB compressed and slowly growing. English wikipedia alone
about 10GB. It's a massive dataset. Even counting number of rows in the files takes
minutes.

Wikipedia titles are messy. There are Wikipedia article title that consist of only
emojis, or a single comma.

We don't know which Wikipedia articles are relevant for Nominatim. Any title could
represent a place name. We could try using wikidata processing first to filter
articles by wikidata id earlier.

Last work was done at a hackweekend September 2021. Current "roadblock" is that
some remote queries in download_wikidata.sh (near "Querying for place type $F")
time out after 60 seconds. That seems to be a server-side limit and the queries
have to be rewritten somehow.

The CSV approach has been a good improvement for filtering and merging files. It's
not clear yet if it's a better approach when calculating the actual scores because
a database is much more efficient joining multiple tables. Maybe the much reduced
data sizes make it possible to try a hybrid approach.

I have some basic test files for the scripts in bin/ Those bin/ scripts could also
be put into a single python library with proper test framework.

csvcut adds a 20x overhead. It could be possible to write a custom script instead
focussing only on the features we need or further optimization.
