# Hash19
[![Build Status](https://travis-ci.org/rcdexta/hash19.svg)](https://travis-ci.org/rcdexta/hash19)
[![Gem Version](https://badge.fury.io/rb/hash19.svg)](http://badge.fury.io/rb/hash19)
[![Coverage Status](https://img.shields.io/coveralls/rcdexta/hash19.svg)](https://coveralls.io/r/rcdexta/hash19)

![Hash-19](https://s3-us-west-1.amazonaws.com/rcdexta/hash-19-droid.png)

>*Hash-19 is as an assassin droid in the Star Wars Universe. These are durasteel drones uploaded with only the most archaic kill programs* <sup>[Wookieepedia]</sup>

Ahem.. Ahem.. So about this gem itself.. When I was writing an aggregation API that had to talk to multiple services each with their own REST end-points and JSON schema, when mashing up multiple hashes and transforming it to a structure acceptable to the consumer, I ended up writing lot of boiler plate code. I could see patterns and there was clearly scope for optimisation.

A [detailed writeup](https://medium.com/@rcdexta/hash19-a-json-aggregation-library-f2ef43d64a86) explaining the need is available for reading.

Hash19 is an attempt at offering a DSL to tame the JSON manipulation and help in dealing with common use-cases. The features include

* whitelisting attributes
* attribute aliasing and keying
* `has_one` and `has_many` associations 
* lazy loading associations via triggers
* mass injection of associations using bulk APIs

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'hash19'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hash19

### One example for all
```ruby
class Jedi
    include Hash19
    attributes :name, :saber, :padawan_id
    attribute :master, key: :trained_by
    has_one :padawan, using: :padawan_id, trigger: ->(id) { Padawan.find id }
    has_many :killings
end

class Padawan
    include Hash19
    attributes :id, :name
    def find(id)..end #implementation hidden
    def find_all(ids)..end #implementation hidden
end

json = '[{"name": "Anakin Skywalker", "saber": "Single Blade Blue",  "trained_by": "Obi Wan",
         "padawan": {"id": 201, "name": "Ahsoka Tano"}},
        {"name": "Mace Windu", "saber": "Single Blade Violet", "padawan_id": 132, "trained_by": "Yoda"}]'
        
jedis = JSON.parse(json)    
Jedi.new(jedis.first).to_h #{"name"=>"Anakin Skywalker", "saber"=>"Single Blade Blue", "master"=>"Obi Wan",
                           #"padawan"=>{"id"=>201, "name"=>"Ahsoka Tano"}}
                           
Jedi.new(jedis.last).to_h #{"name"=>"Mace Windu", "saber"=>"Single Blade Violet", "master"=>"Yoda",
                           #"padawan"=>{"id"=>132, "name"=>"Depa Billaba["}}

```
All aspects of the code are explained with detailed examples below. This gives a quick snapshot of what the gem can do. Ergo...
* the attributes `name`, `saber` and `padawan_id` have been whitelisted. Any other attribute in the JSON will be ignored
* the attributes can have aliases in the actual JSON
* there can be an inline relationship within the JSON with another entity. For example, each `Jedi` entity can contain a `padawan` object. If the association already exists, it will be transformed. This is true for the first Jedi in the example
* If the association is not present in the JSON, it is lazy loaded. The first call to the attribute will call the trigger to fetch the association, if not present. In this case, for the second Jedi, a call `Padawan#find` will be triggered and the association fetched.

Now, this immediately raises the question about firing multiple calls to Padawan#find when there are many entries without the association populated. And that's where injection is recommended:

```ruby
class Jedis
    include Hash19 
    contains :jedi
    inject at: '$', using: :padawan_id, reference: :id, 
           trigger: lambda { |ids| Padawan.find_all ids }, as: 'padawan'
end
```
This is like a wrapper class for the Jedi collection. It collects all `padawan_ids` from the complete JSON, calls `Padawan#find_all` once, the bulk-api equivalent of `find`, with a list of ids and injects the content back to the main collection at appropriate places as defined by the json_path in `at`

## Usage

To get started, include the Hash19 module in the target class and you are good.

A detailed documentation of all features can be found below:

###1. Whitelisting attributes
```ruby
 class SuperHero 
	 include Hash19
	 attributes :name, :strength
	 attribute :universe, key: :comic
 end
 ```
 Assume a JSON payload has many more attributes
 ```json
 [{"name": "Flash", "strength": "Speed", "last_seen": "never", "comic": "DC"},
  {"name": "Magneto", "strength": "Magnetism Control", "first_seen": 1963, "comic": "Marvel"},
  {"name": "Hulk", "strength": "Super Strength", "weakness": "temper", "comic": "Marvel"}]
  ```
  When this JSON is thrown at a Hash19 class...
  ```ruby
    payload = JSON.parse(json)
    results = payload.map { |hash| SuperHero.new(hash).to_h }
    print results #[{"name"=>"Flash", "strength"=>"Speed", "universe"=>"DC"},
                  # {"name"=>"Magneto", "strength"=>"Magnetism Control", "universe"=>"Marvel"},
                  # {"name"=>"Hulk", "strength"=>"Super Strength", "universe"=>"Marvel"}]
  ```
  Note that only the whitelisted attributes are accepted and keys can be aliased. The `to_h` method converts the native hash19 object into a ruby hash. 
  
###2. Still a hash
The Hash19 object acts as a wrapper to Ruby Hash. All hash operations are supported by the wrapper. But, finally `to_h` should be called to retrieve the underlying hash.
``` ruby
 hero = SuperHero.new(name: "Flash", strength: "Speed", comic: "DC")
 hero[:name] #Flash
 hero[:nick_name] = "Scarlet Speedster"
 hero.keys #["name", "strength", "universe", "nick_name"]
 hero.to_h #{"name"=>"Flash", "strength"=>"Speed", "universe"=>"DC", "nick_name"=>"Scarlet Speedster"}
```
###3. Associations
One-to-one and One-to-many relationships are supported. All associations are lazy loaded unless present directly in the root JSON.
```ruby
class Hashable
    include Hash19
end
class SuperVillain < Hashable
    attribute :name
    has_many :minions
    has_one :doctor
end
class Minion < Hashable
  attributes :name, :sound
end
class Doctor < Hashable
  attribute :name
end
```
Now, a JSON of the following structure
```json
{"name": "Gru", "doctor": {"name": "Nefario"}, 
"minions": [{"name": "Poppadom", "sound": "Weebaa"},{"name": "Gelato", "sound": "Ooojaa"}]
```
can be parsed with all associations loaded when calling `SuperVillain.new(json_as_hash)`

If the parent JSON does not contain the associations and they are powered by separate API calls, we can specify triggers to load them.
```ruby
class SuperVillain < Hashable
    attribute :name, doctor_id
    has_one :doctor, using: :doctor_id, trigger: ->(id) { Error.find id }
end
```
If you notice the trigger, the `using` parameter denotes the attribute to use to fetch the association and the lambda passed to `trigger` will be invoked to fetch the association. This is lazy loaded, in the sense when a call is made to `.doctor` or `.to_h`, the trigger is fired.

Associations also support alternate keys and aliasing... The below code snippet illustrates use of a different key in source json, the class to use to construct the object and the alias key in the target.

```ruby
has_one :child, key: :offspring, alias: :junior
{offspring: {name: 'Luke Skywalker'}} # will be parsed as {'junior' => {'name' => 'Luke Skywalker'}}
```


###4. Bulk Injections

Left to itself with associations, when the root JSON is a large collection with none of the associations populated in the first place, there will be several triggers fired for each item in the collection. This is the HTTP equivalent of `N+1` in the ORM world. To avoid this, Hash19 supports association injections. Let's dive into an example:

```ruby
class SuperHeroes < Hashable
    contains :super_heroes
    inject at: '$', using: :weapon_id, reference: :id, trigger: lambda { |ids| Weapon.find_all ids }
  end

  class SuperHero < Hashable
    attributes :name, :power, :weapon_id
    has_one :weapon, using: :weapon_id, trigger: lambda { |id| Weapon.find id }
  end

  class Weapon < Hashable
    attributes :name, :id
    def find_all(ids)..end #calls bulk API across wire. Implementation hidden
  end
```
If you notice, `SuperHeroes` is a wrapper class around `SuperHero`. This is the object equivalent of a JSON collection. The `inject` method will extract `weapon_id` from all items in the collection based on the json-path specified by `at` and call the `trigger` and put back the resultant entities joining `superhero.weapon_id` and `weapon.id`

So, a json like below
```ruby
super_heros = SuperHeroes.new([{name: 'iron man', power: 'none', weapon_id: 1},
				{name: 'thor', power: 'class 100', weapon_id: 2},
				{name: 'hulk', power: 'bulk', weapon_id: 3}])
```

will lead to one call to `Weapon#find_all` with params `[1,2,3]` to fetch all weapon details. And the final collection will be of the form:
```ruby
super_heroes.to_h #[{'name' => 'iron man', 'power' => 'none', 'weapon' => {'name' => 'jarvis', 'id' => 1}},
                  #{'name' => 'thor', 'power' => 'class 100', 'weapon' => {'name' => 'hammer', 'id' => 2}},
                  #{'name' => 'hulk', 'power' => 'bulk', 'weapon' => {'name' => 'hands', 'id' => 3}}
```

Note that `injection` always overrides the association trigger since the former is eager loaded and latter is lazy loaded thus avoiding the `N+1` calls. 

One other important thing to remember is that all the injections will happen in parallel. Hash19 uses [eldritch](https://github.com/beraboris/eldritch) gem to trigger multiple injections concurrently.

Please refer to the [tests](https://github.com/rcdexta/hash19/tree/master/spec/hash19) for more examples and documentation.

## Contributing

1. Fork it ( https://github.com/rcdexta/hash19/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


  
  
