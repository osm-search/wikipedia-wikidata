# Add Wikipedia and Wikidata to Nominatim

## Summary

This project creates an export of Wikipedia articles (title, latitude, longitude) and an calculated importance score (0..1) for each.

The score can be used to approximate how important a place name is relative to another by the same name.

Examples:

   * "Berlin" (capital of Germany, [Wikipedia](https://en.wikipedia.org/wiki/Berlin), [OpenStreetMap](https://www.openstreetmap.org/relation/62422))
vs "Berlin" (town in Maryland, USA, [Wikipedia](https://en.wikipedia.org/wiki/en:Berlin,%20Maryland), [OpenStreetMap](https://www.openstreetmap.org/relation/133689)). 
   * "Eiffel Tower" (Paris, France, [Wikipedia](https://en.wikipedia.org/wiki/Eiffel_Tower), [OpenStreetMap](https://www.openstreetmap.org/way/5013364)) vs "Eiffel Tower" (Paris, Tennessee, United States, [Wikipedia](https://en.wikipedia.org/wiki/Eiffel_Tower_(Paris,_Tennessee)), [OpenStreetMap](https://www.openstreetmap.org/way/1080841041)).
   * 50 places called "Springfield" in the United States
   * 35 places called "Washington" in the United States

[Nominatim](https://nominatim.org/) geocoding engine can import the files and improve its ranking of
place search results. During searches Nominatim combines importance score with other ranking factors like place type
(city vs county vs village), proximity (e.g. current map view position), phrase relevance (how many words
in the results match the search terms).

Wikipedia publishes [dumps](https://meta.wikimedia.org/wiki/Data_dumps) of their databases once per month.

To run one build you need 420GB of disc space (of which 360GB Postgresql database). The scripts process
39 languages and output 4 files. Runtime is approximately 14 hours on a 4 core, 4GB RAM machine with SSD
discs.

```
334M wikimedia_importance.csv.gz # the primary file
303M wikipedia_importance.sql.gz
216M wikipedia_article.csv.gz
 88M  wikipedia_redirect.csv.gz
```


## History of this project

Nominatim 2.2 introduced the first `utils/importWikipedia.php` using [mwdumper](https://github.com/bcollier/mwdumper/),
then parsing HTML pages to find geo coordindates in articles. It was a single script without documentation on runtime
and ran irregular (less than once per year). Output was binary SQL database dumps.

During several months of [Google Summer of Code](https://en.wikipedia.org/wiki/Google_Summer_of_Code) 2019, [tchaddad](https://www.openstreetmap.org/user/tchaddad) rewrote the script, added wikidata processing, documentation and merged files into a new `wikimedia-importance.sql.gz` export. You can read her reports on [her diary posts](https://www.openstreetmap.org/user/tchaddad/diary).

Nominatim 3.5 switched to using the new `wikimedia-importance.sql.gz` file and improved its ranking algorithm.

Later the project was moved into its own git repository. In small steps the process was split into steps for downloading,
converting, processing, creating output. `mysql2pgsql` was replaced with `mysqldump`, which allowed filtering in scripts.
Performance was improved by loading only required data into the database. Some caching (don't redownload files) and
retries (wikidata API being unreliable) was added.


## Output data

`wikimedia_importance.csv.gz` contains about 17 million rows. Number of lines grew 2% between 2022 and 2023. The file
is sorted.

|   Column    |       Type       |
| ----------- | ---------------- |
| language    | text             |
| title       | text             |
| importance  | double precision |
| wikidata_id | text             |

All columns are filled with values.

Combination of language+title are unique.

Importance is between 0.0000000001 (never 0) and 1.

Currently 39 languages, English has by far the largest share.

|  language      |  count           |
| -------------- | ---------------- |
| en (English)   | 3,337,994 (19%)  |
| de (German)    |   966,820 (6%)   |
| fr (French)    |   935,817 (5%)   |
| sv (Swdish)    |   906,813        |
| uk (Ukranian)  |   900,548        |
| ...            |                  |
| bg (Bulgarian) |    88,993        |
 
Examples of `wikimedia_importance.csv.gz` rows:

* Wikipedia contains redirects, so a single wikidata object can have multiple titles even though. Each title has the same importance score. Redirects to non-existing articles are removed.

    ```
    en,Brandenburger_gate,0.5521887760090184,Q82425
    en,Brandenburger_Gate,0.5521887760090184,Q82425
    en,Brandenburger_Tor,0.5521887760090184,Q82425
    en,Brandenburg_gate,0.5521887760090184,Q82425
    en,Brandenburg_Gate,0.5521887760090184,Q82425
    en,BRANDENBURG_GATE,0.5521887760090184,Q82425
    en,Brandenburg_Gates,0.5521887760090184,Q82425
    en,Brandenburg_Tor,0.5521887760090184,Q82425
    ```

* Wikipedia titles contain underscores instead of space, e.g. [Alford,_Massachusetts](https://en.wikipedia.org/wiki/Alford,_Massachusetts)

    ```
    en,"Alford,_ma",0.3659818647022956,Q2431901
    en,"Alford,_MA",0.3659818647022956,Q2431901
    en,"Alford,_Mass",0.3659818647022956,Q2431901
    en,"Alford,_Massachusetts",0.3659818647022956,Q2431901
    ```

* The highest score article is the [United States](https://en.wikipedia.org/wiki/United_States) 

    ```
    pl,Stany_Zjednoczone,1,Q30
    en,United_States,1,Q30
    ru,Соединённые_Штаты_Америки,1,Q30
    hu,Amerikai_Egyesült_Államok,1,Q30
    it,Stati_Uniti_d'America,1,Q30
    de,Vereinigte_Staaten,1,Q30
    ...
    ```

## How importance scores are calculated

Wikipedia articles with more links to them from other articles ("pagelinks") plus from other languages ("langlinks") receive a higher score.

1. The Wikipedia dump file `${language}pagelinks` contains how many links each Wikipedia article
   has **from** other Wikipedia articles of the same language. We store that as `langcount` for
   each article.

   The dump has the columns
   
      ```sql
      CREATE TABLE `pagelinks` (
        `pl_from`            int(8) unsigned    NOT NULL DEFAULT 0,
        `pl_namespace`       int(11)            NOT NULL DEFAULT 0,
        `pl_title`           varbinary(255)     NOT NULL DEFAULT '',
        `pl_from_namespace`  int(11)            NOT NULL DEFAULT 0,
      ```

   After filtering namespaces (0 = articles) we only have to look at the `pl_title` column
   and count now often each title occurs. For example `Eiffel_Tower` 2862 times (*).
   We store that as `langcount` for each article.
   
   *) `zgrep -c -e'^Eiffel_Tower$' converted/wikipedia/en/pagelinks.csv.gz`

2. The dump file `${language}langlinks` contains how many links each Wikipedia article has **to**
   other languages. Such a link doesn't count as 1 but as number of `${language}pagelinks`.

   The dump has the columns

      ```sql
      CREATE TABLE `langlinks` (
        `ll_from`         int(8) unsigned   NOT NULL DEFAULT 0,
        `ll_lang`         varbinary(35)     NOT NULL DEFAULT '',
        `ll_title`        varbinary(255)    NOT NULL DEFAULT '',
      ```

   For example the row `"9232,fr,Tour Eiffel"` in `enlanglinks` file means the
   [English article](https://en.wikipedia.org/wiki/Eiffel_Tower) has a link to the
   [French article](https://fr.wikipedia.org/wiki/Tour_Eiffel) (*).
   
   When processing the English language we need to inspect and calculate the sum of
   the `langlinks` files of all other languages. We store that as `othercount` for
   each article.
   
   For example the French article gets 2862 links from the English article (plus more
   from the other languages).

   *) The `langlink` files have no underscores in the title while other files do.

3. `langcount` and `othercount` together are `totalcount`.

4. We check which article has the highest (maximum) count of links to it. Currently that's
   "United States" with a `totalcount` of 5,198,249. All other articles are scored on a
   logarithmic scale accordingly.
   
   For example an article with half (2,599,124) the links to it gets a score of 0.952664935, an
   article with 10% (519,825) the links get a score of 0.85109869, an article with 1% a score of
   0.7021967.

   ```sql
      SET importance = GREATEST(
                          LOG(totalcount)
                          /
                          LOG((
                            SELECT MAX(totalcount)
                            FROM wikipedia_article_full
                            WHERE wd_page_title IS NOT NULL
                          )),
                          0.0000000001
                       )
    ```





## How Nominatim uses the files

(As of Nominatim 4.2)

During [Nominatim installation](https://nominatim.org/release-docs/latest/admin/Import/#wikipediawikidata-rankings
)
it will check if a wikipedia-importance file is present and automatically import it into the
database tables `wikpedia_article` and `wikipedia_redirect`. There is also a `nominatim refresh`
command to update the tables later.

OpenStreetMap contributors frequently tag items with links to Wikipedia
([documentation](https://wiki.openstreetmap.org/wiki/Key:wikipedia))
and Wikidata ([documentation](https://wiki.openstreetmap.org/wiki/Key:wikidata)). For example
[Newcastle upon Tyne](https://www.openstreetmap.org/relation/142282) has the tags

| tag           | value                           |
| ------------- | ------------------------------- |
| admin_level   | 8                               |
| boundary      | administrative                  |
| name          | Newcastle upon Tyne             |
| type          | boundary                        |
| website       | https://www.newcastle.gov.uk/   |
| wikidata      | Q1425428                        |
| wikipedia     | en:Newcastle upon Tyne          |

When Nominatim indexes places it checks if they have an wikipedia or wikidata tag. If they do
they set the `importance` value in the `placex` table for that place. This happens in
`compute_importance` in `lib-sql/functions/importance.sql` (called from methods in
`lib-sql/functions/placex_triggers.sql`. This is also were default values are set
(when a place has neither).

During a search Nominatim will inspect the `importance` value of a place and use that as
one of the ranking (sorting) factors.

See also [Nominatim importance documentation](https://nominatim.org/release-docs/latest/customize/Importance/).


## Steps of the build

Have a look at `complete_run.sh` as entry point to the code. You will require a local Postgresql database. Edit
the `languages.txt` file to only run a small language (e.g. Bulgarian) first.

1. latest\_available\_data

   Prints a date. Wikipedia exports take many days, then mirrors are sometimes slow copying them. It's not
uncommon for an export starting Jan/1st to only be full ready Jan/20th.

2. wikipedia_download (1h)

   Downloads 40GB compressed files. 4 files per language. English is 10GB.

3. wikidata\_download (0:15h)

   Another 4 files, 5GB.

4. wikidata_api\_fetch\_placetypes (0:15h)

   Runs 300 SPARQL queries against wikidata servers. Output is 5GB.

5. wikipedia_sql2csv (5h)
   
   The MySQL SQL files get parsed sequentially and we try to exclude as much data (rows,
   columns) as possible. Output is 75% smaller than input. Any work done here cuts
   down the time (and space) needed in the database (database used to be 1TB before
   this step).
  
   Command-line tools are great for processing sequential data but piping data through 4
   tools could be replaced by a single custom script later.
   
   Most time is spend on the Pagelinks table
  
   ```
   [language en] Page table      (0:22h)
   [language en] Pagelinks table (3:00h)
   [language en] langlinks table (0:05h)
   [language en] redirect table  (0:02h)
   ```

6. wikidata_sql2csv (1h)

   ```
	geo_tags          (0:02h)
	page              (0:40h)
	wb_items_per_site (0:20h)
   ```

7. wikipedia\_import, wikidata\_import (0:40h)

   Given the number of rows a pretty efficient loading of data into Postgresql.

   English database tables

   ```
   enpage             |  17,211,555 rows | 946 MB
   enpagelinkcount    |  27,792,966 rows | 2164 MB
   enpagelinks        | 846,265,838 rows | 42 GB
   enredirect         |  10,804,606 rows | 599 MB
   ```

8. wikipedia\_process, wikidata\_process (5:00h)

   Postgresql is great joining large datasets together, especially if not all
   data fits into RAM.

   ```
   Process language tables and associated pagelink counts (1:00h)
   set counts                                             (1:00h)
   add underscores to langlinks.ll_title                  (0:20h)
   set othercounts                                        (2:30h)
   Create and fill wikipedia_article_full                 (0.03h)
   Create derived tables                                  (0.03h)
   Process language pages                                 (0.03h)
   Add wikidata to wikipedia_article_full table           (0.04h)
   Calculate importance score for each wikipedia page     (0.08h)
   ```
   
9. output (0:15h)
   
   Uses `pg_dump` tool to create SQL files. Uses SQL `COPY` command to create CSV files.


License
-------
The source code is available under a GPLv2 license.
