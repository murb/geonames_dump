# GeonamesDump

GeonamesDump import geographic data from geonames project into your
application, avoiding to use external service like google maps.  It's a "gem"
version of the
application [brownbeagle/geonames](https://github.com/brownbeagle/geonames).
Now you only need to include the dependency into your Gemfile and your project
will include geonames.

You're free to use [geocoder](https://github.com/alexreisner/geocoder) or
[geokit](https://github.com/imajes/geokit) or any other geocoding solution.

## Installation

Add this line to your application's Gemfile:

```
gem "geonames_dump", git: "https://github.com/murb/geonames_dump.git", branch: "develop", require: "Geonames"
```

And then execute:

```
bundle install
```

Or install it yourself as:

```
gem install geonames_dump
```

To speed up imports with > 10x add the active-import gem:

```
gem 'activerecord-import'
```

(this gem will add `#bulk_import` to all AR classes; so make sure that works, otherwise it will go with the traditional flow)

## Usage

Create models and migration files

```
rails generate geonames:install
```

Import data (takes a loonnnng time!), it will download data, import countries
and many features (Countries, Cities having more than 15000 people, Admin1
(first administrative subdivision), Admin2 (second level administrative
subdivision))

```
rake geonames:install
```

If you need more fine grained control over the installation process you can run
individual geoname rake tasks instead of the all-in-one install :

```
$ rake -T | grep geonames

rake geonames:import:all               # Import ALL geonames data.
rake geonames:import:many              # Import most of geonames data.

rake geonames:import:admin1            # Import admin1 codes
rake geonames:import:admin2            # Import admin2 codes
rake geonames:import:cities            # Import all cities, regardless of population.
rake geonames:import:cities1000        # Import cities with population greater than 1000
rake geonames:import:cities15000       # Import cities with population greater than 15000
rake geonames:import:cities500        # Import cities with population greater than 1000
rake geonames:import:cities5000        # Import cities with population greater than 5000
rake geonames:import:countries         # Import countries informations
rake geonames:import:features          # Import feature data.
rake geonames:import:alternate_names   # Import alternate names
rake geonames:import:hierarchy         # Import hierarchies

rake geonames:truncate:all             # Truncate all geonames data.
rake geonames:truncate:countries       # Truncate countries informations
rake geonames:truncate:admin1          # Truncate admin1 codes
rake geonames:truncate:admin2          # Truncate admin2 codes
rake geonames:truncate:cities          # Truncate cities informations
rake geonames:truncate:features        # Truncate features informations
rake geonames:truncate:alternate_names # Import alternate names
```

### Environment variables

* `IMPORT_STYLE=traditional` will enforce the traditional import; resulting in many creates
* `IMPORT_STYLE=quick` will enforce the traditional 'quick' import; still resulting in many creates; but not checking for existence
* `ALTERNATE_NAMES_LANG=<langcode>` will enforce alternate names to be selected for the given language
* `COUNTRY=<countrycode>` will download all features and alternate names for a given country

For example, to have a high resolution import on a single country, but global names for the rest of the world, use:

COUNTRY=nl ALTERNATE_NAMES_LANG=nl rails geonames:import:all

## Geonames data usage

The above commands will import geonames data in your Rails application, in
other words, this will create models and fill database with place/city/country
informations.

A convenient way to search for data is to use Geonames search accessor
`Geonames.search`. This method interate on data types to find a result.
Search order is the following :

1. Cities
2. Alternate names (localised names)
3. First level admin subdivisions
4. Second level admin subdivisions
5. (other) Features (lakes, mountains and others various features)

Now to find a city for example :

```
Geonames.search('paris')
Geonames.search('東京') # tokyo :-)
```

If your request is ambiguous, like not searching Dublin in Ireland but Dublin
in the USA, you may specify country :

```
Geonames.search('dublin').first.country_code
=> 'IE'
Geonames.search('dublin, us').first.country_code
=> 'US'
```

If needed, requested type may be specified too :

```
Geonames.search('dublin', type: :city)
Geonames.search('dublin, us', type: :city)
Geonames.search('paris', type: :feature)
```

As `Geonames.search` is returning `Feature` objects by default, type should
specified to search for Countries :

```
Geonames.search('Ireland', type: :country)
```

The following types are available :

- `:admin1`, for first level of adminstrative subdivision
- `:admin2`, for second level of adminstrative subdivision
- `:city`, for city names
- `:feature`, for generic names including all the above
- `:auto`, to find any type of feature (even with non-latin characters) matching the query
- `:alternate_name`, for names in non-latin alphabets (may be useless)
- `:country`, for country names

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
